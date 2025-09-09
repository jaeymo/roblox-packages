export type ServerValueService = {
	new: (valueName: string, valueType: string, defaultValue: any?) -> Instance & { Value: any },
	Get: (valueName: string) -> (any?, any?),
	GetAsync: (valueName: string) -> (any, any),
	Set: (valueName: string, newValue: any) -> boolean,
	Increment: (valueName: string, amount: number) -> number?,
}

export type ClientValueService = {
	Get: (valueName: string) -> (any?, any?),
	GetAsync: (valueName: string) -> (any, any),
}

return {}