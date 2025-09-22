local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jaegar = require(ReplicatedStorage.jaegar):Client()

local MyController = {}

function MyController:Prepare()
    print("Prepped!")
end

return Jaegar:CreateController("MyController", MyController)