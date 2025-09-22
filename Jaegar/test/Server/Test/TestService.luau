--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jaegar = require(ReplicatedStorage.jaegar):Server()

local MyService = {}

function MyService:Prepare()
    print "ayayay"
end

return Jaegar:CreateService("MyService", MyService)