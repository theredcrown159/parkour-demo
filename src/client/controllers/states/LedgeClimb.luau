local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local LedgeClimbAlignPosition = ParkourAssets:WaitForChild("LedgeClimbAlignPosition")
local LedgeClimbAlignOrientation = ParkourAssets:WaitForChild("LedgeClimbAlignOrientation")

local LedgeClimb = {}
LedgeClimb.__index = LedgeClimb

function LedgeClimb.new(context, returnToLocomotion)
	local self = setmetatable({}, LedgeClimb)

	self.character = context.character
	self.humanoid = context.humanoid
	self.rootPart = context.rootPart

	self.attachment = context.attachment

	self.onFinished = returnToLocomotion

	self.connection = nil

	self.animationController = context.animationController

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
	self.connection:Disconnect()
	self.connection = nil

	self.alignOrientation:Destroy()
	self.alignOrientation = nil

	self.alignPosition:Destroy()
	self.alignPosition = nil

	self.animationController:Stop("LedgeClimb", 0.15)
end

function LedgeClimb:Destroy()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	if self.alignOrientation then
		self.alignOrientation:Destroy()
		self.alignOrientation = nil
	end

	if self.alignPosition then
		self.alignPosition:Destroy()
		self.alignPosition = nil
	end

	self.animationController:Stop("LedgeClimb", 0)

	self.character = nil
	self.humanoid = nil
	self.rootPart = nil

	self.attachment = nil

	self.onFinished = nil

	self.animationController = nil
end

return LedgeClimb
