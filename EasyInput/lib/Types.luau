local Root = script.Parent

local Signal = require(Root.Parent.signal)

export type Platform = "PC" | "Mobile" | "Console"

export type KeycodeAndInputType = Enum.KeyCode | Enum.UserInputType

export type InputEvent = "Began" | "Ended" | "Changed"

export type TapMetadata = {
	Type: "Tap",
	Bind: KeycodeAndInputType
}

export type HoldMetadata = {
	Type: "Hold",
	State: "Pressed" | "Released",
	Bind: KeycodeAndInputType
}

export type LongPressMetadata = {
	Type: "LongPress",
	Duration: number,
	Bind: KeycodeAndInputType,
}

export type ToggleMetadata = {
	Type: "Toggle",
	State: "Enabled" | "Disabled",
	Bind: KeycodeAndInputType
}

export type InputMetadata = TapMetadata | HoldMetadata | LongPressMetadata | ToggleMetadata

export type InputSignal = Signal.Signal<InputMetadata>

export type InputBinding = {
	__index: InputBinding,
	new: (Name: string, Bind: KeycodeAndInputType, Event: InputSignal) -> InputBinding,
	
	Name: string,
	Bind: KeycodeAndInputType,
	Event: InputSignal,
	
	[any]: any,
}

export type InputBindingEntry = {
	Input: InputBinding,
}

export type PlatformObject = {
	__index: PlatformObject,
	new: (PlatformName: Platform, ActionObject: ActionObject) -> PlatformObject,
	
	Name: string,
	Inputs: { InputBinding },
	ActionObject: ActionObject,
	InputMap: { string: boolean },

	Action: (self: PlatformObject, ActionName: string) -> ActionObject,
	Platform: (self: PlatformObject, PlatformName: Platform) -> PlatformObject,
	
	Tap: (self: PlatformObject, Bind: KeycodeAndInputType) -> PlatformObject,
	Hold: (self: PlatformObject, Bind: KeycodeAndInputType) -> PlatformObject,
	Toggle: (self: PlatformObject, Bind: KeycodeAndInputType) -> PlatformObject,
	LongPress: (self: PlatformObject, Bind: KeycodeAndInputType, PressTime: number) -> PlatformObject,
}

export type ActionObject = {
	__index: ActionObject,
	new: (ActionName: string) -> ActionObject,
	
	Name: string,
	Platforms: { PlatformObject },
	ContextObject: ContextObject,
	Event: InputSignal,
	
	Action: (self: ActionObject, ActionName: string) -> ActionObject,
	
	Platform: (self: ActionObject, PlatformName: Platform) -> PlatformObject,
}

export type ContextObject = {
	__index: ContextObject,
	new: (ContextName: string) -> ContextObject,
	Is: (Object: any) -> boolean,
	
	Name: string,
	Actions: { [string]: ActionObject },
	InputMap: { [string]: { InputBindingEntry } },
	
	NewInput: (self: ContextObject, Bind: KeycodeAndInputType, InputBinding: InputBinding) -> (),
	Action: (self: ContextObject, ActionName: string) -> ActionObject,
}

export type PrivateContextObject = ContextObject & { 
	Handle: (self: ContextObject, InputEventName: InputEvent, Input: InputObject, GPE: boolean) -> (),
	Destroy: (self: ContextObject) -> () 
}

export type PrivateActionObject = ActionObject & { 
	Destroy: (self: ActionObject) -> () 
}

export type PrivatePlatformObject = PlatformObject & { 
	NewInput: (self: PlatformObject, Bind: KeycodeAndInputType, InputBinding: InputBinding) -> (), 
	Destroy: (self: PlatformObject) -> () 
}

export type PrivateInputBinding = InputBinding & { 
	Destroy: (self: InputBinding) -> () 
}

return {}