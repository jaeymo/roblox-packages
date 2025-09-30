--!strict

--[[
	Collision: desc here
	Author: jaeymo
	Version: 0.1.0
	License: MIT
	Created: 09/10/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

--[=[
	@class Collision
	A Collision object is useful for providing simple, accurate hit detection.
]=]
local Collision = {}
Collision.__index = Collision

local Signal = require(script.Parent["signal"])

type Properties<T> = {
	Length: number?,
	IsActive: boolean,
	Params: OverlapParams?,
	OnHit: Signal.Signal<T>,
}

export type Collision<T> = typeof(setmetatable({} :: Properties<T>, Collision))

--[=[
	@return Collision<T>
	Constructs a Collision object.
	
	```lua
	local partCollision = Collision.new()
	```
]=]
function Collision.new<T>(): Collision<T>
	local self = setmetatable({}, Collision)
	self.IsActive = false
	self.OnHit = Signal.new()

	return self
end

--[=[
    @method UpdateParams
    @param params OverlapParams
    @within Collision
	Sets up the overlap params to be used in the hit detection
	
	```lua
	local params = OverlapParams.new()
    params.FilterDescendantInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Include

    partCollision:UpdateParams(params)
	```
]=]
function Collision.UpdateParams<T>(self: Collision<T>, params: OverlapParams)
	self.Params = params
end

--[=[
    @method SetCheckInterval
    @param length number
    @within Collision
	Sets the time to be delayed inbetween each collision check
	
	```lua
    partCollision:SetCheckInterval(0.5) -- task.wait(0.5)
    partCollision:SetCheckInterval()    -- task.wait()
	```
]=]
function Collision.SetCheckInterval<T>(self: Collision<T>, length: number?)
	self.Length = length
end

--[=[
    @method Start
    @param cf CFrame
    @param size Vector3
    @within Collision
	Starts hit detection
	
	```lua
    local connection = partCollision.OnHit:Connect(function(hit: BasePart)
        print(hit)
    end)

    local cf = part.CFrame
    local size = part.Size
    partCollision:Start(cf, size) -- starts hit detection
    partCollision:Stop()  -- cleans up all connections
	```
]=]
function Collision.Start<T>(self: Collision<T>, cf: CFrame, size: Vector3)
	if self.IsActive then return end
	self.IsActive = true
	
	task.spawn(function()
		while self.IsActive do
			task.wait(self.Length)

			local hits = workspace:GetPartBoundsInBox(cf, size, self.Params)

			for _, hit in hits do
				self.OnHit:Fire(hit)
			end
		end
	end)
end

--[=[
    @method Stop
    @within Collision
	Stops detection and disconnects all .OnHit listeners (the Signal remains usable)
	
	```lua
    partCollision:Stop()
	```
]=]
function Collision.Stop<T>(self: Collision<T>)
	if not self.IsActive then return end
	self.IsActive = false

	self.OnHit:DisconnectAll()
end

--[=[
    @method IsActive
    @within Collision
    @return boolean
	Returns whether or not the collision object is active
	
	```lua
    local isActive = partCollision:IsActive()
    local alsoIsActive = partCollision.IsActive
	```
]=]
function Collision.IsActive<T>(self: Collision<T>): boolean
	return self.IsActive
end

--[=[
    @methsod Destroy
    @within Collision
	Cleans connections, destroy metatable and calls :Stop()
	
	```lua
    partCollision:Destroy()
	```
]=]
function Collision.Destroy<T>(self: Collision<T>)
    self:Stop()
	self.OnHit:Destroy()

	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return {
	new = Collision.new
}