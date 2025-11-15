--!strict
local Root = script.Parent.Parent

local Parent = require(script.Parent)
local Types = require(Root.Types)

type KeycodeAndInputType = Types.KeycodeAndInputType
type ParentInput = Types.InputBinding
type InputSignal = Types.InputSignal

local LongPress = setmetatable({}, { __index = Parent })
LongPress.__index = LongPress

export type LongPress = ParentInput & typeof(setmetatable({} :: {
	Time: number,
	_start: number?
}, LongPress))

function LongPress.new(Bind: KeycodeAndInputType, Event: InputSignal, PressTime: number): LongPress
	local self = Parent.new("LongPress", Bind, Event)
	setmetatable(self :: any, LongPress)
	
	self.Time = PressTime
	
	return self :: LongPress
end

function LongPress.Began(self: LongPress)
	self._start = os.clock()
end

function LongPress.Ended(self: LongPress)
	if not self._start then return end
	
	local Duration = os.clock() - self._start
	
	if Duration >= self.Time then
		self.Event:Fire({
			Type = "LongPress",
			Duration = Duration,
			Bind = self.Bind,
		})
		
		self._start = nil
	end
end

return LongPress