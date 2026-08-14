local Sprinting = {}
Sprinting.__index = Sprinting

function Sprinting.new(humanoid, config, animationController)
	local self = setmetatable({}, Sprinting)

	self.humanoid = humanoid
	self.config = config

	self.animationController = animationController

	return self
end

function Sprinting:Enter()
	self.humanoid.WalkSpeed = self.config.SprintSpeed

	self.animationController:Play("Sprinting", 0.15)
end

function Sprinting:Exit()
	self.animationController:Stop("Sprinting", 0.15)
end

return Sprinting
