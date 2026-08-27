local Players = game:GetService("Players")

local player = Players.LocalPlayer

local DISABLED_SOUNDS = {
	Running = true,
	Jumping = true,
	Landing = true,
}

local function disableSound(instance)
	if not DISABLED_SOUNDS[instance.Name] then
		return
	end

	if instance:IsA("Sound") then
		instance.SoundId = ""
	elseif instance:IsA("AudioPlayer") then
		instance.AssetId = ""
	end
end

local function onCharacterAdded(character)
	local rootPart = character:WaitForChild("HumanoidRootPart")

	for _, child in ipairs(rootPart:GetChildren()) do
		disableSound(child)
	end

	rootPart.ChildAdded:Connect(disableSound)
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
