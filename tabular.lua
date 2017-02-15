--local capi      = { client = client, screen = screen, }
local capi      = { client = client, screen = screen, }
local client    = require("awful.client")
local common    = require("awful.widget.common")
local util      = require("awful.util")
local beautiful = require("beautiful")
local naughty   = require("naughty")

local tabular = {}

local theme = beautiful.get()

local function getclients(screen)
    local fcls = {}
    for idx, v in ipairs(client.visible(screen)) do
        if (client.focus.filter(v) and not v.skip_taskbar) then
            table.insert(fcls, v)
        end
    end
    return fcls
end

local function getindex(c)
    for idx, v in ipairs(getclients(c.screen)) do
        if v == c then
            return idx
        end
    end
end


tabular.styler = function(text, n, c)
    return tostring(n)..' '..tostring(text)
end

tabular.focus = function(idx, screen)
    local cls = getclients(screen)
    if (cls[idx]) then
        capi.client.focus = cls[idx]
    end
end

tabular.taskupdate = function(w, buttons, label, data, objects)
    return common.list_update(w, buttons,
    function(c)
        local text, bg, bg_image, icon = label(c, data[c].tb)
        if (c:isvisible() and (#getclients(c.screen) > 1)) then
            text = tabular.styler(text, getindex(c), c)
        end
        --if not (c.skip_taskbar or c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop") then
            --if c.class == 'URxvt' then
                --icon = util.getdir("config").."/themes/tags/terminal.png"
            --end
        --end
        return text, bg, bg_image, icon
    end,
    data, objects)
end

tabular.manage_reorder = function()
    capi.client.connect_signal("manage", function(c)
        local fcls = getclients(c.screen)
        for k, v in ipairs(fcls) do
            if (getindex(c) ~= #fcls) then
                client.swap.byidx(1, c)
            end
        end
    end)
end

tabular.layout = {}
tabular.layout.name = "tabular"
tabular.layout.arrange = function(p)
    local area   = p.workarea
    local cls    = p.clients
    local focus  = p.focus or capi.client.focus
    local fidx

    if focus and focus.screen ~= p.screen then focus = nil end

    if (not focus or focus.floating) and #cls > 0 then
        focus = cls[1]
        fidx = 1
    end

    if not focus then return end

    local geometry =
    {
        x      = area.x,
        y      = area.y,
        width  = area.width,
        height = area.height,
    }
    p.geometries[focus] = geometry

    for k = 1, #cls do
        p.geometries[cls[k]] = geometry
    end
end

return tabular
