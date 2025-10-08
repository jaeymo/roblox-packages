--!strict
local Root = script.Parent.Parent

local Signal = require(Root.Parent.Signal)
local Types = require(Root.Data.Types)

type ImportType = Types.ImportType

local ImportRegistry = {
    ImportsReady = Signal.new(),
    ImportsReadyFired = false,

    CachedImports = {},
    Controllers = {},
    Services = {},
}

local function Verify(Import: any): boolean
    return type(Import) == "table"
end

local function Request(Container: Instance)
    for _, Import in Container:GetDescendants() do
        if Import == Root or Import:IsDescendantOf(Root) then
            continue
        end

        if Import:IsA("ModuleScript") then
            local Success, Cached = pcall(require, Import)
            if Success and Verify(Cached) then
                if type(Cached.Prepare) ~= "function" then
                    continue
                end

                if table.find(ImportRegistry.CachedImports, Cached) then
                    continue
                end

                table.insert(ImportRegistry.CachedImports, Cached)
            end
        elseif #Import:GetDescendants() > 0 then
            Request(Import)
        end
    end
end

local function GetStorageLocation(ImportType: ImportType): { [string]: any }
    return (ImportType == "Service" and ImportRegistry.Services) or ImportRegistry.Controllers
end

function ImportRegistry:Bootstrap(Directories: Instance | { Instance } )
    if typeof(Directories) == "Instance" then
        Request(Directories :: Instance)

    elseif typeof(Directories) == "table" then
        for _, Directory in Directories do
            if typeof(Directory) == "Instance" then
                Request(Directory)
            else
                warn(`[{script.Name}] Invalid directory type in bootstrapping list: {typeof(Directory)}`)
            end
        end
    else
        error(`[{script.Name}] Bootstrapping process expects an instance or a table of instances`)
    end
end

function ImportRegistry:Create(ImportType: ImportType, Identifier: string, Import: any): any
    if not Verify(Import) then
        error(`[{script.Name}] Invalid import type: {Identifier}`)
    end

    local StorageLocation = GetStorageLocation(ImportType)
    if StorageLocation[Identifier] then
        warn(`[{script.Name}] Duplicate registration: {Identifier}`)
        return nil
    end

    StorageLocation[Identifier] = Import
    return Import
end

function ImportRegistry:Catch(ImportType: ImportType, Identifier: string): any
    local StorageLocation = GetStorageLocation(ImportType)
    if not StorageLocation[Identifier] then
        warn(`[{script.Name}] Import has not been registered: {Identifier}`)
        return nil
    end

    return StorageLocation[Identifier]
end

function ImportRegistry:Prepare()
    for _, Import in self.CachedImports do
        task.spawn(function()
            Import:Prepare()
        end)
    end
end

return ImportRegistry