--!strict

--[[
	GeneralUtil: A module containing observer methods
	Author: jaeymo
	Version: 0.1.0
	License: MIT
	Created: 09/09/2025

	For issues or feedback message `jaeymo` on Discord!

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣤⣤⣴⣤⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⠿⠛⠋⠉⠁⠀⠀⠀⠈⠙⠻⢷⣦⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣤⣾⡿⠋⠁⠀⣠⣶⣿⡿⢿⣷⣦⡀⠀⠀⠀⠙⠿⣦⣀⠀⠀⠀⠀
⠀⠀⢀⣴⣿⡿⠋⠀⠀⢀⣼⣿⣿⣿⣶⣿⣾⣽⣿⡆⠀⠀⠀⠀⢻⣿⣷⣶⣄⠀
⠀⣴⣿⣿⠋⠀⠀⠀⠀⠸⣿⣿⣿⣿⣯⣿⣿⣿⣿⣿⠀⠀⠀⠐⡄⡌⢻⣿⣿⡷
⢸⣿⣿⠃⢂⡋⠄⠀⠀⠀⢿⣿⣿⣿⣿⣿⣯⣿⣿⠏⠀⠀⠀⠀⢦⣷⣿⠿⠛⠁
⠀⠙⠿⢾⣤⡈⠙⠂⢤⢀⠀⠙⠿⢿⣿⣿⡿⠟⠁⠀⣀⣀⣤⣶⠟⠋⠁⠀⠀⠀
⠀⠀⠀⠀⠈⠙⠿⣾⣠⣆⣅⣀⣠⣄⣤⣴⣶⣾⣽⢿⠿⠟⠋⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠛⠛⠙⠋⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
]]

local Viewer = {}

local CollectionService = game:GetService("CollectionService")

--[=[
	@function wrapCallback
	@within Viewer
	@param callback { T } | (T) -> ()
	@param reverse boolean?
	@return (T) -> ()

	Wraps a callback (function or table) into a function that either calls the function directly 
		or modifies the table by inserting or removing elements based on the reverse parameter.

	```lua
	local list = {}
	local callback = wrapCallback(list, false)
	callback("item") -- Adds "item" to list
	```
]=]
local function wrapCallback<T>(callback: { T } | (T) -> (), reverse: boolean?): (T) -> ()
	if type(callback) == "function" then
		return callback :: (T) -> ()
	else
		local list = callback :: { T }
		if reverse then

			return function(v: T)
				local index = table.find(list, v)

				if index then
					table.remove(list, index)
				end
			end
		else
			return function(v: T)
				table.insert(list, v)
			end
		end
	end
end

--[=[
	@function WatchTag
	@within Viewer
	@param tag string
	@param reverse boolean
	@param callback { Instance } | (Instance) -> ()
	@param mustBeDescendantOf Instance?
	@return RBXScriptConnection
	
	Watches for instances with a specific tag, calling the callback when instances are added or removed
		(based on reverse).
	
	```lua
	local Viewer = require(script)
	
	local connection = Viewer.WatchTag("Enemy", false, function(instance)
		print("Added:", instance.Name)
	end)
	```
]=]
function Viewer.WatchTag(tag: string, reverse: boolean, callback: { Instance } | (Instance) -> (), mustBeDescendantOf: Instance?): RBXScriptConnection
	assert(callback ~= nil, "Callback parameter is missing, did you forget your reverse parameter?")
	local func = wrapCallback(callback, reverse)

	local function check(instance: Instance)
		if mustBeDescendantOf and not instance:IsDescendantOf(mustBeDescendantOf) then
			return
		end
		
		func(instance)
	end

	if reverse then
		return CollectionService:GetInstanceRemovedSignal(tag):Connect(check)
	else
		for _, tagged in CollectionService:GetTagged(tag) do
			task.spawn(check, tagged)
		end
		
		return CollectionService:GetInstanceAddedSignal(tag):Connect(check)
	end
end

--[=[
	@function WatchDescendants
	@within Viewer
	@param object Instance
	@param callback { Instance? } | (Instance) -> ()
	@param ignoreInitial boolean?
	@return RBXScriptConnection
	
	Watches for descendants added to an object, calling the callback for existing and new descendants.
	
	```lua
	local Viewer = require(script)
	
	local folder = Instance.new("Folder")
	
	local connection = Viewer.WatchDescendants(folder, function(descendant)
		print("Descendant added:", descendant.Name)
	end)
	```
]=]
function Viewer.WatchDescendants(object: Instance, callback: { Instance? } | (Instance) -> (), ignoreInitial: boolean?): RBXScriptConnection
	local func = wrapCallback(callback)
	
	if not ignoreInitial then
		for _, descendant in object:GetDescendants() do
			task.spawn(func, descendant)
		end
	end
	
	return object.DescendantAdded:Connect(func)
end

--[=[
	@function WatchAttribute
	@within Viewer
	@param object Instance
	@param attributeName string
	@param callback { any? } | (any) -> ()
	@param ignoreInitial boolean?
	
	@return RBXScriptConnection
	
	Watches for changes to a specific attribute on an object, calling the callback with the current 
		and updated attribute values.
	
	```lua
	local Viewer = require(script)
	
	local part = Instance.new("Part")
	part:SetAttribute("Health", 100)
	
	local connection = Viewer.WatchAttribute(part, "Health", function(value)
		print("Health changed to:", value)
	end)
	```
]=]
function Viewer.WatchAttribute(object: Instance, attributeName: string, callback: { any? } | (any) -> (), ignoreInitial: boolean?): RBXScriptConnection
	local func = wrapCallback(callback)
	local current = object:GetAttribute(attributeName)
	
	if current ~= nil and not ignoreInitial then
		func(current)
	end
	
	return object:GetAttributeChangedSignal(attributeName):Connect(function()
		func(object:GetAttribute(attributeName))
	end)
end

--[=[
	@function WatchValue
	@within Viewer
	@param valueObject Instance
	@param callback { any? } | (any) -> ()
	@param ignoreInitial boolean?
	@return RBXScriptConnection
	
	Watches for changes to a ValueBase object's Value property, calling the callback with the current 
		and updated values.
	
	```lua
	local Viewer = require(script)
	
	local intValue = Instance.new("IntValue")
	intValue.Value = 42
	
	local connection = Viewer.WatchValue(intValue, function(value)
		print("Value changed to:", value)
	end)
	```
]=]
function Viewer.WatchValue(valueObject: Instance, callback: { any? } | (any) -> (), ignoreInitial: boolean?): RBXScriptConnection
	local typedValueObject = valueObject :: Instance & { Value: any }
	local func = wrapCallback(callback)
	
	if not ignoreInitial then
		func(typedValueObject.Value)
	end
	
	return typedValueObject.Changed:Connect(function()
		func(typedValueObject.Value)
	end)
end

return Viewer