--!strict

--[[
	BetterAnimation: A module to make handling client-animations easier
	Author: jaeymo
	Version: 0.1.0
	License: MIT
	Created: 09/06/2025

	For issues or feedback message `jaeymo` on Discord!
]]

type AnimationMetadata = { fadeTime: number?, weight: number?, speed: number?,  }

type AnimationDataInList = { id: number, fadeTime: number?, weight: number?, speed: number? }
type AnimationList = { [string]: AnimationDataInList }
type Loaded = { [string]: {track: AnimationTrack, metadata: AnimationMetadata } }

local objects = {}

local PREFIX = "[BetterAnimation]"
local HASNT_REGISTERED = string.format("%s You need to register the animator before usage!", PREFIX)

local function getObject(id: string): BetterAnimation?
	return objects[id]
end

--[=[
	@class BetterAnimation
	A BetterAnimation object is helpful for quickly performing
	animation actions from various scripting locations
]=]
local BetterAnimation = {}
BetterAnimation.__index = BetterAnimation

type Properties = {
	Id: string,
	Loaded: Loaded,
	Animator: Animator?
}

export type BetterAnimation = typeof(setmetatable({} :: Properties, BetterAnimation))

--[=[
	@function new
	@within BetterAnimation
	@param id string
	@return BetterAnimation
	Creates or fetches a reusable BetterAnimation object based on the provided ID.
	
	```lua
	local anim = BetterAnimation.new("Character")
	```
]=]
function BetterAnimation.new(id: string): BetterAnimation
	local fetched = getObject(id)
	if fetched then
		return fetched
	end
	
	local self = setmetatable({} :: Properties, BetterAnimation)
	self.Id = id
	self.Loaded = {}
	self.Animator = nil -- nil for now, should be registered later
	
	objects[id] = self
	
	return self :: BetterAnimation
end

--[=[
	@method IsRegistered
	@within BetterAnimation
	@return boolean
	Checks if an Animator has been registered to this BetterAnimation instance.
	
	```lua
	local isRegistered = anim:IsRegistered()
	print(isRegistered) -- false
	
	anim:RegisterAnimator(animator)
	
	isRegistered = anim:IsRegistered()
	print(isRegistered) -- true
	```
]=]
function BetterAnimation.IsRegistered(self: BetterAnimation): boolean
	return typeof(self.Animator) == "Instance" and self.Animator:IsA("Animator")
end

--[=[
	@method GetTrack
	@within BetterAnimation
	@return AnimationTrack?
	Returns an animation track if loaded, else nil.

	```lua
	anim:GetTrack("Idle")
	```
]=]
function BetterAnimation.GetTrack(self: BetterAnimation, animName: string): (AnimationTrack?, AnimationMetadata?)
	return self.Loaded[animName].track, self.Loaded[animName].metadata
end


--[=[
	@method Add
	@within BetterAnimation
	@param animName string
	@param animInstance Animation
	@return AnimationTrack?
	Loads and stores an animation track under a name.
	
	```lua
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://1234567890"
	
	anim:Add("Run", animation)
	```
]=]
function BetterAnimation.Add(self: BetterAnimation, animName: string, animInst: Animation, metadata: AnimationMetadata): AnimationTrack?
	if not self:IsRegistered() then warn(HASNT_REGISTERED) return nil end

	if self.Loaded[animName] then
		warn(`[BetterAnimation] Animation '{animName}' already loaded (ID: {self.Id})`)
		return nil
	end

	local animator = self.Animator :: Animator
	local track = animator:LoadAnimation(animInst)

	self.Loaded[animName] = {track = track, metadata = metadata}
	
	return track
end

--[=[
	@method RegisterAnimator
	@within BetterAnimation
	@param animator Animator
	Sets the Animator used to load and play animations.
	
	```lua
	anim:RegisterAnimator(animator)
	```
]=]
function BetterAnimation.RegisterAnimator(self: BetterAnimation, animator: Animator)
	assert(animator:IsA("Animator"), `Animator is not animator, got type {animator.ClassName}`)
	self.Animator = animator
end

--[=[
	@method RegisterAnimationsFromTable
	@within BetterAnimation
	@param tbl AnimationList
	Automatically creates Animation objects from a list of IDs and loads them using `Add()`.
	
	```lua
	local animations = {
		Run = {id = 1234567890},
		Idle = {id = 0987654321}
	}
	
	anim:RegisterAnimationsFromTable(animations)
	```
]=]
function BetterAnimation.RegisterAnimationsFromTable(self: BetterAnimation, tbl: AnimationList, parent: Instance?): ()
	if not self:IsRegistered() then warn(HASNT_REGISTERED) return end
	
	local oldParent
	if parent then
		oldParent = parent.Parent
		parent.Parent = nil
	end
	
	local animator = self.Animator :: Animator
	for animName: string, animData: AnimationDataInList in tbl do
		local animation = Instance.new("Animation")
		animation.Name = animName
		animation.AnimationId = "rbxassetid://" .. animData.id
		
		local metadata: AnimationMetadata = {
			fadeTime = animData.fadeTime,
			weight = animData.weight,
			speed = animData.speed,
		}
		
		self:Add(animName, animation, metadata)
	end
	
	if oldParent and parent then
		parent.Parent = oldParent
	end
end

