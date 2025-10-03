--!strict

--[[
	Jaegar: A lightweight game framework
	Author: jaeymo
	Version: 1.3.2
	License: MIT
	Created: 09/28/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

local RunService = game:GetService("RunService")

local Types = require(script.Data.Types)

local IS_SERVER = RunService:IsServer()
local IS_RUNNING = RunService:IsRunning()

local Jaegar = {}

--[=[
	@method Server
	@return JaegarServer
	Returns the JaegarServer process
	
	```lua
	local Jaegar = require(Jaegar):Server()
	```
]=]
function Jaegar:Server(): Types.JaegarServer
	if not IS_SERVER then
		error(`[{script.Name}] Cannot call :Server() on the client!`)
	end

	return require(script.Process.JaegarServer)
end

--[=[
	@method Client
	@return JaegarClient
	Returns the JaegarClient process
	
	```lua
	local Jaegar = require(Jaegar):Client()
	```
]=]
function Jaegar:Client(): Types.JaegarClient
	if IS_SERVER then
		error(`[{script.Name}] Cannot call :Client() on the Server!`)
	end

	local JaegarServer = script.Process:FindFirstChild("JaegarServer")
	if JaegarServer and IS_RUNNING then
		JaegarServer:Destroy()
	end

	return require(script.Process.JaegarClient)
end

return Jaegar