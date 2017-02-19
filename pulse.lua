-- некрасиво как-то.
package.cpath   = package.cpath .. ";/usr/local/lib/lua/?.so"
local pa        = require("pulseaudio")
local ipairs    = ipairs
local pairs     = pairs
local type      = type

local beautiful = require("beautiful")
local awful     = require("awful")
local wibox     = require("wibox")
local versed    = require('versed')

local string    = string
local math      = math
local tostring  = tostring

local pulse = {}

pulse.step = 3

local function get_sink_image(v, state)
    local wv = beautiful.wibox.volume
    if (type(wv[v]) == "table") then
        if (wv[v][state]) then return wv[v][state] end
    else
        return wv[state]
    end
end

local function decide_mute_default_image(mute, default)
    if (mute) then
        if (default) then
            return 'mute'
        else
             return "mutedim"
        end
    else
        if (default) then
            return "volume"
        else
            return "dim"
        end
    end
end

local function create_sink_widget(v, format_function)
    return versed(
    {
        widgets =
        {
            wibox.widget.imagebox(),
            wibox.widget.textbox(),
        },

        init = function(w, i)
            w[1].image = get_sink_image(v, decide_mute_default_image(false, true))
            i.name = v
        end,

        update = function(w, i)
            local sinks = i.objects or pa:get_sinks()
            local sink = sinks[v]
            i.objects = nil
            if (sink) then
                w[2].markup = format_function(sink.volume)
                local icon  = decide_mute_default_image(sink.mute, sink.default)
                w[1].image  = get_sink_image(v, icon)
                i.show()
            else
                i.hide()
            end
        end,

        buttons = awful.util.table.join(
            awful.button({ }, 1, function() awful.util.spawn("pavucontrol -t 3") end),
            awful.button({ }, 2, function() awful.util.spawn("pa_toggle") end),
            awful.button({ }, 3, function()
                local sink = pa:get_sinks()[v]
                pa:set_sink_volume(sink.index, {mute = not sink.mute})
            end),
            awful.button({ }, 4, function()
                local sink = pa:get_sinks()[v]
                pa:set_sink_volume(sink.index, {volume = sink.volume + pulse.step})
            end),
            awful.button({ }, 5, function()
                local sink = pa:get_sinks()[v]
                pa:set_sink_volume(sink.index, {volume = sink.volume - pulse.step})
            end)
        )
    })
end

local function choose_input(s)
    local inputs = pa:get_sink_inputs()
    for k, v in pairs(inputs) do
        if (v.name == s) then
            return k, v
        end
    end
end

local function create_sink_input_widget(v, format_function)
    return versed(
    {
        widgets =
        {
            wibox.widget.imagebox(),
            wibox.widget.textbox(),
        },

        init = function(w, i)
            w[1].image = beautiful.wibox.volume.clients[v]
            i.name = v
        end,

        update = function(w, i)
            local inputs = i.objects or pa:get_sink_inputs()
            local input = nil
            for _, t in pairs(inputs) do
                if (t.name == v) then
                    input = t
                    break
                end
            end
            i.objects = nil
            if (input) then
                w[2].markup = format_function(input.volume)
                if (input.mute) then
                    w[2].markup = format_function('∅')
                end
                i.show()
            else
                i.hide()
            end
        end,

        buttons = awful.util.table.join(
            awful.button({ }, 1, function() awful.util.spawn("pavucontrol -t 1") end),
            awful.button({ }, 3, function()
                local index, input = choose_input(v)
                if (index and input) then
                    pa:set_sink_input_volume(index, {mute = not input.mute})
                end
            end),
            awful.button({ }, 4, function()
                local index, input = choose_input(v)
                if (index and input) then
                    pa:set_sink_input_volume(index, {volume = input.volume + pulse.step})
                end
            end),
            awful.button({ }, 5, function()
                local index, input = choose_input(v)
                if (index and input) then
                    pa:set_sink_input_volume(index, {volume = input.volume - pulse.step})
                end
            end)
        )
    })
end

local function create_widgets(tab, format_function, callback)
    local widgets = {}
    local format_function = format_function or function(s) return s end
    for k, v in pairs(tab) do
        widgets[k] = callback(v, format_function)
    end
    return widgets
end

local function update_widgets(w, callback)
    local objects = callback()
    for i, p in pairs(w) do
        p.objects = objects
        p.update()
    end
end

function pulse.sinks( tab, format_function) return create_widgets(tab, format_function, create_sink_widget)       end
function pulse.inputs(tab, format_function) return create_widgets(tab, format_function, create_sink_input_widget) end

function pulse.update_sinks(w)  update_widgets(w, function() return pa:get_sinks()       end) end
function pulse.update_inputs(w) update_widgets(w, function() return pa:get_sink_inputs() end) end

return pulse
