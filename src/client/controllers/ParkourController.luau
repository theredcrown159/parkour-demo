local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParkourConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ParkourConfig"))

local States = script.Parent:WaitForChild("states")
local SlideState = require(States:WaitForChild("Slide"))

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

	self.attachment = nil

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

	local onFinished = function()
		if self.wantsSprint then
			self:TransitionTo("Sprinting")
		else
			self:TransitionTo("Walking")
		end
	end

	local slide = SlideState.new(self.rootPart, self.humanoid, self.attachment, ParkourConfig, onFinished)
	slide:Start()

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

	self:CreateAttachment()

	self.state = "Walking"
end

function ParkourController:CreateAttachment()
	local attachment = Instance.new("Attachment")
	attachment.Parent = self.rootPart

	self.attachment = attachment
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
