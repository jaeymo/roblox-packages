--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

local TestServiceC = {}

function TestServiceC:Prepare()
	print("Prepared C")
end

return Jaegar:CreateService("TestServiceC", TestServiceC)
