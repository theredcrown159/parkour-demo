local LedgeGrab = {}
LedgeGrab.__index = LedgeGrab

function LedgeGrab.new()
	local self = setmetatable({}, LedgeGrab)

	return self
end

return LedgeGrab
