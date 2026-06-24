--!strict

--[[
	FiniteStateMachine: Finite state machine inspired by the Unreal Engine FSM
	Author: Jaeymo
	Version: 2.0.0
	License: MIT
	Created: 10/12/2025

	For issues or feedback message `jaeymo` on Discord!
]]

local RunService = game:GetService("RunService")

local Janitor = require(script.Parent.Janitor)

--[=[
	@class FiniteStateMachine
	A FiniteStateMachine (will be referred to as FSM) is useful for
	switching between states based off of conditionals.
 ]=]
local FiniteStateMachine = {}
FiniteStateMachine.__index = FiniteStateMachine

type NamingConvention = {
	OnEnter: string,
	OnExit: string,
	OnUpdate: string,
}

export type Janitor = Janitor.Janitor

export type FSMConfig = {
	NamingConvention: {
		OnEnter: string?,
		OnExit: string?,
		OnUpdate: string?,
	}?
}

export type State = {
	OnEnter: ((self: State) -> ())?,
	OnExit: ((self: State) -> ())?,
	OnUpdate: ((self: State, dt: number) -> ())?,
}

export type Transition<T> = {
	ToState: T,
	Conditional: () -> boolean,
}

export type FiniteStateMachine<T> = typeof(setmetatable({} :: {
    States: { [T]: State },
    
	Transitions: { [T]: {Transition<T>} },

    IsActive: boolean,
    Context: any,

	InitialState: T?,
	CurrentState: T?,

	Janitor: Janitor,

	_namingConvention: {
		OnEnter: string,
		OnExit: string,
		OnUpdate: string,
	}
}, FiniteStateMachine))

 --[=[
	@priv
]=]
local function safeCall<T>(Data: T, Fn: string, ...: any): ...any
	if typeof(Data) == "table" and typeof((Data :: any)[Fn]) == "function" then
		return (Data :: any)[Fn](...)
	end

	return
end

--[=[
	@priv
]=]
local function resolveNamingConvention(convention: {
	OnEnter: string?,
	OnExit: string?,
	OnUpdate: string?
}?): NamingConvention
	return {
		OnEnter = convention and convention.OnEnter or "OnEnter",
		OnExit = convention and convention.OnExit or "OnExit",
		OnUpdate = convention and convention.OnUpdate or "OnUpdate",
	}
end

 --[=[
	@return FiniteStateMachine
	Constructs a FSM object.

	```lua
	local fsm = FiniteStateMachine.new()
	```
]=]
function FiniteStateMachine.new<T>(Config: FSMConfig?): FiniteStateMachine<T>
	return setmetatable({
		States = {},
		Transitions = {},
		IsActive = false,
		Janitor = Janitor.new(),
		_namingConvention = resolveNamingConvention(Config and Config.NamingConvention),
	}, FiniteStateMachine) :: FiniteStateMachine<T>
end

--[=[
	@method SetContext
	@within FiniteStateMachine
	@param Context any
	Sets the context to be given to the state tables.

	```lua
	local context = { 
		foo = 1,
	}

	-- this works
	fsm:SetContext(context)

	-- this also works
	fsm.Context = context
	```
]=]
function FiniteStateMachine.SetContext<T>(self: FiniteStateMachine<T>, Context: any)
    self.Context = Context
end

--[=[
	@method GetCurrentState
	@within FiniteStateMachine
	@return T?
	Gets the currently active state.

	```lua
	fsm:SetState("Idle")

	local state = fsm:GetState() -- "Idle"
	```
]=]
function FiniteStateMachine.GetCurrentState<T>(self: FiniteStateMachine<T>): T?
	return self.CurrentState
end

--[=[
	@method GetState
	@within FiniteStateMachine
	@return: State?
]=]
function FiniteStateMachine.GetState<T>(self: FiniteStateMachine<T>, stateName: T): State?
	return self.States[stateName]
end

--[=[
	@method RegisterStatesIn
	@within FiniteStateMachine
	@param Ancestor Instance
	Registers state modules under an instance.

	```lua
	local StatesContainer = ReplicatedStorage.StateModules
	fsm:RegisterStatesIn(StatesContainer)
	```
]=]
function FiniteStateMachine.RegisterStatesIn<T>(self: FiniteStateMachine<T>, ancestor: Instance)
	for _, descendant in ancestor:GetDescendants() do
		if self.States[descendant.Name] then
			warn(`[{script.Name}] Cannot have multiple states with the same name: {descendant.Name}`)
			continue
		end

		if not descendant:IsA("ModuleScript") then
			continue
		end

		self:RegisterState(descendant.Name, (require :: any)(descendant))
	end

	self.InitialState = self.InitialState or next(self.States)
