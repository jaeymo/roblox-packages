--!strict

--[[
	FiniteStateMachine: An FSM inspired by Unreal Engine
	Author: jaeymo
	Version: 1.0.1
	License: MIT
	Created: 10/12/2025

	For issues or feedback message `jaeymo` on Discord!
]]

local RunService = game:GetService("RunService")

local GeneralUtil = require(script.Parent["general-util"])
local Trove = require(script.Parent["trove"])

local FiniteStateMachine = {}
FiniteStateMachine.__index = FiniteStateMachine

export type State = {
	SetContext: ((self: State, Context: any) -> ())?,
	OnEnter: ((self: State) -> ())?,
	OnExit: ((self: State) -> ())?,
	Update: ((self: State, DeltaTime: number) -> ())?,
}

export type FiniteStateMachine = typeof(setmetatable({} :: {
    States: { [string]: State },
    Transitions: { [string]: {ToState: string, Conditional: () -> boolean}},
    IsActive: boolean,
    Context: any,

	InitialState: string?,
	CurrentState: string?,
	Trove: Trove.Trove,
}, FiniteStateMachine))

function FiniteStateMachine.new(): FiniteStateMachine
	return setmetatable({
		States = {},
		Transitions = {},
		IsActive = false,
		Trove = Trove.new(),
	}, FiniteStateMachine)
end

function FiniteStateMachine.SetContext(self: FiniteStateMachine, Context)
    self.Context = Context
end

function FiniteStateMachine.GetState(self: FiniteStateMachine)
	return self.CurrentState
end

function FiniteStateMachine.RegisterStatesIn(self: FiniteStateMachine, Ancestor: Instance, DefaultState: string?)
	for _, Descendant in Ancestor:GetDescendants()do
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

function FiniteStateMachine.RegisterState(self: FiniteStateMachine, StateName: string, State: State)
	if self.States[StateName] then warn(`[{script.Name}] A state with the name {StateName} is already registered`) return end

	self.States[StateName] = State
	GeneralUtil.SafeCall(State, "SetContext", State, self.Context)

	if not self.InitialState then
		self.InitialState = StateName
	end
end

function FiniteStateMachine.Start(self: FiniteStateMachine, StartingState: string?)
	if self.IsActive then return end

	self.Trove:Add(RunService.Heartbeat:Connect(function(DeltaTime: number)
		if not self.IsActive then return end
		self:Update(DeltaTime)
	end))

	self.IsActive = true
	self:ChangeState(StartingState or self.InitialState :: string)
end

function FiniteStateMachine:Stop()
	if not self.IsActive then return end

	self.Trove:Clean()

	self.IsActive = false
	self.CurrentState = nil
end

function FiniteStateMachine.ChangeState(self: FiniteStateMachine, NewStateName: string)
	if self.CurrentState then
		local OldState = self.States[self.CurrentState]
		GeneralUtil.SafeCall(OldState, "OnExit", OldState)
	end

	self.CurrentState = NewStateName
	
	local NewStateProfile = self.States[NewStateName]
	GeneralUtil.SafeCall(NewStateProfile, "OnEnter", NewStateProfile)
end

function FiniteStateMachine:Update(DeltaTime: number)
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

function FiniteStateMachine:AddTransition(FromState: string, ToState: string, Conditional: () -> boolean)
	if not self.Transitions[FromState] then
		self.Transitions[FromState] = {}
	end

	table.insert(self.Transitions[FromState], {ToState = ToState, Conditional = Conditional})
end

function FiniteStateMachine:Destroy()
	self.Trove:Destroy()
	setmetatable(self, nil)
end

return FiniteStateMachine