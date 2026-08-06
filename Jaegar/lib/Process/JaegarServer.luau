--!strict
local Root = script.Parent.Parent
local Registries = Root.Registries

local ImportRegistry = require(Registries.ImportRegistry)
local Promise = require(Root.Parent.Promise)
local Types = require(Root.Data.Types)

local Shared = require(script.Parent.Shared) :: Types.SharedModule

local initialized = false

--[=[
	@module JaegerServer
    Client-sided bootstrapper and manager for the Jaegar framework.
]=]
local JaegarServer = {
	ImportRegistry = (ImportRegistry :: any) :: Types.ImportRegistry,
}

setmetatable(JaegarServer, { __index = Shared })

export type JaegarServer = Types.JaegarServer

--[=[
    @method Start
    @within JaegarServer
    @param BootstrapLocation Instance | { Instance }
    Boots the server framework by loading all provided services
    from the given location(s). Should only be called once.
    @return Promise.TypedPromise<any>
    
    ```lua
    local ServerScriptService = game:GetService("ServerScriptService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Server = ServerScriptService.Server
    local Shared = ReplicatedStorage.Shared

    local Locations = { Server, Shared }
    Jaegar:Start(Locations)
    ```
]=]
function JaegarServer.Start(_self: JaegarServer, bootstrapLocation: Instance | { Instance }): Promise.TypedPromise<any>
	if initialized then
		error(`[{script.Name}] Jaegar should only be started once`)
	end

	initialized = true

	return Promise.new(function(resolve)
		ImportRegistry:Bootstrap(bootstrapLocation)
		ImportRegistry:RunLifecycle()
		resolve()
	end)
end

--[=[
    @method CreateService
    @within JaegarServer
    @param ServiceName string
    @param Service any
    @return any
    Registers a new service with the given name and definition.

    ```lua
    local MyService = Jaegar:CreateController("MyService", {
        Foo = 1,
    })

    function MyService:DoSomething()
        print(MyService.Foo)
    end

    return MyService
    ```
]=]
function JaegarServer.CreateService(_self: JaegarServer, serviceName: string, service: any)
	return ImportRegistry:Create("Service", serviceName, service)
end

--[=[
    @method GetService
    @within JaegarServer
    @param ServiceName string
    @return any
    Retrieves an existing service by name, if it exists.

    ```lua
    local MyService = Jaegar:GetService("MyService")
    MyService:DoSomething()
    ```
]=]
function JaegarServer.GetService(_self: JaegarServer, serviceName: string)
	return ImportRegistry:Catch("Service", serviceName)
end

return JaegarServer :: JaegarServer
