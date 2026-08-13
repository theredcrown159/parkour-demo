local InputController = {}
InputController.__index = InputController

function InputController.new(parkourController)
	local self = setmetatable({}, InputController)

	self.parkourController = parkourController

	self.PlayContext = game:GetService("ReplicatedStorage"):WaitForChild("Input"):WaitForChild("PlayContext")
	self.Slide = self.PlayContext:WaitForChild("Slide")
	self.Sprint = self.PlayContext:WaitForChild("Sprint")

	self.connections = {}

	return self
end

function InputController:Start()
	local pressedSlideConnection = self.Slide.Pressed:Connect(function()
		self.parkourController:RequestSlide()
	end)

	local pressedSprintConnection = self.Sprint.Pressed:Connect(function()
		self.parkourController:SetSprintIntent(true)
	end)

	local releasedSprintConnection = self.Sprint.Released:Connect(function()
		self.parkourController:SetSprintIntent(false)
	end)

	table.insert(self.connections, pressedSlideConnection)
	table.insert(self.connections, pressedSprintConnection)
	table.insert(self.connections, releasedSprintConnection)
end

function InputController:Destroy()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end

	self.connections = {}
end

return InputController
