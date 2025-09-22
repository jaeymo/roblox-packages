--!strict
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local IS_RUNNING = RunService:IsRunning()

local Jaegar = {}

function Jaegar:Server()
	if not IS_SERVER then
		error(`[{script.Name}] Cannot call :Server() on the client!`)
	end

	return require(script.Process.JaegarServer)
end

function Jaegar:Client()
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