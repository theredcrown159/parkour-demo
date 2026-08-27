local RunService = game:GetService("RunService")

local Walking = {}
Walking.__index = Walking

function Walking.new(context, config)
	local self = setmetatable({}, Walking)

	self.humanoid = context.humanoid
	self.config = config

	self.currentAnimation = nil

	self.updateConnection = nil
	self.footstepConnection = nil

	self.animationController = context.animationController
	self.sfxController = context.sfxController

	return self
end

function Walking:Enter()
	self.humanoid.WalkSpeed = self.config.Speed

	self.updateConnection = RunService.PreSimulation:Connect(function()
		self:Update()
	end)

	local footstepSignal = self.animationController:GetAnimationMarkerSignal("Walking", "Footstep")

	if footstepSignal then
		self.footstepConnection = footstepSignal:Connect(function()
			self.sfxController:Play("Footstep")
		end)
	end
end

function Walking:Update()
	local nextAnimation = self.humanoid.MoveDirection.Magnitude > 0 and "Walking" or "Idle"
	if nextAnimation ~= self.currentAnimation then
		self.animationController:Stop(self.currentAnimation, 0.15)
		self.animationController:Play(nextAnimation, 0.15)

		self.currentAnimation = nextAnimation
	end
end

function Walking:Exit()
	if self.updateConnection then
		self.updateConnection:Disconnect()
		self.updateConnection = nil
	end

	if self.footstepConnection then
		self.footstepConnection:Disconnect()
		self.footstepConnection = nil
	end

	self.animationController:Stop(self.currentAnimation, 0.15)

	self.currentAnimation = nil
end

function Walking:Destroy()
	if self.updateConnection then
		self.updateConnection:Disconnect()
		self.updateConnection = nil
	end

	if self.footstepConnection then
		self.footstepConnection:Disconnect()
		self.footstepConnection = nil
	end

	self.animationController:Stop(self.currentAnimation, 0)

	self.humanoid = nil
	self.config = nil

	self.currentAnimation = nil

	self.animationController = nil
	self.sfxController = nil
end

return Walking
