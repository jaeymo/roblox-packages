export type NetworkRegistry = {
    Packets: { [string]: any }?,
    CreatePacket: (self: NetworkRegistry, ...any) -> any,
    GetPacket: (self: NetworkRegistry, PacketName: string) -> any,
    Inject: (self: NetworkRegistry, Packets: { [string]: any }) -> { [string]: any },
    SendClient: (self: NetworkRegistry, PacketName: string, Client: Player, ...any) -> (),
    SendServer: (self: NetworkRegistry, PacketName: string, ...any) -> (),
    Broadcast: (self: NetworkRegistry, PacketName: string, ...any) -> (),
    OnInvoke: (self: NetworkRegistry, PacketName: string, Callback: (...any) -> any) -> (),
    OnServer: (self: NetworkRegistry, PacketName: string, Callback: (Player, any) -> any) -> RBXScriptConnection?,
    OnClient: (self: NetworkRegistry, PacketName: string, Callback: (any) -> any) -> RBXScriptConnection?,
}

export type SharedModule = {
    GetNetwork: (self: SharedModule) -> NetworkRegistry,
}

export type JaegarServer = SharedModule & {
    Start: (self: JaegarServer, BootstrapLocation: Instance | { Instance }) -> (),
    CreateService: (self: JaegarServer, ServiceName: string, Service: any) -> any,
    GetService: (self: JaegarServer, ServiceName: string) -> any,
}

export type JaegarClient = SharedModule & {
    Start: (self: JaegarClient, BootstrapLocation: Instance | { Instance }) -> (),
    CreateController: (self: JaegarServer, ControllerName: string, Controller: any) -> any,
    GetController: (self: JaegarServer, ControllerName: string) -> any,
}

return {}