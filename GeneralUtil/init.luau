--!strict

--[[
	GeneralUtil: A module for generic utility functions
	Author: jaeymo
	Version: 0.3.1
	License: MIT
	Created: 09/06/2025

	For issues or feedback message `jaeymo` on Discord!
]]

--[=[
	@class GeneralUtil

	A collection of helpful utility functions. Many are completely unrelated to eachother, but all have
	their purpose.
]=]
local GeneralUtility = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PREFIX = "GENERAL_UTILITY"

--[=[
	@within GeneralUtil
	@function SafeCall
	@param tbl any      -- the table to call a function on
	@param fn string    -- the function name to call
	@param ... any
	@return any?

	Safely calls a function from a table
]=]
function GeneralUtility.SafeCall(tbl: any, fn: string, ...: any): any?
	if tbl and tbl[fn] and typeof(tbl[fn]) == "function" then
		return tbl[fn](...)
    end

	return nil
end

--[=[
	@within GeneralUtil
	@function DebugSafecall
	@param tbl any      -- the table to call a function on
	@param fn string    -- the function name to call
	@param dbg boolean  -- for debugging prints
	@param ... any
	@return any?

	Safely calls a function with a debug parameter
]=]
function GeneralUtility.DebugSafecall(tbl: any, fn: string, dbg: boolean, ...: any): any?
	local method = tbl and tbl[fn]
	
	if typeof(method) == "function" then
		local ok, result = pcall(method, tbl, ...)

		if not ok and dbg then
			warn(`[{PREFIX}] Error calling "{fn}" on tbl, result: {result}`)
		end

		return result
	elseif dbg then
		warn(`[{PREFIX}] Missing method "{fn}" in tbl: `, tbl)
	end

	return nil
end

--[=[
	@within GeneralUtil
	@function NewGUID
	@param prefix string?  -- the prefix to append to the guid
	@return string

	Returns a new guid using the HttpService
]=]
function GeneralUtility.NewGUID(prefix: string?): string
	local guid = HttpService:GenerateGUID(false)
	if prefix then
		return prefix .. "_" .. guid
	end

	return guid
end

--[=[
	@within GeneralUtil
	@function SafePlayerAdded
	@param callback (player: Player) -> ()
	@return RBXScriptConnection

	Calls callback on all existing players and any players who join afterward.
]=]
function GeneralUtility.SafePlayerAdded(callback: (player: Player) -> ())
	for _, player in Players:GetPlayers() do
		pcall(callback, player)
	end

	return Players.PlayerAdded:Connect(function(player) pcall(callback, player) end)
end

--[=[
	@within GeneralUtil
	@function SafeCharacterAdded
	@param player Player
	@param callback (character: Model) -> ()
	@return RBXScriptConnection

	Calls callback on a player's character if it exists, then wraps it with a connection
]=]
function GeneralUtility.SafeCharacterAdded(player: Player, callback: (character: Model) -> ())
	if player.Character then
		pcall(callback, player.Character)
	end

	return player.CharacterAdded:Connect(function(character) pcall(callback, character) end)
end

return GeneralUtility