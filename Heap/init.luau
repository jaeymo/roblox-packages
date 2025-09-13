--!strict

--[[
	Heap: A binary min-heap implementation
	Author: jaeymo
	Version: 1.0.0
	License: MIT
	Created: 09/13/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

--[=[
	@class Heap
	A binary min-heap implementation used as a priority queue.
]=]
local Heap = {}
Heap.__index = Heap

type Entry = { item: any, priority: number }
type HeapProperties = { Heap: { Entry } }
export type Heap = typeof(setmetatable({} :: HeapProperties, Heap))

--[=[
	@return Heap
	Constructs a Heap object.

	```lua
	local heap = Heap.new()
	```
]=]
function Heap.new(): Heap
	return setmetatable( { Heap = {}, }, Heap)
end

--[=[
	@method Peek
	@within Heap
	@return any?
	Returns the item with the lowest priority without removing it from the heap.

	```lua
	local item = heap:Peek()
	```
]=]
function Heap.Peek(self: Heap): any?
	return self.Heap[1] and self.Heap[1].item or nil
end

--[=[
	@method Push
	@within Heap
    @param item any
    @param priority number
	Adds an item to the heap with a given priority.

	```lua
	heap:Push("task1", 1)
	```
]=]
function Heap.Push(self: Heap, item: any, priority: number)
	local node = { item = item, priority = priority }
	table.insert(self.Heap, node)
	
	self:_siftUp(#self.Heap)
end

--[=[
	@method Pop
	@within Heap
    @return (any, number?)
	Removes and returns the item with the lowest priority from the heap.

	```lua
	local item, priority = heap:Pop()
	```
]=]
function Heap.Pop(self: Heap): (any, number?)
	if #self.Heap == 0 then return nil end
	
	local root = self.Heap[1]
	
	if #self.Heap == 1 then
		self.Heap[1] = nil
		return root.item, root.priority
	end
	
	self.Heap[1] = self.Heap[#self.Heap]
	self.Heap[#self.Heap] = nil
	
	self:_siftDown(1)
	
	return root.item, root.priority
end

--[=[
	@method IsEmpty
	@within Heap
    @return boolean
	Checks if the heap contains any items.

	```lua
	local isEmpty = heap:IsEmpty()
	```
]=]
function Heap.IsEmpty(self: Heap): boolean
	return #self.Heap == 0
end

--[=[
	@private
	Sifts an item up the heap to maintain heap property.
]=]
function Heap._siftUp(self: Heap, index: number)
	local parent = math.floor(index / 2)
	
	while index > 1 and self.Heap[parent].priority > self.Heap[index].priority do
		self.Heap[index], self.Heap[parent] = self.Heap[parent], self.Heap[index]
		index = parent
		parent = math.floor(index / 2)
	end
end

--[=[
	@private
	Sifts an item down the heap to maintain heap property.
]=]
function Heap._siftDown(self: Heap, index: number)
	local minIndex = index
	local size = #self.Heap

	while true do
		local left = 2 * index
		local right = 2 * index + 1

		if left <= size and self.Heap[left].priority < self.Heap[minIndex].priority then minIndex = left end
		if right <= size and self.Heap[right].priority < self.Heap[minIndex].priority then minIndex = right end
		if minIndex == index then break end

		self.Heap[index], self.Heap[minIndex] = self.Heap[minIndex], self.Heap[index]
		index = minIndex
	end
end

return {
	new = Heap.new
}