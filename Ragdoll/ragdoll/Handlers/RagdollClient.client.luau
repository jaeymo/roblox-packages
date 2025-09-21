--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Ragdoll = require(script.Parent.Parent)

local player = Players.LocalPlayer

local function startRagdoll(rig: Model)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.AutoRotate = false
end

local function stopRagdoll(rig: Model)
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	humanoid.AutoRotate = true
end

CollectionService:GetInstanceAddedSignal(Ragdoll.Tags.Ragdolled:Connect(function(rig: Model)
    if rig == player.Character then
        startRagdoll(rig)
    end
end))

CollectionService:GetInstanceRemovedSignal(Ragdoll.Tags.Ragdolled):Connect(function(rig: Model)
	if rig == player.Character then
		stopRagdoll(rig)
	end
end)