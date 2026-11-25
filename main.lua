-- Set to "level", "quest", or "collection" to preview that sound on reload.
local preview = nil
local playback = audio.SoundPlaybackParams.new()
local settings = PersistentDB:GetStructuredData("soundSettings") or {}
settings.events = settings.events or {}
settings.variants = settings.variants or {}
-- Emotes are on unless listed here, so settings saved by earlier versions keep every emote.
settings.disabledEmotes = settings.disabledEmotes or {}
settings.volume = settings.volume or 55
playback.volume = settings.volume / 100

-- Patterns match local English game messages. Entries without patterns can be
-- previewed and assigned clips while their RS3 triggers are investigated.
local events = {
    { "level", "Level-up", "levelup_voice", 1 },
    { "milestone", "Level 99 / 110 / 120", "levelup_voice", 1 },
    { "max_total", "Max total level", "levelup_voice", 1, "^you have reached the maximum total level[!%.]?$" },
    { "quest", "Quest completion", "quest", 1 },
    { "collection", "Collection log", "collection", 1 },
    { "area", "Area task", "area", 2, "^area task complete[d]?:", "^you have completed an area task:" },
    { "combat", "Combat Mastery", "combat", 4, "^combat mastery achievement complete[d]?:", "^combat achievement complete[d]?:", "^you have completed a combat mastery achievement:" },
    { "pet", "Pet unlock", "pet", 1, "^you have unlocked the .+ pet[!%.]?$", "^you have unlocked a new pet:" },
    { "death", "Your death", "death", 1, "^oh dear, you are dead[!%.]?$", "^you have died[!%.]?$" },
    { "pvp", "Player kill", "pvp", 4, "^you have defeated .+ in pvp[!%.]?$", "^you have killed .+ in the wilderness[!%.]?$" },
    { "freeze", "Frozen", "freeze", 1, "^you have been frozen[!%.]?$", "^you are frozen and cannot move[!%.]?$" },
    { "prayer", "Prayer depleted", "prayer", 1, "^you have run out of prayer points[!%.]?$",
        "^you have run out of prayer points%. you can recharge at an altar%.$" },
    { "redemption", "Redemption", "redemption", 4, "^your redemption prayer .+", "^redemption has healed you[!%.]?$",
        "^redemption activated[!%.]?$", "^redemption has activated[!%.]?$", "^you are healed by redemption[!%.]?$",
        "^redemption cannot trigger again for 1 minute%.$" },
    { "phoenix", "Phoenix necklace", "phoenix", 1, "^your phoenix necklace .-restor", "^your phoenix necklace .-shatter" },
    { "vengeance", "Vengeance", "vengeance", 1, "^your vengeance spell has .-damage", "^your vengeance rebounds .+" },
    { "ruby", "Ruby bolt proc", "ruby", 1, "^your ruby bolts .-blood forfeit" },
    { "dds", "Dragon dagger special", "dds", 3, "^you use puncture[!%.]?$" },
    { "ags", "Armadyl godsword special", "ags", 3, "^you use armadyl's judgement[!%.]?$" },
    { "accept", "Trade accepted", "accept", 1, "^accepted trade[!%.]?$", "^trade accepted[!%.]?$", "^you have completed the trade[!%.]?$" },
    { "decline", "Trade declined", "decline", 1, "^you declined the trade[!%.]?$", "^other player declined trade[!%.]?$" },
    { "report", "Report sent", "report", 3, "^your abuse report has been received[!%.]?$", "^thank you for submitting an abuse report[!%.]?$" },
    { "run", "Run enabled", "run", 1, "^run mode enabled[!%.]?$" },
    { "crypt", "Dharok's crypt", "crypt", 1, "^you enter dharok's crypt[!%.]?$" },
    { "dog", "Pet a dog", "dog", 1, "^you pet the dog[!%.]?$", "^you pet the stray dog[!%.]?$" },
    { "bone", "Give a dog a bone", "bone", 1, "^you give the stray dog a bone[!%.]?$", "^you give the dog some nice bones%." },
    { "rat", "Rat kill", "rat", 2, "^you have defeated a rat[!%.]?$", "^you have killed a rat[!%.]?$" },
    { "hair", "Hairdresser", "hair", 3, "^you have changed your hairstyle[!%.]?$" },
    { "snowball", "Hit by a snowball", "snowball", 2, "^you (.+) hit by a snowball[!%.]?$" },
    { "loot", "Your broadcasted rare drop", "loot", 1 },
    { "boss_unique", "Boss unique reward", "boss_unique", 2 },
    { "barrows_empty", "Empty Barrows chest", "barrows_empty", 1 },
    { "dharok_block", "Dharok axe block", "dharok_block", 3 },
    { "dharok_chop", "Dharok axe chop", "dharok_chop", 2 },
    { "dharok_hack", "Dharok axe hack", "dharok_hack", 1 },
    { "dharok_smash", "Dharok axe smash", "dharok_smash", 3 },
    { "disconnect", "Connection lost", "disconnect", 1 },
    { "bank_open", "Bank opened", "bank_open", 1 },
    { "welcome", "Welcome", "welcome", 1 },
    { "warriors", "Odablock Warriors", "warriors", 1 },
    { "terry", "Terry", "terry", 1 },
    { "livestream", "Livestream alert", "livestream", 1 },
    { "announcement", "Plugin announcement", "announcement", 1 },
    { "acb", "Armadyl Eye (OSRS)", "acb", 3 },
    { "big_gamon", "Big Gamon", "big_gamon", 1 },
    { "dismiss", "Dismiss random event (OSRS)", "dismiss", 1 },
    { "dismiss_snowball", "Random event snowball (OSRS)", "dismiss_snowball", 1 },
    { "fahhhhh", "Fahhhhh", "fahhhhh", 1 },
    { "ragged", "Getting ragged", "ragged", 2 },
    { "livestream_alt", "Livestream alternate clip", "livestream_alt", 1 },
    { "pk_chest", "PK chest (OSRS)", "pk_chest", 1 },
    { "regular_gamon", "Regular Gamon", "regular_gamon", 1 },
    { "toa_open", "ToA chest opening (OSRS)", "toa_open", 1 },
    { "custom_run", "Run enabled custom clip", "custom_run", 1 },
    { "white_reward", "White raid reward (OSRS)", "white_reward", 1 },
    { "zebak", "Zebak roar (OSRS)", "zebak", 1 },
    { "ziklover_off", "Ziklover is off", "ziklover_off", 1 },
    { "ziklover_on", "Ziklover is on", "ziklover_on", 1 },
}

