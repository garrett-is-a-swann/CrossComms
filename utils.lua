local ADDON_NAME, NAMESPACE = ...

-- String split
NAMESPACE.split = function(string, over)
    local list = {}

    local cur_string = string
    while true do
        local next_index, end_index = cur_string:find(over)
        if next_index == nil then
            list[#list + 1] = cur_string
            break
        end
        local next_string = cur_string:sub(0, next_index-1)
        cur_string = cur_string:sub(end_index+1)
        last_index = next_index
        list[#list + 1] = next_string
    end

    return list
end

-- Debug function
local DEBUG_LEVEL = false
NAMESPACE.debug = function(...)
    if DEBUG_LEVEL then
        print(...)
    end
end


-- Wait until elapsed function
local waitTable = {}
local waitFrame = nil
NAMESPACE.wait = function(delay, func, ...)
    if(type(delay) ~= "number" or type(func) ~= "function") then
        return false
    end
    if not waitFrame then
        waitFrame = CreateFrame("Frame", nil, UIParent)
        waitFrame:SetScript("OnUpdate", function (self, elapse)
            for i = 1, #waitTable do
                local waitRecord = tremove(waitTable, i)
                local d = tremove(waitRecord, 1)
                local f = tremove(waitRecord, 1)
                local p = tremove(waitRecord, 1)
                if d > elapse then
                    tinsert(waitTable, i, {d - elapse, f, p})
                    i = i + 1
                else
                    i = i - 1
                    f(unpack(p))
                end
            end
        end)
    end
    tinsert(waitTable, {delay, func, {...}})
    return true
end
