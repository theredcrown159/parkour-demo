local Walking = {}
Walking.__index = Walking

function Walking.new(humanoid, config)
	local self = setmetatable({}, Walking)

	self.humanoid = humanoid
	self.config = config

	return self
end

function Walking:Enter()
	self.humanoid.WalkSpeed = self.config.WalkSpeed
end

return Walking
