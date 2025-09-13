--!strict

--[[
	Grid: A module for 2D grid math
	Author: jaeymo
	Version: 2.1.0
	License: MIT
	Created: 09/13/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

--[=[
	@class Grid
	Represents a 2D grid for procedural generation and pathfinding
]=]
local Grid = {}
Grid.__index = Grid

local Trove = require(script.Parent["trove"])
local Heap = require(script.Parent["heap"])

local DIRECTIONS = { Vector2.new(1,0), Vector2.new(-1,0), Vector2.new(0,1), Vector2.new(0,-1) }
local DIRECTION_MAP = { ["Up"] = Vector2.new(1, 0), ["Down"] = Vector2.new(-1, 0), ["Right"] = Vector2.new(0, 1), ["Left"] = Vector2.new(0, -1), }
local ROTATION_MAP = { [1] = 90, [2] = 0, [3] = 270, [4] = 180, }

local WORLD_CELL_OFFSET = Vector3.new(0, -5, 0)
local WORLD_CELL_PROPERTIES = {
	Color = Color3.fromRGB(134, 166, 255),
	Material = Enum.Material.Neon,
	Transparency = 0.8,
	CanCollide = false,
	Anchored = true,
}

type CheckMethod = "IsAvailable" | "IsInBounds" | "IsOccupied" | "CanConnectToAny"

type GridProperties = {
	StateColors: { [number]: Color3 },
	Occupied: { [string]: number? }, -- vec2: state
	GridActive: boolean,
	PivotNode: Vector2,
	Trove: Trove.Trove,
	CellSize: number,
	Height: number,
	Width: number,
	Pivot: CFrame,

	_cellBase: BasePart,
	_visualizerInstance: Folder,
}

export type Grid = typeof(setmetatable({} :: GridProperties, Grid))

local function createWorldCell(cellSize: number): BasePart
	local cell = Instance.new("Part")
	cell.Size = Vector3.new(cellSize, 1, cellSize)

	for k, v in WORLD_CELL_PROPERTIES do
		if (cell :: any)[k] ~= nil then
			(cell :: any)[k] = v
		end
	end

	return cell
end

local count = 0

local function getCount(): number
	count += 1; return count
end

local function recursiveConvertDirection(tbl: any)
	if typeof(tbl) == "table" then
		for k, v in tbl do
			if typeof(v) == "string" and DIRECTION_MAP[v] then
				tbl[k] = DIRECTION_MAP[v]
				tbl["DirectionString"] = v
			elseif typeof(v) == "table" then
				recursiveConvertDirection(v)
			end
		end
	end
end

local function recursiveReverseXY(tbl: any)
	if typeof(tbl) == "table" then
		for k, v in tbl do
			if typeof(v) == "Vector2" then
				tbl[k] = Vector2.new(v.Y, v.X)
			elseif typeof(v) == "table" then
				recursiveReverseXY(v)
			end
		end
	end
end

--[=[
	@param width number
	@param height number
	@param cellSize number
	@param pivot CFrame?
	@return Grid
	Constructs a Grid object
	
	```lua
	local grid = Grid.new()
	```
]=]
function Grid.new(width: number, height: number, cellSize: number, pivot: CFrame?): Grid
	local count = getCount()

	local self = setmetatable({} :: GridProperties, Grid)
	self.PivotNode = Vector2.new(0, 0)
	self.Pivot = pivot or CFrame.new()
	self.CellSize = cellSize
	self.Trove = Trove.new()
	self.GridActive = false
	self.Height = height
	self.Width = width
	self.Occupied = {}

	self._cellBase = createWorldCell(cellSize)
	self._visualizerInstance = Instance.new("Folder")
	self._visualizerInstance.Name = `GRID_{count}`

	self.Trove:Add(self._cellBase)
	self.Trove:Add(self._visualizerInstance)

	return self
end

--[=[
	@method GetRandom
	@rng Random?
	@return Vector2
	Returns a random node on the grid
	
	```lua
	local rng = Random.new() -- for seeds
	local randomNode = grid:GetRandom(rng)
	```
]=]
function Grid.GetRandom(self: Grid, rng: Random?)
	rng = rng or Random.new()

	local x = (rng :: Random):NextInteger(0, self.Width - 1)
	local y = (rng :: Random):NextInteger(0, self.Height - 1)

	return Vector2.new(x, y)
end

--[=[
	@method GetPosition
	@param vertical string
	@param horizontal string
	@return Vector2
	Returns a node on the grid by string
	
	```lua
	local bottomLeft = grid:GetPosition("Bottom", "Left")
	local topRight = grid:GetPosition("Top", "Right")
	local bottomMiddle = grid:GetPosition("Bottom", "Middle")
	```
]=]
function Grid.GetPosition(self: Grid, vertical: string, horizontal: string): Vector2
	local x, y

	if horizontal == "Left" then
		x = 0
	elseif horizontal == "Middle" then
		x = math.floor(self.Width / 2)
	elseif horizontal == "Right" then
		x = self.Width - 1
	else
		error(`Unknown horizontal: {horizontal}`)
	end

	if vertical == "Bottom" then
		y = 0
	elseif vertical == "Middle" then
		y = math.floor(self.Height / 2)
	elseif vertical == "Top" then
		y = self.Height - 1
	else
		error(`Unknown vertical: {vertical}`)
	end

	return Vector2.new(y, x)
end

--[=[
	@method GetKey
	@param node Vector2
	@return string
	Returns a string for the Vector2
	
	```lua
	local vec = Vector2.new(0, 1)
	local str = grid:GetKey(vec)
	print(str) -- "0,1"
	```
]=]
function Grid.GetKey(self: Grid, node: Vector2): string
	return `{node.X},{node.Y}`
end

--[=[
	@method GetVec
	@param key string
	@return Vector2
	Returns a Vector2 for a key
	
	```lua
	local str = "0,1"
	local vec = grid:GetVec(str) -- Vector2.new(0, 1)
	```
]=]
function Grid.GetVec(self: Grid, key: string): Vector2
	local xStr, yStr = string.match(key, "([^,]+),([^,]+)")
	return Vector2.new(tonumber(xStr), tonumber(yStr))
end

--[=[
	@method GetDirectionFromString
	@param direction string
	@return Vector2
	Gets a vector direction from a string

	```lua
	local up = grid:GetDirectionFromString("Up") -- Vector2.new(1, 0)
	```
]=]
function Grid.GetDirectionFromString(self: Grid, direction: string): Vector2
	return DIRECTION_MAP[direction]
end

--[=[
	@method IsInBounds
	@param node Vector2
	@return boolean
	Returns if a node is in bounds
	
	```lua
	-- assuming grid borders are 3x3
	local insideVec2 = Vector2.new(0, 0)
	print(grid:IsInBounds(insideVec2)) -- true

	local outsideVec2 = Vector2.new(3, 3)
	print(grid:IsInBounds(outsideVec2)) -- false, the grid goes from 0 to 2 because of a 3x3 grid
	```
]=]
function Grid.IsInBounds(self: Grid, node: Vector2): boolean
	return node.X >= 0 
		and node.X < self.Width 
		and node.Y >= 0 
		and node.Y < self.Height
end

--[=[
	@method IsOccupied
	@param node Vector2
	@return boolean
	Returns if a node is occupied
	
	```lua
	local node = Vector2.new(0, 1)
	
	grid:SetOccupied(node, 1) -- sets the nodes state to 1 (can be any number to represent the states you're using)
	print(grid:IsOccupied(node)) -- true

	grid:SetOccupied(node, 0) -- state of 0 is unoccupied
	print(grid:IsOccupied(node)) -- false
	```
]=]
function Grid.IsOccupied(self: Grid, node: Vector2): boolean
	return self.Occupied[self:GetKey(node)] ~= nil and self.Occupied[self:GetKey(node)] ~= 0
end

--[=[
	@method IsAvailable
	@param node Vector2
	@return boolean
	Returns if a node is available (checks in bounds and occupation)
	
	```lua
	local node = Vector2.new(0, 1)
	print(grid:IsAvailable(node)) -- true

	grid:SetOccupied(node, 2)

	print(grid:IsAvailable(node)) -- false
	```
]=]
function Grid.IsAvailable(self: Grid, node: Vector2): boolean
	return self:IsInBounds(node) and not self:IsOccupied(node)
end

--[=[
	@method CanConnectToAny
	@param start Vector2
	@param nodes { Vector2 }
	@return boolean
	Returns a path from a start node if it can connect to any node
	in the list of nodes.
	
	```lua
	local start = Vector2.new(0, 0)
	local nodes = {
		Vector.new(0, 5),
		Vector.new(5, 0),
	}
	
	local didConnect, path = grid:CanConnectToAny(start, nodes) -- true, the path from [0, 0] to the connected node
	```
]=]
function Grid.CanConnectToAny(self: Grid, start: Vector2, nodes: { Vector2 }): boolean
	if not nodes or #nodes == 0 then
		return false
	end

	for _, node in nodes do
		local path = self:AStar(start, node)
		if path then
			return true, path
		end
	end

	return false
end

--[=[
	@method SetOccupied
	@param node Vector2
	@param state number
	Updates the occupancy of a node, and colors it if the grid is visualized and state colors
	have been provided
	
	```lua
	local colors = {
		[0] = Color3.FromRGB(0, 0, 0)
		[1] = Color3.FromRGB(1, 1, 1)
	}

	grid:SetStateColors(colors)

	local node = Vector2.new(0, 1)
	grid:SetOccupied(node, 1) -- it will be colored Color3.FromRGB(1, 1, 1) now
	```
]=]
function Grid.SetOccupied(self: Grid, node: Vector2, state: number)
	local key = self:GetKey(node)
	self.Occupied[key] = state ~= 0 and state or nil

	if self.GridActive and self.StateColors then
		local part = self._visualizerInstance:FindFirstChild(`GRID_CELL_{node.X}_{node.Y}`) :: BasePart
		if not part then
			warn(`[{script.Name}] Missing part for 2d position: {node.X}_{node.Y}`)
			return
		end

		local color = self.StateColors[state]
		part.Color = color
	end
end

--[=[
	@method SetStateColors
	@param stateColors { [number]: Color3 }
	Provides the state colors to be used when nodes become occupied and
	the grid is drawn in world space.
	
	```lua
	local colors = {
		[0] = Color3.FromRGB(0, 0, 0)
		[1] = Color3.FromRGB(1, 1, 1)
	}

	grid:SetStateColors(colors)

	local node = Vector2.new(0, 1)
	grid:SetOccupied(node, 1) -- it will be colored Color3.FromRGB(1, 1, 1) now
	```
]=]
function Grid.SetStateColors(self: Grid, stateColors: { [number]: Color3 } )
	self.StateColors = stateColors
end

--[=[
	@method SetPivot
	@param pivot CFrame
	Sets the grid's pivot to a CFrame
	
	```lua
	local pivot = CFrame.new()
	grid:SetPivot(pivot)
	```
]=]
function Grid.SetPivot(self: Grid, pivot: CFrame)
	self.Pivot = pivot
end

--[=[
	@method SetPivotToNode
	@param node Vector2
	@param pivotCFrame CFrame
	Sets the pivot based on a specific node and target world CFrame.

	```lua
	local node = grid:GetPosition("Bottom", "Middle")
	local gridPivot = grid.Pivot.CFrame

	-- this will make it so the grid transforms to be pivoted on a node
	grid:SetPivotToNode(node, gridPivot)
	```
]=]
function Grid.SetPivotToNode(self: Grid, node: Vector2, pivotCFrame: CFrame)
	self.PivotNode = node

	local localX = (node.Y - self.PivotNode.Y) * self.CellSize
	local localZ = -(node.X - self.PivotNode.X) * self.CellSize
	local localOffset = Vector3.new(localX, 0, localZ)

	self.Pivot = pivotCFrame * CFrame.new(-localOffset)
end

--[=[
	@method TransformRotationally
	@param targetNode Vector2
	@param mainNode Vector2
	@param rot number
	@return Vector2
	Rotates a node around a pivot

	```lua
	local targetNode = Vector2.new(3, 0)
	local mainNode = Vector2.new(0, 0)
	local rotation = 1 -- 90 degrees to the right

	local transformed = grid:TransformRotationally(targetNode, mainNode, rotation)
	print(transformed) -- 0, 3
	```
]=]
function Grid.TransformRotationally(self: Grid, targetNode: Vector2, mainNode: Vector2, rot: number): Vector2
	local x, y, px, py = targetNode.X, targetNode.Y, mainNode.X, mainNode.Y
	local k = rot

	k = ((k % 4) + 4) % 4
	local dx = x - px
	local dy = y - py

	if k == 0 then
		return Vector2.new(x, y)
	elseif k == 1 then
		return Vector2.new(px - dy, py + dx)
	elseif k == 2 then
		return Vector2.new(px - dx, py - dy)
	else
		return Vector2.new(px + dy, py - dx)
	end
end

--[=[
	@method TransformLocally
	@param targetNode Vector2
	@param localNode Vector2
	@param mainNode Vector2
	@return Vector2
	Translates a node from one local coordinate frame to another

	```lua
	local targetNode = Vector2.new(3, 0)
	local localNode = Vector2.new(1, 1)
	local mainNode = Vector2.new(0, 0)

	local transformed = grid:TransformLocally(targetNode, localNode, mainNode)
	print(transformed) -- Vector2.new(2, -1)
	```
]=]
function Grid.TransformLocally(self: Grid, targetNode: Vector2, localNode: Vector2, mainNode: Vector2): Vector2
	return (targetNode - localNode) + mainNode
end

--[=[
	@method RotateVector2
	@param targetNode Vector2
	@param rot number
	@return Vector2?
	Rotates a node in 90 degree increments clockwise

	```lua
	local node = Vector2.new(2, 2)

	local rotated = grid:RotateVector2(node, 2)
	print(rotated) -- Vector2.new(-2, -2)
	```
]=]
function Grid.RotateVector2(self: Grid, node: Vector2, rot: number): Vector2
	rot = rot % 4
	
	if rot == 0 then
		return node
	elseif rot == 1 then -- 90 CW
		return Vector2.new(-node.Y, node.X)
	elseif rot == 2 then -- 180
		return Vector2.new(-node.X, -node.Y)
	elseif rot == 3 then -- 270 CW
		return Vector2.new(node.Y, -node.X)
	end
	
	return (nil :: any)
end

--[=[
	@method Manhattan
	@param a Vector2
	@param b Vector2
	@return number
	Computes the Manhattan distance between two grid nodes.

	```lua
	local a = Vector2.new(0, 0)
	local b = Vector2.new(2, 3)
	local distance = grid:Manhattan(a, b)
	print(distance) -- 5
	```
]=]
function Grid.Manhattan(self: Grid, a: Vector2, b: Vector2)
	return math.abs(a.X - b.X) + math.abs(a.Y - b.Y)
end

--[=[
	@method AStar
	@param start Vector2
	@param goal Vector2
	@return { Vector2 }?
	Computes a path from `start` to `goal` using the A* pathfinding algorithm.
	Returns an ordered list of grid nodes forming the path, or nil if no path exists.

	```lua
	local start = Vector2.new(0, 0)
	local goal = Vector2.new(2, 2)
	local path = grid:AStar(start, goal)

	if path then
		for _, node in path do
			print(node)
		end
	else
		print("No path found")
	end
	```
]=]
function Grid.AStar(self: Grid, start: Vector2, goal: Vector2): { Vector2 }?
	if not self:IsInBounds(start) or not self:IsInBounds(goal) then
		warn("[Grid.AStar] Start or goal node is out of bounds")
		return nil
	end

	local openSet = Heap.new()
	openSet:Push(start, 0)

	local cameFrom = {}
	local gScore = { [self:GetKey(start)] = 0 }
	local fScore = { [self:GetKey(start)] = self:Manhattan(start, goal) }
	local closedSet = {}

	local function reconstructPath(currentKey)
		local path = { self:GetVec(currentKey) }
		while cameFrom[currentKey] do
			currentKey = cameFrom[currentKey]
			table.insert(path, 1, self:GetVec(currentKey))
		end

		return path
	end

	local iterations = 0
	local maxIterations = self.Width * self.Height

	while not openSet:IsEmpty() do
		iterations += 1
		if iterations > maxIterations then
			warn("[Grid.AStar] Iteration cap hit, aborting.")
			return nil
		end

		local current, _ = openSet:Pop()
		local currentKey = self:GetKey(current)

		if current == goal then
			return reconstructPath(currentKey)
		end

		closedSet[currentKey] = true

		for _, offset in DIRECTIONS do
			local neighbor = current + offset
			local neighborKey = self:GetKey(neighbor)

			if closedSet[neighborKey] then
				continue
			end

			if (neighbor == goal or not self:IsOccupied(neighbor)) and self:IsInBounds(neighbor) then
				local tentativeG = gScore[currentKey] + 1
				if tentativeG < (gScore[neighborKey] or math.huge) then
					cameFrom[neighborKey] = currentKey
					gScore[neighborKey] = tentativeG
					fScore[neighborKey] = tentativeG + self:Manhattan(neighbor, goal)

					openSet:Push(neighbor, fScore[neighborKey])
				end
			end
		end
	end

	return nil
end

--[=[
	@method NodesInRadius
	@param center Vector2
	@param radius number
	@param clampToBounds boolean?
	@return { Vector2 }
	Returns all grid nodes within a circular radius from a center node.

	```lua
	local center = Vector2.new(1, 1)
	local radius = 2
	local nodes = grid:NodesInRadius(center, radius, true)

	for _, node in nodes do
		print(node)
	end
	```
]=]
function Grid.NodesInRadius(self: Grid, center: Vector2, radius: number, clampToBounds: boolean?): { Vector2 }
	local nodes = {}
	local rSq = radius * radius

	for x = center.X - radius, center.X + radius do
		for y = center.Y - radius, center.Y + radius do
			local candidate = Vector2.new(x, y)

			if (not clampToBounds or self:IsInBounds(candidate)) then
				local dx = candidate.X - center.X
				local dy = candidate.Y - center.Y

				if dx * dx + dy * dy <= rSq then
					table.insert(nodes, candidate)
				end
			end
		end
	end

	return nodes
end

--[=[
	@method WorldToGrid
	@param worldPos Vector3
	@return Vector2
	Converts a world position into a grid node

	```lua
	local worldPosition = Vector3.new(0, 0, 0)
	local node = grid:WorldToGrid(worldPosition)
	print(node) -- e.g. Vector2.new(0, 1)
	```
]=]
function Grid.WorldToGrid(self: Grid, worldPos: Vector3): Vector2
	local localPos = self.Pivot:PointToObjectSpace(worldPos)
	local gx = math.floor(-localPos.Z / self.CellSize + self.PivotNode.X)
	local gy = math.floor(localPos.X / self.CellSize + self.PivotNode.Y)

	return Vector2.new(gx, gy)
end

--[=[
	@method GridToWorld
	@param node Vector2
	@return Vector3
	Converts a grid node to world-space Vector3.

	```lua
	local node = Vector2.new(0, 1)
	local worldPosition = grid:GridToWorld(node)
	print(worldPosition)
	```
]=]
function Grid.GridToWorld(self: Grid, node: Vector2): Vector3
	local localX = (node.Y - self.PivotNode.Y) * self.CellSize
	local localZ = -(node.X - self.PivotNode.X) * self.CellSize
	local localPos = Vector3.new(localX, 0, localZ)

	return self.Pivot:PointToWorldSpace(localPos)
end

--[=[
	@method BatchCall
	@param fn string
	@param nodes { Vector2 }
	@param ... any
	Calls a method on the object for each node in a list, passing any extra arguments.

	```lua
	local nodes = {
		Vector2.new(0, 1),
		Vector2.new(1, 0),
	}

	grid:BatchCall("TransformLocally", nodes, Vector2.new(0, 0), Vector.new(0, 0))
	```
]=]
function Grid.BatchCall(self: Grid, fn: string, nodes: { Vector2 }, ...): { any }?
	local method = self[fn]
	assert(type(method) == "function", ("Grid has no method called '%s'"):format(fn))

	local list = {}
	local args = { ... }

	for _, node in nodes do
		local s, ret = pcall(method, self, node, table.unpack(args))

		if not s then
			warn(("[Grid.BatchCall] Error calling %s for node %s: %s"):format(fn, self:GetKey(node), tostring(ret)))
		else
			table.insert(list, ret)
		end
	end

	return list
end

--[=[
	@method BatchCheck
	@param nodes { Vector2 }
	@param fn string
	@return boolean
	Calls the specified boolean method on each node. Returns true if all nodes return true.
	
	```lua
	local nodes = { Vector2.new(0, 0), Vector2.new(1, 1) }

	if grid:BatchCheck(nodes, "IsInBounds") then
		print("all in bounds")
	end
	```
]=]
function Grid.BatchCheck(self: Grid, fn: CheckMethod, nodes: {Vector2}): boolean
	local method = self[fn]
	assert(type(method) == "function", ("Grid has no method called '%s'"):format(fn))

	for _, node in nodes do
		if not method(self, node) then
			return false
		end
	end
	
	return true
end

--[=[
	@method Build
	Draws the grid in world space

	```lua
	grid:Build()
	```
]=]
function Grid.Build(self: Grid)
	if self.GridActive then return end
	self.GridActive = true

	local pivot = Instance.new("Part")
	pivot.Name = `GRID_PIVOT`
	pivot.CFrame = self.Pivot
	pivot.Size = Vector3.one * 2
	pivot.Material = Enum.Material.SmoothPlastic
	pivot.Color = Color3.fromRGB(255, 156, 126)
	pivot.Anchored = true
	pivot.Parent = self._visualizerInstance

	for x = 0, self.Width - 1 do
		for y = 0, self.Height -1 do
			local node = Vector2.new(x, y)
			local pos = self:GridToWorld(node)
			local localPos = self.Pivot:PointToObjectSpace(pos)

			local cell = self._cellBase:Clone()
			cell.Name = `GRID_CELL_{node.X}_{node.Y}`
			cell.CFrame = self.Pivot * CFrame.new(localPos) * CFrame.new(WORLD_CELL_OFFSET)

			if self.StateColors then
				local state = self.Occupied[self:GetKey(node)] or 0
				local color = self.StateColors[state]

				if color then
					cell.Color = color
				end
			end

			cell.Parent = self._visualizerInstance
		end
	end

	self._visualizerInstance.Parent = workspace
end

--[=[
	@method Clean
	Cleans the grid from the world

	```lua
	grid:Clean()
	```
]=]
function Grid.Clean(self: Grid)
	if not self.GridActive then return end
	self.GridActive = false

	self._visualizerInstance:ClearAllChildren()
	self._visualizerInstance.Parent = nil
end

--[=[
	@method Destroy
	Cleans the grid and trove

	```lua
	grid:Destroy()
	```
]=]
function Grid.Destroy(self: Grid)
	self:Clean()
	self.Trove:Destroy()
end

return {
	RecursiveReverseXY = recursiveReverseXY,
	RecursiveConvertDirection = recursiveConvertDirection,
	
	Directions = DIRECTIONS,
	RotationMap = ROTATION_MAP,
	DirectionMap = DIRECTION_MAP,
	WorldCellOffset = WORLD_CELL_OFFSET,
	
	new = Grid.new
}