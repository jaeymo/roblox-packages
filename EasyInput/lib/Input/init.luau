--!strict
local Root = script.Parent

local Types = require(Root.Types)

type InputBinding = Types.InputBinding
type InputSignal = Types.InputSignal
type KeycodeAndInputType = Types.KeycodeAndInputType

local Input = {}
Input.__index = Input

function Input.new(Name: string, Bind: KeycodeAndInputType, Event: InputSignal): InputBinding
	return setmetatable({
		Name = Name,
		Bind = Bind,
		Event = Event
	} :: any, Input)
end

function Input.Destroy(self: InputBinding)
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return Input