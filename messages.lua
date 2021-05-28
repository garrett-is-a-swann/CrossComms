local ADDON_NAME, NAMESPACE = ...
local MessageContainer = {}
local MessageTable = {}
local MessageTableIndex = 0
local MESSAGE_TABLE_LENGTH = 10

NAMESPACE.markMessageUsed = function(hash) 
    -- If Message Container does not contain this hash
    if not MessageContainer[hash] then

        -- We now contain this hash
        debug('hash ', hash)
        MessageContainer[hash] = true

        -- If Message Table index is used
        if MessageTable[MessageTableIndex] then
            -- Evict previously held Message in the Container to free resources
            MessageContainer[MessageTable[MessageTableIndex]] = nil
        end

        -- Store Hash in Message Table for future eviction, and increment TableIndex
        MessageTable[MessageTableIndex] = hash

        MessageTableIndex = MessageTableIndex + 1
        if MessageTableIndex == MESSAGE_TABLE_LENGTH then
            MessageTableIndex = 0
        end

        debug('Message Table Index:', MessageTableIndex)
        return true
    else
        return false
    end
end
