local RunService = game:GetService("RunService")

local Falling = {}
Falling.__index = Falling

function Falling.new(context, returnToLocomotion, tryLedgeGrab)
	local self = setmetatable({}, Falling)

	self.humanoid = context.humanoid
	self.rootPart = context.rootPart

	self.onFinished = returnToLocomotion

	self.animationController = context.animationController
	self.sfxController = context.sfxController
	self.vfxController = context.vfxController

	self.connection = nil

	self.tryLedgeGrab = tryLedgeGrab

	self.stateChangedConnection = nil

	return self
end

function Falling:Enter()
	self.stateChangedConnection = self.humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			self.sfxController:Play("Landing")
			self.vfxController:CreateLandingDebris()
			self.onFinished()
		end
	end)

	self.connection = RunService.PreSimulation:Connect(function()
		self:Update()
	end)
end

function Falling:Update()
	local yVelocity = self.rootPart.AssemblyLinearVelocity.Y
	local isJumping = yVelocity > 0
	local isFalling = yVelocity < 0

	if isJumping then
		self.animationController:Play("Jumping")
	elseif isFalling then
		local canLedgeGrab = self.tryLedgeGrab()

		if canLedgeGrab then
			self.animationController:Stop("Jumping")
		else
			self.animationController:Stop("Jumping")
			self.animationController:Play("Falling")
		end
	end
end

function Falling:Exit()
	self.animationController:Stop("Falling", 0.15)

	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	if self.stateChangedConnection then
		self.stateChangedConnection:Disconnect()
		self.stateChangedConnection = nil
	end
end

function Falling:Destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	if self.stateChangedConnection then
		self.stateChangedConnection:Disconnect()
		self.stateChangedConnection = nil
	end

	self.animationController:Stop("Jumping", 0)
	self.animationController:Stop("Falling", 0)

	self.humanoid = nil
	self.rootPart = nil

	self.onFinished = nil

	self.animationController = nil
	self.sfxController = nil
	self.vfxController = nil

	self.tryLedgeGrab = nil
end

return Falling
