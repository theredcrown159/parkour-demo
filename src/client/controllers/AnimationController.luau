local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimationsConfig"))

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(humanoid)
	local self = setmetatable({}, AnimationController)

	self.humanoid = humanoid
	self.animator = humanoid:WaitForChild("Animator")

	self.currentTrack = nil

	self.tracks = {}

	self:LoadAnimations()

	return self
end

function AnimationController:Load(name, animationID)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationID

	self.tracks[name] = self.animator:LoadAnimation(animation)
end

function AnimationController:LoadAnimations()
	for name, animationID in pairs(AnimationsConfig) do
		self:Load(name, animationID)
	end
end

function AnimationController:Play(name, fade)
	if self.currentTrack == name then
		return
	end

	self.currentTrack = name

	self.tracks[name]:Play(fade)
end

function AnimationController:Stop(name, fade)
	self.tracks[name]:Stop(fade)
end

return AnimationController
