local ParkourController = {}
ParkourController.__index = ParkourController

function ParkourController.new()
	local self = setmetatable({}, ParkourController)

	self.state = "Normal"

	return self
end

function ParkourController:CanTransitionTo(newState)
	if self.state == "Normal" and newState == "Sprinting" then
		return true
	elseif self.state == "Sprinting" and (newState == "Normal" or newState == "Sliding") then
		return true
	elseif self.state == "Sliding" and (newState == "Normal" or newState == "Sprinting") then
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

return ParkourController
