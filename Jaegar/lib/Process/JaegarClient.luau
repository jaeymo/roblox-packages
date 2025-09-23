--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registries = script.Parent.Parent.Registries

local Promise = require(ReplicatedStorage.Packages.Promise)
local ImportRegistry = require(Registries.ImportRegistry)
local Shared = require(script.Parent.Shared)

local JaegarClient = {}
setmetatable(JaegarClient, {__index = Shared})

local Initialized = false

function JaegarClient:Start(BootstrapLocation: Instance | { Instance } )
    if Initialized then
        error(`[{script.Name}] Jaegar should only be started once per client`)
    end

    Initialized = true

    Promise.try(function()
        ImportRegistry:Bootstrap(BootstrapLocation)
    end):andThen(function()
        ImportRegistry:Prepare()
    end):catch(function(err)
        warn(`[{script.Name}] Failed to start: {err}`)
    end)
end

function JaegarClient:CreateController(ControllerName: string, Controller: any)
    return ImportRegistry:Create("Controller", ControllerName, Controller)
end

function JaegarClient:GetController(ControllerName: string)
    return ImportRegistry:Catch("Controller", ControllerName)
end

return JaegarClient