--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

Jaegar:GetSettings().InitMethod = "OnAwake"
Jaegar:GetSettings().StartMethod = "OnStart"

Jaegar:Start(script)
