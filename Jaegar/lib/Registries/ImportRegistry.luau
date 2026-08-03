--!strict
local root = script.Parent.Parent

local Settings = require(root.Data.Settings)
local Types = require(root.Data.Types)

-- How much time must pass for a load warning to be logged
local LOAD_WARNING_TIME = Settings.LoadWarningTime

-- The name for the method called in modules when loading
local STARTUP_METHOD = Settings.StartupMethod

-- Should we use task.spawn() for start methods? Or should it be deterministic? You choose!
local PARALLEL_STARTUP = Settings.ParallelStartup

type LoadMetric = Types.LoadMetric
type ImportType = Types.ImportType

local ImportRegistry = {
	LoadMetrics = {} :: { Types.LoadMetric },
	CachedImports = {} :: { any },

	Controllers = {} :: { [string]: any },
	Services = {} :: { [string]: any },
}

export type ImportRegistry = typeof(ImportRegistry)

local function timedRequire(module: ModuleScript): (boolean, any, number, boolean)
	LOAD_WARNING_TIME = Settings.LoadWarningTime

	local startTime = os.clock()
	local warned = false
	local finished = false

	task.delay(LOAD_WARNING_TIME, function()
		if not finished then
			warned = true
			warn(
				string.format(
					"[ImportRegistry] Module taking longer than %ds to load: %s",
					LOAD_WARNING_TIME,
					module:GetFullName()
				)
			)
		end
	end)

	local success, result = pcall(require, module)
	finished = true

	return success, result, os.clock() - startTime, warned
end

local function request(container: Instance)
	for _, import in container:GetChildren() do
		if import == root or import:IsDescendantOf(root) then
			continue
		end

		if import:IsA("ModuleScript") then
			local success, cached, timeTaken, warned = timedRequire(import)

			table.insert(ImportRegistry.LoadMetrics, {
				Name = import.Name,
				Path = import:GetFullName(),
				Time = timeTaken,
				Warned = warned,
			})

			if success and type(cached) == "table" and not table.find(ImportRegistry.CachedImports, cached) then
				table.insert(ImportRegistry.CachedImports, cached)
			elseif not success then
				warn(
					string.format("[ImportRegistry] Failed to require %s:\n%s", import:GetFullName(), tostring(cached))
				)
			end
		end

		if #import:GetChildren() > 0 then
			request(import)
		end
	end
end

local function getStorageLocation(importType: ImportType): { [string]: any }
	return (importType == "Service" and ImportRegistry.Services) or ImportRegistry.Controllers
end

function ImportRegistry.Bootstrap(_self: ImportRegistry, directories: Instance | { Instance })
	if typeof(directories) == "Instance" then
		request(directories :: Instance)
	elseif typeof(directories) == "table" then
		for _, Directory in directories do
			if typeof(Directory) == "Instance" then
				request(Directory)
			else
				warn(`[{script.Name}] Invalid directory type in bootstrapping list: {typeof(Directory)}`)
			end
		end
	else
		error(`[{script.Name}] Bootstrapping process expects an instance or a table of instances`)
	end
end

function ImportRegistry.Create(_self: ImportRegistry, importType: ImportType, identifier: string, import: any): any
	if type(import) ~= "table" then
		error(`[{script.Name}] Invalid import type (expected table): {identifier}`)
	end

	local storageLocation = getStorageLocation(importType)
	if storageLocation[identifier] then
		warn(`[{script.Name}] Duplicate registration: {identifier}`)
		return nil
	end

	storageLocation[identifier] = import
	return import
end

function ImportRegistry.Catch(_self: ImportRegistry, importType: ImportType, identifier: string): any
	local storageLocation = getStorageLocation(importType)
	if not storageLocation[identifier] then
		warn(`[{script.Name}] Import has not been registered: {identifier}`)
		return nil
	end

	return storageLocation[identifier]
end

function ImportRegistry.Prepare(self: ImportRegistry)
	STARTUP_METHOD = Settings.StartupMethod
	PARALLEL_STARTUP = Settings.ParallelStartup

	local function handleCall(import: any)
		if type(import) == "table" then
			pcall(function()
				if import[STARTUP_METHOD] then
					import[STARTUP_METHOD]()
				end
			end)
		end
	end

	for _, import in self.CachedImports do
		if PARALLEL_STARTUP then
			task.spawn(function()
				handleCall(import)
			end)
		else
			handleCall(import)
		end
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
		print(string.format("%s | %.3fs | %s", Metric.Name, Metric.Time, Metric.Warned and "SLOW" or "OK"))
	end
	print("==============================")
end

return ImportRegistry
