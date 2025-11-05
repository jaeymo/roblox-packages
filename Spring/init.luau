--!strict

--[[
	Spring: Damped harmonic oscillator spring, properly typed version of the Quenty/NevermoreEngine Spring module.
	Author: Jaeymo
	Version: 1.0.1
	License: MIT
	Created: 11/5/2025

	For issues or feedback message `jaeymo` on Discord!
]]

local Spring = {}

export type Spring<T = number | Vector3> = typeof(setmetatable({} :: {
	Impulse: (self: Spring<T>, Velocity: T) -> (),
	TimeSkip: (self: Spring<T>, Delta: number) -> (),

	_clock: () -> number;
	_time0: number;
	_position0: number;
	_velocity0: number;
	_target: number;
	_damper: number;
	_speed: number;

	Position: T,       -- number/v3
	Velocity: T,       -- number/v3
	Target: T,         -- number/v3
	Damper: number,    -- [-inf, inf]
	Speed: number,     -- [0, inf]
}, Spring))

--[[
	@private
]]

local function zeroOf<T>(Value: T?): T
	if not Value then
		return 0 :: any
	end

	if typeof(Value) == "number" then
		return 0 :: any
	else
		return Vector3.zero :: any
	end
end

--[=[
	@return Spring<T>
	Constructs a Spring object.

	```lua
	local spring = Spring.new(0, os.clock) -- params can be nil
	```
]=]
function Spring.new<T>(Initial: T?, Clock: (() -> number)?): Spring<T>
	local Target = Initial or 0
	local TrueClock = Clock or os.clock

	return setmetatable({
		_clock = TrueClock;
		_time0 = TrueClock();
		_position0 = Target;
		_velocity0 = zeroOf(Target);
		_target = Target;
		_damper = 1;
		_speed = 1;
	}, Spring) :: Spring<T>
end

--[=[
	@method Impulse
	@within Spring
	@param Velocity T
	IApplies an instantaneous velocity to the spring

	```lua
	local mySpring = Spring.new(0)
	mySpring.Target = 10
	mySpring.Damper = 0.5
	mySpring.Speed = 5

	mySpring:Impulse(25)
	print(mySpring.Position)
	```
]=]
function Spring.Impulse<T>(self: Spring<T>, Velocity: T)
	self.Velocity += (Velocity :: any)
end

--[=[
	@method TimeSkip
	@within Spring
	@param Delta number
	Applies a time skip on the spring to handle FPS

	```lua
	local mySpring = Spring.new(0)
	mySpring.Target = 10
	mySpring.Damper = 0.5
	mySpring.Speed = 5

	mySpring:Impulse(25)

	RunService.RenderStepped:Connect(function(DeltaTime: number)
		mySpring:TimeSkip(DeltaTime)
	end)
	```
]=]
function Spring.TimeSkip<T>(self: Spring<T>, Delta: number)
	local Now = self._clock()

	local Position, Velocity = self:_positionVelocity(Now + Delta)
	self._position0 = Position
	self._velocity0 = Velocity
	self._time0 = Now
end

--[=[
	@private
]=]
function Spring._positionVelocity<T>(self: Spring<T>, Now: number): (number, number)
	local p0 = self._position0
	local v0 = self._velocity0
	local p1 = self._target
	local d = self._damper
	local s = self._speed

	local t = s*(Now - self._time0)
	local d2 = d*d

	local h, si, co
	if d2 < 1 then
		h = math.sqrt(1 - d2)
		local ep = math.exp(-d*t)/h
		co, si = ep*math.cos(h*t), ep*math.sin(h*t)
	elseif d2 == 1 then
		h = 1
		local ep = math.exp(-d*t)/h
		co, si = ep, ep*t
	else
		h = math.sqrt(d2 - 1)
		local u = math.exp((-d + h)*t)/(2*h)
		local v = math.exp((-d - h)*t)/(2*h)
		co, si = u + v, u - v
	end

	local a0 = h*co + d*si
	local a1 = 1 - (h*co + d*si)
	local a2 = si/s

	local b0 = -s*si
	local b1 = s*si
	local b2 = h*co - d*si

	return (a0*p0 + a1*p1 + a2*v0), (b0*p0 + b1*p1 + b2*v0)
end

function Spring.__newindex<T>(self: Spring<T>, Index: any, Value: any)
	local Now = self._clock()

	if Index == "Value" or Index == "Position" or Index == "p" then
		local _, Velocity = self:_positionVelocity(Now)
		self._position0 = Value
		self._velocity0 = Velocity
		self._time0 = Now

	elseif Index == "Velocity" or Index == "v" then
		local Position, _ = self:_positionVelocity(Now)
		self._position0 = Position
		self._velocity0 = Value
		self._time0 = Now

	elseif Index == "Target" or Index == "t" then
		local Position, Velocity = self:_positionVelocity(Now)
		self._position0 = Position
		self._velocity0 = Velocity
		self._target = Value
		self._time0 = Now

	elseif Index == "Damper" or Index == "d" then
		local Position, Velocity = self:_positionVelocity(Now)
		self._position0 = Position
		self._velocity0 = Velocity
		self._damper = Value
		self._time0 = Now

	elseif Index == "Speed" or Index == "s" then
		local Position, Velocity = self:_positionVelocity(Now)
		self._position0 = Position
		self._velocity0 = Velocity
		self._speed = Value < 0 and 0 or Value
		self._time0 = Now
	elseif Index == "Clock" then
		local Position, Velocity = self:_positionVelocity(Now)
		self._position0 = Position
		self._velocity0 = Velocity
		self._clock = Value
		self._time0 = Value()
	else
		error(("%q is not a valid member of Spring"):format(tostring(Index)), 2)
	end
end

function Spring.__index<T>(self: Spring<T>, Index: any): any
	if Spring[Index] then
		return Spring[Index]

	elseif Index == "Value" or Index == "Position" or Index == "p" then
		local pos = self:_positionVelocity(self._clock())
		return pos

	elseif Index == "Velocity" or Index == "v" then
		local _, velocity = self:_positionVelocity(self._clock())
		return velocity

	elseif Index == "Target" or Index == "t" then
		return self._target

	elseif Index == "Damper" or Index == "d" then
		return self._damper

	elseif Index == "Speed" or Index == "s" then
		return self._speed

	elseif Index == "Clock" then
		return self._clock

	else
		error(("%q is not a valid member of Spring"):format(tostring(Index)), 2)
	end
end

return Spring