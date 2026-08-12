local ParkourController = {}
ParkourController.__index = ParkourController

function ParkourController.new()
	local self = setmetatable({}, ParkourController)

	self.state = "Walking"
	self.player = game.Players.LocalPlayer
	self.conennctions = {}

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

	return true
end

function ParkourController:SetCharacter(character)
	self.character = character
	self.humanoid = self.character:WaitForChild("Humanoid")

	self.state = "Walking"
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
