local InlineEmotes = {}

function InlineEmotes.new(emoteByTrigger)
    local messages = {}
    local rows = {}
    local unmatchedRows = {}
    local occupiedSlots = {}
    local chatParent
    local overlayLayer
    local clipLayer
    local clipBounds

    local function positionViewport(parent, layer)
        local viewport = parent.xyGlobal
        local origin = layer.xyGlobal
        local x, y = math.floor(viewport.x - origin.x), math.floor(viewport.y - origin.y)
        local width, height = parent.width, parent.height
        if not clipLayer then
            clipLayer = ui.Layer.new(layer, 169, 1)
            if not clipLayer then error("Could not create the inline emote viewport") end
            clipLayer.clickthrough = true
        end
        if not clipBounds or clipBounds.x ~= x or clipBounds.y ~= y then
            clipLayer:SetPos(x, y)
        end
        if not clipBounds or clipBounds.width ~= width or clipBounds.height ~= height then
            clipLayer:SetSize(width, height)
        end
        if not clipBounds or clipBounds.x ~= x or clipBounds.y ~= y
            or clipBounds.width ~= width or clipBounds.height ~= height then
            clipBounds = { x = x, y = y, width = width, height = height }
        end
        return viewport
    end

    local function releaseSprites(record)
        for _, entry in ipairs(record.sprites) do
            occupiedSlots[entry.slot] = nil
            pcall(function() entry.sprite:Destroy() end)
        end
        record.sprites = {}
    end

    local function restoreText(record)
        pcall(function()
            if record.row.content == record.masked then
                record.row.content = record.original
            end
        end)
    end

    local function restore(record)
        restoreText(record)
        releaseSprites(record)
    end

    local function beforeChat()
        -- Native chat moves text between row components when inserting a line.
        for _, record in pairs(rows) do
            if #record.sprites > 0 then restoreText(record) end
        end
    end

    local function positionSprites(record, parent, viewport)
        local rowOrigin = record.row.xyGlobal
        local x = rowOrigin.x - parent.scrollX - viewport.x
        local y = rowOrigin.y - parent.scrollY - viewport.y
        local text = record.row.content
        if not parent.visibleGlobal or y >= parent.height or y + record.height <= 0
            or (text ~= record.masked and text ~= record.original) then
            if #record.sprites > 0 then restore(record) end
            return
        end
        if #record.sprites == 0 then
            for _, position in ipairs(record.positions) do
                local slot = 1
                while occupiedSlots[slot] do slot = slot + 1 end
                if slot > 255 then error("Too many inline emotes") end
                local sprite = ui.Sprite.new(clipLayer, 170, slot)
                if not sprite then error("Native chat rejected the emote sprite") end
                occupiedSlots[slot] = true
                record.sprites[#record.sprites + 1] = { sprite = sprite, slot = slot }
                sprite.sprite = position.image
                sprite.clickthrough = true
                sprite:SetSize(position.size, position.size)
            end
        end
        if text ~= record.masked then record.row.content = record.masked end
        for index, position in ipairs(record.positions) do
            local entry = record.sprites[index]
            local spriteX = math.floor(x + position.x)
            local spriteY = math.floor(y + (record.height - position.size) / 2)
            if entry.x ~= spriteX or entry.y ~= spriteY then
                entry.sprite:SetPos(spriteX, spriteY)
                entry.x, entry.y = spriteX, spriteY
            end
        end
    end

    local function remember(sender, message)
        messages[#messages + 1] = (sender .. ": " .. message):lower()
        if #messages > 120 then table.remove(messages, 1) end
        unmatchedRows = {}
    end

    local function clear()
        for key, record in pairs(rows) do
            pcall(restore, record)
            rows[key] = nil
        end
        chatParent = nil
        overlayLayer = nil
        unmatchedRows = {}
        if clipLayer then
            pcall(function() clipLayer:Destroy() end)
            clipLayer = nil
            clipBounds = nil
        end
    end

    -- Strip markup while keeping each visible character's offset in the native label.
    local function visibleText(raw)
        local characters, offsets = {}, {}
        local cursor = 1
        while cursor <= #raw do
            local tagEnd = raw:sub(cursor, cursor) == "<" and raw:find(">", cursor + 1, true)
            if tagEnd then
                cursor = tagEnd + 1
            else
                characters[#characters + 1] = raw:sub(cursor, cursor)
                offsets[#offsets + 1] = cursor
                cursor = cursor + 1
            end
        end
        return table.concat(characters), offsets
    end

    local function historicalMessageStart(plain)
        local separator = plain:find(": ", 1, true)
        if not separator then return end
        local sender = plain:sub(1, separator - 1)
        sender = sender:gsub("^%s*%[[%d:]+%]%s*", ""):gsub("^%[[^%]]+%]%s*", "")
        sender = sender:match("^%s*(.-)%s*$")
        local label = sender:lower()
        if #sender >= 1 and #sender <= 12 and sender:match("^[%w][%w _%-]*$")
            and label ~= "news" and label ~= "system" and label ~= "warning" and label ~= "error"
            and not label:match("^from ") and not label:match("^to ") then
            return separator + 2
        end
    end

    local function layout(row, raw)
        local plain, offsets = visibleText(raw)
        local lowered = plain:lower()
        local messageStart
        for index = #messages, 1, -1 do
            local message = messages[index]
            if lowered:sub(-#message) == message then
                messageStart = #plain - #message + (message:find(": ", 1, true) or 0) + 2
                break
            end
        end
        messageStart = messageStart or historicalMessageStart(plain)
        if not messageStart then return end
        local font = config.Font.FromID(row.font)
        if not font or row.width <= 0 or row.height < 10
            or font:GetStringLineCount(raw, row.width) ~= 1 then
            return
        end
        local images = Plugin.resources.emotes
        if not images then return end

        local parts, positions = {}, {}
        local cursor = 1
        local body = plain:sub(messageStart)
        local spaceWidth = font:GetStringWidth(" ")
        if spaceWidth <= 0 then return end
        for start, token in body:gmatch("()(%S+)") do
            local word = token:gsub("[!?,.]+$", "")
            local resource = emoteByTrigger[token:lower()]
            if resource then
                word = token
            else
                resource = emoteByTrigger[word:lower()]
            end
            local first = offsets[messageStart + start - 1]
            local last = offsets[messageStart + start + #word - 2]
            if resource and images[resource] and first and last and last - first + 1 == #word then
                parts[#parts + 1] = raw:sub(cursor, first - 1)
                local prefix = table.concat(parts)
                local size = math.min(16, row.height)
                positions[#positions + 1] = { x = font:GetStringWidth(prefix), image = images[resource], size = size }
                parts[#parts + 1] = string.rep(" ", math.ceil(size / spaceWidth))
                cursor = last + 1
            end
        end
        if #positions == 0 then return end
        parts[#parts + 1] = raw:sub(cursor)
        local masked = table.concat(parts)
        if font:GetStringLineCount(masked, row.width) ~= 1 then return end
        for _, position in ipairs(positions) do
            if position.x + position.size > row.width then return end
        end
        return masked, positions
    end

    local function scan()
        -- All Chat in the current RS3 desktop layout.
        local parent = ui.Interfaces:GetComponent(137, 86)
        local layer = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
        if not parent or not parent.visibleGlobal or not layer then
            clear()
            return
        end
        chatParent = parent
        overlayLayer = layer
        local seen = {}
        local stale = {}
        parent:IterateDynamicComponents(function(row)
            if row.type ~= ui.ComponentType.LABEL then return false end
            local key = row.categoryID .. ":" .. row.dynamicID
            local record = rows[key]
            local raw = row.content
            if record and ((raw ~= record.masked and raw ~= record.original) or row.width ~= record.width
                or row.height ~= record.height or row.font ~= record.font) then
                stale[key] = record
                if raw == record.masked then raw = record.original end
                rows[key] = nil
                record = nil
            end
            if not record then
                local unmatched = unmatchedRows[key]
                if not unmatched or unmatched.text ~= raw or unmatched.width ~= row.width
                    or unmatched.height ~= row.height or unmatched.font ~= row.font then
                    local masked, positions = layout(row, raw)
                    if masked then
                        unmatchedRows[key] = nil
                        record = { row = row, original = raw, masked = masked, positions = positions,
                            width = row.width, height = row.height, font = row.font, sprites = {} }
                        rows[key] = record
                    else
                        unmatchedRows[key] = { text = raw, width = row.width, height = row.height, font = row.font }
                    end
                end
            end
            if record then
                seen[key] = true
            end
            return false
        end)
        for _, record in pairs(stale) do
            pcall(restore, record)
        end
        for key, record in pairs(rows) do
            if not seen[key] then
                pcall(restore, record)
                rows[key] = nil
            end
        end
    end

    local function draw()
        if not chatParent or not overlayLayer or not next(rows) then return end
        local viewport = positionViewport(chatParent, overlayLayer)
        for _, record in pairs(rows) do
            positionSprites(record, chatParent, viewport)
        end
    end

    return { remember = remember, beforeChat = beforeChat, scan = scan, draw = draw, clear = clear }
end

return InlineEmotes