end

--[=[
	@method RegisterState
	@within FiniteStateMachine
	@param stateName T
	@param state State
	Registers a state internally

	```lua
	local StatesContainer = ReplicatedStorage.StateModules
	local StateModule = require(StatesContainer.State)

	fsm:RegisterState(StateModule)
	```
]=]
function FiniteStateMachine.RegisterState<T>(self: FiniteStateMachine<T>, stateName: T, state: State)
	if self.States[stateName] then 
		warn(`[{script.Name}] A state with the name "{stateName}" is already registered`) 
		return 
	end

	self.States[stateName] = state

	if not self.InitialState then
		self.InitialState = stateName
	end
end

--[=[
	@method Start
	@within FiniteStateMachine
	@param startingState string?
	Starts the FSM.

	```lua
	fsm:Start("Idle")
	```
]=]
function FiniteStateMachine.Start<T>(self: FiniteStateMachine<T>, startingState: T?)
	if self.IsActive then 
		return 
	end

	self.Janitor:Add(RunService.Heartbeat:Connect(function(dt: number)
		if not self.IsActive then
			return
		end

		self:_update(dt)
	end))

	self.IsActive = true

	if not self.InitialState and not startingState then
		warn(`[{script.Name}] Must set an initial/starting state!`)
		self:Stop()
		return
	end
	
	self:SetState(startingState or self.InitialState)
end

--[=[
	@method Stop
	@within FiniteStateMachine
	Stops the FSM.

	```lua
	fsm:Start("Idle")

	task.wait(2)

	fsm:Stop()
	```
]=]
function FiniteStateMachine.Stop<T>(self: FiniteStateMachine<T>)
	if not self.IsActive then
		return
	end

	if self.CurrentState and self.States[self.CurrentState] then
		safeCall(self.States[self.CurrentState], self._namingConvention.OnExit, self.States[self.CurrentState])
	end

	self.Janitor:Cleanup()

	self.IsActive = false
	self.CurrentState = nil
end

--[=[
	@method SetState
	@within FiniteStateMachine
	@param newStateName string
	Changes to a new FSM state.

	```lua
	fsm:SetState("Idle")

	task.wait(2)

	fsm:SetState("Moving")
	```
]=]
function FiniteStateMachine.SetState<T>(self: FiniteStateMachine<T>, newStateName: T)
	local newStateProfile = self.States[newStateName]
	if not newStateProfile then
		error(`[{script.Name}] State "{newStateName}" is not registered`)
	end

	if self.CurrentState == newStateName then
		return
	end

	if self.CurrentState then
		local oldState = self.States[self.CurrentState]
		safeCall(oldState, self._namingConvention.OnExit, oldState)
	end

	self.CurrentState = newStateName
	safeCall(newStateProfile, self._namingConvention.OnEnter, newStateProfile)
end

--[=[
	@method AddTransition
	@within FiniteStateMachine
	@param fromState string
	@param toState string
	@param conditional () -> boolean
	Adds a conditional transition between states.

	```lua
	fsm:AddTransition("Idle", "Moving", function()
		return true -- typically would be a method like: "IsMoving"
	end)

	fsm:AddTransition("Moving", "Idle", function()
		return true -- typically would be a method like: "IsStill"
	end)
	```
]=]
function FiniteStateMachine.AddTransition<T>(self: FiniteStateMachine<T>, fromState: T, toState: T, conditional: () -> boolean)
	if not self.Transitions[fromState] then
		self.Transitions[fromState] = {}
	end

	table.insert(self.Transitions[fromState], {ToState = toState, Conditional = conditional})
end

--[=[
	@method Destroy
	@within FiniteStateMachine
	Destroys the FSM and renders it useless.

	```lua
	fsm:Destroy()
	```
]=]
function FiniteStateMachine.Destroy<T>(self: FiniteStateMachine<T>)
	self:Stop()
	self.Janitor:Cleanup()

	table.clear(self)
	setmetatable(self, nil)
end

function FiniteStateMachine._update<T>(self: FiniteStateMachine<T>, dt: number)
	if not self.CurrentState then 
		return 
	end

	if not self.States[self.CurrentState] then 
		return 
	end

	local state = self.States[self.CurrentState]
	safeCall(state, self._namingConvention.OnUpdate, state, dt)

	local stateTransitions = self.Transitions[self.CurrentState] :: {Transition<T>}
	if not stateTransitions then
		return
	end

	for _, toStateData in stateTransitions do
		if toStateData.Conditional() then
			self:SetState(toStateData.ToState)
			break
		end
	end
end

return FiniteStateMachine