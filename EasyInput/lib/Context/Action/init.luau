--!strict
local Root = script.Parent.Parent

local Signal = require(Root.Parent.signal)
local Platform = require(script.Platform)
local Types = require(Root.Types)

type ContextObject = Types.ContextObject
type ActionObject = Types.ActionObject
type PlatformObject = Types.PlatformObject
type KeycodeAndInputType = Types.KeycodeAndInputType
type PrivatePlatformObject = Types.PrivatePlatformObject

local Action = {}
Action.__index = Action

function Action.new(ActionName: string, ContextObject: ContextObject): ActionObject
	return setmetatable({
		ContextObject = ContextObject,
		Name = ActionName,
		Platforms = {},
		Event = Signal.new(),
	} :: any, Action)
end

function Action.Platform(self: ActionObject, PlatformName: Types.Platform): PlatformObject
	local PlatformObject = Platform.new(PlatformName, self)
	table.insert(self.Platforms, PlatformObject)
	
	return PlatformObject
end

function Action.Action(self: ActionObject, ActionName: string): ActionObject
	return self.ContextObject:Action(ActionName)
end

function Action.End(self: ActionObject): ContextObject
	return self.ContextObject
end

function Action.Destroy(self: ActionObject)
	for _, PlatformObject in self.Platforms do
		(PlatformObject :: PrivatePlatformObject):Destroy()
	end
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return Action