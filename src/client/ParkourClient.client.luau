local ParkourController = require(script.Parent.controllers.ParkourController)
local InputController = require(script.Parent.controllers.InputController)

local parkourController = ParkourController.new()
local inputController = InputController.new(parkourController)

parkourController:Start()
inputController:Start()
