--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent

local Packet = require(root.Parent.Packet)

local IS_SERVER = RunService:IsServer()

local NetworkRegistry = {
	Packets = nil :: { [string]: any }?,
}

export type NetworkRegistry = typeof(NetworkRegistry)

function NetworkRegistry.CreatePacket(_self: NetworkRegistry, ...: any)
	return Packet.new(...)
end

function NetworkRegistry.GetPacket(self: NetworkRegistry, packetName: string): any
	local packets = self.Packets
	if not packets then
		error(`[{script.Name}] Packets have not been injected.`)
	end

	local packet = packets[packetName]
	if not packet then
		error(`[{script.Name}] Missing packet: {packetName}`)
	end

	return (self.Packets :: any)[packetName]
end

function NetworkRegistry.Inject(self: NetworkRegistry, Packets: { [string]: any })
	if self.Packets then
		error(`[{script.Name}] Can't inject multiple packet tables!`)
	end

	self.Packets = Packets
	return Packets
end

function NetworkRegistry.SendClient(self: NetworkRegistry, packetName: string, client: Player, ...: any): ...any
	if type(packetName) ~= "string" then
		error(`[{script.Name}] PacketName is not a string, got: {type(packetName)}`)
	end

	assert(client:IsA("Player"), `[{script.Name}] "Client" is not a player!`)

	local fetched = self:GetPacket(packetName)

	return fetched:FireClient(client, ...)
end

function NetworkRegistry.SendServer(self: NetworkRegistry, packetName: string, ...: any): ...any
	if type(packetName) ~= "string" then
		error(`[{script.Name}] PacketName is not a string, got: {type(packetName)}`)
	end

	local fetched = self:GetPacket(packetName)

	return fetched:Fire(...)
end

function NetworkRegistry.Broadcast(self: NetworkRegistry, PacketName: string, ...: any)
	if type(PacketName) ~= "string" then
		error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`)
	end

	local Fetched = self:GetPacket(PacketName)
	if not Fetched then
		return
	end

	Fetched:Fire(...)
end

--[=[
    @priv
]=]
local function buildExcluded(except: (Player | { Player })?): { [Player]: boolean }
	local excluded: { [Player]: boolean } = {}

	if typeof(except) == "Instance" then
		if except:IsA("Player") then
			excluded[except] = true
		end
	elseif type(except) == "table" then
		for _, v in except do
			if typeof(v) == "Instance" and v:IsA("Player") then
				excluded[v] = true
			end
		end
	end

	return excluded
end

function NetworkRegistry.BroadcastExcept(
	self: NetworkRegistry,
	packetName: string,
	except: Player | { Player },
	...: any
): ()
	if type(packetName) ~= "string" then
		error(`[{script.Name}] PacketName is not a string, got: {type(packetName)}`)
	end

	local fetched = self:GetPacket(packetName)

	if not IS_SERVER then
		error(`[{script.Name}] Cannot call ":BroadcastExcept()" on the client!`)
		return
	end

	local excluded = buildExcluded(except)

	for _, player in Players:GetPlayers() do
		if excluded[player] then
			continue
		end

		fetched:FireClient(player, ...)
	end
end

function NetworkRegistry.BroadcastInRange(
	self: NetworkRegistry,
	packetName: string,
	position: Vector3,
	range: number,
	except: (Player | { Player })?,
	...: any
)
	if type(packetName) ~= "string" then
		error(`[{script.Name}] PacketName is not a string, got: {type(packetName)}`)
	end

	local fetched = self:GetPacket(packetName)

	if not IS_SERVER then
		error(`[{script.Name}] Cannot call ":BroadcastInRange()" on the client!`)
		return
	end

	local excluded = buildExcluded(except)

	for _, player in Players:GetPlayers() do
		if excluded[player] then
			continue
		end

		local character = player.Character
		if not character then
			continue
		end

		if (character:GetPivot().Position - position).Magnitude <= range then
			fetched:FireClient(player, ...)
		end
	end
end

function NetworkRegistry.OnInvoke(self: NetworkRegistry, packetName: string, Callback: (...any) -> ...any?)
	local fetched = self:GetPacket(packetName)

	if IS_SERVER then
		fetched.OnServerInvoke = Callback
	else
		fetched.OnClientInvoke = Callback
	end
end

function NetworkRegistry.OnServer(
	self: NetworkRegistry,
	packetName: string,
	Callback: (Player, ...any) -> ()
): RBXScriptConnection
	local fetched = self:GetPacket(packetName)

	assert(IS_SERVER, `[{script.Name}] OnServer called on client!`)

	return fetched.OnServerEvent:Connect(Callback)
end

function NetworkRegistry.OnClient(
	self: NetworkRegistry,
	packetName: string,
	Callback: (...any) -> ()
): RBXScriptConnection
	local fetched = self:GetPacket(packetName)

	assert(not IS_SERVER, `[{script.Name}] OnClient called on server!`)

	return fetched.OnClientEvent:Connect(Callback)
end

return NetworkRegistry
