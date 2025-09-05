--!strict

--[[
	GeneralUtility: A module for generic utility functions
	Author: jaey-dev
	Version: 0.1.1
	License: MIT
	Created: 09/02/2025
	
	For issues or feedback message `jaeymo` on Discord!
]]

local GeneralUtility = {}

function GeneralUtility.SafeCall(tbl: any, fn: string, ...: any)
	if tbl and tbl[fn] and typeof(tbl[fn]) == "function" then
		return tbl[fn](...)
    end
end

return GeneralUtility