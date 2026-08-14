local Vaulting = {}
Vaulting.__index = Vaulting

function Vaulting.new(character, humanoid, rootPart, config)
	local self = setmetatable({}, Vaulting)

	self.character = character
	self.humanoid = humanoid
	self.rootPart = rootPart

	self.config = config

	return self
end

function Vaulting:Enter()
	print()
end

function Vaulting:Check()
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local lookVector = self.rootPart.CFrame.LookVector
	local forward = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

	local context = {
		lookVector = lookVector,
		forward = forward,
		raycastParams = raycastParams,
	}

	local groudResult = self:FindGround(context)
	if not groudResult then
		return false
	end

	local frontFaceResult = self:FindFrontFace(context)
	if not frontFaceResult then
		return false
	end

	local topGuardResult = self:HasTopClearance(context)
	if not topGuardResult then
		return false
	end

	local topSurfaceResult = self:FindTopSurface(frontFaceResult, context)
	if not topSurfaceResult then
		return false
	end

	local clearanceResult = self:HasClearance(frontFaceResult, context)
	if not clearanceResult then
		return false
	end

	local landingSurfaceResult = self:FindLandingSurface(frontFaceResult, context)
	if not landingSurfaceResult then
		return false
	end

	if topSurfaceResult.Position.Y - groudResult.Position.Y > self.config.VaultMaxHeight then
		return false
	end

	return true
end

function Vaulting:FindFrontFace(context)
	local rayOrigin = self.rootPart.Position - Vector3.new(0, 1, 0)
	local rayDirection = Vector3.new(context.lookVector.X, 0, context.lookVector.Z)

	return game.Workspace:Raycast(rayOrigin, rayDirection * self.config.VaultCheckDistance, context.raycastParams)
end

function Vaulting:HasTopClearance(context)
	local rayOrigin = self.rootPart.Position + Vector3.new(0, 2.5, 0)
	local rayDirection = Vector3.new(context.lookVector.X, 0, context.lookVector.Z)

	return not game.Workspace:Raycast(rayOrigin, rayDirection * self.config.VaultCheckDistance, context.raycastParams)
end

function Vaulting:FindGround(context)
	local rayOrigin = self.rootPart.Position
	local rayDirection = Vector3.new(0, -1, 0)

	return game.Workspace:Raycast(rayOrigin, rayDirection * 5, context.raycastParams)
end

function Vaulting:FindTopSurface(result, context)
	local rayOrigin = result.Position + Vector3.new(0, self.config.VaultMaxHeight, 0) + context.forward * 0.05
	local rayDirection = Vector3.new(0, -1, 0) * self.config.VaultMaxHeight

	return game.Workspace:Raycast(rayOrigin, rayDirection, context.raycastParams)
end

function Vaulting:HasClearance(result, context)
	local rayOrigin = result.Position + context.forward * 6
	local rayDirection = Vector3.new(-context.lookVector.X, 0, -context.lookVector.Z)

	return not game.Workspace:Raycast(rayOrigin, rayDirection * 2, context.raycastParams)
end

function Vaulting:FindLandingSurface(result, context)
	local rayOrigin = result.Position + context.forward * 5
	local rayDirection = Vector3.new(0, -1, 0)

	return game.Workspace:Raycast(rayOrigin, rayDirection * 5, context.raycastParams)
end

function Vaulting:Exit()
	print()
end

return Vaulting
