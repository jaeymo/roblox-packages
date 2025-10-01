--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jaegar = require(ReplicatedStorage.jaegar):Server()

local TestServiceC = {}

function TestServiceC:Prepare()
    print("Prepared C")
end

return Jaegar:CreateService("TestServiceC", TestServiceC)