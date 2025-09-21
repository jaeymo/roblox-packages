--!strict

--[[
	Ragdoll: Handles R6 ragdoll mechanics
	Author: jaeymo
	Version: 1.6.0
	License: MIT
	Created: 09/20/2025
	
	For issues or feedback message `jaeymo` on Discord!

    ::note
    DanCodes is the original author of this module, I have just repurposed
    it to be available through Wally.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Blueprint = require(script.Blueprint)
local Errors = require(script.Errors)

local GETTING_UP = Enum.HumanoidStateType.GettingUp
local PHYSICS = Enum.HumanoidStateType.Physics
local DEAD = Enum.HumanoidStateType.Dead
local IS_CLIENT = RunService:IsClient()

local Ragdoll = {}
Ragdoll.Tags = {
    Ragdolled = "Ragdolled",
    Ragdoll = "Ragdoll"
}

export type Timer = { EndTime: number, Thread: thread }
export type Ragdoll = typeof(Ragdoll)

local timers: { [Model]: Timer } = {}
local jointCache: { [Model]: { Motor6D } } = {}

local function clearCache(rig: Model)
	jointCache[rig] = nil
end

local function cleanup(rig: Model)
	local timerData = timers[rig]

	if not timerData then
		return
	end

	local status = coroutine.status(timerData.Thread)
	
	if status ~= "dead" and status ~= "running" then
		task.cancel(timerData.Thread)
	end
	
	timers[rig] = nil
end

local function destroyJoints(rig: Model)
	for _, motor6d in jointCache[rig] do
		motor6d:Destroy()
	end

	clearCache(rig)
end

local function toggleJoints(rig: Model, enable: boolean)
	for _, motor6d in jointCache[rig] do
		motor6d.Enabled = enable
	end
end

local function verifyRig(rig: Model): (Humanoid, BasePart)
	assert(typeof(rig) == "Instance", Errors.EXPECTED_MODEL:format(typeof(rig)))
	assert(rig:IsA("Model"), Errors.EXPECTED_MODEL:format(rig.ClassName))
	
	local humanoid = assert(rig:FindFirstChildOfClass("Humanoid"), Errors.NO_HUMANOID:format(rig:GetFullName()))
	local root = assert(rig:FindFirstChild("HumanoidRootPart") :: BasePart, Errors.NO_ROOT:format(rig:GetFullName()))

	return humanoid, root
end

local function createRagdollJoint(from: Motor6D, folder: Folder)
	local socket = Instance.new("BallSocketConstraint")
	local a1 = Instance.new("Attachment")
	local a2 = Instance.new("Attachment")

	socket.Attachment0 = a1
	socket.Attachment1 = a2

	a1.CFrame = from.C0
	a2.CFrame = from.C1

	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true

	if from.Name == "Neck" then
		socket.MaxFrictionTorque = 150
		socket.UpperAngle = 45
		socket.TwistLowerAngle = -40
		socket.TwistUpperAngle = 40
	end
	
	a1.Parent = from.Part0
	a2.Parent = from.Part1
	
	socket.Parent = folder
end

--[=[
	@method Setup
	@within Ragdoll
	@param rig Model
	Sets up a model to be be available for ragdoll.
	
	```lua
	Ragdoll.Setup(someModel)
	```
]=]
function Ragdoll.Setup(rig: Model)
	local humanoid, _ = verifyRig(rig)

	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	rig:AddTag(Ragdoll.Tags.Ragdoll)

	local joints = {}
	local jointsFolder = rig:FindFirstChild("RagdollJoints")
	
	for _, motor6d in rig:GetDescendants() do
		if not motor6d:IsA("Motor6D") then
			continue
		end

		local isValid = Blueprint.socketSettings[motor6d.Name]

		if not isValid then
			continue
		end
		
		table.insert(joints, motor6d)
	end
	
	if not jointsFolder then
		local folder = Instance.new("Folder")
		folder.Name = "RagdollJoints"
		
		for _, joint in joints do
			createRagdollJoint(joint, folder)
		end
		
		folder.Parent = rig
	end
	
	jointCache[rig] = joints
	
	local connection: RBXScriptConnection
	connection = rig.AncestryChanged:Connect(function()
		if not rig:IsDescendantOf(game) then
			destroyJoints(rig)
			cleanup(rig)
		end
	end)
	
	humanoid.Died:Once(function()
		if connection.Connected then
			connection:Disconnect()
		end
		
		Ragdoll.Ragdoll(rig)
		destroyJoints(rig)
	end)
end

--[=[
	@method IsRagdolled
	@within Ragdoll
	@param rig Model
	Predicate method to check if a rig is ragdolled.
	
	```lua
    local isRagdolled = Ragdoll.IsRagdolled(someModel)
	print(isRagdolled)
	```
]=]
function Ragdoll.IsRagdolled(rig: Model)
	return rig:HasTag(Ragdoll.Tags.Ragdolled)
end

--[=[
	@method Ragdoll
	@within Ragdoll
	@param rig Model
    @param duration number?
	Ragdolls a rig with an optional duration
	
	```lua
    Ragdoll.Ragdoll(someModel, 3)
	```
]=]
function Ragdoll.Ragdoll(rig: Model, duration: number?)
	local humanoid, root = verifyRig(rig)
	
	if humanoid:GetState() == DEAD or duration == 0 then
		return
	end

	rig:AddTag(Ragdoll.Tags.Ragdolled)
	
	if IS_CLIENT or not root:GetNetworkOwner() then
		humanoid:ChangeState(PHYSICS)
	end
	
	toggleJoints(rig, false)
	
	if not duration or duration == -1 then
		cleanup(rig)
		return
	end
	
	local timerData = timers[rig]
	local endTime = time() + duration

	if timerData then
		if endTime > timerData.EndTime then
			cleanup(rig)
		else
			return
		end
	end	
	
	local data = timers[rig]
	
	timers[rig] = {
		EndTime = endTime,
		Thread = task.delay(duration, function()
			Ragdoll.Unragdoll(rig)
		end),
	}
end

--[=[
	@method Unragdoll
	@within Ragdoll
	@param rig Model
	Unragdolls a model if it is ragdolled.
	
	```lua
    Ragdoll.Unragdoll(someModel)
	```
]=]
function Ragdoll.Unragdoll(rig: Model)
	local humanoid, root = verifyRig(rig)
	
	if humanoid:GetState() == DEAD or not Ragdoll.IsRagdolled(rig) then
		return
	end

	rig:RemoveTag(Ragdoll.Tags.Ragdolled)

	if IS_CLIENT or not root:GetNetworkOwner() then
		humanoid:ChangeState(GETTING_UP)
	end

	toggleJoints(rig, true)
	cleanup(rig)
end

Players.PlayerRemoving:Connect(function(player)
	local rig = player.Character
	
	if rig then
		clearCache(rig)
		cleanup(rig)
	end
end)

function Ragdoll:Boostrap()
	if IS_CLIENT then
		local RagdollClient = require(script.Handlers.RagdollClient)
		RagdollClient:OnStart(self)
	else
		local RagdollServer = require(script.Handlers.RagdollServer)
		RagdollServer:OnStart(self)
	end
end
Ragdoll:Boostrap()

return Ragdoll