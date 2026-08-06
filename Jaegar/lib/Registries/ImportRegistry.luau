--!strict
local root = script.Parent.Parent

local Promise = require(root.Parent.Promise)
local Settings = require(root.Data.Settings)
local Signal = require(root.Parent.Signal)
local Types = require(root.Data.Types)

-- The name of the flag variable that marks a module to be ignored from loading
local IGNORE_MODULE_LOAD_TAG_NAME = Settings.IgnoreModuleLoadTagName

-- How much time must pass for a load warning to be logged
local LOAD_WARNING_TIME = Settings.LoadWarningTime

-- The method name for a method ran during the "Awake" phase
local AWAKE_METHOD = Settings.AwakeMethod

-- The method name for a method ran during the "Init" phase
local INIT_METHOD = Settings.InitMethod

-- The method name for a method ran during the "Start" phase
local START_METHOD = Settings.StartMethod

local ImportRegistry = {
	LoadMetrics = {} :: { Types.LoadMetric },
	CachedImports = {} :: { any },

	Controllers = {} :: { [string]: any },
	Services = {} :: { [string]: any },

	Phase = "Prerequisite" :: LifecyclePhase,
	LifecyclePhaseChanged = Signal.new() :: Signal.Signal<LifecyclePhase>,
}

type LoadMetric = Types.LoadMetric

type ImportType = Types.ImportType

type LifecyclePhase = Types.LifecyclePhase

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
	IGNORE_MODULE_LOAD_TAG_NAME = Settings.IgnoreModuleLoadTagName

	for _, import in container:GetChildren() do
		if import == root or import:IsDescendantOf(root) then
			continue
		end

		if import:IsA("ModuleScript") then
			if import:HasTag(IGNORE_MODULE_LOAD_TAG_NAME) then
				continue
			end

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

function ImportRegistry.SetPhase(self: ImportRegistry, phase: LifecyclePhase)
	if phase == self.Phase then
		return
	end

	self.Phase = phase
	self.LifecyclePhaseChanged:Fire(phase)
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

function ImportRegistry.RunLifecycle(self: ImportRegistry)
	-- Doing this junk so the settings are changeable at runtime for Wally users
	INIT_METHOD = Settings.InitMethod
	AWAKE_METHOD = Settings.AwakeMethod
	START_METHOD = Settings.StartMethod

	local initPromises: { Promise.TypedPromise<any> } = {}

	local function invoke(import: any, methodName: string, allowPromise: boolean): Promise.TypedPromise<any>?
		if type(import) ~= "table" then
			return nil
		end

		local method = import[methodName]
		if type(method) ~= "function" then
			return nil
		end

		local success, result = pcall(method, import)
		if not success then
			warn(`[{script.Name}] {tostring(import)}.{methodName} failed:\n{tostring(result)}`)
			return nil
		end

		if Promise.is(result) then
			if not allowPromise then
				error(
					`[{script.Name}] {tostring(import)}.{method} returned a Promise. Awake methods must be synchronous.`
				)
			end
			return result
		end

		return nil
	end

	self:SetPhase("Awake")

	-- Phase 1: Awake (sync)
	for _, import in self.CachedImports do
		invoke(import, AWAKE_METHOD, false)
	end

	self:SetPhase("Init")

	-- Phase 2: Init (async)
	for _, import in self.CachedImports do
		local promise = invoke(import, INIT_METHOD, true)

		if promise then
			table.insert(initPromises, promise)
		end
	end

	self:SetPhase("Start")

	-- Phase 3: Start (after all init promises)
	Promise.all(initPromises)
		:andThen(function()
			for _, import in self.CachedImports do
				invoke(import, START_METHOD, false)
			end
		end)
		:catch(function(err)
			error(err)
		end)

	self:SetPhase("Done")
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
