local ADDON_NAME, NAMESPACE = ...

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

local DEBUG_LEVEL = true
NAMESPACE.debug = function(...)
    if DEBUG_LEVEL then
        print(...)
    end
end
