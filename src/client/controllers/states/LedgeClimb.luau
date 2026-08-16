local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local LedgeClimbAlignPosition = ParkourAssets:WaitForChild("LedgeClimbAlignPosition")
local LedgeClimbAlignOrientation = ParkourAssets:WaitForChild("LedgeClimbAlignOrientation")

local LedgeClimb = {}
LedgeClimb.__index = LedgeClimb

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local function DrawBox(cframe: CFrame, size: Vector3, color: Color3?, lifetime: number?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false

	part.Size = size
	part.CFrame = cframe

	part.Transparency = 0.7
	part.Material = Enum.Material.Neon
	part.Color = color or Color3.fromRGB(0, 255, 0)

	part.Parent = workspace

	Debris:AddItem(part, lifetime or 1)
end

function LedgeClimb.new(character, humanoid, rootPart, attachment, animationController, onFinished)
	local self = setmetatable({}, LedgeClimb)

	self.character = character
	self.humanoid = humanoid
	self.rootPart = rootPart

	self.attachment = attachment

	self.onFinished = onFinished

	self.connection = nil

	self.animationController = animationController

	return self
end

function LedgeClimb:Enter()
	self:CreateAlignPosition()
	self:CreateAlignOrientation()

	self.animationController:Play("LedgeClimb", 0.15)

	local runs = 0

	self.connection = RunService.PreSimulation:Connect(function()
		if (self.targetPosition - self.rootPart.Position).Magnitude < 0.5 then
			runs += 1
			if runs >= 2 then
				self.onFinished()
				return
			end
			self.targetPosition = (self.rootPart.CFrame * CFrame.new(0, 0.5, -2.5)).Position
			self.alignPosition.Position = self.targetPosition
		end
	end)
end

function LedgeClimb:CreateAlignPosition()
	local force = self.rootPart.AssemblyMass * 1000

	local alignPosition = LedgeClimbAlignPosition:Clone()
	alignPosition.Position = self.targetPosition
	alignPosition.MaxAxesForce = Vector3.new(force, force, force)
	alignPosition.Attachment0 = self.attachment
	alignPosition.Parent = self.rootPart

	self.alignPosition = alignPosition
end

function LedgeClimb:CreateAlignOrientation()
	local lookVec = self.rootPart.CFrame.LookVector
	local horizontalLookDir = Vector3.new(lookVec.X, 0, lookVec.Z).Unit

	local alignOrientation = LedgeClimbAlignOrientation:Clone()
	alignOrientation.CFrame = CFrame.lookAt(Vector3.zero, horizontalLookDir)
	alignOrientation.Attachment0 = self.attachment
	alignOrientation.Parent = self.rootPart

	self.alignOrientation = alignOrientation
end

function LedgeClimb:Check()
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { self.character }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local boxCFrame = self.rootPart.CFrame * CFrame.new(0, 4.5, -1.5)
	local boxSize = Vector3.new(2, 3, 2)

	self.targetPosition = (self.rootPart.CFrame * CFrame.new(0, 4, 0)).Position

	--DrawBox(boxCFrame, boxSize, nil, 0.5)

	local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)

	local hasClearance = #parts == 0
	if not hasClearance then
		return false
	end

	return true
end

function LedgeClimb:Exit()
	self.animationController:Stop("LedgeClimb", 0.15)
	self.alignOrientation:Destroy()
	self.alignPosition:Destroy()

	self.connection:Disconnect()
end

return LedgeClimb
