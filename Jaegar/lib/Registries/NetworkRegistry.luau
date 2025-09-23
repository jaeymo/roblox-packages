--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

local Packet = require(ReplicatedStorage.Packages.Packet)

local NetworkRegistry = {}

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

function NetworkRegistry:Send(PacketName: string, ...: any)
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end

    local Fetched = NetworkRegistry:GetPacket(PacketName)
    if not Fetched then return end

    Fetched:Fire(...)
end

function NetworkRegistry:On(PacketName: string, Callback: (any) -> any)
    if type(PacketName) ~= "string" then 
        error(`[{script.Name}] PacketName is not a string, got: {type(PacketName)}`) 
    end

    local Fetched = NetworkRegistry:GetPacket(PacketName)
    if not Fetched then return end

    if IS_SERVER then
        return Fetched.OnServerEvent:Connect(Callback)
    else
        return Fetched.OnClientEvent:Connect(Callback)
    end
end

return NetworkRegistry