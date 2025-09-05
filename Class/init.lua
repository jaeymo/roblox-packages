--!strict
local Class = {}

--[[
	Class: A library for making OOP faster to write
	Author: jaey-dev
	Version: 0.1.1
	License: MIT
	Created: 09/02/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

export type ClassLike = {
	__index: any,
	__name: string,
}

export type Class<T> = ClassLike & {
	__init: (() -> ()?),
	construct: (... any) -> T,
	Destroy: (self: T) -> (),
}

function Class.newClass<T>(className: string): Class<T>
	assert(type(className) == "string", `[{script.Name}] Expected type "string", got type: {type(className)}`)
	
	local cls = {} :: Class<T>
	cls.__name = className
	cls.__index = cls

	function cls.construct(...: any): T
		local self = setmetatable({}, cls)
		if cls.__init and typeof(cls.__init) == "function" then
			(self :: any):__init(...)
		end

		return (self :: any)
	end

	function cls.Destroy(self: T)
		table.clear(self :: any)
		setmetatable(self :: any, nil)
	end

	return cls
end

return Class