local Sprinting = {}
Sprinting.__index = Sprinting

function Sprinting.new(context, config)
	local self = setmetatable({}, Sprinting)

	self.humanoid = context.humanoid
	self.config = config

	self.animationController = context.animationController

	return self
end

function Sprinting:Enter()
	self.humanoid.WalkSpeed = self.config.Speed

	self.animationController:Play("Sprinting", 0.15)
end

function Sprinting:Exit()
	self.animationController:Stop("Sprinting", 0.15)
end

function Sprinting:Destroy()
	self.animationController:Stop("Sprinting", 0)

	self.humanoid = nil
	self.config = nil

	self.animationController = nil
end

return Sprinting
