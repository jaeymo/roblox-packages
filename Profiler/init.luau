--!strict

--[[
	Profiler: Manages and transitions between profiles (state-like objects)
	Author: jaeymo
	Version: 1.1.0
	License: MIT
	Created: 09/29/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

local GeneralUtil = require(script.Parent.GeneralUtil)
local Loader = require(script.Parent.Loader)

--[=[
	@class Profiler
	A Profiler is useful for managing and activating profile objects.
	Profiles are arbitrary tables that may represent states, contexts, or
	any structured set of behaviors.
]=]
local Profiler = {}
Profiler.__index = Profiler

export type Profiler<T> = typeof(setmetatable({} :: {
    Profiles: { [string]: T },
    To: string?,
    From: string?,
    Active: T?,
}, Profiler))

--[=[
	@return Profiler<T>
	Constructs a new Profiler from a container of ModuleScripts.

	```lua
	local profiler = Profiler.new(someFolder, "Prepare")
	```
]=]
function Profiler.new<T>(Container: Instance, InitCall: string): Profiler<T>
    local self = setmetatable({}, Profiler)
    self.Profiles = Loader.LoadChildren(Container)

    if InitCall then
        Loader.SpawnAll(self.Profiles, InitCall)
    end

    return self
end

--[=[
	@method IsValid
	@within Profiler
	@param Name string
	@return boolean
	Returns true if the profile exists and is not nil.

	```lua
	if profiler:IsValid("Lobby") then
	    profiler:SetActive("Lobby")
	end
	```
]=]
function Profiler.IsValid<T>(self: Profiler<T>, Name: string): boolean
    return self.Profiles[Name] ~= nil
end

--[=[
	@method GetProfile
	@within Profiler
	@param Name string
	@return T?
	Returns a profile by name, if it exists.

	```lua
	local lobbyProfile = profiler:GetProfile("Lobby")
	```
]=]
function Profiler.GetProfile<T>(self: Profiler<T>, Name: string): T?
    local Profile = self.Profiles[Name]
    if not Profile then
        warn(`[{script.Name}] No profile found with name: {Name}`)
    end

    return Profile
end

--[=[
	@method GetActive
	@within Profiler
	@return T?
	Returns the currently active profile, if one is set.

	```lua
	local active = profiler:GetActive()
	```
]=]
function Profiler.GetActive<T>(self: Profiler<T>): T?
    return self.Active
end

--[=[
	@method Call
	@within Profiler
	@param Name string
	@param Fn string
	@param ... any
	@return any
	Calls a named function on the specified profile.

	```lua
	profiler:Call("Lobby", "OnEnter")
	```
]=]
function Profiler.Call<T>(self: Profiler<T>, Name: string, Fn: string, ...: any): any
    local Profile = self:GetProfile(Name)
    if not Profile then
        return
    end

    return GeneralUtil.SafeCall(Profile, Fn, Profile, ...)
end

--[=[
	@method CallActive
	@within Profiler
	@param Fn string
	@param ... any
	@return any
	Calls a named function on the currently active profile.

	```lua
	profiler:CallActive("OnExit")
	```
]=]
function Profiler.CallActive<T>(self: Profiler<T>, Fn: string, ...: any): any
    if not self.Active then
        return
    end

    return GeneralUtil.SafeCall(self.Active, Fn, self.Active, ...)
end

--[=[
	@method SetToAndFrom
	@within Profiler
	@param To string
	@param From string
	Sets the function names that will be called on transitions.
	- `From` is called on the old active profile before exit.
	- `To` is called on the new active profile after activation.

	```lua
	profiler:SetToAndFrom("OnEnter", "OnExit")
	```
]=]
function Profiler.SetToAndFrom<T>(self: Profiler<T>, To: string, From: string)
    self.To = To
    self.From = From
end

--[=[
	@method SetActive
	@within Profiler
	@param Name string
	@param ... any
	Sets the active profile by name. Calls the configured
	`From` and `To` method.

	```lua
	profiler:SetActive("Intermission")
	```
]=]
function Profiler.SetActive<T>(self: Profiler<T>, Name: string, ...: any)
    local NextProfile = self:GetProfile(Name)
    if not NextProfile then return end

    if self.Active == NextProfile then
        return
    end

	if self.From then self:CallActive(self.From, ...) end

	self.Active = NextProfile

	if self.To then self:CallActive(self.To, ...) end
end

return {
    new = Profiler.new
}