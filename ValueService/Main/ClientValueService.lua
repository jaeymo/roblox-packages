--!strict
type ValueObject = Instance & { Value: any }

local ReplicaContainer = script.Parent:WaitForChild("Container") :: Folder

local ClientValueService = {}
ClientValueService.ValueCache = {} :: { [string]: ValueObject }

--[=[
	@function Get
	@within ClientValueService
	@param valueName string
	@return (any?, any?)
	
	Retrieves the value of a named ValueBase object from the ReplicaContainer, caching it for future access.
	
	```lua
	local value = ClientValueService.Get("PlayerScore") -- e.g., 100
	```
]=]
function ClientValueService.Get(valueName: string): (any?, any?)
	local cached = ClientValueService.ValueCache[valueName]
	if cached then
		return cached.Value, cached
	end

	local inst = ReplicaContainer:FindFirstChild(valueName)
	if inst and inst:IsA("ValueBase") then
		local valueObj = inst :: ValueObject
		ClientValueService.ValueCache[valueName] = valueObj
		
		return valueObj.Value, valueObj
	end

	return nil, nil
end

--[=[
	@function GetAsync
	@within ClientValueService
	@param valueName string
	@return (any, any)
	
	Retrieves the value of a named ValueBase object, waiting for it to exist in the ReplicaContainer if necessary.
	
	```lua
	local value = ClientValueService.GetAsync("PlayerScore") -- waits and returns e.g., 100
	```
]=]
function ClientValueService.GetAsync(valueName: string): (any, any)
	local cachedValue, cachedObj = ClientValueService.Get(valueName)
	if cachedValue ~= nil then
		return cachedValue, cachedObj
	end

	local inst = ReplicaContainer:WaitForChild(valueName)
	assert(inst:IsA("ValueBase"), `Found instance, but it's not a ValueBase: ${inst.ClassName}`)

	local valueObj = inst :: ValueObject
	ClientValueService.ValueCache[valueName] = valueObj

	return valueObj.Value, valueObj
end

return ClientValueService