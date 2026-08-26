local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local SlideLinearVelocity = ParkourAssets:WaitForChild("SlideLinearVelocity")

local Sliding = {}
Sliding.__index = Sliding

function Sliding.new(context, returnToLocomotion, config)
	local self = setmetatable({}, Sliding)

	self.rootPart = context.rootPart
	self.humanoid = context.humanoid

	self.elapsedTime = 0

	self.config = config

	self.linearVelocity = nil
	self.attachment = context.attachment

	self.horizontalLookDir = nil
	self.slideSpeed = nil

	self.onFinished = returnToLocomotion

	self.connection = nil

	self.animationController = context.animationController
	self.sfxController = context.sfxController

	self.isActive = false

	return self
end

function Sliding:CreateLinearVelocity()
	local linearVelocity = SlideLinearVelocity:Clone()
	linearVelocity.Attachment0 = self.attachment

	local force = self.rootPart.AssemblyMass * 1000
	linearVelocity.MaxPlanarAxesForce = Vector2.new(force, force)

	linearVelocity.Parent = self.rootPart

	self.linearVelocity = linearVelocity
end

function Sliding:CalculateSlideMovement()
	local lookVec = self.rootPart.CFrame.LookVector
	local horizontalLookDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local velocity = self.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local horizontalSpeed = horizontalVelocity.Magnitude
	local slideSpeed = horizontalSpeed + self.config.Boost

	self.horizontalLookDir = horizontalLookDir
	self.slideSpeed = slideSpeed
end

function Sliding:Enter()
	self.isActive = true
	self.humanoid.AutoRotate = false

	self:CreateLinearVelocity()
	self:CalculateSlideMovement()

	self.animationController:Play("Sliding", 0.08)
	self.sfxController:Play("Sliding")

	self.connection = RunService.PreSimulation:Connect(function(dt)
		self:Update(dt)
	end)
end

function Sliding:Update(dt)
	self.elapsedTime += dt

	self.linearVelocity.PlaneVelocity =
		Vector2.new(self.horizontalLookDir.X * self.slideSpeed, self.horizontalLookDir.Z * self.slideSpeed)

	self.slideSpeed = math.max(0, self.slideSpeed - self.config.Deceleration * dt)

	if self.elapsedTime >= self.config.Duration or self.slideSpeed <= self.config.MinSpeed then
		self.animationController:Stop("Sliding", 0.2)
		self.onFinished()
	end
end

function Sliding:Exit()
	self.connection:Disconnect()
	self.connection = nil

	self.linearVelocity:Destroy()
	self.linearVelocity = nil

	self.isActive = false
	self.humanoid.AutoRotate = true

	self.elapsedTime = 0
	self.slideSpeed = 0
end

function Sliding:Destroy()
	if self.isActive then
		self.humanoid.AutoRotate = true
		self.isActive = nil
	end

	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	if self.linearVelocity then
		self.linearVelocity:Destroy()
		self.linearVelocity = nil
	end

	self.rootPart = nil
	self.humanoid = nil

	self.attachment = nil

	self.elapsedTime = nil

	self.config = nil

	self.horizontalLookDir = nil
	self.slideSpeed = nil

	self.onFinished = nil

	self.animationController = nil
	self.sfxController = nil
end

return Sliding
