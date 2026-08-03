--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

local TestServiceB = {}

function TestServiceB:Prepare()
	print("Prepared B")
end

return Jaegar:CreateService("TestServiceB", TestServiceB)
