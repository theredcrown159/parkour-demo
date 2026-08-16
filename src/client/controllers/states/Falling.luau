local RunService = game:GetService("RunService")

local Falling = {}
Falling.__index = Falling

function Falling.new(humanoid, rootPart, onFinished)
	local self = setmetatable({}, Falling)

	self.humanoid = humanoid
	self.rootPart = rootPart

	self.onFinished = onFinished

	self.connection = nil

	return self
end

function Falling:Enter()
	self.connection = RunService.PreSimulation:Connect(function()
		self:Update()
	end)
end

function Falling:Update()
	if self.humanoid:GetState() == Enum.HumanoidStateType.Landed then
		self.onFinished()
	end
end

function Falling:Exit()
	self.connection:Disconnect()
end

return Falling
