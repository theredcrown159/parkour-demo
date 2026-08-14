local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local SlideLinearVelocity = ParkourAssets:WaitForChild("SlideLinearVelocity")

local Slide = {}
Slide.__index = Slide

function Slide.new(rootPart, humanoid, attachment, config, onFinished)
	local self = setmetatable({}, Slide)

	self.rootPart = rootPart
	self.humanoid = humanoid

	self.elapsedTime = 0

	self.config = config

	self.linearVelocity = nil
	self.attachment = attachment

	self.horizontalLookDir = nil
	self.slideSpeed = nil

	self.onFinished = onFinished

	self.connection = nil

	return self
end

function Slide:CreateLinearVelocity()
	local linearVelocity = SlideLinearVelocity:Clone()
	linearVelocity.Attachment0 = self.attachment

	local force = self.rootPart.AssemblyMass * 1000
	linearVelocity.MaxPlanarAxesForce = Vector2.new(force, force)

	linearVelocity.Parent = self.rootPart

	self.linearVelocity = linearVelocity
end

function Slide:CalculateSlideMovement()
	local lookVec = self.rootPart.CFrame.LookVector
	local horizontalLookDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local velocity = self.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local horizontalSpeed = horizontalVelocity.Magnitude
	local slideSpeed = horizontalSpeed + self.config.SlideBoost

	self.horizontalLookDir = horizontalLookDir
	self.slideSpeed = slideSpeed
end

function Slide:Start()
	self.humanoid.AutoRotate = false

	self:CreateLinearVelocity()
	self:CalculateSlideMovement()

	self.connection = RunService.PreSimulation:Connect(function(dt)
		self:Update(dt)
	end)
end

function Slide:Update(dt)
	self.elapsedTime += dt

	self.linearVelocity.PlaneVelocity =
		Vector2.new(self.horizontalLookDir.X * self.slideSpeed, self.horizontalLookDir.Z * self.slideSpeed)

	self.slideSpeed = math.max(0, self.slideSpeed - self.config.SlideDeceleration * dt)

	if self.elapsedTime >= self.config.SlideDuration then
		self:Exit()
	end
end

function Slide:Exit()
	self.humanoid.AutoRotate = true

	self.linearVelocity:Destroy()
	self.connection:Disconnect()
	self.onFinished()
end

return Slide
