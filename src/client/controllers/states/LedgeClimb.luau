local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ParkourAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Parkour")
local LedgeClimbAlignPosition = ParkourAssets:WaitForChild("LedgeClimbAlignPosition")
local LedgeClimbAlignOrientation = ParkourAssets:WaitForChild("LedgeClimbAlignOrientation")

local LedgeClimb = {}
LedgeClimb.__index = LedgeClimb

function LedgeClimb.new(context, returnToLocomotion, config)
	local self = setmetatable({}, LedgeClimb)

	self.character = context.character
	self.humanoid = context.humanoid
	self.rootPart = context.rootPart

	self.alignPosition = nil
	self.alignOrientation = nil

	self.targetPosition = nil

	self.attachment = context.attachment

	self.onFinished = returnToLocomotion

	self.connection = nil

	self.animationController = context.animationController

	self.config = config

	return self
end

function LedgeClimb:Enter()
	self:CreateAlignPosition()
	self:CreateAlignOrientation()

	self.animationController:Play("LedgeClimb", self.config.AnimationFadeTime)

	local climbStage = "Lift"
	local startTime = os.clock()

	self.connection = RunService.PreSimulation:Connect(function()
		if os.clock() - startTime > self.config.MaxDuration then
			self.onFinished()
			return
		end

		if (self.targetPosition - self.rootPart.Position).Magnitude < self.config.ArrivalDistance then
			if climbStage == "Forward" then
				self.onFinished()
				return
			end

			self.targetPosition = (self.rootPart.CFrame * self.config.ForwardOffset).Position
			self.alignPosition.Position = self.targetPosition

			climbStage = "Forward"
		end
	end)
end

function LedgeClimb:CreateAlignPosition()
	local force = self.rootPart.AssemblyMass * self.config.ForceMultiplier

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

	local boxCFrame = self.rootPart.CFrame * self.config.ClearanceOffset
	local boxSize = self.config.ClearanceSize

	local targetPosition = (self.rootPart.CFrame * self.config.LiftOffset).Position

	local parts = workspace:GetPartBoundsInBox(boxCFrame, boxSize, overlapParams)

	local hasClearance = #parts == 0
	if not hasClearance then
		return false
	end

	self.targetPosition = targetPosition

	return true
end

function LedgeClimb:Exit()
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

	self.targetPosition = nil

	self.animationController:Stop("LedgeClimb", self.config.AnimationFadeTime)
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

	self.targetPosition = nil

	self.attachment = nil

	self.onFinished = nil

	self.animationController = nil

	self.config = nil
end

return LedgeClimb
