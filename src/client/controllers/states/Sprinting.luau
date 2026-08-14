local Sprinting = {}
Sprinting.__index = Sprinting

function Sprinting.new(humanoid, config)
	local self = setmetatable({}, Sprinting)

	self.humanoid = humanoid
	self.config = config

	return self
end

function Sprinting:Enter()
	self.humanoid.WalkSpeed = self.config.SprintSpeed
end

return Sprinting
