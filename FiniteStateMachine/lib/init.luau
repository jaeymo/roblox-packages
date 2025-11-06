--!strict

--[[
	FiniteStateMachine: Finite state machine inspired by the Unreal Engine FSM
	Author: Jaeymo
	Version: 1.1.0
	License: MIT
	Created: 10/12/2025

	For issues or feedback message `jaeymo` on Discord!
]]

local RunService = game:GetService("RunService")

local GeneralUtil = require(script.Parent["general-util"])
local Trove = require(script.Parent["trove"])

--[=[
	@class FiniteStateMachine
	A FiniteStateMachine (will be referred to as FSM) is useful for
	switching between states based off of conditionals.
 ]=]
local FiniteStateMachine = {}
FiniteStateMachine.__index = FiniteStateMachine

export type State = {
	OnEnter: ((self: State) -> ())?,
	OnExit: ((self: State) -> ())?,
	Update: ((self: State, DeltaTime: number) -> ())?,
}

export type FiniteStateMachine = typeof(setmetatable({} :: {
	StartupMethod: string?,
    States: { [string]: State },
    Transitions: { [string]: {ToState: string, Conditional: () -> boolean}},
    IsActive: boolean,
    Context: any,

	InitialState: string?,
	CurrentState: string?,
	Trove: Trove.Trove,
}, FiniteStateMachine))

 --[=[
	@return FiniteStateMachine
	Constructs a FSM object.

	```lua
	local fsm = FiniteStateMachine.new()
	```
]=]
function FiniteStateMachine.new(StartupMethod: string?): FiniteStateMachine
	return setmetatable({
		StartupMethod = StartupMethod,
		States = {},
		Transitions = {},
		IsActive = false,
		Trove = Trove.new(),
	}, FiniteStateMachine)
end

--[=[
	@method SetContext
	@within FiniteStateMachine
	@param Context any
	Sets the context to be given to the state tables.

	```lua
	local context = { foo = 1, }

	-- both work
	fsm:SetContext(context)
	fsm.Context = context
	```
]=]
function FiniteStateMachine.SetContext(self: FiniteStateMachine, Context: any)
    self.Context = Context
end

--[=[
	@method GetState
	@within FiniteStateMachine
	@return string?
	Gets the currently active state.

	```lua
	fsm:SetState("Idle")

	local state = fsm:GetState() -- "Idle"
	```
]=]
function FiniteStateMachine.GetState(self: FiniteStateMachine): string?
	return self.CurrentState
end

--[=[
	@method RegisterStatesIn
	@within FiniteStateMachine
	@param Ancestor Instance
	@param DefaultState string?
	Registers state modules under an instance.

	```lua
	local StatesContainer = ReplicatedStorage.StateModules
	fsm:RegisterStatesIn(StatesContainer)
	```
]=]
function FiniteStateMachine.RegisterStatesIn(self: FiniteStateMachine, Ancestor: Instance, DefaultState: string?)
	for _, Descendant in Ancestor:GetDescendants() do
		if self.States[Descendant.Name] then
			warn(`[{script.Name}] Cannot have multiple states with the same name: {Descendant.Name}`)
			continue
		end

		if not Descendant:IsA("ModuleScript") then
			continue
		end

		local State = require(Descendant)
		self:RegisterState(Descendant.Name, State)
	end

	self.InitialState = DefaultState or self.InitialState or next(self.States)
end

--[=[
	@method RegisterState
	@within FiniteStateMachine
	@param StateName string
	@param State State
	Registers a state internally and calls the StartupMethod if applicable.

	```lua
	local StatesContainer = ReplicatedStorage.StateModules
	local StateModule = require(StatesContainer.State)

	fsm:RegisterState(StateModule)
	```
]=]
function FiniteStateMachine.RegisterState(self: FiniteStateMachine, StateName: string, State: State)
	if self.States[StateName] then warn(`[{script.Name}] A state with the name {StateName} is already registered`) return end

	self.States[StateName] = State
	GeneralUtil.SafeCall(State, self.StartupMethod, State, self.Context)

	if not self.InitialState then
		self.InitialState = StateName
	end
end

--[=[
	@method Start
	@within FiniteStateMachine
	@param StartingState string?
	Starts the FSM.

	```lua
	fsm:Start("Idle")
	```
]=]
function FiniteStateMachine.Start(self: FiniteStateMachine, StartingState: string?)
	if self.IsActive then return end

	self.Trove:Add(RunService.Heartbeat:Connect(function(DeltaTime: number)
		if not self.IsActive then return end
		self:_update(DeltaTime)
	end))

	self.IsActive = true
	self:ChangeState(StartingState or self.InitialState :: string)
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
function FiniteStateMachine:Stop()
	if not self.IsActive then return end

	self.Trove:Clean()

	self.IsActive = false
	self.CurrentState = nil
end

--[=[
	@method ChangeState
	@within FiniteStateMachine
	@param NewStateName string
	Changes to a new FSM state.

	```lua
	fsm:ChangeState("Idle")

	task.wait(2)

	fsm:ChangeState("Moving")
	```
]=]
function FiniteStateMachine.ChangeState(self: FiniteStateMachine, NewStateName: string)
	if self.CurrentState then
		local OldState = self.States[self.CurrentState]
		GeneralUtil.SafeCall(OldState, "OnExit", OldState)
	end

	self.CurrentState = NewStateName

	local NewStateProfile = self.States[NewStateName]
	GeneralUtil.SafeCall(NewStateProfile, "OnEnter", NewStateProfile)
end

--[=[
	@method AddTransition
	@within FiniteStateMachine
	@param FromState string
	@param ToState string
	@param Conditional () -> boolean
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
function FiniteStateMachine:AddTransition(FromState: string, ToState: string, Conditional: () -> boolean)
	if not self.Transitions[FromState] then
		self.Transitions[FromState] = {}
	end

	table.insert(self.Transitions[FromState], {ToState = ToState, Conditional = Conditional})
end

--[=[
	@method Destroy
	@within FiniteStateMachine
	Destroys the FSM.

	```lua
	fsm:Destroy()
	```
]=]
function FiniteStateMachine:Destroy()
	self.Trove:Destroy()
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

function FiniteStateMachine:_update(DeltaTime: number)
	if not self.CurrentState then return end
	if not self.States[self.CurrentState] then return end

	local State = self.States[self.CurrentState]
	GeneralUtil.SafeCall(State, "Update", State, DeltaTime)

	local StateTransitions = self.Transitions[self.CurrentState]
	if StateTransitions then
		for _, ToStateData in ipairs(StateTransitions) do
			if ToStateData.Conditional and ToStateData.Conditional() then
				self:ChangeState(ToStateData.ToState)
				break
			end
		end
	end
end

return FiniteStateMachine