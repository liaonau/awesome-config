local beautiful  = require("beautiful")
local wibox      = require("wibox")
local awful      = require("awful")
local type       = type
local screen     = screen
local math       = math

local infobox = { mt = {} }

local function new(updater, state, icon, title, text)
    local ib = {}
    ib.state = state or {}

    ib.mwh                 = beautiful.main_wibox_height or 0
    local default_geometry = {width = 800, height = 600, x = 0, y = ib.mwh}
    local default_bg       = "#000000"
    ib.box = wibox({bg = beautiful.infobox_bg or default_bg})

    ib.layout              = wibox.layout.align.vertical()
    ib.layout_title        = wibox.layout.align.horizontal()
    ib.box.visible         = false
    ib.box.ontop           = true
    default_geometry.y     = ib.mwh
    ib.box:geometry(default_geometry)
    ib.box.widget          = ib.layout
    ib.title               = wibox.widget.textbox()
    ib.title.markup        = title or ''
    ib.text                = wibox.widget.textbox()
    ib.text.markup         = text or ''
    ib.icon                = wibox.widget.imagebox()
    ib.icon.image          = icon
    ib.title.align         = "center"
    ib.title.valign        = "top"
    ib.text.align          = "left"
    ib.text.valign         = "top"
    ib.icon.resize         = false
    ib.layout.top          = ib.layout_title
    ib.layout_title.left   = ib.icon
    ib.layout_title.middle = ib.title
    ib.layout.middle       = ib.text
    ib.update = function()
        updater(ib)
    end
    ib.clear = function()
        ib.text.text  = ''
        ib.title.text = ''
        ib.icon.image = nil
    end

    function ib.fit()
        local sg     = screen[1].geometry
        local sw, sh = sg.width, sg.height - ib.mwh

        -- {dpi = 96} - грязный хак, чтобы не разбираться с lgi cairo.Context
        local dpi = 96
        local w1, h1 = ib.text:fit( {dpi = dpi}, sw, -1)
        local w2, h2 = ib.title:fit({dpi = dpi}, sw, -1)
        local w3, h3 = ib.icon:fit( {dpi = dpi}, sw, -1)
        local bw, bh = (beautiful.border_width or 0) + 4, (beautiful.border_width or 0) + 4
        local w, h = math.min(sw, math.max(w1, w2 + w3) + bw), math.min(sh, math.max(h2, h3) + h1 + bh)
        ib.box:geometry({width = w, height = h, x = sw - w})
    end
    -- без этого первое появление не работает как надо в 4.0
    ib.update()

    ib.show = function()
        if (type(ib.on_show) == "function") then
            ib.on_show(ib.state)
        end
        ib.update()
        ib.box.visible = true
        ib.fit()
    end
    ib.hide = function()
        if (type(ib.on_hide) == "function") then
            ib.on_hide(ib.state)
        end
        ib.box.visible = false
    end
    ib.toggle = function()
        if (not ib.box.visible) then
            ib.show()
        else
            ib.hide()
        end
    end
    return ib
end


function infobox.mt:__call(...)
    return new(...)
end

return setmetatable(infobox, infobox.mt)
