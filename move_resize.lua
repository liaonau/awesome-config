local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local awful     = require("awful")

local naughty   = require("naughty")

local mr = {}
mr.move_resize_step = 35

gears.shape.resize_arrows = function(cr, width, height)
    local w, h = width/8, height/8

    cr:move_to(0*w, 8*h)
    cr:line_to(5*w, 8*h)
    cr:line_to(0*w, 3*h)
    cr:line_to(0*w, 8*h)

    cr:move_to(8*w, 0*h)
    cr:line_to(3*w, 0*h)
    cr:line_to(8*w, 5*h)
    cr:line_to(8*w, 0*h)

    cr:close_path()
end

gears.shape.move_arrows = function(cr, width, height)
    local w, h = width/16, height/16
    cr:move_to( 0*w,  8*h)
    cr:line_to( 3*w,  5*h)
    cr:line_to( 3*w, 11*h)
    cr:line_to( 0*w,  8*h)

    cr:move_to(16*w,  8*h)
    cr:line_to(13*w,  5*h)
    cr:line_to(13*w, 11*h)
    cr:line_to(16*w,  8*h)

    cr:move_to( 8*w,  0*h)
    cr:line_to( 5*w,  3*h)
    cr:line_to(11*w,  3*h)
    cr:line_to( 8*w,  0*h)

    cr:move_to( 8*w, 16*h)
    cr:line_to( 5*w, 13*h)
    cr:line_to(11*w, 13*h)
    cr:line_to( 8*w, 16*h)

    cr:rectangle(  3*w, 7.5*h, 10*w,  1*h)
    cr:rectangle(7.5*w,   3*h,  1*w, 10*h)

    cr:close_path()
end

local function create_informational_box(shape)
    local box
    local size    = 64
    local margins = 5
    local shape   = shape or gears.shape.resize_arrows
    local bg      = "#aaaaaa"
    local fg      = "#000000"
    box = wibox(
    {
        ontop   = true,
        visible = false,
        width   = size,
        height  = size,
    })
    box:setup(
    {
        {
            {
                {
                    widget = wibox.widget.imagebox
                },
                shape  = shape,
                bg     = fg,
                widget = wibox.container.background
            },
            margins = margins,
            widget  = wibox.container.margin,
        },
        bg     = bg,
        widget = wibox.container.background
    })
    gears.surface.apply_shape_bounding(box, gears.shape.rounded_rect)
    return box
end

local function move_to_end(c, direction)
    local g = c:geometry()
    local s = awful.screen.focused().geometry
    local m = beautiful.main_wibox_height or 0
    if     direction == 'Up'    then
        g.y = m
    elseif direction == 'Down'  then
        g.y = math.max(m, s.height - g.height)
    elseif direction == 'Right' then
        g.x = math.max(0, s.width - g.width)
    elseif direction == 'Left'  then
        g.x = 0
    else
        return
    end
    c:geometry(g)
end

mr.res_box = create_informational_box()
mr.mod_box = create_informational_box(gears.shape.move_arrows)

do
    local s = mr.move_resize_step
    mr.mods = {}
    mr.mods[{}] =
    {
        up    = { 0, -s,  0,  s},
        down  = { 0,  0,  0,  s},
        right = { 0,  0,  s,  0},
        left  = {-s,  0,  s,  0},
    }
    mr.mods[{"Shift"}] =
    {
        up    = { 0,  0,  0, -s},
        down  = { 0,  s,  0, -s},
        right = { s,  0, -s,  0},
        left  = { 0,  0, -s,  0},
    }
    mr.mods[{"Mod4"}] =
    {
        up    = { 0, -s,  0,  0},
        down  = { 0,  s,  0,  0},
        right = { s,  0,  0,  0},
        left  = {-s,  0,  0,  0},
    }
    mr.mods[{"Mod4", "Shift"}] =
    {
        up    = function(c) move_to_end(c, 'Up'   ) end,
        down  = function(c) move_to_end(c, 'Down' ) end,
        right = function(c) move_to_end(c, 'Right') end,
        left  = function(c) move_to_end(c, 'Left' ) end,
    }
    mr.keys =
    {
        up    = {"Up",    "k"},
        down  = {"Down",  "j"},
        right = {"Right", "l"},
        left  = {"Left",  "h"},
    }
end

mr.callback = function(c, in_mods, in_key)
    if (not c.floating) then
        return
    end
    local s = awful.screen.focused()
    mr.res_box:geometry({x = (s.geometry.width)/2, y = 0})
    mr.mod_box:geometry({x = (s.geometry.width)/2, y = 0})
    mr.res_box.visible = true
    mr.mod_box.visible = false

    local move_mode = false
    local grabber
    grabber = awful.keygrabber.run(
    function(mod, key, event)
        naughty.notify({icon='info',title=key,text=event})
        if event == "release" then
            if (key == "Super_L") then
                mr.mod_box.visible = false
                mr.res_box.visible = true
            end
            return
        end
        if (key == "Super_L") then
            mr.mod_box.visible = true
            mr.res_box.visible = false
            return
        end
        local is_switcher = false
        if (in_key and in_mods) then
            is_switcher = awful.key.match({key = in_key, modifiers = in_mods}, mod, key)
        end
        -- почему " ", а не "space"?
        if (key == "Return" or key == "Escape" or key == " " or key == "q" or is_switcher) then
            mr.res_box.visible = false
            mr.mod_box.visible = false
            awful.keygrabber.stop(grabber)
            return
        end
        local tab = nil
        for k, v in pairs(mr.mods) do
            if awful.key.match({key = key, modifiers = k}, mod, key) then
                tab = v
                break
            end
        end
        if not tab then
            return
        end
        for k, v in pairs(mr.keys) do
            for _, ks in pairs(v) do
                if (ks == key) then
                    local t = tab[k]
                    if (t) then
                        if (type(t) == 'table') then
                            c:relative_move(table.unpack(t))
                        else -- если не таблица, то функция
                            t(c)
                        end
                    end
                    return
                end
            end
        end
    end)
end

return mr
