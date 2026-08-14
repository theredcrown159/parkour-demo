local RunService = game:GetService("RunService")

local Walking = {}
Walking.__index = Walking

function Walking.new(humanoid, config, animationController)
	local self = setmetatable({}, Walking)

	self.humanoid = humanoid
	self.config = config

	self.currentState = "Idle"

	self.connection = nil

	self.animationController = animationController

	return self
end

function Walking:Enter()
	self.humanoid.WalkSpeed = self.config.WalkSpeed

	self.connection = RunService.PreSimulation:Connect(function()
		self:Update()
	end)
end

function Walking:Update()
	if self.humanoid.MoveDirection.Magnitude > 0 then
		self.currentState = "Walking"

		self.animationController:Stop("Idle", 0.15)
		self.animationController:Play("Walking", 0.15)
	else
		self.currentState = "Idle"

		self.animationController:Stop("Walking", 0.15)
		self.animationController:Play("Idle", 0.15)
	end
end

function Walking:Exit()
	self.connection:Disconnect()
	self.animationController:Stop(self.currentState, 0.15)
end

return Walking
