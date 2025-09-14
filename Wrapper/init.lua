--!strict

--[[
	Wrapper: Manages instantiating objects from tagged Instances
	Author: jaeymo
	Version: 0.5.0
	License: MIT
	Created: 09/06/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]
	
local GeneralUtil = require(script.Parent["general-util"])
local Viewer = require(script.Parent["viewer"])
local Trove = require(script.Parent["trove"])

local PREFIX = "WRAPPER"
local DEFAULT_OPTIONS = 
{
	Methods = {
		Init = "Init",
		Constructor = "new",
		Destroy = "Destroy",
		Startup = "OnStart",
	},

	Debug = false,                                          -- Whether debug mode is enabled (extra logs, warnings, etc.)
	Context = nil,                                          -- The context provided to the class
	Logging = false,                                        -- Logging of all instances being processed
	AutoInit = true,                                        -- Automatically call the init method on creation
	Filter = function(instance: Instance) return true end,  -- Function to filter instances
	Resolver = function(instance: Instance) return nil end,
}

--[=[
	@class Wrapper
	A Wrapper is useful for instantiating and managing instances of
	a class based off tags.
]=]
local Wrapper = {}
Wrapper.__index = Wrapper


export type Options = 
{
	Methods: {
		Init: string,
		Startup: string,
		Destroy: string,
		Constructor: string,
	}?,
	Context: any?,
	GUID: string?,
	Logging: boolean?,
	Debug: boolean?,
	AutoInit: boolean?,
	Filter: ((object: Instance) -> boolean)?,
	Resolver: ((instance: Instance) -> Class<any>)?,
}

export type Trove = typeof(Trove.new())

export type Class<T> = {
	__index: any,
	new: (inst: Instance, trove: Trove, guid: string?) -> T,
}

type WrapperProperties<T> = {
	Trove: Trove,
	Options: Options,
	Tag: string,
	Class: Class<T>?,

	ObjectTroves: { [Instance]: Trove },
	Objects: { [Instance]: T },
	IdMap: { [string]: Instance },
	
	_isActive: boolean,
}

export type Wrapper<T> = typeof(setmetatable({} :: WrapperProperties<T>, Wrapper))

--[=[
	@return Wrapper<T>
	Constructs a Wrapper object .
	
	```lua
	local wrapper = Wrapper.new()
	```
]=]
function Wrapper.new<T>(class: Class<T>?, tag: string, options: Options?): Wrapper<T>
	local properties = {}
	
	properties.Options = options or {} :: Options
	properties.Trove = Trove.new()
	properties.Class = class
	properties.Tag = tag
	
	for k, v in DEFAULT_OPTIONS do
		if properties.Options[k] == nil then
			properties.Options[k] = v
		end
	end
	
	properties.ObjectTroves = {}
	properties.Objects = {}
	properties.IdMap = {}
	
	-- if there is a startup method, we will pass this wrapper object and the context to that func
	local methods = properties.Options.Methods
	local startup = methods and methods.Startup
	local context = properties.Options.Context
	local dbg = properties.Options.Debug :: boolean
	
	if startup then
		GeneralUtil.DebugSafecall(class, startup, dbg, properties, context)
	end
	
	local self = setmetatable(properties, Wrapper) :: Wrapper<T>
	self:_watch()
	
	return self
end

--[=[
	@method GetAll
	@within Wrapper
	@return { [ Instance ]: T }
	Returns all of the currently tracked objects.
	
	```lua
	local objects = wrapper:GetAll()
	```
]=]
function Wrapper.GetAll<T>(self: Wrapper<T>): { [Instance]: T }
	return self.Objects
end

--[=[
	@method GetObject
	@within Wrapper
	@param inst Instance
	@return T?
	Gets the object associated with the given instance.
	
	```lua
	local object = wrapper:GetObject(someInstance)
	object:DoSomething()
	```
]=]
function Wrapper.GetObject<T>(self: Wrapper<T>, inst: Instance): T?
	return self.Objects[inst]
end

--[=[
	@method GetObjectByGUID
	@within Wrapper
	@param GUID string
	@return T?
	Gets the object associated with the given GUID.
	
	```lua
	local guid = "342dcb0a-11b0-4119-abd8-ef8a100816b4"
	local object = wrapper:GetObjectByGUID(guid)
	object:DoSomething()
	```
]=]
function Wrapper.GetObjectByGUID<T>(self: Wrapper<T>, GUID: string): T?	
	return self.IdMap[GUID] and self:GetObject(self.IdMap[GUID])
end

--[=[
	@method Call
	@within Wrapper
	@param object T
	@param fn string
	@param ... any
	@return any
	Calls a method on the object associated with the given instance.
	
	```lua
	local object = wrapper:GetObject(someInstance)
	wrapper:Call(object, "DoSomething")
	```
]=]
function Wrapper.Call<T>(self: Wrapper<T>, object: T, fn: string, ...: any)
	return GeneralUtil.DebugSafecall(object, fn, self.Options.Debug or DEFAULT_OPTIONS.Debug, ...)
end

--[=[
	@method CallAll
	@within Wrapper
	@param fn string
	@param ... any
	Calls a method on all objects.
	
	```lua
	local randomVariable = 10
	wrapper:CallAll("DoSomething", randomVariable)
	```
]=]
function Wrapper.CallAll<T>(self: Wrapper<T>, fn: string, ...: any)
	for _, object in self.Objects do
		self:Call(object, fn, ...)
	end
end

--[=[
	@method Apply
	@within Wrapper
	@param inst Instance
	Creates a new object for an instance and starts tracking it.
	Also provides the object with a trove that will be cleaned up
	upon destruction.
	
	```lua
	local object = wrapper:Apply(someInstance)
	if object then
		object: DoSomething()
	end
	```
]=]
function Wrapper.Apply<T>(self: Wrapper<T>, inst: Instance): T?
	if self.Objects[inst] then return nil end
	
	if self.Options.Filter and not self.Options.Filter(inst) then
		return nil
	end
	
	local objectTrove = Trove.new()
	local guid = self.Options.GUID and GeneralUtil.NewGUID(self.Options.GUID)

	local class = self.Options.Resolver and self.Options.Resolver(inst) or self.Class
	if not class then
		objectTrove:Destroy()

		if self.Options.Debug then
			warn(`[{PREFIX}] No class could be resolved for {inst:GetFullName()}`)
		end

		return nil
	end
	
	local methods = self.Options.Methods
	local constructor = methods and methods.Constructor or DEFAULT_OPTIONS.Methods.Constructor
	local s, object = pcall(class[constructor], inst, objectTrove, guid)
	if not s then
		objectTrove:Destroy()

		if self.Options.Debug then
			warn(`[{PREFIX}] Failed to construct object for {inst:GetFullName()} | Error: {object}`)
		end

		return nil
	end
	
	if guid then
		inst:SetAttribute("GUID", guid)
		self.IdMap[guid] = inst
	end
	
	self.Objects[inst] = object
	self.ObjectTroves[inst] = objectTrove
	
	if self.Options.AutoInit then
		local init = methods and methods.Init or DEFAULT_OPTIONS.Methods.Init
		local dbg = self.Options.Debug or DEFAULT_OPTIONS.Debug
		GeneralUtil.DebugSafecall(object, init, dbg)
	end
	
	if self.Options.Logging then
		print(`[{PREFIX}] Added instance: {inst:GetFullName()}`)
	end
	
	if not inst:HasTag(self.Tag) then
		inst:AddTag(self.Tag)
	end
	
	return object
end

--[=[
	@method Revoke
	@within Wrapper
	@param inst Instance
	Manually cleans up an object. Note, this does not
	destroy the object (though that is another way to force
	cleanup).
	
	```lua
	local object = wrapper:Apply(someInstance)
	
	-- cleans up the instance in the wrapper
	wrapper:Revoke(someInstance)
	
	-- you could also destroy the instance, thereby invoking the tag removed event
	someInstance:Destroy -- also cleans up
	```
]=]
function Wrapper.Revoke<T>(self: Wrapper<T>, inst: Instance)
	if not self.Objects[inst] then return end
	
	if inst:GetAttribute("GUID") then
		self.IdMap[inst:GetAttribute("GUID")] = nil
		inst:SetAttribute("GUID", nil)
	end

	local objectTrove = self.ObjectTroves[inst]
	if objectTrove then
		objectTrove:Destroy()
		self.ObjectTroves[inst] = nil
	end
	
	local object = self.Objects[inst]
	if object then
		local methods = self.Options.Methods
		local destroy = methods and methods.Destroy or DEFAULT_OPTIONS.Methods.Destroy
		local dbg = self.Options.Debug or DEFAULT_OPTIONS.Debug
		GeneralUtil.DebugSafecall(object, destroy, dbg)

		setmetatable(object :: any, nil)
		table.clear(object :: any)
		
		self.Objects[inst] = nil
	end
	
	if self.Options.Logging then
		print(`[{PREFIX}] Removed instance: {inst:GetFullName()}`)
	end
end

--[=[
	@method Destroy
	@within Wrapper
	Cleans up the entire Wrapper, destroying all tracked objects and resources.
	
	```lua
	wrapper:Destroy()
	```
]=]
function Wrapper.Destroy<T>(self: Wrapper<T>)
	for inst in self.Objects do
		self:Revoke(inst)
	end
	
	self.Trove:Destroy()
end

function Wrapper._watch<T>(self: Wrapper<T>)
	if self._isActive then return end
	self._isActive = true
	
	self.Trove:Add(Viewer.WatchTag(self.Tag, false, function(inst: Instance)
		self:Apply(inst)
	end))
	
	self.Trove:Add(Viewer.WatchTag(self.Tag, true, function(inst: Instance)
		self:Revoke(inst)
	end))
end

Wrapper.__call = function(_, ...)
	return Wrapper.new(...)
end

return Wrapper