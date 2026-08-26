local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFXConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SFXConfig"))

local SFXController = {}
SFXController.__index = SFXController

function SFXController.new(rootPart)
	local self = setmetatable({}, SFXController)

	self.config = SFXConfig

	self.rootPart = rootPart

	self.sounds = {}
	self.activeLoops = {}
	self.lastVariants = {}

	self.random = Random.new()

	self:CreateSounds()

	return self
end

function SFXController:CreateSounds()
	for soundName, soundConfig in pairs(self.config.Sounds) do
		self.sounds[soundName] = {}

		local volume = soundConfig.Volume * self.config.MasterVolume
		local looped = soundConfig.Looped
		local rollOffMinDistance = self.config.RollOffMinDistance
		local rollOffMaxDistance = self.config.RollOffMaxDistance

		for variantIndex, variantId in ipairs(soundConfig.SoundIds) do
			local sound = Instance.new("Sound")
			sound.SoundId = variantId
			sound.Volume = volume
			sound.Looped = looped
			sound.RollOffMinDistance = rollOffMinDistance
			sound.RollOffMaxDistance = rollOffMaxDistance

			self.sounds[soundName][variantIndex] = sound
		end
	end
end

function SFXController:SelectVariant(soundName)
	local sounds = self.sounds[soundName]

	if not sounds or #sounds == 0 then
		return nil
	end

	if #sounds == 1 then
		return sounds[1]
	end

	local availableVariants = table.clone(sounds)
	local lastVariant = self.lastVariants[soundName]

	if lastVariant then
		local excludedIndex = table.find(availableVariants, lastVariant)
		if excludedIndex then
			table.remove(availableVariants, excludedIndex)
		end
	end

	local sound = availableVariants[self.random:NextInteger(1, #availableVariants)]

	self.lastVariants[soundName] = sound

	return sound
end

function SFXController:Play(soundName)
	local soundSource = self:SelectVariant(soundName)

	if not soundSource then
		return false
	end

	local sound = soundSource:Clone()
	local playbackSpeedRange = self.config.Sounds[soundName].PlaybackSpeedRange
	sound.PlaybackSpeed = self.random:NextNumber(playbackSpeedRange.Min, playbackSpeedRange.Max)
	sound.Parent = self.rootPart

	if not sound.Looped then
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	else
		self:StopLoop(soundName)
		self.activeLoops[soundName] = sound
	end

	sound:Play()

	return true
end

function SFXController:StopLoop(soundName)
	local activeLoop = self.activeLoops[soundName]

	if not activeLoop then
		return false
	end

	activeLoop:Stop()
	activeLoop:Destroy()

	self.activeLoops[soundName] = nil

	return true
end

function SFXController:Destroy()
	self.config = nil

	self.rootPart = nil

	for _, sounds in pairs(self.sounds) do
		for _, sound in ipairs(sounds) do
			sound:Destroy()
		end
	end

	self.sounds = nil

	for _, sound in pairs(self.activeLoops) do
		sound:Stop()
		sound:Destroy()
	end

	self.activeLoops = nil

	self.lastVariants = nil

	self.random = nil
end

return SFXController
