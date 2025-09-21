--!strict
local Players = game:GetService("Players")

local Ragdoll = require(script.Parent.Parent)

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