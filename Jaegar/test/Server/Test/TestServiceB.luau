--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jaegar = require(ReplicatedStorage.jaegar):Server()

local TestServiceB = {}

function TestServiceB:Prepare()
    print("Prepared B")
end

return Jaegar:CreateService("TestServiceB", TestServiceB, {
    Dependencies = { "TestServiceA" }
})