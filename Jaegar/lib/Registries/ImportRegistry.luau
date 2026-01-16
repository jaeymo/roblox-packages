--!strict
local Root = script.Parent.Parent

local Types = require(Root.Data.Types)

local LOAD_WARNING_TIME = 15

type LoadMetric = Types.LoadMetric
type ImportType = Types.ImportType

local ImportRegistry = {
    CachedImports = {},
    Controllers = {},
    Services = {},
    LoadMetrics = {} :: { Types.LoadMetric },
}

export type ImportRegistry = typeof(ImportRegistry)

local function TimedRequire(Module: ModuleScript): (boolean, any, number, boolean)
    local StartTime = os.clock()
    local Warned = false
    local Finished = false

    task.delay(LOAD_WARNING_TIME, function()
        if not Finished then
            Warned = true
            warn(string.format(
                "[ImportRegistry] Module taking longer than %ds to load: %s",
                LOAD_WARNING_TIME,
                Module:GetFullName()
            ))
        end
    end)

    local Success, Result = pcall(require, Module)
    Finished = true

    local Elapsed = os.clock() - StartTime
    return Success, Result, Elapsed, Warned
end

local function Verify(Import: any): boolean
    return type(Import) == "table"
end

local function Request(Container: Instance)
    for _, Import in ipairs(Container:GetChildren()) do
        if Import == Root or Import:IsDescendantOf(Root) then
            continue
        end

        if Import:IsA("ModuleScript") then
            local Success, Cached, TimeTaken, Warned = TimedRequire(Import)

            table.insert(ImportRegistry.LoadMetrics, {
                Name = Import.Name,
                Path = Import:GetFullName(),
                Time = TimeTaken,
                Warned = Warned,
            })

            if Success and Verify(Cached)
                and type(Cached.Prepare) == "function"
                and not table.find(ImportRegistry.CachedImports, Cached)
            then
                table.insert(ImportRegistry.CachedImports, Cached)
            elseif not Success then
                warn(Cached)
            end
        end

        if #Import:GetChildren() > 0 then
            Request(Import)
        end
    end
end

local function GetStorageLocation(ImportType: ImportType): { [string]: any }
    return (ImportType == "Service" and ImportRegistry.Services) or ImportRegistry.Controllers
end

function ImportRegistry.Bootstrap(self: ImportRegistry, Directories: Instance | { Instance })
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

function ImportRegistry.Create(self: ImportRegistry, ImportType: ImportType, Identifier: string, Import: any): any
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

function ImportRegistry.Catch(self: ImportRegistry, ImportType: ImportType, Identifier: string): any
    local StorageLocation = GetStorageLocation(ImportType)
    if not StorageLocation[Identifier] then
        warn(`[{script.Name}] Import has not been registered: {Identifier}`)
        return nil
    end

    return StorageLocation[Identifier]
end

function ImportRegistry.Prepare(self: ImportRegistry)
    for _, Import in self.CachedImports do
        task.spawn(function()
            Import:Prepare()
        end)
    end
end

function ImportRegistry.SimpleOutput(self: ImportRegistry)
    print(self.LoadMetrics)
end

function ImportRegistry.PrintLoadReport(self: ImportRegistry)
    table.sort(self.LoadMetrics, function(A: LoadMetric, B: LoadMetric)
        return A.Time > B.Time
    end)

    print("===== Import Load Report =====")
    for _, Metric in self.LoadMetrics do
        print(string.format(
            "%s | %.3fs | %s",
            Metric.Name,
            Metric.Time,
            Metric.Warned and "SLOW" or "OK"
        ))
    end
    print("==============================")
end

return ImportRegistry