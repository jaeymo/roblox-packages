--!strict
local Root = script.Parent.Parent.Parent

local Types = require(Root.Types)

local InputFramework = Root.Input

local INPUT_MODULES = {
	LONG_PRESS = require(InputFramework.LongPress),
	TOGGLE = require(InputFramework.Toggle),
	HOLD = require(InputFramework.Hold),	
	TAP = require(InputFramework.Tap),
}

type InputBinding = Types.InputBinding
type ActionObject = Types.ActionObject
type PlatformObject = Types.PlatformObject
type PrivateInputBinding = Types.PrivateInputBinding
type KeycodeAndInputType = Types.KeycodeAndInputType
type PrivatePlatformObject = Types.PrivatePlatformObject

local Platform = {}
Platform.__index = Platform

function Platform.new(PlatformName: Types.Platform, ActionObject: ActionObject): PlatformObject
	return setmetatable({
		ActionObject = ActionObject,
		Name = PlatformName,
		Inputs = {},
		InputMap = {},
	} :: any, Platform)
end

function Platform.NewInput(self: PlatformObject, Bind: KeycodeAndInputType, InputBinding: InputBinding)
	self.InputMap[Bind.Name] = true
	self.ActionObject.ContextObject:NewInput(Bind, InputBinding)
end

function Platform.Tap(self: PlatformObject, Bind: KeycodeAndInputType): PlatformObject
	local InputBinding = INPUT_MODULES.TAP.new(Bind, self.ActionObject.Event)
	table.insert(self.Inputs, InputBinding);
	
	(self :: PrivatePlatformObject):NewInput(Bind, InputBinding);
	
	return self
end

function Platform.Hold(self: PlatformObject, Bind: KeycodeAndInputType): PlatformObject
	local InputBinding = INPUT_MODULES.HOLD.new(Bind, self.ActionObject.Event)
	table.insert(self.Inputs, InputBinding);
	
	(self :: PrivatePlatformObject):NewInput(Bind, InputBinding);
	
	return self
end

function Platform.Toggle(self: PlatformObject, Bind: KeycodeAndInputType): PlatformObject
	local InputBinding = INPUT_MODULES.TOGGLE.new(Bind, self.ActionObject.Event)
	table.insert(self.Inputs, InputBinding);
	
	(self :: PrivatePlatformObject):NewInput(Bind, InputBinding)
	
	return self
end

function Platform.LongPress(self: PlatformObject, Bind: KeycodeAndInputType, PressTime: number): PlatformObject
	if type(PressTime) ~= "number" then
		error(`[{script.Name}] Expected "number" type for PressTime, got: {type(PressTime)}`)
	end
	
	local InputBinding = INPUT_MODULES.LONG_PRESS.new(Bind, self.ActionObject.Event, PressTime)
	table.insert(self.Inputs, InputBinding);

	(self :: PrivatePlatformObject):NewInput(Bind, InputBinding)

	return self
end

function Platform.Action(self: PlatformObject, ActionName: string): ActionObject
	return self.ActionObject:Action(ActionName)
end

function Platform.Platform(self: PlatformObject, PlatformName: Types.Platform): PlatformObject
	return self.ActionObject:Platform(PlatformName)
end

function Platform.Destroy(self: PlatformObject)
	for _, InputBinding in self.Inputs do
		(InputBinding :: PrivateInputBinding):Destroy()
	end
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return Platform