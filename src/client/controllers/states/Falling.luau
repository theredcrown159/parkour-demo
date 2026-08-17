local RunService = game:GetService("RunService")

local Falling = {}
Falling.__index = Falling

function Falling.new(context, returnToLocomotion, tryLedgeGrab)
	local self = setmetatable({}, Falling)

	self.humanoid = context.humanoid
	self.rootPart = context.rootPart

	self.onFinished = returnToLocomotion

	self.animationController = context.animationController

	self.connection = nil

	self.tryLedgeGrab = tryLedgeGrab

	return self
end

function Falling:Enter()
	self.connection = RunService.PreSimulation:Connect(function()
		self:Update()
	end)
end

function Falling:Update()
	local yVelocity = self.rootPart.AssemblyLinearVelocity.Y
	local isJumping = yVelocity > 0
	local isFalling = yVelocity < 0
	local isLanded = self.humanoid:GetState() == Enum.HumanoidStateType.Landed

	if isJumping then
		self.animationController:Play("Jumping")
	elseif isFalling and not isLanded then
		local canLedgeGrab = self.tryLedgeGrab()

		if canLedgeGrab then
			self.animationController:Stop("Jumping")
		else
			self.animationController:Stop("Jumping")
			self.animationController:Play("Falling")
		end
	elseif isLanded then
		self.animationController:Stop("Falling", 0.15)
		self.onFinished()
	end
end

function Falling:Exit()
	self.animationController:Stop("Falling", 0.15)

	self.connection:Disconnect()
	self.connection = nil
end

function Falling:Destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	self.animationController:Stop("Jumping", 0)
	self.animationController:Stop("Falling", 0)

	self.humanoid = nil
	self.rootPart = nil

	self.onFinished = nil

	self.animationController = nil

	self.tryLedgeGrab = nil
end

return Falling
