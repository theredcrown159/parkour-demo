local InputController = {}
InputController.__index = InputController

function InputController.new(parkourController)
	local self = setmetatable({}, InputController)

	self.parkourController = parkourController

	self.PlayContext = game:GetService("ReplicatedStorage"):WaitForChild("Input"):WaitForChild("PlayContext")
	self.Sprint = self.PlayContext:WaitForChild("Sprint")

	self.connections = {}

	return self
end

function InputController:Start()
	local pressedConnection = self.Sprint.Pressed:Connect(function()
		self.parkourController:TransitionTo("Sprinting")
	end)

	local releasedConnection = self.Sprint.Released:Connect(function()
		self.parkourController:TransitionTo("Walking")
	end)

	table.insert(self.connections, pressedConnection)
	table.insert(self.connections, releasedConnection)
end

function InputController:Destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end

	self.connections = {}
end

return InputController
