--!strict
local root = script.Parent.Parent

local ImportRegistry = require(root.Registries.ImportRegistry)

local Shared = {
	Network = require(root.Registries.NetworkRegistry),
	Settings = require(root.Data.Settings),
	Promise = require(root.Parent.Promise),
}

function Shared:GetNetwork()
	return Shared.Network
end

function Shared:GetSettings()
	return Shared.Settings
end

function Shared:GetPhase()
	return ImportRegistry.Phase
end

function Shared:GetPromise()
	return Shared.Promise
end

return Shared
