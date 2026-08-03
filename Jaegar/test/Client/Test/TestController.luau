local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Client()

local MyController = {}

function MyController:Prepare()
	print("Prepped!")
end

function MyController:_onConstruct()
	print("CONSTRUCTED")
	MyController:Prepare()
end

return MyController
