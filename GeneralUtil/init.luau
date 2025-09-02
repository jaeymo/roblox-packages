--!strict
local GeneralUtility = {}

function GeneralUtility.SafeCall(tbl: any, fn: string, ...: any)
	if tbl and tbl[fn] and typeof(tbl[fn]) == "function" then
		return tbl[fn](...)
    end
end

return GeneralUtility