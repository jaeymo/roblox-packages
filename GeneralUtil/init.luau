--!strict

--[[
	GeneralUtil: A module for generic utility functions
	Author: jaeymo
	Version: 0.3.2
	License: MIT
	Created: 09/06/2025

	For issues or feedback message `jaeymo` on Discord!
]]

--[=[
	@class GeneralUtil

	A collection of helpful utility functions. Many are completely unrelated to eachother, but all have
	their purpose.
]=]
local GeneralUtil = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local PREFIX = "GENERAL_UTILITY"

--[=[
	@within GeneralUtil
	@function SafeCall
	@param Tbl any      -- the table to call a function on
	@param Fn string    -- the function name to call
	@param ... any
	@return any?

	Safely calls a function from a table
]=]
function GeneralUtil.SafeCall(Tbl: any, Fn: string, ...: any): any?
	if Tbl and Tbl[Fn] and typeof(Tbl[Fn]) == "function" then
		return Tbl[Fn](...)
    end

	return nil
end

--[=[
	@within GeneralUtil
	@function DebugSafecall
	@param Tbl any      -- the table to call a function on
	@param Fn string    -- the function name to call
	@param Debug boolean  -- for debugging prints
	@param ... any
	@return any?

	Safely calls a function with a debug parameter
]=]
function GeneralUtil.DebugSafecall(Tbl: any, Fn: string, Debug: boolean, ...: any): any?
	local method = Tbl and Tbl[Fn]
	
	if typeof(method) == "function" then
		local Ok, Result = pcall(method, Tbl, ...)

		if not Ok and Debug then
			warn(`[{PREFIX}] Error calling "{Fn}" on tbl, result: {Result}`)
		end

		return Result
	elseif Debug then
		warn(`[{PREFIX}] Missing method "{Fn}" in tbl: `, Tbl)
	end

	return nil
end

--[=[
	@within GeneralUtil
	@function NewGUID
	@param Prefix string?  -- the prefix to append to the guid
	@return string

	Returns a new guid using the HttpService
]=]
function GeneralUtil.NewGUID(Prefix: string?): string
	local GUID = HttpService:GenerateGUID(false)
	if Prefix then
		return Prefix .. "_" .. GUID
	end

	return GUID
end

--[=[
	@within GeneralUtil
	@function SafePlayerAdded
	@param Callback (player: Player) -> ()
	@return RBXScriptConnection

	Calls callback on all existing players and any players who join afterward.
]=]
function GeneralUtil.SafePlayerAdded(Callback: (player: Player) -> ())
	for _, Player in Players:GetPlayers() do
		pcall(Callback, Player)
	end

	return Players.PlayerAdded:Connect(function(Player) pcall(Callback, Player) end)
end

--[=[
	@within GeneralUtil
	@function SafeCharacterAdded
	@param Player Player
	@param Callback (Character: Model) -> ()
	@return RBXScriptConnection

	Calls callback on a player's character if it exists, then wraps it with a connection
]=]
function GeneralUtil.SafeCharacterAdded(Player: Player, Callback: (Character: Model) -> ())
	if Player.Character then
		pcall(Callback, Player.Character)
	end

	return Player.CharacterAdded:Connect(function(Character) pcall(Callback, Character) end)
end

--[=[
	@within GeneralUtil
	@function StringToEnum<T>
	@param EnumType EnumItem
	@param Name string
	@return T?

	Converts a string into an enum
]=]
function GeneralUtil.StringToEnum<T>(EnumType: EnumItem, Name: string): T?
	local Success, Value = pcall(function()
		return (EnumType :: any)[Name]
	end)

	if Success then
		return Value :: T
	end
    
	return nil
end

return GeneralUtil