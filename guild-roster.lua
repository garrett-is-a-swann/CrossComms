local ADDON_NAME, NAMESPACE = ...
local GUILD_ROSTER = {}
NAMESPACE.buildGuildRoster = function()
    GUILD_ROSTER = {}
    for index=0, GetNumGuildMembers() do
        local name,
        rank,
        rank_index,
        level,
        class,
        zone,
        note,
        officer_note = GetGuildRosterInfo(index);

        if name ~= nil then
            local cannonical_name = name:gmatch('[^-]+')()
            GUILD_ROSTER[cannonical_name:lower()] = {
                name = name,
                index = index,
                rank = rank_index,
                level = level,
                class = class,
                note = note,
                officer_note = officer_note
            }
        end
    end

    return GUILD_ROSTER
end
