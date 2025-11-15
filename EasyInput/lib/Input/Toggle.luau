--!strict
local Root = script.Parent.Parent

local Parent = require(script.Parent)
local Types = require(Root.Types)

type KeycodeAndInputType = Types.KeycodeAndInputType
type ParentInput = Types.InputBinding
type InputSignal = Types.InputSignal

local Toggle = setmetatable({}, { __index = Parent })
Toggle.__index = Toggle

export type Toggle = ParentInput & typeof(setmetatable({} :: {
	_state: boolean,	
}, Toggle))

local function getState(State: boolean): "Enabled" | "Disabled"
	return State and "Enabled" or "Disabled" :: any
end

function Toggle.new(Bind: KeycodeAndInputType, Event: InputSignal): Toggle
	local self = Parent.new("Toggle", Bind, Event)
	setmetatable(self :: any, Toggle)
	self._state = false

	return self :: Toggle
end

function Toggle.Began(self: Toggle)
	self._state = not self._state
	
	self.Event:Fire({
		Type = "Toggle",
		Bind = self.Bind,
		State = getState(self._state),
	})
end

return Toggle