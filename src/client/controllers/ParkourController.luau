local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParkourConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ParkourConfig"))

local States = script.Parent:WaitForChild("states")
local SlidingState = require(States:WaitForChild("Sliding"))
local WalkingState = require(States:WaitForChild("Walking"))
local SprintingState = require(States:WaitForChild("Sprinting"))

local ALLOWED_TRANSITIONS = {
	Walking = {
		Sprinting = true,
	},
	Sprinting = {
		Walking = true,
		Sliding = true,
	},
	Sliding = {
		Walking = true,
		Sprinting = true,
	},
}

local ParkourController = {}
ParkourController.__index = ParkourController

function ParkourController.new()
	local self = setmetatable({}, ParkourController)

	self.state = "Walking"
	self.states = {}
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
	local transitions = ALLOWED_TRANSITIONS[self.state]
	return transitions ~= nil and transitions[newState] == true
end

function ParkourController:TransitionTo(state)
	if not self:CanTransitionTo(state) then
		return false
	end

	self.state = state
	self.states[state]:Enter()

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

function ParkourController:SetSprintIntent(isSprinting)
	self.wantsSprint = isSprinting
	self:UpdateState()
end

function ParkourController:RequestSlide()
	self:TransitionTo("Sliding")
end

function ParkourController:SetCharacter(character)
	self.character = character
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.humanoid = self.character:WaitForChild("Humanoid")

	self:CreateAttachment()

	self.state = "Walking"

	self.states = {
		Walking = WalkingState.new(self.humanoid, ParkourConfig),
		Sprinting = SprintingState.new(self.humanoid, ParkourConfig),
		Sliding = SlidingState.new(self.rootPart, self.humanoid, self.attachment, ParkourConfig, function()
			if self.wantsSprint then
				self:TransitionTo("Sprinting")
			else
				self:TransitionTo("Walking")
			end
		end),
	}
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
