--!strict
type ValueObject = Instance & { Value: any }

local Container = Instance.new("Folder")
Container.Name = "Container"
Container.Parent = script.Parent

local ServerValueService = {}
ServerValueService.ValueCache = {} :: { [string]: ValueObject }

--[=[
	@function new
	@within ServerValueService
	@param valueName string
	@param valueClassName string
	@param defaultValue any?
	@return ValueObject
	
	Creates a new ValueBase object with the specified name, type, and optional default value, 
		storing it in the Container.
	
	```lua
	local valueObj = ServerValueService.new("PlayerScore", "Int", 0)
	```
]=]
function ServerValueService.new(valueName: string, valueClassName: string, defaultValue: any?): ValueObject
	assert(type(valueName) == "string", `Value name must be a string! Got: {type(valueName)}`)
	assert(type(valueClassName) == "string", `Value type must be a string! Got: {type(valueClassName)}`)

	local success, inst = pcall(function()
		return Instance.new(valueClassName .. "Value")
	end)

	assert(success and inst ~= nil and inst:IsA("ValueBase"), `Invalid ValueBase type: ${valueClassName}`)

	local valueObj = inst :: ValueObject
	valueObj.Name = valueName
	valueObj.Parent = Container

	if defaultValue ~= nil then
		valueObj.Value = defaultValue
	end

	ServerValueService.ValueCache[valueName] = valueObj
	return valueObj
end

--[=[
	@function Get
	@within ServerValueService
	@param valueName string
	@return (any?, any?)
	
	Retrieves the value of a named ValueBase object from the Container, caching it for future access.
	
	```lua
	local value = ServerValueService.Get("PlayerScore") -- e.g., 100
	```
]=]
function ServerValueService.Get(valueName: string): (any?, any?)
	local cached = ServerValueService.ValueCache[valueName]
	if cached then
		return cached.Value, cached
	end

	local inst = Container:FindFirstChild(valueName)
	if inst and inst:IsA("ValueBase") then
		local valueObj = inst :: ValueObject
		ServerValueService.ValueCache[valueName] = valueObj
		
		return valueObj.Value, valueObj
	end

	return nil, nil
end

--[=[
	@function GetAsync
	@within ServerValueService
	@param valueName string
	@return (any, any)
	
	Retrieves the value of a named ValueBase object, waiting for it to exist in the Container if necessary.
	
	```lua
	local value = ServerValueService.GetAsync("PlayerScore") -- waits and returns e.g., 100
	```
]=]
function ServerValueService.GetAsync(valueName: string): (any, any)
	local cachedValue, cachedObject = ServerValueService.Get(valueName)
	if cachedValue ~= nil then
		return cachedValue, cachedObject
	end

	local inst = Container:WaitForChild(valueName)
	assert(inst:IsA("ValueBase"), `Found instance, but it's not a ValueBase: ${inst.ClassName}`)

	local valueObj = inst :: ValueObject
	ServerValueService.ValueCache[valueName] = valueObj

	return valueObj.Value, valueObj
end

--[=[
	@function Set
	@within ServerValueService
	@param valueName string
	@param newValue any
	@return boolean
	
	Sets the value of a named ValueBase object in the Container, returning true if successful.
	
	```lua
	local success = ServerValueService.Set("PlayerScore", 200) -- returns true
	```
]=]
function ServerValueService.Set(valueName: string, newValue: any): boolean
	local obj = ServerValueService.ValueCache[valueName]
	if not obj then
		local inst = Container:FindFirstChild(valueName)
		if inst and inst:IsA("ValueBase") then
			obj = inst :: ValueObject
			ServerValueService.ValueCache[valueName] = obj
		else
			warn(`Tried to set value of '${valueName}', but it doesn't exist.`)
			return false
		end
	end

	obj.Value = newValue
	
	return true
end

--[=[
	@function Increment
	@within ServerValueService
	@param valueName string
	@param amount number
	@return number?
	
	Increments a numeric ValueBase object by the specified amount, returning the new value or nil if the 
		value is not a number.
	
	```lua
	local newValue = ServerValueService.Increment("PlayerScore", 10) -- e.g., 110
	```
]=]
function ServerValueService.Increment(valueName: string, amount: number): number?
	local current = ServerValueService.Get(valueName) :: number?
	if typeof(current) ~= "number" then
		warn(`Cannot increment value '{valueName}' because it is not a number.`)
		return nil
	end
	
	ServerValueService.Set(valueName, current + amount)
	return current + amount
end

return ServerValueService