local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local VaultLinearVelocity = ParkourAssets:WaitForChild("VaultLinearVelocity")
local VaultAlignOrientation = ParkourAssets:WaitForChild("VaultAlignOrientation")

local Vaulting = {}
Vaulting.__index = Vaulting

function Vaulting.new(character, humanoid, rootPart, config, attachment, animationController, onFinished)
	local self = setmetatable({}, Vaulting)

	self.config = config

	self.character = character
	self.humanoid = humanoid
	self.rootPart = rootPart

	self.linearVelocity = nil
	self.alignOrientation = nil
	self.attachment = attachment

	self.horizontalLookDir = nil
	self.horizontalSpeed = nil
	self.verticalLookDir = nil
	self.verticalSpeed = nil

	self.animationController = animationController

	self.verticalAcceleration = nil

	self.onFinished = onFinished

	self.connection = nil

	return self
end

function Vaulting:Enter()
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	self:CalculateVaultMovement()

	self:CreateLinearVelocity()
	self:CreateAlignOrientation()

	self.animationController:Play("Vaulting", 0.05)

	local connection = RunService.PreSimulation:Connect(function(dt)
		self:Update(dt)
	end)

	self.connection = connection
end

function Vaulting:Update(dt)
	self.linearVelocity.VectorVelocity = self.horizontalLookDir * self.horizontalSpeed
		+ self.verticalLookDir * self.verticalSpeed

	self.verticalSpeed -= self.verticalAcceleration * dt

	if self.verticalSpeed <= -10 then
		self.onFinished()
	end
end

function Vaulting:CalculateVaultMovement()
	local lookVec = self.rootPart.CFrame.LookVector
	self.horizontalLookDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local velocity = self.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
	self.horizontalSpeed = horizontalVelocity.Magnitude * self.config.VaultHorizontalSpeedMultiplier

	self.verticalLookDir = Vector3.yAxis
	self.verticalSpeed = 12 * self.config.VaultHorizontalSpeedMultiplier

	self.verticalAcceleration = 60 * self.config.VaultVerticalSpeedMultiplier
end

function Vaulting:CreateLinearVelocity()
	local force = self.rootPart.AssemblyMass * 1000

	local linearVelocity = VaultLinearVelocity:Clone()
	linearVelocity.MaxAxesForce = Vector3.new(force, force, force)
	linearVelocity.Attachment0 = self.attachment
	linearVelocity.Parent = self.rootPart

	self.linearVelocity = linearVelocity
end

function Vaulting:CreateAlignOrientation()
	local alignOrientation = VaultAlignOrientation:Clone()
	alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, self.horizontalLookDir)
	alignOrientation.Attachment0 = self.attachment
	alignOrientation.Parent = self.rootPart

	self.alignOrientation = alignOrientation
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

	local groundResult = self:FindGround(context)
	if not groundResult then
		return false
	end

	local frontFaceResult = self:FindFrontFace(context)
	if not frontFaceResult then
		return false
	end

	local hasTopClearance = self:HasTopClearance(context)
	if not hasTopClearance then
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

	if topSurfaceResult.Position.Y - groundResult.Position.Y > self.config.VaultMaxHeight then
		return false
	end

	return true
end

function Vaulting:FindFrontFace(context)
	local rayOrigin = self.rootPart.Position - Vector3.new(0, 1, 0)
	local rayDirection = context.forward

	return game.Workspace:Raycast(rayOrigin, rayDirection * self.config.VaultCheckDistance, context.raycastParams)
end

function Vaulting:HasTopClearance(context)
	local rayOrigin = self.rootPart.Position + Vector3.new(0, 2.5, 0)
	local rayDirection = context.forward

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
	local rayDirection = -context.forward

	return not game.Workspace:Raycast(rayOrigin, rayDirection * 2, context.raycastParams)
end

function Vaulting:FindLandingSurface(result, context)
	local rayOrigin = result.Position + context.forward * 5
	local rayDirection = Vector3.new(0, -1, 0)

	return game.Workspace:Raycast(rayOrigin, rayDirection * 5, context.raycastParams)
end

function Vaulting:Exit()
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	self.linearVelocity:Destroy()
	self.alignOrientation:Destroy()
	self.connection:Disconnect()
end

return Vaulting