local byCategory = {}
for _, entry in ipairs(events) do
    byCategory[entry[1]] = entry
end

local function save()
    PersistentDB:SetStructuredData("soundSettings", settings)
end

local rules = {
    { "level", "^you've just advanced .+ level" },
    { "level", "^you have just advanced .+ level" },
    { "level", "^you have reached level %d+ in " },
    { "level", "^you are now level %d+ in " },
    { "quest", "^you have completed the quest[: ]" },
    { "quest", "^congratulations! you have completed: .+ %-%s*complete this quest%." },
    { "quest", "^quest complete[d]?:" },
    { "collection", "^you have added .+ to your .-collection log" },
    { "collection", "^you[' ]ve added .+ to your .-collection log" },
    { "collection", "^.+ has been added to your .-collection log" },
    { "collection", "^new collection log slot[: ]" },
    { "collection", "^new collection log entry[: ]" },
}

local currentSound
local currentTrack
local musicPlayback
local function play(category)
    local entry = byCategory[category]
    local variant = settings.variants[category] or 0
    if variant < 1 or variant > entry[4] then
        variant = math.random(entry[4])
    end
    local resourceName = entry[3] .. (variant == 1 and "" or "_" .. variant)
    local resource = Plugin.resources[resourceName]
    if not resource then
        return "Missing audio resource " .. resourceName .. ".ogg."
    end
    local music = category == "warriors" or category == "terry"
    local previous = music and currentTrack or (not music and currentSound)
    if previous then audio.Stop(previous) end
    local parameters = playback
    if music then
        if not musicPlayback then
            musicPlayback = audio.SoundPlaybackParams.new()
            musicPlayback.audioBus = audio.AudioBus.MUSIC
        end
        musicPlayback.volume = playback.volume
        parameters = musicPlayback
    end
    local sound = audio.Play(resource, parameters)
    if not sound then
        return "Audio API could not start playback for " .. resourceName .. ".ogg."
    end
    if music then currentTrack = sound.id else currentSound = sound.id end
    return "Playback started for " .. resourceName .. ".ogg."
end

local function normalize(text)
    return text:gsub("<br%s*/?>", " "):gsub("<[^>]+>", ""):gsub("’", "'")
        :lower():gsub("%s+", " "):match("^%s*(.-)%s*$")
end

local function levelCategory(level)
    return (level == 99 or level == 110 or level == 120) and "milestone" or "level"
end

local function skillKey(name)
    name = name:lower():gsub("[%s_%-]", "")
    return ({ hitpoints = "constitution", runecraft = "runecrafting" })[name] or name
end

local function classify(text)
    local message = normalize(text)
    local achievement = message:gsub("^congratulations[!,%.:]?%s+", "")
    for _, rule in ipairs(rules) do
        local candidate = rule[1] == "level" and achievement or message
        if candidate:find(rule[2]) then
            local category = rule[1]
            if category == "level" then
                local level = tonumber(achievement:match("reached level (%d+)") or achievement:match("now level (%d+)"))
                local skill = achievement:match("advanced an? (.-) level")
                    or achievement:match("level %d+ in ([%a%s%-]+)")
                return levelCategory(level), message, level, skill
            end
            return category, message
        end
    end
    for _, entry in ipairs(events) do
        for i = 5, #entry do
            if achievement:find(entry[i]) then
                return entry[1], message
            end
        end
    end
end

local function enabled(category)
    local value = settings.events[category]
    if value ~= nil then
        return value
    end
    return category ~= "welcome" and category ~= "livestream" and category ~= "announcement"
end

local function isAutomatic(entry)
    local category = entry[1]
    return #entry > 4 or category == "level" or category == "milestone"
        or category == "quest" or category == "collection"
        or category == "welcome" or category == "disconnect" or category == "loot"
        or category == "livestream" or category == "announcement"
end

local alerts = require("alerts").new(enabled, play)

local function announce(category)
    if not enabled(category) then
        return
    end
    play(category)
    if settings.captions then
        Chat.AddMessage("[Odablock] " .. byCategory[category][2])
    end
end

local tick = 0
local emoteCatalog = require("emote_catalog")
local emoteTriggers = {}
for _, entry in ipairs(emoteCatalog) do
    for index = 2, #entry do
        emoteTriggers[entry[index]] = entry[1]
    end
end

local function emoteEnabled(name)
    return settings.disabledEmotes[name] ~= true
end

-- Overhead and inline rendering share this lookup, so a disabled emote and all
-- of its aliases are skipped in new messages and in chat history.
local emoteByTrigger = setmetatable({}, {
    __index = function(_, trigger)
        local name = emoteTriggers[trigger]
        if name and emoteEnabled(name) then
            return name
        end
    end,
})
local emoteShown
local emoteSprite
local emoteBadge
local emoteBadgeWidth
local emoteParent
local emoteSpeaker
local emoteExpires
local emotePreview = 0
local overheadChatTicks = 175 -- Three and a half seconds at 50 client logic ticks per second.
local inlineEmotes = require("inline_emotes").new(emoteByTrigger)
local inlineEmoteFailed = false
local nextInlineScan = 0
local inlineResizeUntil
local inlineChatRefreshUntil

local function refreshInlineChat()
    nextInlineScan = tick
    inlineChatRefreshUntil = tick + 3
end

Event.WindowSizeChanged.Subscribe("odablock-sounds-rs3-inline-resize", function(event)
    if not settings.inlineEmotes or (event.oldWidth == event.newWidth and event.oldHeight == event.newHeight) then
        return
    end
    if not inlineResizeUntil then
        inlineEmotes.clear()
    end
    -- Wait for the last resize event before measuring the chat rows again.
    inlineResizeUntil = tick + 12
end)

Event.Draw.Subscribe("odablock-sounds-rs3-inline-scroll", function()
    if not settings.inlineEmotes or inlineEmoteFailed or inlineResizeUntil then return end
    local ok, err = pcall(function()
        if tick >= nextInlineScan then
            nextInlineScan = tick + ((inlineChatRefreshUntil and tick <= inlineChatRefreshUntil) and 1 or 8)
            inlineEmotes.scan()
        end
        inlineEmotes.draw()
    end)
    if not ok then
        inlineEmotes.clear()
        inlineEmoteFailed = true
        print("[Odablock emotes] Inline rendering paused: " .. tostring(err))
    end
end)

local function setInlineEmotes(value)
    settings.inlineEmotes = value
    inlineEmoteFailed = false
    if not value then inlineEmotes.clear() end
    save()
