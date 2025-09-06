--!strict

--[[
	ResourceAllocator: Module to handle weighted cost-budget systems
	Author: jaeymo
	Version: 0.1.1
	License: MIT
	Created: 09/06/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

local ResourceAllocator = {}
ResourceAllocator.__index = ResourceAllocator

type ItemList = {[string]: {Weight: number, Cost: number}}
type Properties = { Items: ItemList }

export type ResourceAllocator = typeof(setmetatable({} :: Properties, ResourceAllocator))

local function getWeightedList(items: ItemList)
	local weighted = {}
	for name, data in items do
		for _ = 1, data.Weight do
			table.insert(weighted, name)
		end
	end

	return weighted
end

--[=[
	@return ResourceAllocator
	Creates a new ResourceAllocator object with an empty item list.
	
	```lua
	local allocator = ResourceAllocator.new()
	```
]=]
function ResourceAllocator.new(): ResourceAllocator
	return setmetatable({
		Items = {},
	}, ResourceAllocator)
end

--[=[
	@method BatchAddItems
	@within ResourceAllocator
	@param items ItemList
	Adds multiple items to the allocator's item list in a single operation.
	
	```lua
	local allocator = ResourceAllocator.new()
	local items = { Sword = { Weight = 2, Cost = 10 }, Shield = { Weight = 1, Cost = 15 } }
	allocator:BatchAddItems(items)
	```
]=]
function ResourceAllocator.BatchAddItems(self: ResourceAllocator, items: ItemList)
	for name, data in items do
		self.Items[name] = data
	end
end

--[=[
	@method AddItem
	@within ResourceAllocator
	@param name string
	@param cost number
	@param weight number
	Adds a single item with specified cost and weight to the allocator's item list.
	
	```lua
	local allocator = ResourceAllocator.new()
	allocator:AddItem("Sword", 10, 2)
	```
]=]
function ResourceAllocator.AddItem(self: ResourceAllocator, name: string, cost: number, weight: number)
	self.Items[name] = { Cost = cost, Weight = weight }
end
	
--[=[
	@method Allocate
	@within ResourceAllocator
	@param totalBudget number
	@return {[string]: number}
	Allocates items randomly based on their weights within the given budget, returning a table of item counts.
	
	```lua
	local allocator = ResourceAllocator.new()
	allocator:AddItem("Sword", 10, 2)
	allocator:AddItem("Shield", 15, 1)
	
	local result = allocator:Allocate(25) -- e.g., { Sword = 2, Shield = 1 }
	```
]=]
function ResourceAllocator.Allocate(self: ResourceAllocator, totalBudget: number): { [string]: number }
	local result = {}
	local budget = totalBudget
	local weightedPool = getWeightedList(self.Items)

	while budget > 0 and #weightedPool > 0 do
		local pick = weightedPool[math.random(1, #weightedPool)]
		local cost = self.Items[pick].Cost

		if cost <= budget then
			result[pick] = (result[pick] or 0) + 1
			budget -= cost
		end
	end

	return result
end

--[=[
	@method Clean
	@within ResourceAllocator
	Clears all items from the allocator's item list.
	
	```lua
	local allocator = ResourceAllocator.new()
	allocator:AddItem("Sword", 10, 2)
	allocator:Clean()
	```
]=]
function ResourceAllocator.Clean(self: ResourceAllocator)
	self.Items = {}
end

return ResourceAllocator