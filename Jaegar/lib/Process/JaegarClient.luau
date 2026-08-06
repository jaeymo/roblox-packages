--!strict
local Root = script.Parent.Parent
local Registries = Root.Registries

local ImportRegistry = require(Registries.ImportRegistry)
local Promise = require(Root.Parent.Promise)
local Types = require(Root.Data.Types)

local Shared = require(script.Parent.Shared) :: Types.SharedModule

local initialized = false

--[=[
	@module JaegarClient
    Client-sided bootstrapper and manager for the Jaegar framework.
]=]
local JaegarClient = {
	ImportRegistry = ImportRegistry :: Types.ImportRegistry,
}

setmetatable(JaegarClient, { __index = Shared })

export type JaegarClient = Types.JaegarClient

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
function JaegarClient.Start(_self: JaegarClient, bootstrapLocation: Instance | { Instance }): Promise.TypedPromise<any>
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
function JaegarClient.CreateController(_self: JaegarClient, controllerName: string, controller: any)
	return ImportRegistry:Create("Controller", controllerName, controller)
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
function JaegarClient.GetController(_self: JaegarClient, ControllerName: string)
	return ImportRegistry:Catch("Controller", ControllerName)
end

return JaegarClient :: Types.JaegarClient