end

local function localPlayer()
    if Player.IsAvailable() then
        return Player.GetEntity()
    end
end

local function findEmoteSpeaker(event)
    local sender = normalize(event.senderNameSimple or "")
    if sender == "" then return end
    local player = localPlayer()
    if player and player.isValid and normalize(player.displayName) == sender then
        return player
    end
    for _, other in ipairs(PlayerList.All()) do
        if other.isValid and normalize(other.displayName) == sender then
            return other
        end
    end
end

local function hideEmote()
    if emoteSprite then emoteSprite.hidden = true end
    if emoteBadge then emoteBadge.hidden = true end
    emoteSpeaker = nil
    emoteExpires = nil
    emoteShown = nil
end

local function showEmote(name, speaker, overheadToken)
    local images = Plugin.resources.emotes
    local image = images and images[name]
    if not image or not speaker or not speaker.isValid then return false end
    if not emoteSprite then
        local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
        if not parent then return false end
        emoteBadge = ui.Rectangle.new(parent)
        if emoteBadge then
            emoteBadge.fill = true
            emoteBadge.colour = Vector4.new(0.09, 0.08, 0.07, 1)
            emoteBadge.clickthrough = true
            emoteBadge.hidden = true
        end
        emoteSprite = ui.Sprite.new(parent)
        if not emoteSprite then return false end
        emoteParent = parent
        emoteSprite.clickthrough = true
    end
    emoteBadgeWidth = nil
    if overheadToken and emoteBadge then
        local font = config.Font.MUSEO_SANS_15PT_REGULAR
        local textWidth = font and font:GetStringWidth(overheadToken) or #overheadToken * 8
        emoteBadgeWidth = math.max(30, textWidth + 12)
        emoteBadge:SetSize(emoteBadgeWidth, 26)
    end
    if emoteBadge then emoteBadge.hidden = true end
    local size = emoteBadgeWidth and 22 or 50
    emoteSprite:SetSize(size, size)
    emoteSprite.sprite = image
    emoteSprite.hidden = true
    emoteSpeaker = speaker
    emoteExpires = tick + overheadChatTicks
    emoteShown = name
    return true
end

Event.Draw.Subscribe("odablock-sounds-rs3-emote-position", function()
    if not emoteExpires then return end
    if not emoteSpeaker.isValid then
        hideEmote()
        return
    end
    local screen = ScreenConvert.Vector3ToScreen(emoteSpeaker.position + Vector3.new(0, 1024, 0))
    local halfWidth = (emoteBadgeWidth or 50) / 2
    local top = screen and (screen.y + (emoteBadgeWidth and -1 or -55))
    local height = emoteBadgeWidth and 26 or 50
    if not screen or screen.x < halfWidth or screen.x > emoteParent.width - halfWidth
        or top < 0 or top + height > emoteParent.height then
        emoteSprite.hidden = true
        if emoteBadge then emoteBadge.hidden = true end
        return
    end
    if emoteBadgeWidth then
        emoteBadge:SetPos(math.floor(screen.x - halfWidth), math.floor(top))
        emoteBadge.hidden = false
        emoteSprite:SetPos(math.floor(screen.x - 11), math.floor(top + 2))
    else
        emoteSprite:SetPos(math.floor(screen.x - 25), math.floor(top))
    end
    emoteSprite.hidden = false
end)

local function setEmotes(value)
    settings.emotes = value
    save()
    if not value then hideEmote() end
end

local function refreshEmoteMatches()
    if emoteShown and not emoteEnabled(emoteShown) then
        hideEmote()
    end
    if settings.inlineEmotes then
        -- Restore every converted row, then measure the visible history again.
        inlineEmotes.clear()
        refreshInlineChat()
    end
end

local function setEmoteEnabled(name, value)
    settings.disabledEmotes[name] = (not value) or nil
    save()
    refreshEmoteMatches()
end

local function setAllEmotes(value)
    for _, entry in ipairs(emoteCatalog) do
        settings.disabledEmotes[entry[1]] = (not value) or nil
    end
    save()
    refreshEmoteMatches()
end

local function enabledEmoteCount()
    local count = 0
    for _, entry in ipairs(emoteCatalog) do
        if emoteEnabled(entry[1]) then count = count + 1 end
    end
    return count
end

-- Previews work for disabled emotes too, so a viewer can check one before enabling it.
local function previewEmote(index)
    if not index then
        emotePreview = emotePreview % #emoteCatalog + 1
        index = emotePreview
    end
    local entry = emoteCatalog[index]
    if showEmote(entry[1], localPlayer(), entry[2]) then
        Chat.AddMessage("[Odablock emote] " .. entry[2])
    end
end

Event.ChatMessage.Subscribe("odablock-sounds-rs3-emotes", function(event)
    local kind = event.chatType
    if settings.inlineEmotes and kind ~= ChatType.CONSOLE and kind ~= ChatType.CONSOLE_ERROR
        and kind ~= ChatType.CONSOLE_BUFFER_REPLACE then
        -- The native chat row is laid out after this event.
        inlineEmotes.beforeChat()
        refreshInlineChat()
    end
    if not settings.emotes then return end
    if kind ~= ChatType.PUBLIC and kind ~= ChatType.MOD and kind ~= ChatType.FRIEND_CHAT
        and kind ~= ChatType.CLANCHANNEL_AFFINED_CHAT and kind ~= ChatType.CLANCHANNEL_GUEST_CHAT
        and kind ~= ChatType.GROUP_SAME_TEAM and kind ~= ChatType.GROUP_ALL then
        return
    end
    local message = normalize(event.chatMessage)
    local public = kind == ChatType.PUBLIC or kind == ChatType.MOD
    if public and emoteSpeaker and emoteSpeaker.isValid
        and normalize(event.senderNameSimple or "") == normalize(emoteSpeaker.displayName) then
        hideEmote()
    end
    for word in message:gmatch("%S+") do
        local name = emoteByTrigger[word] or emoteByTrigger[word:gsub("[!?,.]+$", "")]
        if name then
            if settings.inlineEmotes and event.senderNameSimple and event.senderNameSimple ~= "" then
                inlineEmotes.remember(normalize(event.senderNameSimple), message)
            end
            showEmote(name, findEmoteSpeaker(event), public and word == message and message or nil)
            return
        end
    end
end)

local developerLines = {}
local developerRequest
local nextDeveloperFlush = 0
local developerFileStatus

