local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local LedgeGrabAlignPosition = ParkourAssets:WaitForChild("LedgeGrabAlignPosition")
local LedgeGrabAlignOrientation = ParkourAssets:WaitForChild("LedgeGrabAlignOrientation")

local LedgeGrab = {}
LedgeGrab.__index = LedgeGrab

function LedgeGrab.new(character, humanoid, rootPart, attachment, animationController)
	local self = setmetatable({}, LedgeGrab)

	self.character = character
	self.humanoid = humanoid
	self.rootPart = rootPart

	self.attachment = attachment

	self.animationController = animationController

	self.lastUseTime = 0

	return self
end

function LedgeGrab:Enter()
	self:CreateAlignPosition()
	self:CreateAlignOrientation()

	self.animationController:Play("LedgeGrab")
end

function LedgeGrab:CreateAlignPosition()
	local alignPosition = LedgeGrabAlignPosition:Clone()
	alignPosition.Position = Vector3.new(self.frontFace.Position.X, self.topFace.Position.Y, self.frontFace.Position.Z)
		+ self.frontFace.Normal * 0.7
		- Vector3.new(0, 1.5, 0)
	alignPosition.Attachment0 = self.attachment
	alignPosition.Parent = self.rootPart

	self.alignPosition = alignPosition
end

function LedgeGrab:CreateAlignOrientation()
	local alignOrientation = LedgeGrabAlignOrientation:Clone()
	alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, -self.frontFace.Normal)
	alignOrientation.Attachment0 = self.attachment
	alignOrientation.Parent = self.rootPart

	self.alignOrientation = alignOrientation
end

function LedgeGrab:Check()
	if os.clock() - self.lastUseTime < 1 then
		return false
	end

	local lookVec = self.rootPart.CFrame.LookVector
	self.horizontalLookVec = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	self.frontFace = self:FindFrontFace(raycastParams)
	if not self.frontFace then
		return
	end

	self.topFace = self:FindTopSurface(raycastParams)
	if not self.topFace then
		return
	end

	if self.topFace.Position.Y - self.rootPart.Position.Y < 3 then
		return true
	end

	return false
end

function LedgeGrab:FindFrontFace(raycastParams)
	local rayOrigin = self.rootPart.Position + Vector3.new(0, 2, 0)
	return game.Workspace:Raycast(rayOrigin, self.horizontalLookVec * 3, raycastParams)
end

function LedgeGrab:FindTopSurface(raycastParams)
	local rayOrigin = self.frontFace.Position + Vector3.new(0, 4, 0) + self.horizontalLookVec * 0.1
	return game.Workspace:Raycast(rayOrigin, Vector3.new(0, -4, 0), raycastParams)
end

function LedgeGrab:Exit()
	self.lastUseTime = os.clock()

	self.alignPosition:Destroy()
	self.alignOrientation:Destroy()

	self.animationController:Stop("LedgeGrab")
end

return LedgeGrab
