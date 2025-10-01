--!strict
local Root = script.Parent.Parent

local Signal = require(Root.Parent.Signal)
local Types = require(Root.Data.Types)

type ImportType = Types.ImportType
type ImportSettings = Types.ImportSettings

local ImportRegistry = {
    ImportsReady = Signal.new(),
    ImportsReadyFired = false,

    DependencyMap = {},
    CachedImports = {},
    Controllers = {},
    Services = {},
}

local function DetectCycle(StartIdentifier: string, Graph: { [string]: any }): boolean
    local Visited = {}
    local Stack = {}

    local function dfs(Node: string): boolean
        if Stack[Node] then return true end
        if Visited[Node] then  return false  end

        Visited[Node] = true
        Stack[Node] = true

        local Entry = Graph[Node]
        if Entry then
            for _, Dependency in Entry.DependsOn do
                if dfs(Dependency) then
                    return true
                end
            end
        end

        Stack[Node] = false
        return false
    end

    return dfs(StartIdentifier)
end

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

function ImportRegistry:Create(ImportType: ImportType, Identifier: string, Import: any, Settings: ImportSettings?): any
    if not Verify(Import) then
        error(`[{script.Name}] Invalid import type: {Identifier}`)
    end

    if DetectCycle(Identifier, self.DependencyMap) then
        error(`[{script.Name}] Circular dependency detected at "{Identifier}"`)
    end

    local StorageLocation = GetStorageLocation(ImportType)
    if StorageLocation[Identifier] then
        warn(`[{script.Name}] Duplicate registration: {Identifier}`)
        return nil
    end

    Settings = Settings or {}
    local Dependencies = (Settings :: ImportSettings).Dependencies or {} :: { string }

    self.DependencyMap[Identifier] = {
        DependsOn = Dependencies,
        Finished = false,
        Import = Import,
    }

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
    local IdsToSeed = {}
    for _, Import in self.CachedImports do
        for Key, Value in self.DependencyMap do
            if Value.Import == Import then
                Value.Signal = Value.Signal or Signal.new()
                table.insert(IdsToSeed, Key)
                break
            end
        end
    end

    local Total = #IdsToSeed
    local Completed = 0

    local function TryPrepare(Identifier: string)
        local Entry = self.DependencyMap[Identifier]
        if not Entry then
            return
        end

        if Entry.Finished then
            return
        end

        for _, Dependency in Entry.DependsOn or {} do
            local DependencyEntry = self.DependencyMap[Dependency]
            if not DependencyEntry then
                warn(`[{script.Name}] Dependency "{Dependency}" not found for {Identifier}`)
                return
            elseif not DependencyEntry.Finished then
                return
            end
        end

        Entry.Finished = true

        task.spawn(function()
            if Verify(Entry.Import) then
                if typeof(Entry.Import.Prepare) == "function" then
                    Entry.Import:Prepare()
                end
            end
            
            if Entry.Signal then
                Entry.Signal:Fire()
            end

            Completed = Completed + 1
            if Completed >= Total and not self.ImportsReadyFired then
                self.ImportsReady:Fire()
                self.ImportsReadyFired = true
            end

            for Key, _ in self.DependencyMap do
                TryPrepare(Key)
            end
        end)
    end

    for _, Id in IdsToSeed do
        TryPrepare(Id)
    end
end

return ImportRegistry