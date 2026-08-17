local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParkourConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ParkourConfig"))

local States = script.Parent:WaitForChild("states")
local SlidingState = require(States:WaitForChild("Sliding"))
local WalkingState = require(States:WaitForChild("Walking"))
local SprintingState = require(States:WaitForChild("Sprinting"))
local VaultingState = require(States:WaitForChild("Vaulting"))
local FallingState = require(States:WaitForChild("Falling"))
local LedgeGrabState = require(States:WaitForChild("LedgeGrab"))
local LedgeClimbState = require(States:WaitForChild("LedgeClimb"))

local AnimationController = require(script.Parent:WaitForChild("AnimationController"))

local ALLOWED_TRANSITIONS = {
	None = {
		Walking = true,
	},
	Falling = {
		Walking = true,
		Sprinting = true,
		LedgeGrab = true,
	},
	Walking = {
		Falling = true,
		Sprinting = true,
		Vaulting = true,
		LedgeGrab = true,
	},
	Sprinting = {
		Falling = true,
		Walking = true,
		Sliding = true,
		Vaulting = true,
		LedgeGrab = true,
	},
	Sliding = {
		Walking = true,
		Sprinting = true,
	},
	Vaulting = {
		Walking = true,
		Sprinting = true,
	},
	LedgeGrab = {
		Falling = true,
		LedgeClimb = true,
	},
	LedgeClimb = {
		Walking = true,
		Sprinting = true,
	},
}

local ParkourController = {}
ParkourController.__index = ParkourController

function ParkourController.new()
	local self = setmetatable({}, ParkourController)

	self.state = "None"
	self.states = {}
	self.wantsSprint = false

	self.player = game.Players.LocalPlayer
	self.character = nil
	self.rootPart = nil
	self.humanoid = nil

	self.attachment = nil

	self.connections = {}

	self.animationController = nil

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

	self.states[self.state]:Exit()
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

function ParkourController:RequestJump()
	local canLedgeClimb = self.states.LedgeClimb:Check()
	if self.state == "LedgeGrab" and canLedgeClimb then
		self:TransitionTo("LedgeClimb")
		return
	end

	local canVault = self.states.Vaulting:Check()
	if canVault then
		self:TransitionTo("Vaulting")
		return
	end

	self:TransitionTo("Falling")
end

function ParkourController:ReturnToLocomotion()
	local nextState = self.wantsSprint and "Sprinting" or "Walking"
	return self:TransitionTo(nextState)
end

function ParkourController:TryLedgeGrab()
	if not self.states.LedgeGrab:Check() then
		return false
	end
	return self:TransitionTo("LedgeGrab")
end

function ParkourController:CreateStates()
	local characterContext = {
		character = self.character,
		humanoid = self.humanoid,
		rootPart = self.rootPart,
		config = ParkourConfig,
		attachment = self.attachment,
		animationController = self.animationController,
	}

	local returnToLocomotion = function()
		return self:ReturnToLocomotion()
	end

	local tryLedgeGrab = function()
		return self:TryLedgeGrab()
	end

	self.states = {
		Walking = WalkingState.new(characterContext),
		Sprinting = SprintingState.new(characterContext),
		Sliding = SlidingState.new(characterContext, returnToLocomotion),
		Vaulting = VaultingState.new(characterContext, returnToLocomotion),
		LedgeGrab = LedgeGrabState.new(characterContext),
		LedgeClimb = LedgeClimbState.new(characterContext, returnToLocomotion),
		Falling = FallingState.new(characterContext, returnToLocomotion, tryLedgeGrab),
	}
end

function ParkourController:SetCharacter(character)
	self.character = character
	self.rootPart = self.character:WaitForChild("HumanoidRootPart")
	self.humanoid = self.character:WaitForChild("Humanoid")

	self.animationController = AnimationController.new(self.humanoid)

	self:CreateAttachment()

	self:CreateStates()

	self.state = "Walking"
	self.states.Walking:Enter()
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
