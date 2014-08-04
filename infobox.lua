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

    ib.mwh = beautiful.main_wibox_height or 0
    local default_geometry = {width = 800, height = 600, x = 0, y = ib.mwh}
    local default_bg       = "#000000"
    ib.box = wibox({bg = beautiful.infobox_bg or default_bg})

    ib.layout       = wibox.layout.align.vertical()
    ib.layout_title = wibox.layout.align.horizontal()
    ib.box.visible = false
    ib.box.ontop   = true
    default_geometry.y = ib.mwh
    ib.box:geometry(default_geometry)
    ib.box:set_widget(ib.layout)
    ib.title = wibox.widget.textbox()
    ib.title:set_markup(title or '')
    ib.text  = wibox.widget.textbox()
    ib.text:set_markup(text or '')
    ib.icon  = wibox.widget.imagebox()
    ib.icon:set_image(icon)
    ib.title:set_align("center")
    ib.title:set_valign("top")
    ib.text:set_align("left")
    ib.text:set_valign("top")
    ib.icon:set_resize(false)
    ib.layout:set_top(ib.layout_title)
    ib.layout_title:set_left(ib.icon)
    ib.layout_title:set_middle(ib.title)
    ib.layout:set_middle(ib.text)
    ib.update = function()
        local ret = updater(ib.state)
        if (ret.text)  then ib.text:set_markup(ret.text)   end
        if (ret.title) then ib.title:set_markup(ret.title) end
        if (ret.icon)  then ib.icon:set_image(ret.icon)    end
    end
    ib.clear = function()
        ib.text:set_text('')
        ib.title:set_text('')
        ib.icon:set_image(nil)
    end
    function ib.fit()
        local sg = screen[1].geometry
        local sw, sh = sg.width, sg.height - ib.mwh
        local w1, h1 = ib.text:fit(sw, -1)
        local w2, h2 = ib.title:fit(sw, -1)
        local w3, h3 = ib.icon:fit(sw, sh)
        local bw, bh = (beautiful.border_width or 0) + 4, (beautiful.border_width or 0) + 4
        local w, h = math.min(sw, math.max(w1, w2 + w3) + bw), math.min(sh, math.max(h2, h3) + h1 + bh)
        ib.box:geometry({width = w, height = h, x = sw - w})
    end
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
