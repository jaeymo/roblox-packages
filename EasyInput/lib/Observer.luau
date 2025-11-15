--!strict
local UserInputService = game:GetService("UserInputService")

local Root = script.Parent

local Signal = require(Root.Parent.signal)
local Trove = require(Root.Parent.trove)

local Observer = {}
Observer.__index = Observer

export type ObserverSignal = Signal.Signal<InputObject, boolean>

export type Observer = typeof(setmetatable({} :: {
	Trove: Trove.Trove,	
	IsActive: boolean,
	
	OnBegan: ObserverSignal,
	OnEnded: ObserverSignal,
	OnChanged: ObserverSignal,
}, Observer))

function Observer.new(): Observer
	return setmetatable({
		Trove = Trove.new(),
		IsActive = false,
		
		OnBegan = Signal.new(),
		OnEnded = Signal.new(),
		OnChanged = Signal.new(),
	}, Observer)
end

function Observer.Start(self: Observer)
	if self.IsActive then return end
	self.IsActive = true
	
	local function WrapInputEvent(InputSignal: RBXScriptSignal, ActualSignal: ObserverSignal)
		self.Trove:Add(InputSignal:Connect(function(Input: InputObject, GPE: boolean)
			ActualSignal:Fire(Input, GPE)
		end))
	end
	
	WrapInputEvent(UserInputService.InputBegan, self.OnBegan)
	WrapInputEvent(UserInputService.InputEnded, self.OnEnded)
	WrapInputEvent(UserInputService.InputChanged, self.OnChanged)
end

function Observer.Stop(self: Observer)
	if not self.IsActive then return end
	self.IsActive = false
	
	self.Trove:Clean()
end

function Observer.Destroy(self: Observer)
	self.Trove:Destroy()
	
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return Observer