--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jaegar = require(ReplicatedStorage.Packages.Jaegar):Server()

local ServiceA = {
	Foo = 1,
	Bar = "String",
}

export type ServiceA = typeof(ServiceA)

-- API Trial 1:

-- Runs when the module "wakes" up
function ServiceA.OnAwake(self: ServiceA)
	print("[ServiceA] Woke up!")
	print(self)
end

function ServiceA.OnInit(self: ServiceA)
	return Jaegar:GetPromise().new(function(resolve)
		print("[Service A] Initialized!")
		print(self)
		resolve()
	end)
end

-- Runs when *all* modules have awoken
function ServiceA.OnStart(self: ServiceA)
	print("[Service A] Started!")
	print(self)
end

-- API Trial 2:

-- Jaegar:OnAwake(ServiceA, function(self: ServiceA)
-- 	return Jaegar:GetPromise().new(function(resolve)
-- 		print("[Service A] Initialized!")
-- 		resolve()
-- 	end)
-- end)

-- Jaegar:OnStart(ServiceA, function(self: ServiceA)
-- 	print("[Service A] Started!")
-- end)

return ServiceA