local function developerLog(kind, detail)
    if not settings.developerMode then return end
    local line = ("[Odablock dev %d] %s %s"):format(tick, kind, detail:gsub("[\r\n]", " "):sub(1, 240))
    print(line)
    if #developerLines >= 160 then
        table.remove(developerLines, 1)
    end
    developerLines[#developerLines + 1] = line
end

local function flushDeveloperLog()
    if developerRequest or #developerLines == 0 or tick < nextDeveloperFlush then
        return
    end
    if not Plugin.HasPermission(PluginPermissions.httpAccess) then
        if developerFileStatus ~= "permission" then
            developerFileStatus = "permission"
            print("[Odablock dev] httpAccess is off. Events are in the console.")
        end
        nextDeveloperFlush = tick + 250
        return
    end
    nextDeveloperFlush = tick + 50
    local sent = table.concat(developerLines, "\n") .. "\n"
    developerLines = {}
    local ok, err = pcall(function()
        developerRequest = HTTPRequest.new(Plugin.urls.developerLog, "odablock-debug")
        if developerFileStatus ~= "sending" and developerFileStatus ~= "connected" then
            developerFileStatus = "sending"
            print("[Odablock dev] Sending trace to the local file writer.")
        end
        developerRequest:Post(sent, function(request)
            developerRequest = nil
            if request.successful then
                if developerFileStatus ~= "connected" then
                    developerFileStatus = "connected"
                    print("[Odablock dev] Local file writer connected.")
                end
            else
                developerFileStatus = "failed"
                nextDeveloperFlush = tick + 250
                print(("[Odablock dev] Local file writer failed (HTTP %s, error %s). Events are in the console.")
                    :format(tostring(request.responseCode), tostring(request.errorCode)))
            end
        end)
    end)
    if not ok then
        developerRequest = nil
        nextDeveloperFlush = tick + 250
        print("[Odablock dev] Local file writer error: " .. tostring(err))
    end
end

local function setDeveloperMode(value)
    settings.developerMode = value
    save()
    if value then
        developerLog("capture", "Developer mode enabled")
        if not Plugin.HasPermission(PluginPermissions.httpAccess) then
            print("[Odablock dev] File logging needs httpAccess. Events are in the console.")
        end
    else
        print("[Odablock dev] Developer mode disabled")
    end
end

Event.VarTransmit.Subscribe("odablock-sounds-rs3-developer-vars", function(event)
    if not settings.developerMode or event.oldValue == event.newValue or event.var.typeName ~= "VarPlayer" then
        return
    end
    local valueType = type(event.newValue)
    if valueType == "number" or valueType == "boolean" then
        developerLog("var", ("%s (%d): %s -> %s"):format(
            event.var.configName, event.var.id, tostring(event.oldValue), tostring(event.newValue)))
    end
end)

local prayerDepletedAt
local redemptionAt
local prayerPairWindow = 35
local lastDogSound
local function announceDog()
    if enabled("dog") and (not lastDogSound or tick - lastDogSound > 150) then
        lastDogSound = tick
        announce("dog")
    end
end

local function isNextToDog(npc)
    if not Player.IsAvailable() then
        return false
    end
    local player = Player.GetEntity()
    if not player or not player.isValid then
        return false
    end
    local playerTile = player.coordGrid
    local dogTile = npc.coordGrid
    return playerTile.level == dogTile.level
        and math.abs(playerTile.x - dogTile.x) <= 1
        and math.abs(playerTile.z - dogTile.z) <= 1
end

local recentSkill = {}
local cappedLevels = {}
local lastMessage = {}
local ratTarget
local removedRatAt
local combatXPAt
local lastRatSound
local ratNames = {
    rat = true,
    ["giant rat"] = true,
    ["zombie rat"] = true,
    ["crypt rat"] = true,
    ["giant crypt rat"] = true,
    ["dungeon rat"] = true,
}

local function announceRat()
    if not lastRatSound or tick - lastRatSound > 100 then
        lastRatSound = tick
        announce("rat")
    end
end

local function checkRatKill()
    -- XP and removal can arrive in either order.
    if removedRatAt and combatXPAt and math.abs(removedRatAt - combatXPAt) <= 150 then
        removedRatAt = nil
        combatXPAt = nil
        announceRat()
    end
end

Event.Logic.Subscribe("odablock-sounds-rs3-clock", function(event)
    tick = event.logicTick
    alerts.update(tick)
    if inlineResizeUntil and tick >= inlineResizeUntil then
        inlineResizeUntil = nil
        nextInlineScan = tick
    end
    if emoteExpires and tick >= emoteExpires then
        hideEmote()
    end
    flushDeveloperLog()
    if prayerDepletedAt and tick - prayerDepletedAt > prayerPairWindow then
        prayerDepletedAt = nil
        announce("prayer")
    end
    if ratTarget and tick - ratTarget.tick > 600 then
        ratTarget = nil
    end
    if removedRatAt and tick - removedRatAt > 150 then
        removedRatAt = nil
    end
end)

Event.MiniMenuEntrySelected.Subscribe("odablock-sounds-rs3-rat-target", function(event)
    local entry = event.entry
    if entry.actionEntryType ~= MiniMenuEntryType.NPC then
        return
    end
    local npc = entry.npcData.entity
    if normalize(entry.verbText) == "pet" and npc and npc.isValid then
        local name = normalize(npc.displayName)
        if (name:match("%f[%a]dog%f[%A]") or name:match("%f[%a]puppy%f[%A]")) and isNextToDog(npc) then
            announceDog()
        end
    end
    if entry.actionVerbType ~= MiniMenuActionVerbType.ATTACK then
        return
    end
    if ratTarget and ratTarget.npc == npc then
        ratTarget.tick = tick
        return
    end
    ratTarget = nil
    removedRatAt = nil
    combatXPAt = nil
    if enabled("rat") and npc and npc.isValid and ratNames[normalize(npc.displayName)] then
        ratTarget = { npc = npc, tick = tick }
    end
end)

Event.NPCEntityRemoved.Subscribe("odablock-sounds-rs3-rat-removed", function(event)
    if not ratTarget or ratTarget.npc ~= event.npcEntity then
        return
    end
    local recent = tick - ratTarget.tick <= 600
    ratTarget = nil
    if recent and Player.IsAvailable() then
        removedRatAt = tick
        checkRatKill()
    end
end)

local function announceSkill(skill, level, category)
    if skill and level then
        local key = skillKey(skill)
        local previous = recentSkill[key]
        if previous and previous.level == level and tick - previous.tick <= 100 then
            return
        end
        recentSkill[key] = { level = level, tick = tick }
    end
    announce(category)
end

Event.SkillTransmit.Subscribe("odablock-sounds-rs3-level", function(event)
    if not Player.IsAvailable() then
        return
    end
    local skill = event.skill
    if (ratTarget or removedRatAt) and event.oldXP >= 0 and event.newXP > event.oldXP
        and (skill == SkillType.ATTACK or skill == SkillType.STRENGTH or skill == SkillType.DEFENCE
            or skill == SkillType.HITPOINTS or skill == SkillType.RANGED
            or skill == SkillType.MAGIC or skill == SkillType.NECROMANCY) then
        combatXPAt = tick
        checkRatKill()
    end
    local level = Player.GetLevelCapped(skill)
    local previous = cappedLevels[skill]
    cappedLevels[skill] = level
    -- The first update seeds the baseline. Chat also covers the first level-up.
    if not previous or level <= previous or event.oldXP < 0 or event.newXP <= event.oldXP then
        return
    end
    announceSkill(SkillType.FromID(skill), level, levelCategory(level))
end)

Event.GameStateChanged.Subscribe("odablock-sounds-rs3-connection", function(event)
    if event.newState ~= GameState.GAME then
        inlineEmotes.clear()
        hideEmote()
        emoteSprite = nil
        emoteBadge = nil
        emoteParent = nil
        prayerDepletedAt = nil
        redemptionAt = nil
        lastDogSound = nil
        recentSkill = {}
        cappedLevels = {}
        lastMessage = {}
        ratTarget = nil
        removedRatAt = nil
        combatXPAt = nil
        lastRatSound = nil
    end
    if event.oldState == GameState.GAME
        and (event.newState == GameState.RECONNECTING or event.newState == GameState.RECONNECTING_FULL)
        and enabled("disconnect") then
        play("disconnect")
    elseif (event.oldState == GameState.LOBBY or event.oldState == GameState.LOGINSCREEN)
        and event.newState == GameState.GAME and enabled("welcome") then
        play("welcome")
    end
end)

local function classifyBroadcast(text)
    if not Player.IsAvailable() then
        return
    end
    local player = Player.GetEntity()
    if not player or not player.isValid then
        return
    end
    local name = normalize(player.displayName)
    local message = normalize(text)
    local body = message:match("^news:%s*(.+)$")
    local prefix = name .. " has received "
    if name == "" or not body or body:sub(1, #prefix) ~= prefix then
        return
    end
    local reward = body:sub(#prefix + 1)
    if reward:match("^.+, the .+ pet drop") then
        return "pet", message
    end
    if reward:match("^.+ drop[!%.]$") then
        return "loot", message
    end
end

Event.ChatMessage.Subscribe("odablock-sounds-rs3", function(event)
    local kind = event.chatType
    local category, message, level, skill
    if kind == ChatType.BROADCAST or kind == ChatType.BROADCAST_WORLD
        or kind == ChatType.BROADCAST_GLOBAL or kind == ChatType.BROADCAST_FRIENDS then
        category, message = classifyBroadcast(event.chatMessage)
    elseif kind == ChatType.GENERAL or kind == ChatType.GENERAL_LINKABLE or kind == ChatType.SPAM
        or kind == ChatType.TRADE_NOTIFICATION or kind == ChatType.ENGINE then
        category, message, level, skill = classify(event.chatMessage)
        if settings.developerMode and (not event.senderNameSimple or event.senderNameSimple == "") then
            developerLog("game message", ("type=%s match=%s %s"):format(
                tostring(kind), category or "-", event.chatMessage))
        end
    else
        return
    end
    if not category or (category ~= "redemption" and not enabled(category)) then
        return
    end
    local previous = lastMessage[category]
    if not previous or previous.text ~= message or event.timestamp - previous.timestamp > 2 then
        lastMessage[category] = { text = message, timestamp = event.timestamp }
        if category == "level" or category == "milestone" then
            announceSkill(skill, level, category)
        elseif category == "rat" then
            announceRat()
        elseif category == "dog" then
            announceDog()
        elseif category == "prayer" then
            if not redemptionAt or tick - redemptionAt > prayerPairWindow then
                prayerDepletedAt = tick
            end
        elseif category == "redemption" then
            prayerDepletedAt = nil
            redemptionAt = tick
            announce("redemption")
        else
            announce(category)
        end
    end
end)

local levelTest = { "level", "Congratulations! You've just advanced an Attack level! You are now level 2." }
local testKeys = {
    [SystemKey.F8] = levelTest,
    [SystemKey.F11] = levelTest,
    [SystemKey.F9] = { "quest", "Congratulations! You have completed: 'Learning the Ropes' - Complete this quest." },
    [SystemKey.F10] = { "collection", "New collection log entry: Goblin mail" },
}

Event.KeyDown.Subscribe("odablock-sounds-rs3-test", function(event)
    local modifiers = event.modifiers
    local alternateLevelTest = event.systemKey == SystemKey.F9 and modifiers == 3
    local sample = alternateLevelTest and levelTest or testKeys[event.systemKey]
    -- Ctrl + Alt tests the message. Add Shift to play the clip directly.
    if event.isRepeat or not sample or (modifiers ~= 6 and modifiers ~= 7 and not alternateLevelTest) then
        return
    end

    local category = sample[1]
    if modifiers == 6 then
        Chat.AddMessage("[Odablock test] " .. sample[2])
        category = classify(sample[2])
        if category ~= sample[1] then
            Chat.AddMessage("[Odablock test] Message did not match the expected trigger.")
            return
        end
    end

    Chat.AddMessage("[Odablock test] " .. category .. ": " .. play(category))
end)

-- Settings groups for the panel. Every event appears exactly once.
local soundGroups = {
    { "Progress", "Skills, quests, the collection log and achievements.",
        { "level", "milestone", "max_total", "quest", "collection", "area", "combat" } },
    { "Loot and pets", "Your own broadcasts and rewards.",
        { "loot", "pet", "boss_unique", "barrows_empty" } },
    { "Combat", "Deaths, kills, prayers and special attacks.",
        { "death", "pvp", "freeze", "prayer", "redemption", "phoenix", "vengeance", "ruby", "dds", "ags",
            "dharok_block", "dharok_chop", "dharok_hack", "dharok_smash" } },
    { "Trading and reports", "Trade results and abuse reports.",
        { "accept", "decline", "report" } },
    { "World and NPCs", "Run mode, pets, rats and other encounters.",
        { "run", "crypt", "dog", "bone", "rat", "hair", "snowball", "bank_open" } },
    { "Session", "Login and connection changes.",
        { "welcome", "disconnect" } },
    { "Extras and stream", "Songs, stream alerts and OSRS clips without an RS3 trigger.",
        { "warriors", "terry", "livestream", "livestream_alt", "announcement", "acb", "big_gamon",
            "regular_gamon", "dismiss", "dismiss_snowball", "fahhhhh", "ragged", "pk_chest", "toa_open",
            "custom_run", "white_reward", "zebak", "ziklover_off", "ziklover_on" } },
}

local eventIndex = {}
for index, entry in ipairs(events) do
    eventIndex[entry[1]] = index
end

local function stopSound()
    if currentSound then
        audio.Stop(currentSound)
        currentSound = nil
    end
end

local function cycleVariant(category)
    local entry = byCategory[category]
    settings.variants[category] = ((settings.variants[category] or 0) + 1) % (entry[4] + 1)
    save()
end

local function soundState(category)
    local entry = byCategory[category]
    if not isAutomatic(entry) then
        return "Preview only"
    end
    return enabled(category) and "Enabled" or "Disabled"
end

local function clipLabel(category)
    local count = byCategory[category][4]
    local variant = settings.variants[category] or 0
    if count == 1 then
        return "Single clip"
    end
    if variant == 0 then
        return ("Random clip of %d"):format(count)
    end
    return ("Clip %d of %d"):format(variant, count)
end

local function previewSound(category)
    Chat.AddMessage("[Odablock test] " .. play(category))
end

local function testInlineEmotes()
    local sender = "[Odablock inline test]"
    local message = "Before aiaiai kek after"
    inlineEmotes.remember(sender:lower(), message:lower())
    Chat.AddMessage(sender .. ": " .. message)
end

local panel
local selected = 1
local selectedEmote = 1
local prettyWindow
local settingsView

local WINDOW_WIDTH = 470
local WINDOW_HEIGHT = 560
local TEXT_MUTED = 0xA89E8AFF
local TEXT_PREVIEW_ONLY = 0x8C8475FF
local ROW_STRIPES = { 0x2E28204D, 0x00000000 }

local hostWidth = WINDOW_WIDTH - 16

-- Rows keep room for the page padding and a scrollbar that appears once the page fills.
local function rowWidth(page, reserved)
    local width = page.contentWidth
    if not width or width < 200 then width = hostWidth end
    return math.max(150, width - 28 - 20 - reserved)
end

local function buildSoundsPage(page)
    local comboEntries = {}
    for _, group in ipairs(soundGroups) do
        for _, category in ipairs(group[3]) do
            local entry = byCategory[category]
            local suffix = isAutomatic(entry) and "" or " (preview only)"
            comboEntries[#comboEntries + 1] = { label = group[1] .. ": " .. entry[2] .. suffix, id = eventIndex[category] }
        end
    end
    local current = soundGroups[1][3][1]
    local combo, status

    local function update()
        if status then
            status.content = soundState(current) .. "  |  " .. clipLabel(current)
        end
    end

    local function choose(category)
        current = category
        if combo then combo:Select(eventIndex[category], false) end
        update()
    end

    page:AddTitle({ text = "Preview and clips", rowBackground = false })
    combo = page:AddComboBox({
        entries = comboEntries,
        selectedID = eventIndex[current],
        maxVisibleEntries = 12,
        rowBackground = false,
        tooltip = "Choose a sound to preview or to pick its clip",
        onChange = function(_, id)
            current = events[id][1]
            update()
        end,
    })
    status = page:AddText({ text = "", colour = TEXT_MUTED, rowBackground = false })
    page:AddSimpleButton("Preview", function() previewSound(current) end,
        { rowBackground = false, tooltip = "Play the selected sound" })
    page:AddSimpleButton("Stop", stopSound, { inline = true, tooltip = "Stop the current sound" })
    page:AddSimpleButton("Change clip", function()
        cycleVariant(current)
        update()
    end, { inline = true, tooltip = "Cycle between a random clip and each clip variant" })

    local playWidth = 56
    local labelWidth = rowWidth(page, playWidth + 8)
    for _, group in ipairs(soundGroups) do
        page:AddTitle({ text = group[1], rowBackground = false })
        page:AddText({ text = group[2], colour = TEXT_MUTED, rowBackground = false })
        local boxes = {}
        local automatic = {}
        for _, category in ipairs(group[3]) do
            if isAutomatic(byCategory[category]) then
                automatic[#automatic + 1] = category
            end
        end
        local function setGroup(value)
            for _, category in ipairs(automatic) do
                settings.events[category] = value
                boxes[category]:SetSelected(category, value, false)
            end
            save()
            update()
        end
        if #automatic > 1 then
            page:AddSimpleButton("Enable all", function() setGroup(true) end,
                { rowBackground = false, tooltip = "Turn on every " .. group[1]:lower() .. " sound" })
            page:AddSimpleButton("Disable all", function() setGroup(false) end,
                { inline = true, tooltip = "Turn off every " .. group[1]:lower() .. " sound" })
        end
        for _, category in ipairs(group[3]) do
            local entry = byCategory[category]
            if isAutomatic(entry) then
                boxes[category] = page:AddCheckboxButton({
                    { text = entry[2], value = category, selected = enabled(category),
                        tooltip = "Play this sound when it triggers" },
                }, {
                    width = labelWidth,
                    onChange = function(_, _, value, checked)
                        settings.events[value] = checked
                        save()
                        if value == current then update() end
                    end,
                })
            else
                page:AddText({ text = entry[2] .. "  -  preview only", width = labelWidth, height = 24,
                    maxLines = 1, colour = TEXT_PREVIEW_ONLY,
                    tooltip = "No RS3 trigger yet. The clip can still be previewed." })
            end
            page:AddSimpleButton("Play", function()
                choose(category)
                previewSound(category)
            end, { inline = true, width = playWidth, tooltip = "Preview " .. entry[2] })
        end
    end
    update()
end

local function buildEmotesPage(page)
    local countTitle
    local boxes = {}
    local function updateCount()
        countTitle.content = ("Emotes (%d of %d on)"):format(enabledEmoteCount(), #emoteCatalog)
    end

    page:AddTitle({ text = "Display", rowBackground = false })
    page:AddCheckboxButton({
        { text = "Show emotes above speakers", value = "emotes", selected = settings.emotes == true,
            tooltip = "Public, friends, clan and group chat. Badges last about 3.5 seconds." },
        { text = "Inline emotes in All Chat (experimental)", value = "inlineEmotes",
            selected = settings.inlineEmotes == true,
            tooltip = "Draws images in short single-line chat rows, including existing history" },
    }, {
        rowBackground = false,
        onChange = function(_, _, value, checked)
            if value == "emotes" then setEmotes(checked) else setInlineEmotes(checked) end
        end,
    })
    page:AddSimpleButton("Preview next emote", function() previewEmote() end,
        { rowBackground = false, tooltip = "Show the next emote above your character" })
    page:AddSimpleButton("Test inline emotes", testInlineEmotes,
        { inline = true, tooltip = "Add a local-only test line to chat" })

    countTitle = page:AddTitle({ text = "", rowBackground = false })
    page:AddText({ text = "Triggers are listed after each emote name.", colour = TEXT_MUTED, rowBackground = false })
    page:AddSimpleButton("Enable all", function()
        setAllEmotes(true)
        for name, box in pairs(boxes) do box:SetSelected(name, true, false) end
        updateCount()
    end, { rowBackground = false })
    page:AddSimpleButton("Disable all", function()
        setAllEmotes(false)
        for name, box in pairs(boxes) do box:SetSelected(name, false, false) end
        updateCount()
    end, { inline = true })

    local images = Plugin.resources.emotes or {}
    local previewWidth = 88
    local labelWidth = rowWidth(page, 24 + 8 + previewWidth + 8)
    for index, entry in ipairs(emoteCatalog) do
        local name = entry[1]
        local triggers = {}
        for trigger = 2, #entry do
            triggers[#triggers + 1] = entry[trigger]
        end
        local label = name
        if #triggers > 1 or triggers[1] ~= name then
            label = name .. "   " .. table.concat(triggers, "  ")
        end
        local image = images[name]
        local shown = image and pcall(function()
            -- Load from our resource directory before handing the sprite to PrettyUI.
            if type(image) == "userdata" then image:Load() end
            page:AddSprite(image, { size = 24, tooltip = name })
        end)
        if not shown then
            page:AddText({ text = "", width = 24, height = 24 })
        end
        boxes[name] = page:AddCheckboxButton({
            { text = label, value = name, selected = emoteEnabled(name),
                tooltip = "Show " .. name .. " overhead and inline" },
        }, {
            inline = true,
            width = labelWidth,
            offsetY = 1,
            onChange = function(_, _, value, checked)
                setEmoteEnabled(value, checked)
                updateCount()
            end,
        })
        page:AddSimpleButton("Preview", function() previewEmote(index) end,
            { inline = true, width = previewWidth, tooltip = "Show " .. name .. " above your character" })
    end
    updateCount()
end

local function buildGeneralPage(page)
    page:AddTitle({ text = "Playback", rowBackground = false })
    local volumeLabel = page:AddText({ text = ("Volume %d%%"):format(settings.volume), rowBackground = false })
    page:AddSlider({
        min = 0, max = 100, step = 5, value = settings.volume, rowBackground = false,
        tooltip = "Volume for every Odablock sound",
        onChange = function(_, value)
            settings.volume = value
            playback.volume = value / 100
            volumeLabel.content = ("Volume %d%%"):format(value)
            save()
        end,
    })
    page:AddCheckboxButton({
        { text = "Show captions in local chat", value = "captions", selected = settings.captions == true,
            tooltip = "Adds the sound name to chat when it plays" },
    }, {
        rowBackground = false,
        onChange = function(_, _, _, checked)
            settings.captions = checked
            save()
        end,
    })
    page:AddSimpleButton("Stop sound", stopSound, { rowBackground = false })

    page:AddTitle({ text = "Music", rowBackground = false })
    page:AddSimpleButton("Terry", function() play("terry") end)
    page:AddSimpleButton("Odablock Warriors", function() play("warriors") end, { inline = true })
    page:AddSimpleButton("Stop music", function()
        if currentTrack then
            audio.Stop(currentTrack)
            currentTrack = nil
        end
    end)

    page:AddTitle({ text = "Alert feeds", rowBackground = false })
    page:AddSimpleButton("Check feeds", function() alerts.checkNow(tick) end)
    page:AddText({ text = "Enable Livestream alert and Plugin announcement in Sounds.", colour = TEXT_MUTED })

    page:AddTitle({ text = "Menu shortcut", rowBackground = false })
    if page.AddKeybindField then
        page:AddText({ text = "Click the field and press one or two keys. Default: Ctrl+Alt+F7.", colour = TEXT_MUTED })
        local keybind = page:AddKeybindField({
            value = settings.menuBinding or {},
            onChange = function(_, value)
                settings.menuBinding = #value > 0 and value or nil
                save()
            end,
        })
        page:AddSimpleButton("Reset to Ctrl+Alt+F7", function()
            settings.menuBinding = nil
            keybind:SetValue({})
            save()
        end)
    end

    page:AddTitle({ text = "Tools", rowBackground = false })
    page:AddCheckboxButton({
        { text = "Developer mode", value = "developerMode", selected = settings.developerMode == true,
            tooltip = "Logs player-variable changes and game messages to the console" },
    }, {
        rowBackground = false,
        onChange = function(_, _, _, checked) setDeveloperMode(checked) end,
    })
    page:AddText({
        text = "The Plugin Hub gear also opens settings. Ctrl+Alt+F8, F9 and F10 test the level-up, quest and "
            .. "collection log messages. Add Shift to play the clip directly.",
        colour = TEXT_MUTED, rowBackground = false,
    })
end

local function buildPrettyControls(host, height, width)
    hostWidth = width
    local tabs = host:AddTabs({
        { text = "Sounds", tooltip = "Turn each sound on or off and preview it" },
        { text = "Emotes", tooltip = "Choose which chat emotes appear" },
        { text = "Settings", tooltip = "Volume, captions and developer tools" },
    }, {
        height = height,
        activeIndex = settings.uiTab or 1,
        tabInset = 8,
        scrollStep = 48,
        contentLayout = { padding = 14, startY = 8, rowGap = 4 },
        rowBackgroundColours = ROW_STRIPES,
        onChange = function(_, index)
            settings.uiTab = index
            save()
        end,
    })
    buildSoundsPage(tabs:GetPage(1))
    buildEmotesPage(tabs:GetPage(2))
    buildGeneralPage(tabs:GetPage(3))
    for index = 1, 3 do
        tabs:GetPage(index):RefreshRowBackgrounds()
    end
    return tabs
end

local function getPrettyUI()
    return prettyui or prettyuiDev
end

-- Returns false after cleaning up when PrettyUI rejects the layout.
local function buildSafely(host, height, width)
    local ok, err = pcall(buildPrettyControls, host, height, width)
    if not ok then
        print("[Odablock] PrettyUI settings failed: " .. tostring(err))
        pcall(function() host:Destroy() end)
    end
    return ok
end

if Event.SettingsLayerReady then
    Event.SettingsLayerReady.Subscribe("odablock-sounds-rs3-prettyui", function(event)
        if settingsView then
            settingsView:Destroy()
            settingsView = nil
        end
        local library = getPrettyUI()
        if library then
            local parent = event.component
            local view = library.SimpleView.new(parent, {
                categoryID = "auto",
                width = parent.width, height = parent.height,
                scrollable = false,
                layout = { padding = 0, startY = 0 },
            })
            if buildSafely(view, parent.height, parent.width) then
                settingsView = view
            end
        end
    end)
end

local function togglePanel()
    if panel then
        panel.hidden = not panel.hidden
        return
    end
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
    if not parent then
        return
    end
    if prettyWindow then
        prettyWindow:Destroy()
        prettyWindow = nil
        return
    end
    local library = getPrettyUI()
    if library then
        local window = library.Window.new(parent, {
            title = "Odablock Sounds RS3",
            categoryID = "auto",
            x = -WINDOW_WIDTH // 2, y = -WINDOW_HEIGHT // 2, xAnchor = 0.5, yAnchor = 0.5,
            width = WINDOW_WIDTH, height = WINDOW_HEIGHT, destroyOnClose = true,
            scrollable = false,
            layout = { padding = 0, startY = 0 },
            onClose = function() prettyWindow = nil end,
        })
        -- The title bar is 32 pixels and the lower border is 8.
        if buildSafely(window, WINDOW_HEIGHT - 44, WINDOW_WIDTH - 16) then
            prettyWindow = window
            return
        end
    end
    panel = ui.GroupBox.new(parent)
    panel.stylesheetID = id.StyleSheet.DEFAULT
    panel:SetHeaderLayout(0, 0, 0, 0, 0)
    panel:SetSize(330, 256)
    panel:SetPos(0, 0, 0.28, 0.2)

    local function button(label, x, y, width, onClick)
        local control = ui.Button.new(panel)
        control.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        control:SetPos(x, y)
        control:SetSize(width, 28)
        control.label = label
        control:Subscribe(ui.Hook.ONBUTTONPRESSED, onClick)
        return control
    end

    local title, state, variant, volume, captions, developer, emotes, emote
    local function update()
        local entry = events[selected]
        local category = entry[1]
        title.label = entry[2]
        state.label = soundState(category)
        local choice = settings.variants[category] or 0
        variant.label = choice == 0 and "Random clip" or "Clip " .. choice
        volume.label = "Volume " .. settings.volume .. "%"
        captions.label = settings.captions and "Captions on" or "Captions off"
        developer.label = settings.developerMode and "Developer mode on" or "Developer mode off"
        emotes.label = settings.emotes and "Chat emotes on" or "Chat emotes off"
        local name = emoteCatalog[selectedEmote][1]
        emote.label = name .. (emoteEnabled(name) and " on" or " off")
    end

    button("<", 8, 8, 40, function()
        selected = (selected - 2) % #events + 1
        update()
    end)
    title = button("", 52, 8, 226, function()
        previewSound(events[selected][1])
    end)
    button(">", 282, 8, 40, function()
        selected = selected % #events + 1
        update()
    end)
    state = button("", 8, 44, 154, function()
        local entry = events[selected]
        if isAutomatic(entry) then
            local category = entry[1]
            settings.events[category] = not enabled(category)
            save()
            update()
        end
    end)
    variant = button("", 166, 44, 156, function()
        cycleVariant(events[selected][1])
        update()
    end)
    local function changeVolume(amount)
        settings.volume = math.max(0, math.min(100, settings.volume + amount))
        playback.volume = settings.volume / 100
        save()
        update()
    end
    button("-", 8, 80, 40, function() changeVolume(-5) end)
    volume = button("", 52, 80, 226, function() changeVolume(0) end)
    button("+", 282, 80, 40, function() changeVolume(5) end)
    captions = button("", 8, 116, 100, function()
        settings.captions = not settings.captions
        save()
        update()
    end)
    button("Stop", 115, 116, 100, stopSound)
    button("Close", 222, 116, 100, function() panel.hidden = true end)
    developer = button("", 8, 152, 154, function()
        setDeveloperMode(not settings.developerMode)
        update()
    end)
    emotes = button("", 166, 152, 156, function()
        setEmotes(not settings.emotes)
        update()
    end)
    -- The emote row selects one of the 20 emotes. Click its name to turn it on or off.
    button("<", 8, 188, 40, function()
        selectedEmote = (selectedEmote - 2) % #emoteCatalog + 1
        update()
    end)
    emote = button("", 52, 188, 226, function()
        local name = emoteCatalog[selectedEmote][1]
        setEmoteEnabled(name, not emoteEnabled(name))
        update()
    end)
    button(">", 282, 188, 40, function()
        selectedEmote = selectedEmote % #emoteCatalog + 1
        update()
    end)
    button("Preview emote", 8, 222, 154, function() previewEmote(selectedEmote) end)
    button("Preview next emote", 166, 222, 156, function() previewEmote() end)
    update()
end

Event.KeyDown.Subscribe("odablock-sounds-rs3-settings", function(event)
    if event.isRepeat then return end
    local library = getPrettyUI()
    if library and library.KeybindField and library.KeybindField.IsCapturing() then return end
    local binding = settings.menuBinding
    if not binding then
        if event.modifiers == 6 and event.systemKey == SystemKey.F7 then togglePanel() end
        return
    end
    if (event.gameKey == binding[1] or event.gameKey == binding[2]) and not Keyboard.IsBlocked() then
        for _, key in ipairs(binding) do
            if key ~= event.gameKey and not Keyboard.IsGameKeyDown(key) then return end
        end
        togglePanel()
    end
end)

function PluginShutdown()
    alerts.stop()
    inlineEmotes.clear()
    if prettyWindow then prettyWindow:Destroy() end
    if settingsView then settingsView:Destroy() end
end

if preview and byCategory[preview] then
    play(preview)
elseif enabled("welcome") then
    play("welcome")
end
