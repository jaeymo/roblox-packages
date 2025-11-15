--!strict

--[[
	EasyInput: Context-based input module, with various input types.
	Author: jaeymo
	Version: 1.0.0
	License: MIT
	Created: 11/14/2025

	For issues or feedback message `jaeymo` on Discord!
]]

local Signal = require(script.Parent.Signal)
local Trove = require(script.Parent.Trove)
local Observer = require(script.Observer)
local Context = require(script.Context)
local Types = require(script.Types)

type Trove = Trove.Trove
type Observer = Observer.Observer
type InputEvent = Types.InputEvent
type Connection = Signal.Connection
type ObserverSignal = Observer.ObserverSignal
type PrivateContextObject = Types.PrivateContextObject
export type TapMetadata = Types.TapMetadata
export type HoldMetatdata = Types.HoldMetadata
export type ToggleMetadata = Types.ToggleMetadata
export type LongPressMetadata = Types.LongPressMetadata
export type InputMetadata = Types.InputMetadata
export type ContextObject = Types.ContextObject
export type ActionObject = Types.ActionObject
export type InputBinding = Types.InputBinding
export type PlatformObject = Types.PlatformObject

--[=[
	@class EasyInput
	A EasyInput is useful for abstracting the logic away from input connections.
	There are various input types that can be used.
]=]
local EasyInput = {}
EasyInput.__index = EasyInput

export type EasyInput = typeof(setmetatable({} :: {
	IsActive: boolean,
	Trove: Trove,
	Observer: Observer,
	Contexts: { [string]: ContextObject },
	ActiveContext: {  Name: string, Framework: ContextObject }?,
}, EasyInput))

--[=[
	Instantiates a new EasyInput object.
	@return EasyInput
]=]
function EasyInput.new(): EasyInput
	return setmetatable({
		Contexts = {},
		IsActive = false,
		Trove = Trove.new(),
		Observer = Observer.new(),
	}, EasyInput)
end

--[=[
	Starts listening for inputs.
]=]
function EasyInput.Enable(self: EasyInput): ()
	if self.IsActive then return end
	self.IsActive = true

	local function HandleObserverEvent(InputEventName: InputEvent, InputSignal: ObserverSignal)
		self.Trove:Add(InputSignal:Connect(function(Input: InputObject, GPE: boolean)
			if not self.ActiveContext then return end

			(self.ActiveContext.Framework :: PrivateContextObject):Handle(InputEventName, Input, GPE)
		end))
	end

	HandleObserverEvent("Began", self.Observer.OnBegan)
	HandleObserverEvent("Ended", self.Observer.OnEnded)
	HandleObserverEvent("Changed", self.Observer.OnChanged)

	self.Observer:Start()
end

--[=[
	Disables listening for inputs.
]=]
function EasyInput.Disable(self: EasyInput): ()
	if not self.IsActive then return end
	self.IsActive = false

	self.Trove:Clean()
	self.Observer:Stop()
end

--[=[
	Creates a new context.

	```lua
	input:AddContext("Gameplay")
		:Action("Test1")
			:Platform("PC")
				:Hold(KEYCODE.R)
				:LongPress(KEYCODE.X, 5)
	```

	@param ContextName string
	@return ContextObject
]=]
function EasyInput.AddContext(self: EasyInput, ContextName: string): ContextObject
	if self.Contexts[ContextName] then
		error(`[{script.Name}] Duplicate context entry: {ContextName}`)
	end

	local ContextObject = Context.new(ContextName)
	self.Contexts[ContextName] = ContextObject

	return ContextObject
end

--[=[
	Removes an instantiated context.

	```lua
	input:RemoveContext("Gameplay")
	```
	@param ContextName string
]=]
function EasyInput.RemoveContext(self: EasyInput, ContextName: string): ()
	local ContextObject = self:GetContext(ContextName) :: PrivateContextObject
	if not ContextObject then return end

	ContextObject:Destroy()
	self.Contexts[ContextName] = nil
end

--[=[
	Sets the new active context. Also disables the current active context.

	@param ContextName string
]=]
function EasyInput.SwitchContext(self: EasyInput, ContextName: string): ()
	if self.ActiveContext then
		self:_disableContext(ContextName)
	end

	self:_enableContext(ContextName)
end

--[=[
	Gets a ContextObject.

	@param ContextName string
	@return ContextObject
]=]
function EasyInput.GetContext(self: EasyInput, ContextName: string): ContextObject
	local ContextObject = self.Contexts[ContextName]

	if not ContextObject then
		error(`[{script.Name}] Failed to fetch context: {ContextName}`)
	end

	return ContextObject
end

--[=[
	Begin listening for when an action event is fired.

	```lua
	local connection = input:Hook("Gameplay", "Test1", function(metadata)
		print(metadata.Type, metadata.Bind)
	end)
	```

	@param ContextName string
]=]
function EasyInput.Hook(self: EasyInput, ContextName: string, ActionName: string, Fn: (InputMetadata) -> ()): Connection
	if typeof(Fn) ~= "function" then
		error(`[{script.Name}] Passed method is not a function! Got: {typeof(Fn)}`)
	end

	local ContextObject = self:GetContext(ContextName)

	local ActionObject = ContextObject.Actions[ActionName]
	if not ActionObject then
		error(`[{script.Name}] Failed to get ActionObject: {ActionName}`)
	end

	return ActionObject.Event:Connect(Fn)
end

--[=[
	Cleans all up the EasyInput object.

	:::warning Metatable Removal
	Running this will make any further attempts to call a method of EasyInput
	error.
	:::

	```lua
	input:Destroy()
	```
]=]
function EasyInput.Destroy(self: EasyInput)
	self.Trove:Destroy()

	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

function EasyInput._enableContext(self: EasyInput, ContextName: string)
	local ContextObject = self.Contexts[ContextName]
	if not ContextObject then
		warn(`[{script.Name}] Missing context: {ContextName}`)
		return
	end

	self.ActiveContext = {
		Name = ContextName,
		Framework = ContextObject,
	}
end

function EasyInput._disableContext(self: EasyInput, ContextName: string)
	if not self.ActiveContext then return end
	if self.ActiveContext.Name ~= ContextName then return end

	self.ActiveContext = nil
end

return EasyInput