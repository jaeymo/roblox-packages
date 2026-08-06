--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

local ServiceB = {
	Foo = 2,
	Bar = "Something",
}

export type ServiceB = typeof(ServiceB)

-- API Trial 1:

-- Runs when the module "wakes" up
function ServiceB.OnAwake(self: ServiceB)
	return Jaegar:GetPromise().new(function(resolve)
		print("[Service B] Initialized!")
		print(self)
		resolve()
	end)
end

-- Runs when *all* modules have awoken
function ServiceB.OnStart(self: ServiceB)
	print("[Service B] Started!")
	print(self)
end

-- API Trial 2:

-- Jaegar:OnAwake(ServiceB, function(self: ServiceB)
-- 	return Jaegar:GetPromise().new(function(resolve)
-- 		print("[Service A] Initialized!")
-- 		resolve()
-- 	end)
-- end)

-- Jaegar:OnStart(ServiceB, function(self: ServiceB)
-- 	print("[Service A] Started!")
-- end)

return ServiceB
