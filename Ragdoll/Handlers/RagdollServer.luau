--!strict
local Players = game:GetService("Players")

local RagdollServer = {}

function RagdollServer:OnStart(Ragdoll: any)
	local function safePlayerAdded(callback: (Player) -> ())
		for _, player in Players:GetPlayers() do
			callback(player)
		end

		Players.PlayerAdded:Connect(callback)
	end

	safePlayerAdded(function(player)
		player.CharacterAdded:Connect(function(character)
			print("SETUP!", character)
			Ragdoll.Setup(character)
		end)
	end)

end

return RagdollServer