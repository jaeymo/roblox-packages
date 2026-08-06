--!strict
local Shared = {
	Network = require(script.Parent.Parent.Registries.NetworkRegistry),
	Settings = require(script.Parent.Parent.Data.Settings),
	Promise = require(script.Parent.Parent.Parent.Promise),
}

function Shared:GetNetwork()
	return Shared.Network
end

function Shared:GetSettings()
	return Shared.Settings
end

function Shared:GetPromise()
	return Shared.Promise
end

return Shared
