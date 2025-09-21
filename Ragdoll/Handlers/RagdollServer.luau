--!strict
local Players = game:GetService("Players")

local RagdollServer = {}
RagdollServer.IsActive = false

function RagdollServer:OnStart(Ragdoll: any)
	if RagdollServer.IsActive then return end
	RagdollServer.IsActive = true
	
	local function safePlayerAdded(callback: (Player) -> ())
		for _, player in Players:GetPlayers() do
			callback(player)
		end

		Players.PlayerAdded:Connect(callback)
	end

	safePlayerAdded(function(player)
		player.CharacterAdded:Connect(function(character)
			Ragdoll.Setup(character)
		end)
	end)

end

return RagdollServer