--!strict
local Root = script.Parent.Parent
local Registries = Root.Registries

local ImportRegistry = require(Registries.ImportRegistry)
local Types = require(Root.Data.Types)
local Promise = require(Root.Parent.Promise)
local Shared = require(script.Parent.Shared) :: Types.SharedModule

--[=[
	@class JaegarClient
    Client-sided bootstrapper and manager for the Jaegar framework.
]=]
local JaegarClient: Types.JaegarClient = {
    ImportRegistry = (ImportRegistry::any) :: Types.ImportRegistry,
} :: any
setmetatable(JaegarClient, {__index = Shared})

local Initialized = false

--[=[
    @method Start
    @within JaegarClient
    @param BootstrapLocation Instance | { Instance }
    Boots the client framework by loading all provided controllers
    from the given location(s). Should only be called once.
    @return Promise.TypedPromise<any>

    ```lua
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local Shared = ReplicatedStorage.Shared
    local Client = ReplicatedStorage.Client

    local Locations = { Shared, Client }
    Jaegar:Start(Locations)
    ```
]=]
function JaegarClient:Start(BootstrapLocation: Instance | { Instance }): Promise.TypedPromise<any>
    if Initialized then
        error(`[{script.Name}] Jaegar should only be started once`)
    end
    
    return Promise.new(function(Resolve, Reject)
        ImportRegistry:Bootstrap(BootstrapLocation)
        ImportRegistry:Prepare()
        Resolve()
    end)
end

--[=[
    @method CreateController
    @within JaegarClient
    @param ControllerName string
    @param Controller any
    @return any
    Registers a new controller with the given name and definition.

    ```lua
    local MyController = Jaegar:CreateController("MyController", {
        Foo = 1,
    })

    function MyController:DoSomething()
        print(MyController.Foo)
    end

    return MyController
    ```
]=]
function JaegarClient:CreateController(ControllerName: string, Controller: any)
    return ImportRegistry:Create("Controller", ControllerName, Controller)
end

--[=[
    @method GetController
    @within JaegarClient
    @param ControllerName string
    @return any
    Retrieves an existing controller by name, if it exists.

    ```lua
    local MyController = Jaegar:GetController("MyController")
    MyController:DoSomething()
    ```
]=]
function JaegarClient:GetController(ControllerName: string)
    return ImportRegistry:Catch("Controller", ControllerName)
end

return JaegarClient