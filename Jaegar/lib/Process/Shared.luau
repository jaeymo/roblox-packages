--!strict
local Shared = {
	Network = require(script.Parent.Parent.Registries.NetworkRegistry),
	Settings = require(script.Parent.Parent.Data.Settings),
}

function Shared:GetNetwork()
	return Shared.Network
end

function Shared:GetSettings()
	return Shared.Settings
end

return Shared
