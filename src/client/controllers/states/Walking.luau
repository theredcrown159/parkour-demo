local RunService = game:GetService("RunService")

local Walking = {}
Walking.__index = Walking

function Walking.new(context)
	local self = setmetatable({}, Walking)

	self.humanoid = context.humanoid
	self.config = context.config

	self.currentState = nil

	self.connection = nil

	self.animationController = context.animationController

	return self
end

function Walking:Enter()
	self.humanoid.WalkSpeed = self.config.WalkSpeed

	self.connection = RunService.PreSimulation:Connect(function()
		self:Update()
	end)
end

function Walking:Update()
	local nextState = self.humanoid.MoveDirection.Magnitude > 0 and "Walking" or "Idle"
	if nextState ~= self.currentState then
		self.animationController:Stop(self.currentState, 0.15)
		self.animationController:Play(nextState, 0.15)

		self.currentState = nextState
	end
end

function Walking:Exit()
	self.connection:Disconnect()
	self.connection = nil

	self.animationController:Stop(self.currentState, 0.15)

	self.currentState = nil
end

function Walking:Destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	self.animationController:Stop(self.currentState, 0)

	self.humanoid = nil
	self.config = nil

	self.currentState = nil

	self.animationController = nil
end

return Walking
