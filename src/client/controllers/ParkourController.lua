local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ParkourConfig"))

local ParkourController = {}
ParkourController.__index = ParkourController

function ParkourController.new()
	local self = setmetatable({}, ParkourController)

	self.state = "Walking"
	self.wantsSprint = false

	self.player = game.Players.LocalPlayer
	self.character = nil
	self.rootPart = nil
	self.humanoid = nil

	self.connections = {}

	return self
end

function ParkourController:CanTransitionTo(newState)
	if self.state == "Walking" and newState == "Sprinting" then
		return true
	elseif self.state == "Sprinting" and (newState == "Walking" or newState == "Sliding") then
		return true
	elseif self.state == "Sliding" and (newState == "Walking" or newState == "Sprinting") then
		return true
	else
		return false
	end
end

function ParkourController:TransitionTo(state)
	if not self:CanTransitionTo(state) then
		return false
	end

	self.state = state
	self:ApplyState(state)

	return true
end

function ParkourController:SetSprintIntent(isSprinting)
	self.wantsSprint = isSprinting
	self:UpdateState()
end

function ParkourController:RequestSlide()
	if not self:TransitionTo("Sliding") then
		return false
	end

	self:UpdateLinearVelocity()

	local elapsedTime = 0

	local lookVec = self.rootPart.CFrame.LookVector
	local horizontalLookDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local velocity = self.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	local horizontalSpeed = horizontalVelocity.Magnitude
	local slideSpeed = horizontalSpeed + ParkourConfig.SlideBoost

	self.humanoid.AutoRotate = false

	local connection
	connection = RunService.PreSimulation:Connect(function(dt)
		elapsedTime += dt

		self.linearVelocity.PlaneVelocity =
			Vector2.new(horizontalLookDir.X * slideSpeed, horizontalLookDir.Z * slideSpeed)

		slideSpeed = math.max(0, slideSpeed - ParkourConfig.SlideDeceleration * dt)

		if elapsedTime >= ParkourConfig.SlideDuration then
			self.linearVelocity.Enabled = false
			self.humanoid.AutoRotate = true

			connection:Disconnect()

			if self.wantsSprint then
				self:TransitionTo("Sprinting")
			else
				self:TransitionTo("Walking")
			end
		end
	end)

	return true
end

function ParkourController:UpdateState()
	if self.state == "Sliding" then
		return false
	end

	if self.wantsSprint and self.state == "Walking" then
		return self:TransitionTo("Sprinting")
	elseif not self.wantsSprint and self.state == "Sprinting" then
		return self:TransitionTo("Walking")
	else
		return false
	end
end

function ParkourController:ApplyState(state)
	if state == "Walking" then
		self.humanoid.WalkSpeed = ParkourConfig.WalkSpeed
	elseif state == "Sprinting" then
		self.humanoid.WalkSpeed = ParkourConfig.SprintSpeed
	end
end

function ParkourController:SetCharacter(character)
	self.character = character
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.humanoid = self.character:WaitForChild("Humanoid")

	self:CreateLinearVelocity()

	self.state = "Walking"
end

function ParkourController:CreateLinearVelocity()
	local attachment = Instance.new("Attachment")
	attachment.Parent = self.rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.Enabled = false
	linearVelocity.Parent = self.rootPart

	self.linearVelocity = linearVelocity
end

function ParkourController:UpdateLinearVelocity()
	if self.state == "Sliding" then
		self.linearVelocity.Enabled = true

		self.linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		self.linearVelocity.PrimaryTangentAxis = Vector3.new(1, 0, 0)
		self.linearVelocity.SecondaryTangentAxis = Vector3.new(0, 0, 1)

		self.linearVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis

		local force = self.rootPart.AssemblyMass * 1000
		self.linearVelocity.MaxPlanarAxesForce = Vector2.new(force, force)
	end
end

function ParkourController:Start()
	self:SetCharacter(self.player.Character or self.player.CharacterAdded:Wait())

	local charaterAddedConnection = self.player.CharacterAdded:Connect(function(character)
		self:SetCharacter(character)
	end)

	table.insert(self.connections, charaterAddedConnection)
end

function ParkourController:Destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end

	self.connections = {}
end

return ParkourController
