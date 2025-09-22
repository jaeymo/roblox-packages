--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registries = script.Parent.Parent.Registries

local Promise = require(ReplicatedStorage.Packages.Promise)
local ImportRegistry = require(Registries.ImportRegistry)

local JaegarServer = {}

local Initialized = false

function JaegarServer:Start(BootstrapLocation: Instance | { Instance } )
    if Initialized then
        error(`[{script.Name}] Jaegar should only be started once`)
    end

    Promise.try(function()
        ImportRegistry:Bootstrap(BootstrapLocation)
    end):andThen(function()
        ImportRegistry:Prepare()
    end):catch(function(err)
        warn(`[{script.Name}] Failed to start: {err}`)
    end)
end

function JaegarServer:CreateService(ServiceName: string, Service: any)
    return ImportRegistry:Create("Service", ServiceName, Service)
end

function JaegarServer:GetService(ServiceName: string)
    return ImportRegistry:Catch("Service", ServiceName)
end

return JaegarServer