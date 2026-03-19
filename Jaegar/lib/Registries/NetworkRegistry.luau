--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Root = script.Parent.Parent

local Packet = require(Root.Parent.Packet)

local IS_SERVER = RunService:IsServer()

local NetworkRegistry = {
	Packets = nil :: any?,
}

export type NetworkRegistry = typeof(NetworkRegistry)

function NetworkRegistry.CreatePacket(self: NetworkRegistry, ...: any)
    return Packet.new(...)
end

function NetworkRegistry.GetPacket(self: NetworkRegistry, PacketName: string)
    if not (self.Packets :: any)[PacketName] then
        error(`[{script.Name}] Missing packet: {PacketName}`)
    end

    return (self.Packets :: any)[PacketName]
end

function NetworkRegistry.Inject(self: NetworkRegistry, Packets: any)
    if self.Packets then
        error(`[{script.Name}] Can't inject multiple packets!`)
    end

    self.Packets = Packets
    return Packets
end

function NetworkRegistry.SendClient(self: NetworkRegistry, PacketName: string, Client: Player, ...: any): any
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end
    assert(Client:IsA("Player"), `[{script.Name}] "Client" is not a player!`)

    local Fetched = self:GetPacket(PacketName)
    if not Fetched then return end

    return Fetched:FireClient(Client, ...)
end

function NetworkRegistry.SendServer(self: NetworkRegistry, PacketName: string, ...: any): any
	if type(PacketName) ~= "string" then 
		error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
	end

	local Fetched = self:GetPacket(PacketName)
	if not Fetched then return end

	return Fetched:Fire(...)
end

function NetworkRegistry.Broadcast(self: NetworkRegistry, PacketName: string, ...: any): any
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end

    local Fetched = self:GetPacket(PacketName)
    if not Fetched then return end

    return Fetched:Fire(...)
end

function NetworkRegistry.BroadcastExcept(
    self: NetworkRegistry,
    PacketName: string,
    Except: Player | {Player},
    ...: any
): ()
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end

    local Fetched = self:GetPacket(PacketName)
    if not Fetched then return end

    if not IS_SERVER then return end

    local Excluded: {[Player]: boolean} = {}

    if typeof(Except) == "Instance" then
        if Except:IsA("Player") then
            Excluded[Except] = true
        end
    elseif type(Except) == "table" then
        for _, v in Except do
            if typeof(v) == "Instance" and v:IsA("Player") then
                Excluded[v] = true
            end
        end
    end

    for _, Player in Players:GetPlayers() do
        if not Excluded[Player] then
            Fetched:FireClient(Player, ...)
        end
    end
end

function NetworkRegistry.OnInvoke(self: NetworkRegistry, PacketName: string, Callback: (...any) -> any?)
	local Fetched = self:GetPacket(PacketName)
	if not Fetched then return end

	if IS_SERVER then
		Fetched.OnServerInvoke = Callback
	else
		Fetched.OnClientInvoke = Callback
	end
end

function NetworkRegistry.OnServer(self: NetworkRegistry, PacketName: string, Callback: (Player, ...any) -> ())
	local Fetched = self:GetPacket(PacketName)
	if not Fetched then return end
    
	assert(IS_SERVER, `[{script.Name}] OnServer called on client!`)

	return Fetched.OnServerEvent:Connect(Callback)
end

function NetworkRegistry.OnClient(self: NetworkRegistry, PacketName: string, Callback: (...any) -> ())
	local Fetched = self:GetPacket(PacketName)
	if not Fetched then return end

	assert(not IS_SERVER, `[{script.Name}] OnClient called on server!`)

	return Fetched.OnClientEvent:Connect(Callback)
end

return NetworkRegistry