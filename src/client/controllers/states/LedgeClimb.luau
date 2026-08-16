local LedgeClimb = {}
LedgeClimb.__index = LedgeClimb

function LedgeClimb.new()
	local self = setmetatable({}, LedgeClimb)

	return self
end

return LedgeClimb
