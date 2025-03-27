--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local XFunctions = {}

function XFunctions:SetGlobalData(key, value)
    getgenv()[key] = value
    shared[key] = value
end

return XFunctions