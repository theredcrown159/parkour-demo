local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local VaultLinearVelocity = ParkourAssets:WaitForChild("VaultLinearVelocity")
local VaultAlignOrientation = ParkourAssets:WaitForChild("VaultAlignOrientation")

local Vaulting = {}
Vaulting.__index = Vaulting

function Vaulting.new(context, returnToLocomotion, config)
	local self = setmetatable({}, Vaulting)

	self.config = config

	self.character = context.character
	self.humanoid = context.humanoid
	self.rootPart = context.rootPart

	self.linearVelocity = nil
	self.alignOrientation = nil
	self.attachment = context.attachment

	self.horizontalLookDir = nil
	self.horizontalSpeed = nil
	self.verticalLookDir = nil
	self.verticalSpeed = nil

	self.animationController = context.animationController

	self.verticalAcceleration = nil

	self.onFinished = returnToLocomotion

	self.connection = nil

	self.isActive = false

	return self
end

function Vaulting:Enter()
	self.isActive = true
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

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

	if self.verticalSpeed <= self.config.FinishVerticalSpeed then
		self.onFinished()
	end
end

function Vaulting:BuildMovementPlan()
	local lookVec = self.rootPart.CFrame.LookVector
	local horizontalLookDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local velocity = self.rootPart.AssemblyLinearVelocity
	local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)

	local forwardSpeed = horizontalVelocity:Dot(horizontalLookDir)
	forwardSpeed = forwardSpeed < 0 and 0 or forwardSpeed * self.config.HorizontalSpeedMultiplier

	local horizontalSpeed = math.max(forwardSpeed, self.config.MinHorizontalSpeed)

	local verticalLookDir = Vector3.yAxis

	local verticalSpeed = self.config.InitialVerticalSpeed * self.config.VerticalSpeedMultiplier

	local verticalAcceleration = self.config.VerticalAcceleration * self.config.VerticalSpeedMultiplier

	local duration = (verticalSpeed - self.config.FinishVerticalSpeed) / verticalAcceleration
	local distance = duration * horizontalSpeed

	return {
		horizontalLookDir = horizontalLookDir,
		horizontalSpeed = horizontalSpeed,
		verticalLookDir = verticalLookDir,
		verticalSpeed = verticalSpeed,
		verticalAcceleration = verticalAcceleration,
		duration = duration,
		distance = distance,
	}
end

function Vaulting:CreateLinearVelocity()
	local force = self.rootPart.AssemblyMass * self.config.ForceMultiplier

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

	local movementPlan = self:BuildMovementPlan()

	local context = {
		forward = movementPlan.horizontalLookDir,
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

	if topSurfaceResult.Position.Y - groundResult.Position.Y > self.config.MaxHeight then
		return false
	end

	self.horizontalLookDir = movementPlan.horizontalLookDir
	self.horizontalSpeed = movementPlan.horizontalSpeed
	self.verticalLookDir = movementPlan.verticalLookDir
	self.verticalSpeed = movementPlan.verticalSpeed
	self.verticalAcceleration = movementPlan.verticalAcceleration

	return true
end

function Vaulting:FindFrontFace(context)
	local rayOrigin = self.rootPart.Position - Vector3.new(0, 1, 0)
	local rayDirection = context.forward

	return game.Workspace:Raycast(rayOrigin, rayDirection * self.config.CheckDistance, context.raycastParams)
end

function Vaulting:HasTopClearance(context)
	local rayOrigin = self.rootPart.Position + Vector3.new(0, self.config.TopClearanceHeight, 0)
	local rayDirection = context.forward

	return not game.Workspace:Raycast(rayOrigin, rayDirection * self.config.CheckDistance, context.raycastParams)
end

function Vaulting:FindGround(context)
	local rayOrigin = self.rootPart.Position
	local rayDirection = Vector3.new(0, -1, 0)

	return game.Workspace:Raycast(rayOrigin, rayDirection * 5, context.raycastParams)
end

function Vaulting:FindTopSurface(result, context)
	local rayOrigin = result.Position
		+ Vector3.new(0, self.config.MaxHeight, 0)
		+ context.forward * self.config.TopProbeInset
	local rayDirection = Vector3.new(0, -1, 0) * self.config.MaxHeight

	return game.Workspace:Raycast(rayOrigin, rayDirection, context.raycastParams)
end

function Vaulting:HasClearance(result, context)
	local rayOrigin = result.Position + context.forward * self.config.ClearanceDistance
	local rayDirection = -context.forward

	return not game.Workspace:Raycast(rayOrigin, rayDirection * self.config.ClearanceCheckLength, context.raycastParams)
end

function Vaulting:FindLandingSurface(result, context)
	local rayOrigin = result.Position + context.forward * self.config.LandingCheckDistance
	local rayDirection = Vector3.new(0, -1, 0)

	return game.Workspace:Raycast(rayOrigin, rayDirection * self.config.GroundCheckDistance, context.raycastParams)
end

function Vaulting:Exit()
	self.connection:Disconnect()
	self.connection = nil

	self.linearVelocity:Destroy()
	self.linearVelocity = nil

	self.alignOrientation:Destroy()
	self.alignOrientation = nil

	self.isActive = false
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	self.horizontalLookDir = nil
	self.horizontalSpeed = nil
	self.verticalLookDir = nil
	self.verticalSpeed = nil

	self.animationController:Stop("Vaulting", 0.05)
end

function Vaulting:Destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	if self.linearVelocity then
		self.linearVelocity:Destroy()
		self.linearVelocity = nil
	end

	if self.alignOrientation then
		self.alignOrientation:Destroy()
		self.alignOrientation = nil
	end

	if self.isActive then
		self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		self.isActive = nil
	end

	self.animationController:Stop("Vaulting", 0)

	self.config = nil

	self.character = nil
	self.humanoid = nil
	self.rootPart = nil

	self.attachment = nil

	self.horizontalLookDir = nil
	self.horizontalSpeed = nil
	self.verticalLookDir = nil
	self.verticalSpeed = nil

	self.animationController = nil

	self.verticalAcceleration = nil

	self.onFinished = nil
end

return Vaulting
