--local capi      = { client = client, screen = screen, }
local capi      = { client = client, screen = screen, }
local client    = require("awful.client")
local common    = require("awful.widget.common")
local util      = require("awful.util")
local beautiful = require("beautiful")
local naughty   = require("naughty")

local tabs = {}

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


tabs.styler = function(text, n, c)
    return tostring(n)..' '..tostring(text)
end

tabs.focus = function(idx, screen)
    local cls = getclients(screen)
    if (cls[idx]) then
        capi.client.focus = cls[idx]
    end
end

tabs.taskupdate = function(w, buttons, label, data, objects)
    return common.list_update(w, buttons, function(c)
        local text, bg, bg_image, icon = label(c)
        if (c:isvisible() and (#getclients(c.screen) > 1)) then
            text = tabs.styler(text, getindex(c), c)
        end
        if not (c.skip_taskbar or c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop") then
            if c.class == 'URxvt' then
                icon = util.getdir("config").."/themes/tags/terminal.png"
            end
        end
        return text, bg, bg_image, icon
    end, data, objects)
end

tabs.manage_reorder = function()
    capi.client.connect_signal("manage", function(c)
        local fcls = getclients(c.screen)
        for k, v in ipairs(fcls) do
            if (getindex(c) ~= #fcls) then
                client.swap.byidx(1, c)
            end
        end
    end)
end

tabs.layout = {}
tabs.layout.name = "tabs"
tabs.layout.arrange = function(p)
    local area   = p.workarea
    local cls    = p.clients
    local focus  = capi.client.focus
    local fidx

    --naughty.notify({timeout=15, title=tostring(p)})
    -- Check that the focused window is on the right screen
    if focus and focus.screen ~= p.screen then focus = nil end

    if not focus and #cls > 0 then
        focus = cls[1]
        fidx = 1
    end

    -- If focused window is not tiled, take the first one which is tiled.
    if client.floating.get(focus) then
        focus = cls[1]
        fidx = 1
    end

    -- Abort if no clients are present
    if not focus then return end

    local geometry =
    {
        x      = area.x,
        y      = area.y,
        width  = area.width,
        height = area.height,
    }
    for k = 1, #cls do
        cls[k]:geometry(geometry)
    end
    focus:raise()
end

return tabs
