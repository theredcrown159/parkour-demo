local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFXConfig"))

local VFXController = {}
VFXController.__index = VFXController

function VFXController.new(character, rootPart)
	local self = setmetatable({}, VFXController)

	self.character = character
	self.rootPart = rootPart

	self.config = VFXConfig

	self.random = Random.new()

	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterDescendantsInstances = { self.character }
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	return self
end

function VFXController:FindGroundSurface()
	local rayOrigin = self.rootPart.Position
	local rayDirection = -Vector3.yAxis * self.config.LandingDebris.GroundCheckDistance

	return game.Workspace:Raycast(rayOrigin, rayDirection, self.raycastParams)
end

function VFXController:CreateDebrisChunk(surface)
	local debrisConfig = self.config.LandingDebris

	local lifetimeRange = debrisConfig.LifetimeRange
	local lifetime = self.random:NextNumber(lifetimeRange.Min, lifetimeRange.Max)

	local chunkSizeRange = debrisConfig.ChunkSizeRange
	local size = self.random:NextNumber(chunkSizeRange.Min, chunkSizeRange.Max)

	local spawnDistance = self.random:NextNumber(0, debrisConfig.SpawnRadius)

	local angle = self.random:NextNumber(0, math.pi * 2)
	local randomDirection = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local normal = surface.Normal

	local surfaceDirection = randomDirection - normal * randomDirection:Dot(normal)
	if surfaceDirection.Magnitude < 0.001 then
		return nil
	end

	surfaceDirection = surfaceDirection.Unit

	local part = Instance.new("Part")
	part.Size = Vector3.new(size, size, size)
	part.Position = surface.Position + surfaceDirection * spawnDistance + surface.Normal * debrisConfig.SurfaceOffset
	part.Color = surface.Instance.Color
	part.Material = surface.Material
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = game.Workspace

	local outwardSpeedRange = debrisConfig.OutwardSpeedRange
	local outwardSpeed = self.random:NextNumber(outwardSpeedRange.Min, outwardSpeedRange.Max)

	local upwardSpeedRange = debrisConfig.UpwardSpeedRange
	local upwardSpeed = self.random:NextNumber(upwardSpeedRange.Min, upwardSpeedRange.Max)

	part.AssemblyLinearVelocity = surfaceDirection * outwardSpeed + surface.Normal * upwardSpeed

	local rotationAxis =
		Vector3.new(self.random:NextNumber(-1, 1), self.random:NextNumber(-1, 1), self.random:NextNumber(-1, 1))

	if rotationAxis.Magnitude < 0.001 then
		rotationAxis = Vector3.yAxis
	else
		rotationAxis = rotationAxis.Unit
	end

	local angularSpeedRange = debrisConfig.AngularSpeedRange
	local angularSpeed = self.random:NextNumber(angularSpeedRange.Min, angularSpeedRange.Max)

	part.AssemblyAngularVelocity = rotationAxis * angularSpeed

	Debris:AddItem(part, lifetime)

	return part
end

function VFXController:CreateLandingDebris()
	local surface = self:FindGroundSurface()

	if not surface then
		return
	end

	local chunkCountRange = self.config.LandingDebris.ChunkCountRange
	local chunkCount = self.random:NextInteger(chunkCountRange.Min, chunkCountRange.Max)

	for i = 1, chunkCount do
		print(i)
		self:CreateDebrisChunk(surface)
	end
end

function VFXController:Destroy()
	self.character = nil
	self.rootPart = nil

	self.config = nil

	self.random = nil

	self.raycastParams = nil
end

return VFXController
