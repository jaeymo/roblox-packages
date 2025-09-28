--!strict
local RunService = game:GetService("RunService")

local Root = script.Parent.Parent

local Packet = require(Root.Parent.Packet)

local IS_SERVER = RunService:IsServer()

local NetworkRegistry = {
    Packets = {}
}

function NetworkRegistry:CreatePacket(...)
    return Packet.new(...)
end

function NetworkRegistry:GetPacket(PacketName: string)
    if not NetworkRegistry.Packets[PacketName] then
        error(`[{script.Name}] Missing packet: {PacketName}`)
    end

    return NetworkRegistry.Packets[PacketName]
end

function NetworkRegistry:Inject(Packets: any)
    if self.Packets then
        error(`[{script.Name}] Can't inject multiple packets!`)
    end

    self.Packets = Packets
    return Packets
end

function NetworkRegistry:SendClient(PacketName: string, Client: Player, ...: any)
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end
    assert(Client:IsA("Player"), `[{script.Name}] "Client" is not a player!`)

    local Fetched = NetworkRegistry:GetPacket(PacketName)
    if not Fetched then return end

    Fetched:FireClient(Client, ...)
end

function NetworkRegistry:SendServer(PacketName: string, ...: any)
	if type(PacketName) ~= "string" then 
		error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
	end

	local Fetched = NetworkRegistry:GetPacket(PacketName)
	if not Fetched then return end

	Fetched:Fire(...)
end

function NetworkRegistry:Broadcast(PacketName: string, ...: any)
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end

    local Fetched = NetworkRegistry:GetPacket(PacketName)
    if not Fetched then return end

    Fetched:Fire(...)
end

function NetworkRegistry:OnInvoke(PacketName: string, Callback: (...any) -> any)
	local Fetched = NetworkRegistry:GetPacket(PacketName)
	if not Fetched then return end

	if IS_SERVER then
		Fetched.OnServerInvoke = Callback
	else
		Fetched.OnClientInvoke = Callback
	end
end

function NetworkRegistry:OnServer(PacketName: string, Callback: (Player, any) -> any)
	local Fetched = NetworkRegistry:GetPacket(PacketName)
	if not Fetched then return end
    
	assert(IS_SERVER, `[{script.Name}] OnServer called on client!`)

	return Fetched.OnServerEvent:Connect(Callback)
end

function NetworkRegistry:OnClient(PacketName: string, Callback: (any) -> any)
	local Fetched = NetworkRegistry:GetPacket(PacketName)
	if not Fetched then return end

	assert(not IS_SERVER, `[{script.Name}] OnClient called on server!`)

	return Fetched.OnClientEvent:Connect(Callback)
end

return NetworkRegistry