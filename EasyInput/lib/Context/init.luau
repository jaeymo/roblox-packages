--!strict
local Root = script.Parent

local Action = require(script.Action)
local Types = require(Root.Types)

type InputEvent = Types.InputEvent
type InputBinding = Types.InputBinding
type ActionObject = Types.ActionObject
type ContextObject = Types.ContextObject
type PlatformObject = Types.PlatformObject
type PrivateActionObject = Types.PrivateActionObject
type KeycodeAndInputType = Types.KeycodeAndInputType

local Context = {}
Context.__index = Context

function Context.new(ContextName: string): ContextObject
	return setmetatable({
		Name = ContextName,
		Actions = {},
		InputMap = {},
	} :: any, Context)
end

function Context.Is(Object: any): boolean
	return type(Object) == "table" and getmetatable(Object) == Context
end

function Context.NewInput(self: ContextObject, Bind: KeycodeAndInputType, InputBinding: InputBinding)
	local Name = Bind.Name
	self.InputMap[Name] = self.InputMap[Name] or {}
	
	table.insert(self.InputMap[Name], {
		Input = InputBinding,
	})
end

function Context.Handle(self: ContextObject, InputEventName: InputEvent, Input: InputObject, GPE: boolean)
	local Name = Input.KeyCode.Name or Input.UserInputType.Name
	local Bindings = self.InputMap[Name]
	if not Bindings then return end
	
	-- GPE CHECK!

	for _, Entry in Bindings do
		local InputBinding = Entry.Input

		if InputBinding[InputEventName] and typeof(InputBinding[InputEventName]) == "function" then
			InputBinding[InputEventName](InputBinding)
		end
	end
end

function Context.Action(self: ContextObject, ActionName: string): ActionObject
	if self.Actions[ActionName] then
		warn(`[{script.Name}] Duplicate action entries: {ActionName}`)
		return self.Actions[ActionName]
	end
	
	local ActionObject = Action.new(ActionName, self)
	self.Actions[ActionName] = ActionObject
	
	return ActionObject
end

function Context.Destroy(self: ContextObject)
	for _, ActionObject in self.Actions do
		(ActionObject :: PrivateActionObject):Destroy()
	end
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return Context