--[=[
	@method RegisterAnimationsFromInstance
	@within BetterAnimation
	@param instance Instance
	Finds all `Animation` descendants under the instance and loads them.
	
	```lua
	local animationsFolder = game:GetService(path.to.animations)
	anim:RegisterAnimationsFromInstance(animationsFolder)
	```
]=]
function BetterAnimation.RegisterAnimationsFromInstance(self: BetterAnimation, inst: Instance, parent: Instance?): ()
	if not self:IsRegistered() then warn(HASNT_REGISTERED) return nil end
	
	local oldParent
	if parent then
		oldParent = parent.Parent
		parent.Parent = nil
	end
	
	local animator = self.Animator :: Animator
	for _, descendant: Instance in inst:GetDescendants() do
		local metadata: AnimationMetadata = {
			fadeTime = descendant:GetAttribute("FadeTime"),
			weight = descendant:GetAttribute("Weight"),
			speed = descendant:GetAttribute("Speed"),
		}
		
		if descendant:IsA("Animation") then
			self:Add(descendant.Name, descendant, metadata)
		end
	end
	
	if oldParent and parent then
		parent.Parent = oldParent
	end
end

--[=[
	@method Play
	@within BetterAnimation
	@param animName string
	@param considerIsPlaying boolean?
	@return AnimationTrack?
	Plays the specified animation track if loaded.
	
	```lua
	local track = anim:Play("Run")
	
	 -- won't play because it's already playing and `considerIsPlaying` is true
	anim:Play("Run", true)
	```
]=]
function BetterAnimation.Play(self: BetterAnimation, animName: string, considerIsPlaying: boolean?): AnimationTrack?
	if not self:IsRegistered() then warn(HASNT_REGISTERED) return nil end
	
	local track: AnimationTrack?, metadata: AnimationMetadata? = self:GetTrack(animName)
	if track and metadata then
		if considerIsPlaying and track.IsPlaying then
			return track
		end
		
		track:Play(metadata.fadeTime, metadata.weight, metadata.speed)
		--track:AdjustSpeed(metadata.speed)
	end

	return track
end

--[=[
	@method PlayRandom
	@within BetterAnimation
	@param predicate ((name: string, data: {track: AnimationTrack, metadata: AnimationMetadata}) -> boolean)?
	@param considerIsPlaying boolean?
	@return AnimationTrack?
	Plays a random animation that passes the optional predicate filter.

	```lua
	local track = anim:PlayRandom(function(name, data)
		return name:find("attack") and not data.track.IsPlaying
	end)

	--[[
		if the loaded tracks consisted of:
		- "attack_1"
		- "attack_2"
		- "run"

		it would play either "attack_1" or "attack_2", never considering "run"
	]]
	```
]=]
function BetterAnimation.PlayRandom(self: BetterAnimation, predicate: ((string, {track: AnimationTrack, metadata: AnimationMetadata}) -> boolean)?, considerIsPlaying: boolean?): AnimationTrack?
	if not self:IsRegistered() then
		warn(HASNT_REGISTERED)
		return nil
	end

	local candidates = {}

	for name, data in self.Loaded do
		if predicate == nil or predicate(name, data) then
			table.insert(candidates, name)
		end
	end

	if #candidates == 0 then
		warn(`[BetterAnimation] No animations matched predicate for ID '{self.Id}'`)
		return nil
	end

	local randomName = candidates[math.random(1, #candidates)]
	return self:Play(randomName, considerIsPlaying)
end

--[=[
	@method Stop
	@within BetterAnimation
	@param animName string
	@return AnimationTrack?
	Stops the specified animation if it's playing.
	
	```lua
	anim:Play("Run")
	anim:Stop("Run")
	```
]=]
function BetterAnimation.Stop(self: BetterAnimation, animName: string): AnimationTrack?
	if not self:IsRegistered() then warn(HASNT_REGISTERED) return nil end
	
	local track: AnimationTrack? = self:GetTrack(animName)
	if track and track.IsPlaying then
		track:Stop()
	end

	return track
end

--[=[
	@method StopAll
	@within BetterAnimation
	@return {AnimationTrack}
	Stops all currently playing animations and returns the list.
	
	```lua
	anim:Play("Idle")
	anim:Play("LookAround")
	
	anim:StopAll()
	```
]=]
function BetterAnimation.StopAll(self: BetterAnimation): { AnimationTrack }?
	if not self:IsRegistered() then warn(HASNT_REGISTERED) return nil end
	
	local playedTracks = {}
	
	for _, animation in self.Loaded do
		local track = animation.track
		
		if track.IsPlaying then
			track:Stop()
			table.insert(playedTracks, track)
		end
	end
	
	return playedTracks
end

--[=[
	@method Cleanup
	@within BetterAnimation
	Stops all animations and clears all loaded animation tracks.
		
	```lua
	anim:Cleanup()
	```
]=]
function BetterAnimation.Cleanup(self: BetterAnimation)
	self:StopAll()
	table.clear(self.Loaded)
end

--[=[
	@method Destroy
	@within BetterAnimation
	Completely cleans up and removes the BetterAnimation object from memory.
	
	```lua
	anim:Destroy()
	```
]=]
function BetterAnimation.Destroy(self: BetterAnimation)
	self:Cleanup()
	
	objects[self.Id] = nil
	
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

return {
	new = BetterAnimation.new
}