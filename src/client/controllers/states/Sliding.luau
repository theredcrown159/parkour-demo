local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local SlideLinearVelocity = ParkourAssets:WaitForChild("SlideLinearVelocity")

local Sliding = {}
Sliding.__index = Sliding

function Sliding.new(context, returnToLocomotion)
	local self = setmetatable({}, Sliding)

	self.rootPart = context.rootPart
	self.humanoid = context.humanoid

	self.elapsedTime = 0

	self.config = context.config

	self.linearVelocity = nil
	self.attachment = context.attachment

	self.horizontalLookDir = nil
	self.slideSpeed = nil

	self.onFinished = returnToLocomotion

	self.connection = nil

	self.animationController = context.animationController

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
	local slideSpeed = horizontalSpeed + self.config.SlideBoost

	self.horizontalLookDir = horizontalLookDir
	self.slideSpeed = slideSpeed
end

function Sliding:Enter()
	self.humanoid.AutoRotate = false

	self:CreateLinearVelocity()
	self:CalculateSlideMovement()

	self.animationController:Play("Sliding", 0.08)

	self.connection = RunService.PreSimulation:Connect(function(dt)
		self:Update(dt)
	end)
end

function Sliding:Update(dt)
	self.elapsedTime += dt

	self.linearVelocity.PlaneVelocity =
		Vector2.new(self.horizontalLookDir.X * self.slideSpeed, self.horizontalLookDir.Z * self.slideSpeed)

	self.slideSpeed = math.max(0, self.slideSpeed - self.config.SlideDeceleration * dt)

	if self.elapsedTime >= self.config.SlideDuration or self.slideSpeed <= self.config.MinSlideSpeed then
		self.animationController:Stop("Sliding", 0.2)
		self.onFinished()
	end
end

function Sliding:Exit()
	self.humanoid.AutoRotate = true

	self.elapsedTime = 0
	self.slideSpeed = 0

	self.linearVelocity:Destroy()
	self.connection:Disconnect()
end

return Sliding
