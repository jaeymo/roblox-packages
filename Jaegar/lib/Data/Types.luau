--!strict
local root = script.Parent.Parent
local packages = root.Parent

local Promise = require(packages.Promise)
local Settings = require(root.Data.Settings)
local Signal = require(packages.Signal)

export type NetworkRegistry = {
	Packets: { [string]: any }?,
	CreatePacket: (self: NetworkRegistry, ...any) -> any,
	GetPacket: (self: NetworkRegistry, packetName: string) -> any,
	Inject: (self: NetworkRegistry, packets: { [string]: any }) -> { [string]: any },
	SendClient: (self: NetworkRegistry, packetName: string, client: Player, ...any) -> ...any,
	SendServer: (self: NetworkRegistry, packetName: string, ...any) -> ...any,
	Broadcast: (self: NetworkRegistry, packetName: string, ...any) -> (),
	BroadcastExcept: (self: NetworkRegistry, packetName: string, except: Player | { Player }, ...any) -> (),
	BroadcastInRange: (
		self: NetworkRegistry,
		packetName: string,
		position: Vector3,
		range: number,
		except: Player | { Player }?,
		...any
	) -> (),
	OnInvoke: (self: NetworkRegistry, packetName: string, Callback: (...any) -> any) -> (),
	OnServer: (self: NetworkRegistry, packetName: string, Callback: (Player, ...any) -> ()) -> RBXScriptConnection?,
	OnClient: (self: NetworkRegistry, packetName: string, Callback: (...any) -> ()) -> RBXScriptConnection?,
}

export type ImportRegistry = {
	CachedImports: { any },
	Controllers: { [string]: any },
	Services: { [string]: any },
	LoadMetrics: { LoadMetric },

	Bootstrap: (self: ImportRegistry, directories: Instance | { Instance }) -> (),
	Create: (self: ImportRegistry, importType: ImportType, identifier: string, import: any) -> any,
	Catch: (self: ImportRegistry, importType: ImportType, identifier: string) -> any,
	Prepare: (self: ImportRegistry) -> (),
	SimpleOutput: (self: ImportRegistry) -> (),
	PrintLoadReport: (self: ImportRegistry) -> (),
}

export type LoadMetric = {
	Name: string,
	Path: string,
	Time: number,
	Warned: boolean,
}

export type ImportType = "Controller" | "Service"

export type LifecyclePhase = "Prerequisite" | "Awake" | "Init" | "Start" | "Done"

export type SharedModule = {
	Network: NetworkRegistry,
	Promise: typeof(Promise),

	GetPromise: (self: SharedModule) -> typeof(Promise),
	GetNetwork: (self: SharedModule) -> NetworkRegistry,
	GetSettings: (self: SharedModule) -> typeof(Settings),
	GetPhase: (self: SharedModule) -> LifecyclePhase,
}

export type JaegarServer = SharedModule & {
	ImportRegistry: ImportRegistry,
	LifecyclePhaseChanged: Signal.Signal<LifecyclePhase>,

	Start: (self: JaegarServer, bootstrapLocation: Instance | { Instance }) -> Promise.TypedPromise<any>,
	CreateService: (self: JaegarServer, serviceName: string, service: any) -> any,
	GetService: (self: JaegarServer, serviceName: string) -> any,
}

export type JaegarClient = SharedModule & {
	ImportRegistry: ImportRegistry,
	LifecyclePhaseChanged: Signal.Signal<LifecyclePhase>,

	Start: (self: JaegarClient, bootstrapLocation: Instance | { Instance }) -> Promise.TypedPromise<any>,
	CreateController: (self: JaegarClient, controllerName: string, controller: any) -> any,
	GetController: (self: JaegarClient, controllerName: string) -> any,
}

return 0
