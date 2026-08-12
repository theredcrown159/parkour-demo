local InputController = {}
InputController.__index = InputController

function InputController.new()
	local self = setmetatable({}, InputController)

	return self
end

function InputController:ObjectMethod()
	print(self.Property)
end

return InputController
