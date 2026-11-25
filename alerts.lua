local Alerts = {}

local function reportMessage(message)
    if Plugin.HasPermission(PluginPermissions.chatAccess) then
        Chat.AddMessage(message)
    else
        print(message)
    end
end

local escapes = { ['"'] = '"', ['\\'] = '\\', ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }

-- Both upstream feeds are flat JSON objects with string or boolean values.
local function decode(body)
    if type(body) ~= "string" or #body > 16384 then return end
    local cursor = 1
    local function consume(pattern)
        local first, last, result = body:find("^%s*" .. pattern, cursor)
        if not first then return end
        cursor = last + 1
        return result or true
    end
    local function readString()
        if not consume('"') then return end
        local parts = {}
        while cursor <= #body do
            local char = body:sub(cursor, cursor)
            cursor = cursor + 1
            if char == '"' then return table.concat(parts) end
            if char == '\\' then
                local escape = body:sub(cursor, cursor)
                cursor = cursor + 1
                if escape == "u" then
                    local hex = body:sub(cursor, cursor + 3)
                    if not hex:match("^%x%x%x%x$") then return end
                    local value = tonumber(hex, 16)
                    cursor = cursor + 4
                    if value >= 0xD800 and value <= 0xDBFF then
                        local lower = body:sub(cursor, cursor + 5):match("^\\u(%x%x%x%x)$")
                        lower = lower and tonumber(lower, 16)
                        if not lower or lower < 0xDC00 or lower > 0xDFFF then return end
                        value = 0x10000 + (value - 0xD800) * 1024 + lower - 0xDC00
                        cursor = cursor + 6
                    elseif value >= 0xDC00 and value <= 0xDFFF then
                        return
                    end
                    char = utf8.char(value)
                else
                    char = escapes[escape]
                    if not char then return end
                end
            elseif char:byte() < 32 then
                return
            end
            parts[#parts + 1] = char
        end
    end
    if not consume("{") then return end
    local result = {}
    if not consume("}") then
        repeat
            local key = readString()
            if not key or not consume(":") then return end
            local value = readString()
            if value == nil then
                if consume("true") then value = true
                elseif consume("false") then value = false
                elseif not consume("null") then return end
            end
            result[key] = value
        until not consume(",")
        if not consume("}") then return end
    end
    if body:sub(cursor):match("^%s*$") then return result end
end

local function safeText(text)
    if type(text) ~= "string" then return "" end
    return (text:gsub("[<>%c]", " "):match("^%s*(.-)%s*$")):sub(1, 500)
end

function Alerts.new(enabled, play)
    local feeds = {
        { category = "livestream", file = "livestream.json", nextTick = 0 },
        { category = "announcement", file = "custom_notifications.json", nextTick = 0 },
    }
    local active = true

    local function handle(feed, data)
        if feed.category == "livestream" then
            if type(data.live) ~= "boolean" then return end
            local identity = data.live and (safeText(data.wentLiveAt) ~= "" and safeText(data.wentLiveAt) or "live") or false
            local previous = feed.last
            feed.last = identity
            if identity and identity ~= previous then
                local title = safeText(data.title)
                reportMessage("[Odablock] Live on Kick" .. (title ~= "" and (" | " .. title) or "."))
                if previous ~= nil then play(feed.category) end
            elseif previous and not identity then
                reportMessage("[Odablock] The livestream ended.")
            end
        else
            local message = safeText(data.message)
            local identity = safeText(data.time) .. "\n" .. message
            local previous = feed.last
            feed.last = identity
            if message ~= "" and previous and previous ~= identity then
                reportMessage("[Odablock announcement] " .. message)
                play(feed.category)
            end
        end
    end

    local function update(tick)
        if not active then return end
        for _, feed in ipairs(feeds) do
            if not enabled(feed.category) then
                feed.last = nil
                feed.nextTick = 0
            end
        end
        if (not enabled("livestream") and not enabled("announcement"))
            or not Player.IsAvailable() or not Plugin.HasPermission(PluginPermissions.httpAccess) then return end
        for _, feed in ipairs(feeds) do
            if enabled(feed.category) and not feed.request and tick >= feed.nextTick then
                feed.nextTick = tick + 3000
                local ok = pcall(function()
                    local query = ("?t=%d-%d"):format(tick, math.random(1, 999999))
                    feed.request = HTTPRequest.new(Plugin.urls.alertFeed, feed.file .. query)
                    feed.request:Get(function(request)
                        feed.request = nil
                        local data
                        if active and enabled(feed.category) and Player.IsAvailable() and request.successful then
                            data = decode(request.data)
                            if data then handle(feed, data) end
                        end
                        if active and feed.report then
                            feed.report = nil
                            local label = feed.category == "livestream" and "Livestream" or "Announcements"
                            local status = data and "feed connected." or "feed unavailable."
                            if data and feed.category == "livestream" then
                                status = data.live and "live." or "offline."
                            end
                            reportMessage("[Odablock] " .. label .. " " .. status)
                        end
                    end)
                end)
                if not ok then
                    feed.request = nil
                    if feed.report then
                        feed.report = nil
                        reportMessage("[Odablock] Could not open " .. feed.file .. ".")
                    end
                end
            end
        end
    end

    local function checkNow(tick)
        if not enabled("livestream") and not enabled("announcement") then
            reportMessage("[Odablock] Enable Livestream alert or Plugin announcement under Sounds first.")
            return
        end
        if not Plugin.HasPermission(PluginPermissions.httpAccess) then
            reportMessage("[Odablock] Alert feeds need the optional HTTP permission.")
            return
        end
        for _, feed in ipairs(feeds) do
            if enabled(feed.category) then
                feed.report = true
                if not feed.request then feed.nextTick = 0 end
            end
        end
        update(tick)
    end

    return { update = update, checkNow = checkNow, stop = function()
        active = false
        for _, feed in ipairs(feeds) do
            if feed.request then feed.request:Cancel() end
        end
    end }
end

return Alerts
