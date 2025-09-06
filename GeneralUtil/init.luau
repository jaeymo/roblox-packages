--!strict

--[[
	GeneralUtil: A module for generic utility functions
	Author: jaey-dev
	Version: 0.2.0
	License: MIT
	Created: 09/02/2025

	For issues or feedback message `jaeymo` on Discord!
]]

--[=[
	@class GeneralUtil

	A collection of helpful utility functions. Many are completely unrelated to eachother, but all have
	their purpose.
]=]
local GeneralUtility = {}

local HttpService = game:GetService("HttpService")

local PREFIX = "GENERAL_UTILITY"

--[=[
	@within GeneralUtil
	@function SafeCall
	@param tbl any      -- the table to call a function on
	@param fn string    -- the function name to call
	@param ... any
	@return any?

	Performs a pcall on a table's method, with an optional debug parameter
]=]
function GeneralUtility.SafeCall(tbl: any, fn: string, ...: any): any?
	if tbl and tbl[fn] and typeof(tbl[fn]) == "function" then
		return tbl[fn](...)
    end
end

--[=[
	@within GeneralUtil
	@function DebugSafecall
	@param tbl any      -- the table to call a function on
	@param fn string    -- the function name to call
	@param ... any
	@return any?

	Performs a pcall on a table's method, with an optional debug parameter
]=]
function GeneralUtility.DebugSafecall(tbl: any, fn: string, dbg: boolean?, ...: any): any?
	local method = tbl[fn]
	
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

	Performs a pcall on a table's method, with an optional debug parameter
]=]
function GeneralUtility.NewGUID(prefix: string?): string
	local guid = HttpService:GenerateGUID(false)
	if prefix then
		return prefix .. "_" .. guid
	end

	return guid
end

return GeneralUtility