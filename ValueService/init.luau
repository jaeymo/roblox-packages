--!strict
local ValueService = {}

local RunService = game:GetService("RunService")

local Types = require(script.Types)

export type ServerValueService = Types.ServerValueService
export type ClientValueService = Types.ClientValueService

export type ValueService = {
	Server: (self: ValueService) -> ServerValueService,
	Client: (self: ValueService) -> ClientValueService,
}

function ValueService:Server(): ServerValueService
	assert(RunService:IsServer(), "Cannot call :Server() on the client")
	return require(script.Main.ServerValueService)
end

function ValueService:Client(): ClientValueService
	assert(RunService:IsClient(), "Cannot call :Client() on the server")
	return require(script.Main.ClientValueService)
end

return ValueService :: ValueService