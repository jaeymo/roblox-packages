--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local RagdollClient = {}

function RagdollClient:OnStart(Ragdoll: any)
	local player = Players.LocalPlayer

	local function startRagdoll(rig: Model)
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			humanoid.AutoRotate = false
		end
	end

	local function stopRagdoll(rig: Model)
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			humanoid.AutoRotate = true
		end
	end

	CollectionService:GetInstanceAddedSignal(Ragdoll.Tags.Ragdolled):Connect(function(rig: Model)
		if rig == player.Character then
			startRagdoll(rig)
		end
	end)

	CollectionService:GetInstanceRemovedSignal(Ragdoll.Tags.Ragdolled):Connect(function(rig: Model)
		if rig == player.Character then
			stopRagdoll(rig)
		end
	end)
end

return RagdollClient