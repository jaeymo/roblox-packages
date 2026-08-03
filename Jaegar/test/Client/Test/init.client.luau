--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Client()

Jaegar:GetSettings().StartupMethod = "_onConstruct"

Jaegar:Start(script)
