--!strict
local Shared = {}
Shared.Network = require(script.Parent.Parent.Registries.NetworkRegistry)

function Shared:GetNetwork()
    return Shared.Network
end

return Shared