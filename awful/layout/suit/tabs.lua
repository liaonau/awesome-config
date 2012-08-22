-- Grab environment we need
local ipairs = ipairs
local math = math
local tag = require("awful.tag")
local capi = { client = client, screen = screen, }
local client = require("awful.client")

--temporary
--local naughty = require("naughty")
--temporary
module("awful.layout.suit.tabs")

function arrange(p)
    -- Fullscreen?
    local area = p.workarea
    local cls = p.clients
    local focus = capi.client.focus
    local mwfact = tag.getmwfact(tag.selected(p.screen))
    local fidx

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

    local geometry = {}
    geometry.x = area.x
    geometry.y = area.y
    geometry.width = area.width
    geometry.height = area.height
    focus:geometry(geometry)
    focus:raise()

    if #cls > 1 then
        -- We don't know what the focus window index. Try to find it.
        if not fidx then
            for k, c in ipairs(cls) do
                if c == focus then
                    fidx = k
                    break
                end
            end
        end

        for k = 1, #cls do
            if (k ~= fidx) then
                cls[k]:geometry(geometry)
            end
        end
    end
end

name = "tabs"
