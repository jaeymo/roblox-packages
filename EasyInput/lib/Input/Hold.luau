--!strict
local Root = script.Parent.Parent

local Parent = require(script.Parent)
local Types = require(Root.Types)

type KeycodeAndInputType = Types.KeycodeAndInputType
type ParentInput = Types.InputBinding
type InputSignal = Types.InputSignal

local Hold = setmetatable({}, { __index = Parent })
Hold.__index = Hold

export type Hold = ParentInput & typeof(setmetatable({} :: {}, Hold))

function Hold.new(Bind: KeycodeAndInputType, Event: InputSignal): Hold
	local self = Parent.new("Hold", Bind, Event)
	setmetatable(self :: any, Hold)
	
	return self :: Hold
end

function Hold.Began(self: Hold)
	self.Event:Fire({
		Type = "Hold",
		State = "Pressed",
		Bind = self.Bind		
	})
end

function Hold.Ended(self: Hold)
	self.Event:Fire({
		Type = "Hold",
		State = "Released",
		Bind = self.Bind
	})
end

return Hold