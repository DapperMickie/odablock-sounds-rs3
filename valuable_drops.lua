local ValuableDrops = {}
local priceUnits = { k = 1000, m = 1000000, b = 1000000000 }

local function guidePrice(body, id)
    if type(body) ~= "string" or #body > 8192
        or tonumber(body:match('"id"%s*:%s*(%d+)')) ~= id then return end
    local current = body:match('"current"%s*:%s*({[^}]*})')
    local price = current and (current:match('"price"%s*:%s*"([^"]+)"') or current:match('"price"%s*:%s*(%d+)'))
    if not price then return end
    local amount, unit = price:lower():gsub("[,%s]", ""):match("^(%d+%.?%d*)([kmb]?)$")
    if amount then return tonumber(amount) * (priceUnits[unit] or 1) end
end

function ValuableDrops.new(settings, enabled, announce, debugLog, normalize)
    local queue, cache = {}, {}
    local recent = {}
    local request, inFlight
    local tick, nextRequest = 0, 0

    local function remember(name, source)
        local previous = recent[name]
        if previous and previous.source ~= source and tick - previous.tick <= 200 then return false end
        recent[name] = { source = source, tick = tick }
        return true
    end

    local function observe(obj, quantity, isOwner)
        if not isOwner or not obj or quantity <= 0 then return end
        local id, name = obj.id, obj.name
        if settings.developerMode then
            debugLog("owned ground item", ("%d x %s (%d)"):format(quantity, name, id))
        end
        if not enabled("valuable_drop") or not obj.isStockmarket then return end
        if #queue >= 16 then return end
        queue[#queue + 1] = { id = id, name = normalize(name), quantity = quantity, tick = tick }
    end

    local function check(drop, price)
        if not price or not enabled("valuable_drop") or not Player.IsAvailable() then return end
        local total = price * drop.quantity
        if settings.developerMode then
            debugLog("ground item value", ("%s (%d) total=%.0f"):format(drop.name, drop.id, total))
        end
        if total >= (settings.valuableDropThreshold or 1000000) and remember(drop.name, "ground") then
            announce("valuable_drop")
        end
    end

    local function update(now)
        tick = now
        if inFlight and tick - inFlight.tick > 350 then
            local expired = request
            request, inFlight = nil, nil
            if expired then expired:Cancel() end
        end
        if tick % 250 == 0 then
            for name, previous in pairs(recent) do
                if tick - previous.tick > 200 then recent[name] = nil end
            end
            for id, quote in pairs(cache) do
                if quote.expires <= tick then cache[id] = nil end
            end
        end
        local drop = queue[1]
        if not drop or tick - drop.tick < 75 then return end
        if tick - drop.tick > 350 or not enabled("valuable_drop") or not Player.IsAvailable() then
            table.remove(queue, 1)
            return
        end
        local quote = cache[drop.id]
        if quote and quote.expires > tick then
            table.remove(queue, 1)
            check(drop, quote.price)
            return
        end
        if not Plugin.urls.lootPrices or not Plugin.HasPermission(PluginPermissions.httpAccess) then
            table.remove(queue, 1)
            return
        end
        if request or tick < nextRequest then return end
        table.remove(queue, 1)
        nextRequest = tick + 50
        inFlight = drop
        local ok = pcall(function()
            request = HTTPRequest.new(Plugin.urls.lootPrices, "catalogue/detail.json?item=" .. drop.id)
            request:Get(function(response)
                if inFlight ~= drop then return end
                request, inFlight = nil, nil
                local price = response.successful and guidePrice(response.data, drop.id)
                cache[drop.id] = { price = price, expires = tick + (price and 90000 or 3000) }
                if tick - drop.tick <= 350 then check(drop, price) end
            end)
        end)
        if not ok then request, inFlight = nil, nil end
    end

    local function reset()
        queue, recent = {}, {}
        local active = request
        request, inFlight = nil, nil
        if active then active:Cancel() end
    end
    return {
        observe = observe, update = update, reset = reset,
        broadcast = function(name) return remember(name, "broadcast") end,
    }
end

return ValuableDrops
