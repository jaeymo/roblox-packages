--!strict
local Root = script.Parent.Parent
local Registries = Root.Registries

local ImportRegistry = require(Registries.ImportRegistry)
local Shared = require(script.Parent.Shared)
local Promise = require(Root.Promise)

local JaegarServer = {}
setmetatable(JaegarServer, {__index = Shared})

local Initialized = false

--[=[
    @method Start
    @within JaegarServer
    @param BootstrapLocation Instance | { Instance }
    Boots the server framework by loading all provided services
    from the given location(s). Should only be called once.

    ```lua
    local ServerScriptService = game:GetService("ServerScriptService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Server = ServerScriptService.Server
    local Shared = ReplicatedStorage.Shared

    local Locations = { Server, Shared }
    Jaegar:Start(Locations)
    ```
]=]
function JaegarServer:Start(BootstrapLocation: Instance | { Instance } )
    if Initialized then
        error(`[{script.Name}] Jaegar should only be started once`)
    end

    Promise.try(function()
        ImportRegistry:Bootstrap(BootstrapLocation)
    end):andThen(function()
        ImportRegistry:Prepare()
    end):catch(function(err)
        warn(`[{script.Name}] Error on startup: {err}`)
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
function JaegarServer:CreateService(ServiceName: string, Service: any)
    return ImportRegistry:Create("Service", ServiceName, Service)
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
function JaegarServer:GetService(ServiceName: string)
    return ImportRegistry:Catch("Service", ServiceName)
end

return JaegarServer