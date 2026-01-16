local Promise = require(script.Parent.Parent.Parent.Promise)

export type NetworkRegistry = {
    Packets: { [string]: any }?,
    CreatePacket: (self: NetworkRegistry, ...any) -> any,
    GetPacket: (self: NetworkRegistry, PacketName: string) -> any,
    Inject: (self: NetworkRegistry, Packets: { [string]: any }) -> { [string]: any },
    SendClient: (self: NetworkRegistry, PacketName: string, Client: Player, ...any) -> any,
    SendServer: (self: NetworkRegistry, PacketName: string, ...any) -> any,
    Broadcast: (self: NetworkRegistry, PacketName: string, ...any) -> any,
    OnInvoke: (self: NetworkRegistry, PacketName: string, Callback: (...any) -> any) -> (),
    OnServer: (self: NetworkRegistry, PacketName: string, Callback: (Player, any) -> any) -> RBXScriptConnection?,
    OnClient: (self: NetworkRegistry, PacketName: string, Callback: (any) -> any) -> RBXScriptConnection?,
}

export type LoadMetric = {
    Name: string,
    Path: string,
    Time: number,
    Warned: boolean,
}

export type ImportRegistry = {
    CachedImports: { any },
    Controllers: { [string]: any },
    Services: { [string]: any },
    LoadMetrics: { LoadMetric },

    Bootstrap: (self: ImportRegistry, Directories: Instance | { Instance } ) -> (),
    Create: (self: ImportRegistry, ImportType: ImportType, Identifier: string, Import: any) -> any,
    Catch: (self: ImportRegistry, ImportType: ImportRegistry, Identifier: string) -> any,
    Prepare: (self: ImportRegistry) -> (),
    SimpleOutput: (self: ImportRegistry) -> (),
    PrintLoadReport: (self: ImportRegistry) -> (),
}

export type ImportType = "Controller" | "Service"

export type SharedModule = {
    Network: NetworkRegistry,
    GetNetwork: (self: SharedModule) -> NetworkRegistry,
}

export type JaegarServer = SharedModule & {
    ImportRegistry: ImportRegistry,

    Start: (self: JaegarServer, BootstrapLocation: Instance | { Instance }) -> Promise.TypedPromise<any>,
    CreateService: (self: JaegarServer, ServiceName: string, Service: any) -> any,
    GetService: (self: JaegarServer, ServiceName: string) -> any,
}

export type JaegarClient = SharedModule & {
    ImportRegistry: ImportRegistry,

    Start: (self: JaegarClient, BootstrapLocation: Instance | { Instance }) -> Promise.TypedPromise<any>,
    CreateController: (self: JaegarClient, ControllerName: string, Controller: any) -> any,
    GetController: (self: JaegarClient, ControllerName: string) -> any,
}

return {}