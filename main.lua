local ADDON_NAME, NAMESPACE = ...
local CHANNEL_NAME = 'Herbyfection'
local PREFIX = 'crosscomms'
local PERFECTION_PREFIX = '/Perfection/ '
local HERBY_PREFIX = '/Herby/ '

local CURRENT_OWNER = nil
local CharacterStats = {}
-- CharacterStats['Eh'] = 'Herby'
--
debug = NAMESPACE.debug
split = NAMESPACE.split
markMessageUsed = NAMESPACE.markMessageUsed

local SEP = 'I11I'
function relayGuildToOwner()
    local guild_name = GetGuildInfo('player')
    local payload = 'SET_GUILD'..SEP..guild_name
    debug('Current Owner:', CURRENT_OWNER)
    debug('Sending info to owner('..CURRENT_OWNER..': '..payload)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
end

function onChannelJoin(...)
    -- If we are the leader, query the new user's Guild/Version
end

function respondChannelJoinQuery(...)
    -- TODO(Garrett): If version out of date, leave channel and alert user
    relayGuildToOwner()
end

function onGuildMessage(...)
    -- TODO(Garrett)
    -- Capture: Message, 
end

function eventHandler(self, event, ... )
    if event == 'CHAT_MSG_GUILD' then
        debug(event)
        debug(...)
        local message, author, _, _, canonoical_author, _, _, _, _, _, line_id, guid, _, _, _, _, _ = ...

        if message:find('^'..PERFECTION_PREFIX) ~= nil or message:find('^'..HERBY_PREFIX) ~= nil then
            return
        end

        local guild_name = GetGuildInfo('player')
        local payload = 'SENT_FROM'..SEP..'nil'..SEP..canonoical_author..SEP..guild_name..SEP..message
        debug(payload)
        C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
    elseif event == 'PLAYER_ENTERING_WORLD' then
        -- Join a chat channel
        JoinChannelByName(CHANNEL_NAME)

        DisplayChannelOwner(CHANNEL_NAME)

    elseif event == 'CHAT_MSG_CHANNEL_NOTICE_USER' then
        local e_type, owner, _, _, _, _, _, index, channel = ...

        debug(e_type, owner, index, channel)
        if (e_type ~= 'CHANNEL_OWNER' and e_type ~= 'OWNER_CHANGED') or channel ~= CHANNEL_NAME then
            return
        end

        local last_owner = CURRENT_OWNER
        CURRENT_OWNER = owner
        if last_owner ~= CURRENT_OWNER and CURRENT_OWNER ~= UnitName('player') then
            relayGuildToOwner()
        end
        if CURRENT_OWNER == UnitName('player') then
            debug('Registering self...')
            CharacterStats[UnitName('player')] = GetGuildInfo('player')
            debug('Registering', UnitName('player'), '-', GetGuildInfo('player'))
        end

    elseif event == 'CHAT_MSG_ADDON' then
        local prefix, message, channel, sender, target, zone, localid, name, instanceid = ...
        --debug(prefix, prefix~=PREFIX)
        if prefix ~= PREFIX then
            return 
        end
        debug(event)
        debug(...)
        local payload = split(message, SEP)
        debug(payload[1])

        if payload[1] == 'SET_GUILD' then
            debug('Registering...')
            CharacterStats[sender] = payload[2]
            debug('Register ', sender, '-',payload[2])

        -- A child sent us a message to coodinate 
        elseif payload[1] == 'SENT_FROM' then

            -- Generate the correct prefix for the guild.
            local message_prefix = nil
            if payload[4] == 'Herbs and Spices' then
                message_prefix = HERBY_PREFIX
            elseif payload[4] == 'Perfection' then
                message_prefix = PERFECTION_PREFIX
            else
                -- A user
                print('CrossComms!Warning: Expected but did not find a known guild in the parcel: ', payload[4])
                return
            end
            for player, guild in pairs(CharacterStats) do
                debug('LOOPING', player, guild, payload[4])
                --Find the first gamer registered in the next guild.
                if guild ~= payload[4] then
                    if markMessageUsed(payload[3]..payload[5]) then
                        C_ChatInfo.SendAddonMessage(PREFIX, 'PLEASE_SEND'..SEP..message_prefix..payload[3]..': '..payload[5], 'WHISPER', player)
                    end
                    return
                end
            end
        elseif payload[1] == 'PLEASE_SEND' then
            debug('Addon would send', payload[2], 'to guild')
            SendChatMessage(payload[2], 'GUILD')
        end
    elseif event == 'CHAT_MSG_CHANNEL_LEAVE' and channel == CHANNEL_NAME then
        local _, name, _, _, index, channel = ...

        debug('Unregistering....')
        CharacterStats[name] = nil
        debug('Unregistered '..name)
    end
end

function printHelp()
    for key, value in pairs(SLASH_COMMANDS) do
        print('|cffADFF2F/gu '..key..'|r - |cffFFFF00'..value.help_doc..'|r')
    end
end

local SLASH_COMMANDS = {
    help = { help_doc = 'Display help for CrossComms!', func = printHelp},
    
}


-- Init
(function()
    debug('Loading Cross Comms')
    local register_channel = C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

    if not register_channel then
        debug('Failed to load Cross Comms!')
        return
    end

    local CrossComms = CreateFrame('Frame', nil, UIParent);

    -- Register Guild Chat Listener
    CrossComms:RegisterEvent('CHAT_MSG_GUILD');
    CrossComms:RegisterEvent('CHAT_MSG_CHANNEL');
    CrossComms:RegisterEvent('PLAYER_ENTERING_WORLD');
    CrossComms:RegisterEvent('CHAT_MSG_ADDON');
    CrossComms:RegisterEvent('CHAT_MSG_CHANNEL_NOTICE');
    CrossComms:RegisterEvent('CHAT_MSG_CHANNEL_NOTICE_USER');
    CrossComms:RegisterEvent('CHAT_MSG_CHANNEL_LEAVE');
    --CrossComms:RegisterEvent('CHAT_MSG_CHANNEL_JOIN');
    CrossComms:SetScript('OnEvent', eventHandler);

    -- Init slash commands
    SLASH_CROSS_COMMS1, SLASH_CROSS_COMMS2, SLASH_CROSS_COMMS3 = '/xc', '/cross', '/urosscomms' -- INIT global variables with name SLASH_XXXN, where XXX matches a UID bind.
    local function SlashMux(line, editbox)
        local command = string.match(line, '%w*')
        if SLASH_COMMANDS[command] then
            SLASH_COMMANDS[command].func()
        else
            SLASH_COMMANDS['help'].func()
        end
    end
    SlashCmdList["CROSS_COMMS"] = SlashMux -- Bind function handler
end)()
