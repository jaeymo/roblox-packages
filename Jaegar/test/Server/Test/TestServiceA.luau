--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

local TestServiceA = {}

function TestServiceA:_onConstruct()
	print("Prepared A")
end

return TestServiceA
