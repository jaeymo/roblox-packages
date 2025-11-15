--!strict
local Root = script.Parent.Parent

local Parent = require(script.Parent)
local Types = require(Root.Types)

type KeycodeAndInputType = Types.KeycodeAndInputType
type ParentInput = Types.InputBinding
type InputSignal = Types.InputSignal

local Tap = setmetatable({}, { __index = Parent })
Tap.__index = Tap

export type Tap = ParentInput & typeof(setmetatable({} :: {}, Tap))

function Tap.new(Bind: KeycodeAndInputType, Event: InputSignal): Tap
	local self = Parent.new("Tap", Bind, Event)
	setmetatable(self :: any, Tap)

	return self :: Tap
end

function Tap.Began(self: Tap)
	self.Event:Fire({
		Type = "Tap",
		Bind = self.Bind,
	})
end

return Tap