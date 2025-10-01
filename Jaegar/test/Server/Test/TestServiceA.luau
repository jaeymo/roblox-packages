--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jaegar = require(ReplicatedStorage.jaegar):Server()

local TestServiceA = {}

function TestServiceA:Prepare()
    print("Prepared A")
end

return Jaegar:CreateService("TestServiceA", TestServiceA)