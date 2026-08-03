--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

Jaegar:GetSettings().StartupMethod = "_onConstruct"

Jaegar:Start(script)
