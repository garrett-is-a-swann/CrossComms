local ADDON_NAME, NAMESPACE = ...
local CHANNEL_NAME = 'Herbyfection'
local PREFIX = 'crosscomms'
local PERFECTION_PREFIX = '/Perfection/ '
local HERBY_PREFIX = '/Herby/ '

local GUILD_ROSTER = {}
local CURRENT_OWNER = nil
local CharacterStats = {}
-- CharacterStats['Eh-Blaumeow'] = 'Herby'
--
debug = NAMESPACE.debug
split = NAMESPACE.split
markMessageUsed = NAMESPACE.markMessageUsed
buildGuildRoster = NAMESPACE.buildGuildRoster
wait = NAMESPACE.wait

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

function onGuildMessage(text, author)
    -- TODO(Garrett)
    -- Capture: Message, 

    local guild_name = GetGuildInfo('player')
    local payload = table.concat({'SENT_FROM', author, guild_name, ':', text}, SEP)
    debug(payload)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
end

function onStartup()
    JoinChannelByName(CHANNEL_NAME)
    DisplayChannelOwner(CHANNEL_NAME)
end

function eventHandler(self, event, ... )
    if event == 'CHAT_MSG_GUILD' then
        debug(event)
        debug(...)
        local message, author, _, _, canonoical_author, _, _, _, _, _, line_id, guid, _, _, _, _, _ = ...

        if message:find('^'..PERFECTION_PREFIX) ~= nil or message:find('^'..HERBY_PREFIX) ~= nil then
            return
        end
        onGuildMessage(message, canonoical_author)
    elseif event == 'PLAYER_ENTERING_WORLD' then
        -- Join a chat channel
        wait(10, onStartup) 

    elseif event == 'CHAT_MSG_CHANNEL_NOTICE_USER' then
        -- Occurs when a channel notice occurs. We trigger this by displaying the ChannelOwner on init.
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

        GUILD_ROSTER = buildGuildRoster()

    elseif event == 'CHAT_MSG_ADDON' then
        local prefix, message, channel, sender, target, zone, localid, name, instanceid = ...
        --debug(prefix, prefix~=PREFIX)
        if prefix ~= PREFIX then
            return 
        end
        debug(event)
        debug(...)
        local payload = split(message, SEP)
        local signal = payload[1]
        debug(signal)

        if signal == 'SET_GUILD' then
            local signal, player_name = unpack(payload)
            debug('Registering...')
            CharacterStats[sender] = player_name
            debug('Register ', sender, '-', player_name)

        -- A child sent us a message to coodinate 
        elseif signal == 'SENT_FROM' then
            local signal, author, guild_name, message_sep, text = unpack(payload)

            -- Generate the correct prefix for the guild.
            local message_prefix = nil
            if guild_name == 'Herbs and Spices' then
                message_prefix = HERBY_PREFIX
            elseif guild_name == 'Perfection' then
                message_prefix = PERFECTION_PREFIX
            else
                -- A user
                print('CrossComms!Warning: Expected but did not find a known guild in the parcel: ', guild_name)
                return
            end
            for player, guild in pairs(CharacterStats) do
                debug('LOOPING', player, guild, guild_name)
                --Find the first gamer registered in the next guild.
                if guild ~= guild_name then
                    if markMessageUsed(author..text) then
                        C_ChatInfo.SendAddonMessage(PREFIX, 'PLEASE_SEND'..SEP..message_prefix..author..message_sep..' '..text, 'WHISPER', player)
                    end
                    return
                end
            end
        elseif signal == 'PLEASE_SEND' then
            local signal, message_payload = unpack(payload) 
            debug('Addon would send', message_payload, 'to guild')
            SendChatMessage(message_payload, 'GUILD')
        end
    elseif event == 'CHAT_MSG_CHANNEL_LEAVE' then
        local _, name, _, _, _, _, _, index, channel = ...
        if channel ~= CHANNEL_NAME then
            return
        end

        debug('Unregistering....')
        CharacterStats[name] = nil
        debug('Unregistered '..name)
        if name == CURRENT_OWNER then
            DisplayChannelOwner(CHANNEL_NAME)
        end
    elseif event == 'GUILD_ROSTER_UPDATE' then
        --GUILD_ROSTER = buildGuildRoster()
    elseif event == 'CHAT_MSG_SYSTEM' then
        local message = ...
        debug(message)

        if message:find('has come online') then
            relayHasComeOnline(message)
        end
        if message:find('has gone offline') then
            relayHasGoneOffline(message)
        end
        if message:find('has joined the guild') then
            relayHasJoinedGuild(message)
        end
        if message:find('has left the guild') then
            relayHasLeftGuild(message)
        end
    end
end

function relayHasGoneOffline(message)
    local name = message:gmatch('%a+')()
    if not GUILD_ROSTER[name:lower()] then
        return
    end

    local guild_name = GetGuildInfo('player')
    local payload = table.concat({'SENT_FROM', name, guild_name, '' ,'has gone offline.'}, SEP)
    debug(payload)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
end

function relayHasComeOnline(message)
    debug('message is', message)
    local name = message:gmatch('%[(%a+)%]')()
    debug('Has come online check',name, name:lower(), GUILD_ROSTER[name:lower()])
    if not GUILD_ROSTER[name:lower()] then
        return
    end

    local guild_name = GetGuildInfo('player')
    local payload = table.concat({'SENT_FROM', name, guild_name, '', 'has come online.'}, SEP)
    debug(payload)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
end

function relayHasJoinedGuild(message)
    local name = message:gmatch('%a+')()

    local guild_name = GetGuildInfo('player')
    local payload = table.concat({'SENT_FROM', name, guild_name, '', 'has joined the guild'}, SEP)
    debug(payload)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
    local payload = table.concat({'SENT_FROM', name, guild_name, '', 'has come online.'}, SEP)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)

    GUILD_ROSTER = buildGuildRoster();
end


function relayHasLeftGuild(message)
    local name = message:gmatch('%a+')()

    local guild_name = GetGuildInfo('player')
    local payload = table.concat({'SENT_FROM', name, guild_name, '', 'has left the guild'}, SEP)
    GUILD_ROSTER[name:lower()] = nil
    debug(payload)
    C_ChatInfo.SendAddonMessage(PREFIX, payload, 'WHISPER', CURRENT_OWNER)
end



function printHelp()
    for key, value in pairs(SLASH_COMMANDS) do
        print('|cffADFF2F/gu '..key..'|r - |cffFFFF00'..value.help_doc..'|r')
    end
end

local SLASH_COMMANDS = {
    help = { help_doc = 'Display help for CrossComms!', func = printHelp},
    leader = { help_doc = 'Display current leader.', func = function()
        print('Current leader is:', CURRENT_OWNER)
    end}
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
    CrossComms:RegisterEvent('CHAT_MSG_SYSTEM');
    CrossComms:RegisterEvent('GUILD_ROSTER_UPDATE');
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
