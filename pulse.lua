-- некрасиво как-то.
package.cpath   = package.cpath .. ";/usr/local/lib/lua/?.so"
local pa        = require("pulseaudio")
local ipairs    = ipairs
local pairs     = pairs
local type      = type

local cosy     = require("cosy")
local beautiful = require("beautiful")
local awful     = require("awful")

local string    = string
local math      = math
local tostring  = tostring

local pulse = {}

pulse.step = 3

local function get_sink_image (i, state)
    local wv = beautiful.wibox.volume
    if (type(wv[i]) == "table") then
        if (wv[i][state]) then return wv[i][state] end
    else
        return wv[state]
    end
end

local function create_sink_widget(i)
    local wt = cosy.widget.txt()
    local wi = cosy.widget.img()
    wi.image = get_sink_image(i, "volume")

    local volume_control = awful.util.table.join(
        awful.button({ }, 1, function()
            awful.util.spawn("killall pavucontrol")
            awful.util.spawn("pavucontrol -t 3")
        end),
        awful.button({ }, 2, function()
            awful.util.spawn("pa_switch")
        end),
        awful.button({ }, 3, function()
            local sink = pa:get_sinks()[i]
            pa:set_sink_volume(sink.index, {mute = not sink.mute})
        end),
        awful.button({ }, 4, function()
            local sink = pa:get_sinks()[i]
            pa:set_sink_volume(sink.index, {volume = sink.volume + pulse.step})
        end),
        awful.button({ }, 5, function()
            local sink = pa:get_sinks()[i]
            pa:set_sink_volume(sink.index, {volume = sink.volume - pulse.step})
        end)
    )
    wt:buttons(volume_control)
    wi:buttons(volume_control)

    return { textbox = wt, imagebox = wi, pa_index = i }
end

function pulse.sinks(...)
    local widgets = {}
    for _, k in pairs(...) do
        widgets[k] = create_sink_widget(k)
    end
    return widgets
end

function pulse.update_sinks(w, f)
    local sinks = pa:get_sinks()
    local wi = beautiful.wibox.volume
    for i, p in pairs(w) do
       if (sinks[i]) then
          w[i].textbox.visible  = true
          w[i].imagebox.visible = true
          w[i].textbox.text = f(sinks[i].volume)
          if (sinks[i].mute ~= nil) then
             if (sinks[i].mute) then
                if (sinks[i].default) then
                   -- приглушена, активна
                   w[i].imagebox.image = get_sink_image(i, "mute")
                else
                   -- приглушена, неактивна
                   w[i].imagebox.image = get_sink_image(i, "mutedim")
                end
             else
                if (sinks[i].default) then
                   -- включена, активна
                   w[i].imagebox.image = get_sink_image(i, "volume")
                else
                   -- включена, неактивна
                   w[i].imagebox.image = get_sink_image(i, "dim")
                end
             end
          else
             w[i].imagebox.image = nil
          end
       else
          w[i].textbox.visible  = false
          w[i].imagebox.visible = false
       end
    end
end



local function choose_input(s)
    local inputs = pa:get_sink_inputs()
    for k, v in pairs(inputs) do
        if (v.name == s) then
            return k, v
        end
    end
    return nil, nil
end

local function create_sink_input_widget(s)
    local wt = cosy.widget.txt()
    local wi = cosy.widget.img()
    wi.image = beautiful.wibox.volume.clients[s]

    local volume_control = awful.util.table.join(
        awful.button({ }, 1, function()
            awful.util.spawn("killall pavucontrol")
            awful.util.spawn("pavucontrol -t 1")
        end),
        awful.button({ }, 3, function()
            local index, input = choose_input(s)
            pa:set_sink_input_volume(index, {mute = not input.mute})
        end),
        awful.button({ }, 4, function()
            local index, input = choose_input(s)
            pa:set_sink_input_volume(index, {volume = input.volume + pulse.step})
        end),
        awful.button({ }, 5, function()
            local index, input = choose_input(s)
            pa:set_sink_input_volume(index, {volume = input.volume - pulse.step})
        end)
    )
    wt:buttons(volume_control)
    wi:buttons(volume_control)

    return { textbox = wt, imagebox = wi}
end

function pulse.inputs(...)
    local widgets = {}
    for _, k in ipairs(...) do
        widgets[k] = create_sink_input_widget(k)
    end
    return widgets
end

function pulse.update_inputs(w, f)
    local inputs = pa:get_sink_inputs()

    for name, widget in pairs(w) do
        local was = false
        for i, p in pairs(inputs) do
            if (name == p.name and not was) then
                was = true
                widget.imagebox.visible = true
                widget.textbox.visible  = true
                widget.textbox.text = f(p.volume)
                if (p.mute) then
                    widget.textbox.text = f('∅')
                end
            end
        end
        if (not was) then
            widget.imagebox.visible = false
            widget.textbox.visible  = false
        end
    end
end

return pulse
