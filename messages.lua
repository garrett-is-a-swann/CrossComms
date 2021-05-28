local ADDON_NAME, NAMESPACE = ...
local MessageContainer = {}
local MessageTable = {}
local MessageTableIndex = 0
local MESSAGE_TABLE_LENGTH = 10

NAMESPACE.markMessageUsed = function(lineid) 
    if not MessageContainer[lineid] then
        MessageContainer[lineid] = true
        debug('lineid ', lineid)
        if MessageTable[MessageTableIndex] then
            MessageContainer[MessageTable[MessageTableIndex]] = nil
        end

        MessageTable[MessageTableIndex] = lineid

        MessageTableIndex = MessageTableIndex + 1

        debug('Message Table Index:', MessageTableIndex)

        if MessageTableIndex == MESSAGE_TABLE_LENGTH then
            MessageTableIndex = 0
        end
        return true
    else
        return false
    end
end
