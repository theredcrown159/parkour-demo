local Sprinting = {}
Sprinting.__index = Sprinting

function Sprinting.new(context, config)
	local self = setmetatable({}, Sprinting)

	self.humanoid = context.humanoid
	self.config = config

	self.footstepConnection = nil

	self.animationController = context.animationController
	self.sfxController = context.sfxController

	return self
end

function Sprinting:Enter()
	self.humanoid.WalkSpeed = self.config.Speed

	self.animationController:Play("Sprinting", 0.15)

	local footstepSignal = self.animationController:GetAnimationMarkerSignal("Sprinting", "Footstep")

	if footstepSignal then
		self.footstepConnection = footstepSignal:Connect(function()
			self.sfxController:Play("Footstep")
		end)
	end
end

function Sprinting:Exit()
	if self.footstepConnection then
		self.footstepConnection:Disconnect()
		self.footstepConnection = nil
	end

	self.animationController:Stop("Sprinting", 0.15)
end

function Sprinting:Destroy()
	if self.footstepConnection then
		self.footstepConnection:Disconnect()
		self.footstepConnection = nil
	end

	self.animationController:Stop("Sprinting", 0)

	self.humanoid = nil
	self.config = nil

	self.animationController = nil
	self.sfxController = nil
end

return Sprinting
