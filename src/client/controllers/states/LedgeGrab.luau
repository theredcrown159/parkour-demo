local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local LedgeGrabAlignPosition = ParkourAssets:WaitForChild("LedgeGrabAlignPosition")
local LedgeGrabAlignOrientation = ParkourAssets:WaitForChild("LedgeGrabAlignOrientation")

local LedgeGrab = {}
LedgeGrab.__index = LedgeGrab

function LedgeGrab.new(context, config)
	local self = setmetatable({}, LedgeGrab)

	self.config = config

	self.character = context.character
	self.humanoid = context.humanoid
	self.rootPart = context.rootPart
	self.attachment = context.attachment

	self.animationController = context.animationController
	self.sfxController = context.sfxController

	self.lastUseTime = 0

	self.frontFace = nil
	self.topFace = nil

	self.horizontalFrontNormal = nil

	self.alignPosition = nil
	self.alignOrientation = nil

	return self
end

function LedgeGrab:Check()
	if os.clock() - self.lastUseTime < self.config.Cooldown then
		return false
	end

	local lookVec = self.rootPart.CFrame.LookVector
	local horizontalLookVec = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local frontFace = self:FindFrontFace(raycastParams, horizontalLookVec)
	if not frontFace then
		return false
	end

	local frontNormalY = math.abs(frontFace.Normal.Y)
	if frontNormalY > self.config.MaxWallNormalY then
		return false
	end

	local horizontalFrontNormal = Vector3.new(frontFace.Normal.X, 0, frontFace.Normal.Z).Unit

	local topFace = self:FindTopSurface(raycastParams, frontFace, horizontalFrontNormal)
	if not topFace then
		return false
	end

	local topNormalY = topFace.Normal.Y
	if topNormalY < self.config.MinTopNormalY then
		return false
	end

	local height = topFace.Position.Y - self.rootPart.Position.Y

	if height >= self.config.MinHeight and height <= self.config.MaxHeight then
		self.frontFace = frontFace
		self.topFace = topFace

		self.horizontalFrontNormal = horizontalFrontNormal
		return true
	end

	return false
end

function LedgeGrab:FindFrontFace(raycastParams, horizontalLookVec)
	local rayOrigin = self.rootPart.Position + Vector3.new(0, self.config.FrontProbeHeight, 0)
	return game.Workspace:Raycast(rayOrigin, horizontalLookVec * self.config.CheckDistance, raycastParams)
end

function LedgeGrab:FindTopSurface(raycastParams, frontFace, horizontalFrontNormal)
	local rayOrigin = frontFace.Position
		+ Vector3.new(0, self.config.TopProbeHeight, 0)
		+ horizontalFrontNormal * -self.config.TopProbeInset
	return game.Workspace:Raycast(rayOrigin, Vector3.new(0, -self.config.TopProbeHeight, 0), raycastParams)
end

function LedgeGrab:Enter()
	self.sfxController:Play("LedgeGrab")

	self:CreateAlignPosition()
	self:CreateAlignOrientation()

	self.animationController:Play("LedgeGrab", self.config.AnimationFadeTime)
end

function LedgeGrab:CreateAlignPosition()
	local alignPosition = LedgeGrabAlignPosition:Clone()
	alignPosition.Position = Vector3.new(self.frontFace.Position.X, self.topFace.Position.Y, self.frontFace.Position.Z)
		+ self.horizontalFrontNormal * self.config.WallOffset
		- Vector3.new(0, self.config.VerticalOffset, 0)
	alignPosition.Attachment0 = self.attachment
	alignPosition.Parent = self.rootPart

	self.alignPosition = alignPosition
end

function LedgeGrab:CreateAlignOrientation()
	local alignOrientation = LedgeGrabAlignOrientation:Clone()
	alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, -self.horizontalFrontNormal)
	alignOrientation.Attachment0 = self.attachment
	alignOrientation.Parent = self.rootPart

	self.alignOrientation = alignOrientation
end

function LedgeGrab:Exit()
	self.lastUseTime = os.clock()

	self.alignPosition:Destroy()
	self.alignPosition = nil

	self.alignOrientation:Destroy()
	self.alignOrientation = nil

	self.animationController:Stop("LedgeGrab", self.config.AnimationFadeTime)

	self.frontFace = nil
	self.topFace = nil

	self.horizontalFrontNormal = nil
end

function LedgeGrab:Destroy()
	if self.alignPosition then
		self.alignPosition:Destroy()
		self.alignPosition = nil
	end

	if self.alignOrientation then
		self.alignOrientation:Destroy()
		self.alignOrientation = nil
	end

	self.animationController:Stop("LedgeGrab", 0)

	self.config = nil

	self.character = nil
	self.humanoid = nil
	self.rootPart = nil
	self.attachment = nil

	self.animationController = nil
	self.sfxController = nil

	self.lastUseTime = nil

	self.frontFace = nil
	self.topFace = nil

	self.horizontalFrontNormal = nil
end

return LedgeGrab
