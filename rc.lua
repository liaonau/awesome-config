io.stderr:write("Starting Awesome WM\n")
os.setlocale(os.getenv("LANG"))
-- {{{ imports
awful      = require("awful")
gears      = require("gears")
vicious    = require("vicious")
tyrannical = require("tyrannical")
naughty    = require("naughty")
pulse      = require("pulse")

local awful       = awful
local gears       = gears
local vicious     = vicious
local pulse       = pulse
local tyrannical  = tyrannical
local naughty     = naughty

local beautiful   = require("beautiful")
local wibox       = require("wibox")
local menubar     = require("menubar")
local meteo       = require("meteo")
local markup      = require("markup")
local infobox     = require("infobox")
local tabular     = require("tabular")
local freedesktop = require('freedesktop')
local autofocus   = require("awful.autofocus")
local move_resize = require("move_resize")

-- remote последним
awful.remote = require("awful.remote")
-- }}}
-- {{{ variable definitions, auxillary functions
modkey = "Mod4"

tabular.styler = function(text, n, c)
    local bg = "#338833"
    local fg = "white"
    local font_size = "11"
    return '<span font_desc="'..font_size..'" background="'..bg..'" foreground="'..fg..'"> '..n..' </span>'..text
end

beautiful.init(awful.util.getdir("config") .. "/themes/theme.lua")

naughty.config.icon_dirs = beautiful.dirs.naughty_icons
--naughty.config.defaults.opacity=0.6

terminal = "urxvt"
editor   = os.getenv("EDITOR") or "gvim"

local als = awful.layout.suit
als.tabular  = tabular.layout
layouts =
{
    als.tile.top,
    --als.fair,
    --als.floating,
    als.tabular,

    --als.tile,
    --als.tile.left,
    --als.tile.bottom,
    --als.fair.horizontal,
    --als.spiral,
    --als.spiral.dwindle,
    --als.max,
    --als.max.fullscreen,
    --als.magnifier,

    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    awful.layout.suit.corner.ne,
    awful.layout.suit.corner.sw,
    awful.layout.suit.corner.se,
}
-- }}}
-- {{{ helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

local function round(num, pow)
    local p = 10^(pow or 0)
    return math.floor(num * p + 0.5) / p
end

-- lua 5.1/5.2 compatibility
table.pack = table.pack or
    function(...)
        return {n=select('#',...); ...}
    end

table.unpack = table.unpack or unpack

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end
-- }}}
-- {{{ menu
menubar.utils.terminal = terminal
mymainmenu = freedesktop.menu.build(
{
    theme = {width = 250},
    before =
    {
    },
    after =
    {
        { "restart",  function() awesome.restart() end, menubar.utils.lookup_icon('gtk-refresh') },
        { "quit",     function() awesome.quit()    end, menubar.utils.lookup_icon('gtk-quit'   ) },
        { "terminal", terminal,                          menubar.utils.lookup_icon('terminal'   ) },
    }
})

mylauncher = awful.widget.launcher({image = beautiful.awesome_icon, menu = mymainmenu})
-- }}}
-- {{{ infoboxes
-- {{{ info wibox с df
local disksbox = infobox(
function(ib)
    local text
    awful.spawn.easy_async("di -h -f MpTBv -x squashfs,aufs,rootfs,overlay",
    function(stdout, stderr, exitreason, exitcode)
        text = stdout
        text = string.gsub(text, "(/[^%s]*)",  markup.b('%1'))
        text = string.gsub(text, "(%d+%%)",    markup.g("%1"))
        text = string.gsub(text, "([78]%d%%)", markup.y("%1"))
        text = string.gsub(text, "(9%d%%)",    markup.r("%1"))
        text = string.gsub(text, "(100%%)",    markup.r("%1"))
        text = string.gsub(text, "(tmpfs)",    markup("#777777", "%1"))
        text = text:sub(1, -2)
        text = markup.font_desc("monospace 11", text)
        ib.text:set_markup(text)
    end)
end, nil,
beautiful.wibox.disks, 'df'
)
-- }}}
-- {{{ info wibox с календарем
local datebox = infobox(
function(ib)
    local today = os.date('*t')
    local m     = today.year * 12 + today.month + ib.state.offset - 1
    local month = m % 12 + 1
    local year  = math.floor(m / 12)
    local text
    awful.spawn.easy_async("/usr/bin/cal " .. month .. ' ' .. year,
    function(stdout, stderr, exitreason, exitcode)
        text = stdout:sub(1, -2)
        if (ib.state.offset == 0) then
            text = string.gsub(text, "([^%d]"..today.day.."[^%d])", markup.b("%1"))
        end
        text = markup.font_desc('monospace 12', text)
        ib.text:set_markup(text)
    end)
end,
{offset = 0},
beautiful.wibox.calendar, 'календарь'
)
datebox.on_hide = function(s)
    s.offset = 0
end
datebox.on_show = function(s)
    s.offset = 0
end
-- }}}
-- {{{ info wibox с погодой
local weather_lag = 7200
local function get_text_weather(weather)
    local time = os.time()

    local utcdate   = os.date("!*t", time)
    local localdate = os.date("*t",  time)
    localdate.isdst = false -- this is the trick
    local diffdate  = os.difftime(os.time(localdate), os.time(utcdate))

    local diff = weather.time - time
    local diffhour = tostring(round(diff/3600))

    local caption = 'сейчас'
    if (weather.time_txt ~= nil) then
        local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
        local year, month, day, hour, min, sec = weather.time_txt:match(pattern)
        local ts_utc = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec, tz="UTC"})
        local dt = os.date('%c', os.time(os.date('*t', ts_utc)) + diffdate);
        caption = '('..diffhour..') '..dt:gsub(":[0-9][0-9]$", '')
    end
    local text = markup.b(caption)
    if (diff + weather_lag < 0) then
        text = text..markup.r("\nданные устарели\n\n")
    else
        text = text..'\n'..
        markup.m(weather.description)..'\n'..
        'температура, °C     '..markup.m(string.format("%3s", weather.temp))..'\n'..
        'давление, мм рт.ст. '..markup.c(string.format(weather.pressure))..'\n'..
        'влажность, %        '..markup.c(string.format("%3s", weather.humidity))..'\n'..
        'ветер, м/с          '..markup.c(string.format("%3s", weather.wind):gsub(',', '.'))..'\n'..
        'облачность, %       '..markup.c(string.format("%3s", weather.clouds))..'\n'..
        '\n'
    end
    return text
end

meteobox = infobox(
function(ib)
    local dir_meteo = os.getenv("HOME").."/.local/share/meteo/"
    local forecast = meteo.forecast(dir_meteo..'forecast.json')
    local weather = meteo.weather(dir_meteo..'weather.json')
    local now  = ''
    local text = ''

    local icon = beautiful.dirs.weather..weather.icon..'.png'

    now = get_text_weather(weather, 'сейчас')
    now = markup.font_desc('monospace 12', now)
    text = ''
    text = text..get_text_weather(forecast[3])
    text = text..get_text_weather(forecast[5])
    text = text..get_text_weather(forecast[9])
    text = text..get_text_weather(forecast[17])
    --text = text:sub(1, -2)
    text = markup.font_desc('monospace 10', text)
    text = now..text
    title = markup.font_desc('monospace 14', '\nпогода\n'),

    ib.text:set_markup(text)
    ib.title:set_markup(title)
    ib.icon:set_image(icon)
end
)
-- }}}
-- }}}
-- {{{ wibar
--infos = {}
--function update_info(ins, info)
    --if (not ins.info or not ins.info.update or type(ins.info.update) ~= 'function') then
        --return
    --end
    --ins.info.update()
--end
--{{{ keyboard layout
mykeyboardlayout = wibox.widget.imagebox()
local function update_keyboard_layout()
    local current = awesome.xkb_get_layout_group();
    if (current == 0) then
        mykeyboardlayout.image = beautiful.kbd.us
    else
        mykeyboardlayout.image = beautiful.kbd.ru
    end
end
--}}}
-- {{{ tray
systray = wibox.widget.systray()
systray.stupid_bug = drawin({})
systray_layout = wibox.container.constraint()
systray_layout.widget = systray
systray.visible = true
systray.toggle  = function()
    systray.visible = not systray.visible
    if (systray.visible) then
        systray_layout.widget = systray
    else
        -- To hide the systray (actually "to move the systray into the drawin called
        -- stupid_bug which is not visible and making sure it does not get moved back")
        awesome.systray(systray.stupid_bug, 0, 0, 10, true, "#000000")
        systray_layout.widget = nil
    end
end
-- }}}
-- {{{ separator
separator = wibox.widget.imagebox()
separator:set_image(beautiful.wibox.separator)
-- }}}
-- {{{ часы
mydate_icon = wibox.widget.imagebox()
mydate_icon:set_image(beautiful.wibox.date)

mydate = wibox.widget.textbox()
vicious.register(mydate, vicious.widgets.date, markup.b("%a %d %b ")..markup.c("%H:%M"), 10)

mydate:connect_signal(     "mouse::leave", datebox.hide)
mydate_icon:connect_signal("mouse::leave", datebox.hide)
local date_control = awful.util.table.join(
    awful.button({ }, 1, datebox.show),
    awful.button({ }, 4,
    function()
        datebox.state.offset = datebox.state.offset - 1
        datebox.update()
    end),
    awful.button({ }, 5,
    function()
        datebox.state.offset = datebox.state.offset + 1
        datebox.update()
    end)
)
mydate:buttons(date_control)
mydate_icon:buttons(date_control)
-- }}}
-- {{{ звук
--pulse.step = os.getenv("VOLUME_STEP") or 4
pulse.step = 1
local vin, vss
vin =
    {
        mpd = "Music Player Daemon",
        --mplayer = "MPlayer",
        --mplayer = "mplayer2",
        mplayer = "mpv Media Player",
        flash_plugin = "ALSA plug-in [plugin-container]",
        radiotray = "radiotray",
        qemu="qemu-system-x86_64",
        vlc="VLC media player (LibVLC 2.1.4)",
    }
vss =
    {
        headphones = "alsa_output.usb-Logitech_Logitech_Wireless_Headset_000D44D39CAA-00.analog-stereo",
        speakers   = "alsa_output.pci-0000_00_1b.0.analog-stereo",
        ladspa     = "ladspa_sink",
        --ladspa     = "ladspa_normalized_sink",
    }
volume =
    {
        sinks  = pulse.sinks({vss.headphones, vss.speakers, vss.ladspa}),
        inputs = pulse.inputs({vin.mpd, vin.mplayer, vin.flash_plugin, vin.radiotray, vin.qemu, vin.vlc})
    }
volume.update_sinks = function()
    pulse.update_sinks(volume.sinks, function(s) return string.format(markup.b("%s"), s) end)
end
volume.update_inputs = function()
    pulse.update_inputs(volume.inputs, function(s) return string.format(markup.b("%s"), s) end)
end
volume.update_all = function()
    volume.update_sinks()
    volume.update_inputs()
end
volume.update_all()
-- }}}
-- {{{ батарея
--wake up upowerd
dbus.add_match("system", "path='/org/freedesktop/UPower/devices/battery_BAT0',member='PropertiesChanged'")
dbus.add_match("system", "path='/org/freedesktop/UPower/devices/line_power_AC',member='PropertiesChanged'")

mybat_icon            = wibox.widget.imagebox()
mybat_icon.image      = beautiful.wibox.battery["missing"]
mybat_separator       = wibox.widget.imagebox()
mybat_separator.image = beautiful.wibox.separator
mybat                 = wibox.widget.textbox()

local bat_state = 0
vicious.register(mybat, vicious.widgets.bat,
    function(widget, args)
        local sign, level = args[1], args[2]

        if (bat_state ~= 0 and sign == '⌁') then
            if     (bat_state == 1) then
                sign = '+'
            elseif (bat_state == 2) then
                sign = '−'
            elseif (bat_state == 4) then
                sign = '↯'
            end
        end
        if     (sign == '↯') then -- заряжено
            mybat_icon.visible      = false
            mybat.visible           = false
            mybat_separator.visible = false
        else
            if     (sign == '⌁') then -- неизвестно
                mybat_icon.image = beautiful.wibox.battery["missing"]
            elseif (sign == '−' or sign == '+') then
                local suf = ''
                if (sign == '+') then suf = '_c' end
                if     (level == 100) then
                    mybat_icon.image = beautiful.wibox.battery["100"..suf]
                elseif (level > 80 and level < 100) then
                    mybat_icon.image = beautiful.wibox.battery["080"..suf]
                elseif (level > 60 and level <= 80) then
                    mybat_icon.image = beautiful.wibox.battery["060"..suf]
                elseif (level > 40 and level <= 60) then
                    mybat_icon.image = beautiful.wibox.battery["040"..suf]
                elseif (level > 20 and level <= 40) then
                    mybat_icon.image = beautiful.wibox.battery["020"..suf]
                elseif (               level <= 20) then
                    mybat_icon.image = beautiful.wibox.battery["000"..suf]
                end
            end
            mybat_icon.visible      = true
            mybat.visible           = true
            mybat_separator.visible = true
        end

        local perc_color = "#88ff88"
        local warn_level = 35
        local crit_level = 15
        if (level > crit_level and level <= warn_level) then
            perc_color = "#ffff88"
        elseif (level <= crit_level) then
            perc_color = "#ff8888"
        end
        local text = markup(perc_color, level..'%')
        return text
    end,
0, "BAT0")
dbus.connect_signal("org.freedesktop.DBus.Properties",
function(...)
    local data = {...}
    if (data[2] ~= "org.freedesktop.UPower.Device") then return end
    local device = data[1].path:match('([^/]+)$')
    if (device == 'battery_BAT0') then
        local state = data[3].State
        if (state ~= nil and state ~= 0) then
            bat_state = state
        end
    end
    vicious.force({mybat})
end)
vicious.force({mybat})
-- }}}
-- {{{ яркость
mybright_icon            = wibox.widget.imagebox()
mybright_icon.image      = beautiful.wibox.brightness
mybright_separator       = wibox.widget.imagebox()
mybright_separator.image = beautiful.wibox.separator
mybright                 = wibox.widget.textbox()
mybrightness_timer       = gears.timer({timeout = 10})

local brightness_path = 'intel_backlight'
local f = io.open('/sys/class/backlight/'..brightness_path..'/max_brightness')
local max_brightness = f:read("*a")
f:close()

update_brightness = function()
    local f = io.open('/sys/class/backlight/'..brightness_path..'/brightness')
    local level = f:read("*a")
    f:close()
    if (level == max_brightness) then
    mybright_icon.visible      = false
    mybright.visible           = false
    mybright_separator.visible = false
    else
    mybright_icon.visible      = true
    mybright.visible           = true
    mybright_separator.visible = true
    end
    mybright.markup = markup.b(string.format("%.0f", 100*level/max_brightness)..'%')
end

mybrightness_timer:connect_signal("timeout", update_brightness)
update_brightness()
mybrightness_timer:start()
-- }}}
-- {{{ температура
my_cpu_icon = wibox.widget.imagebox()
my_cpu_icon:set_image(beautiful.wibox.cpu)
mythermal_cpu = wibox.widget.textbox()
vicious.register(mythermal_cpu, vicious.widgets.thermal,
function(widget, args)
    local t = math.ceil(args[1])
    local therm_color = "#88ff88"
    if ( t >= 79 ) then
        therm_color = "#ff8888"
    elseif ( t >= 70 ) then
        therm_color = "#ffff88"
    end
    return markup(therm_color, t..'°')
end,
5, "thermal_zone0", "sys")

mythermal_hdd_icon = wibox.widget.imagebox()
mythermal_hdd_icon:set_image(beautiful.wibox.hdd)
mythermal_hdd = wibox.widget.textbox()
local function therm_color_markup(t, warn, crit)
    if (t == nil) then
        t = markup.y("?")
    elseif ( t >= crit ) then
        t = markup("#ff8888", t..'°')
    elseif ( t >= warn ) then
        t = markup("#ffff88", t..'°')
    else
        t = markup("#88ff88", t..'°')
    end
    return t
end
--vicious.register(mythermal_hdd, vicious.widgets.hddtemp,
--function(widget, args)
    --local ta = args["{/dev/sda}"]
    --local tb = args["{/dev/sdb}"]
    --ta = therm_color_markup(ta, 40, 45)
    --tb = therm_color_markup(tb, 50, 55)
    --return ta..' '..tb
--end,
--10, 7634)
-- }}}
-- {{{ память, диски
mymem_icon = wibox.widget.imagebox()
mymem_icon:set_image(beautiful.wibox.mem)

mymem = wibox.widget.textbox()
vicious.register(mymem, vicious.widgets.mem,
function(widget, args)
    local mem, swp = markup.b(args[1]..'%'), ''
    if (args[5] ~= 0) then swp = markup.c(' '..args[5]..'%') end
    return mem..swp
end,
10)

mymem:connect_signal(     "mouse::leave", disksbox.hide )
mymem_icon:connect_signal("mouse::leave", disksbox.hide )

local disks_control = awful.util.table.join(
    awful.button({ }, 1, disksbox.show)
)

mymem:buttons(disks_control)
mymem_icon:buttons(disks_control)
-- }}}
-- {{{ mpd
mympd_icon = wibox.widget.imagebox()
mympd_icon:set_image(beautiful.wibox.mpd.music)

mympd = wibox.widget.textbox()
vicious.register(mympd, vicious.widgets.mpd,
    function(widget, args)
        if args["{state}"] == "Stop" then
            mympd_icon:set_image(beautiful.wibox.mpd.stop)
            return ''
        elseif args["{state}"] == "Pause" then
            mympd_icon:set_image(beautiful.wibox.mpd.pause)
            return ''
        else
            local color_title = "#eeff88"
            if args["{random}"] == 1 then color_title = "#88ff88" end
            mympd_icon:set_image(beautiful.wibox.mpd.play)
            local artist = args["{Artist}"]
            local title = args["{Title}"]
            if (artist == "N/A") then
                artist = args["{file}"]:gsub(".*/(.*)$", "%1")
            end
            if (title == "N/A") then
                title = args["{Name}"]
            end
            return markup("#00bbbb", artist)..' '..markup(color_title, title)
        end
    end, 0) -- 0 is good since mpdcron is been used
vicious.force({mympd})

local mpd_control = awful.util.table.join(
    awful.button({ }, 1, function()
        awful.spawn("mpc toggle")
        -- no need in explicit forcing of vicious widget's update since using mpdcron
        --vicious.force({mympd})
    end),
    awful.button({ }, 3, function()
        awful.spawn("mpc random")
    end),
    awful.button({ }, 4, function()
        awful.spawn("mpc prev")
    end),
    awful.button({ }, 5, function()
        awful.spawn("mpc next")
    end)
)
mympd:buttons(mpd_control)
mympd_icon:buttons(mpd_control)
-- }}}
-- {{{ сеть
nm_widget           = wibox.widget.textbox()
nm_icon             = wibox.widget.imagebox()
nm_icon.image       = beautiful.wibox.net.nm["none"]

net_icon_up         = wibox.widget.imagebox()
net_icon_down       = wibox.widget.imagebox()
net_icon_up.image   = beautiful.wibox.net.up
net_icon_down.image = beautiful.wibox.net.down
mynet               = wibox.widget.textbox()

vicious.register(mynet, vicious.widgets.net,
function(widget, args)
    local round_net = function(num)
        local n = tonumber(num)
        if ((n < 1) and (n > 0)) then return 1 end
        return math.floor(n + 0.5)
    end
    local up_color   = "#88ff88"
    local down_color = "#ff8888"
    local up_speed   = round_net(args["{wlan0 up_kb}"])
    local down_speed = round_net(args["{wlan0 down_kb}"])
    return markup(down_color, down_speed)..' '..markup(up_color, up_speed)
end,
5, "wlan0")

-- I guess we can only connect to signal through awesome api
-- so we'll use perl script to ask properties, although it's quite ugly decision
-- normally it won't be called too often
-- we'll have `nm_ac' name string and `nm_ac_table' properties
local get_ap = function(i)
    local f = io.popen(awful.util.getdir("config").."/bin/nm-perl.pl")
    if f then
       local pl = f:read("*a")
       f:close()
       local func, err = loadstring(pl)
       if func then
          func()
       else
          nm_ac       = nil
          nm_ac_table = nil
       end
    else
       nm_ac       = nil
       nm_ac_table = nil
    end
end

dbus.add_match("system", "interface='org.freedesktop.NetworkManager',member='StateChanged'")
dbus.add_match("system", "interface='org.freedesktop.NetworkManager.AccessPoint',member='PropertiesChanged'")

local function nm_update_widget()
    if (nm_ac == nil or nm_ac_table == nil) then
        net_icon_up.visible   = false
        net_icon_down.visible = false
        mynet.visible         = false
        nm_widget.visible     = false
        nm_icon.image         = beautiful.wibox.net.nm["none"]
    else
        local s = tonumber(nm_ac_table.Strength)
        local c
        if s < 25 then
            c = "#ff8888" -- bad
            nm_icon.image = beautiful.wibox.net.nm["00"]
        elseif s < 50 then
            c = "#ffff88" -- quite bad
            nm_icon.image = beautiful.wibox.net.nm["25"]
        elseif s < 75 then
            c = "#88cc88" -- medium
            nm_icon.image = beautiful.wibox.net.nm["50"]
        elseif s < 100 then
            c = "#88ff88" -- good
            nm_icon.image = beautiful.wibox.net.nm["75"]
        else
            c = "#88ff88" -- good
            nm_icon.image = beautiful.wibox.net.nm["100"]
        end
        net_icon_up.visible   = true
        net_icon_down.visible = true
        mynet.visible         = true
        nm_widget.markup      = markup.c(nm_ac_table.Ssid)..' '..markup(c, nm_ac_table.Strength..'%')
        nm_widget.visible     = true
    end
end

dbus.connect_signal("org.freedesktop.NetworkManager.AccessPoint",
function(...)
    local data = {...}
    local sender = data[1]
    local state  = data[2]
    if (nm_ac and nm_ac == sender["path"]) then
        for k,v in pairs(data[2]) do
            v = (k == "Strength") and string.byte(v) or v
            nm_ac_table[k] = v
        end
        nm_update_widget()
    end
end)

-- can't wait first event after initializing awesome
get_ap()
nm_update_widget()

dbus.connect_signal("org.freedesktop.NetworkManager",
function(...)
    local data = {...}
    local state = data[2]
    if (state ~= 70) then
        nm_ac = nil
        nm_ac_table = nil
    else
        get_ap()
    end
    nm_update_widget()
end)
-- }}}
-- {{{ напоминание
myrem      = wibox.widget.textbox()
myrem_icon = wibox.widget.imagebox()
myrem_icon.image = beautiful.wibox.rem
do_remind = false
local setreminder = function()
    if (not do_remind) then
        myrem_icon.visible = false
        myrem.visible      = false
        return
    end
    local text = ''
    local file = io.open(awful.util.getdir('cache')..'/remind')
    if file then
        text = file:read("*a")
        text = text:gsub("\n$", "")
        io.close(file)
    end
    myrem.markup = markup.r(text)
    if (text == '') then
        myrem_icon.visible = false
        myrem.visible      = false
    else
        myrem_icon.visible = true
        myrem.visible      = true
    end
end
myrem_timer = gears.timer({timeout = 30})
myrem_timer:connect_signal("timeout", setreminder)
setreminder()
myrem_timer:start()
-- }}}
-- {{{ погода
myweather_show      = true
myweather           = wibox.widget.textbox()
myweather_icon      = wibox.widget.imagebox()
myweather_separator = wibox.widget.imagebox()
myweather_separator.image   = beautiful.wibox.separator
myweather_separator.visible = false
myweather_timer = gears.timer({timeout = 300})
function myweather_update()
    local time = os.time()
    local dir_meteo = os.getenv("HOME").."/.local/share/meteo/"
    local weather = meteo.weather(dir_meteo..'weather.json')
    local diff = weather.time - time

    if (diff + weather_lag < 0) then -- данные устарели
        myweather.visible           = false
        myweather_icon.visible      = false
        myweather_separator.visible = false
    else
        myweather.visible           = myweather_show
        myweather_icon.visible      = myweather_show
        myweather_separator.visible = myweather_show
        if (myweather_show) then
            myweather.markup = markup.b(weather.temp..'°')
            myweather_icon.image = beautiful.dirs.weather..weather.icon..'t.png'
        end
    end
end
myweather_update()
myweather_timer:connect_signal("timeout", myweather_update)
myweather_timer:start()

myweather:connect_signal(     "mouse::leave", meteobox.hide )
myweather_icon:connect_signal("mouse::leave", meteobox.hide )

local meteobox_control = awful.util.table.join(
    awful.button({ }, 1, meteobox.show)
)

myweather:buttons(meteobox_control)
myweather_icon:buttons(meteobox_control)
-- }}}
--{{{ taglist_buttons
local taglist_buttons = awful.util.table.join(
    awful.button({ },        1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
    awful.button({ },        3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end),
    awful.button({ },        4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ },        5, function(t) awful.tag.viewprev(t.screen) end)
)
--}}}
--{{{ tasklist_buttons
local tasklist_buttons = awful.util.table.join(
    awful.button({ }, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c.minimized = false
            if not c:isvisible() and c.first_tag then
                c.first_tag:view_only()
            end
            client.focus = c
            c:raise()
        end
    end),
    awful.button({ }, 3, client_menu_toggle_fn()),
    awful.button({ }, 4, function() awful.client.focus.byidx( 1) end),
    awful.button({ }, 5, function() awful.client.focus.byidx(-1) end)
)
--}}}
awful.screen.connect_for_each_screen(
function(s)
    set_wallpaper(s)
--{{{ promptbox, layoutbox, taglist, tasklist
    s.mypromptbox = awful.widget.prompt()
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
        awful.button({ }, 1, function() awful.layout.inc(layouts,  1) end),
        awful.button({ }, 3, function() awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function() awful.layout.inc(layouts,  1) end),
        awful.button({ }, 5, function() awful.layout.inc(layouts, -1) end)
    ))

    s.mytaglist  = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)
    --s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons, nil, tabular.taskupdate)
--}}}
--{{{ создание панели
    s.mywibox = awful.wibar({ position = "top", screen = s, height = beautiful.main_wibox_height })

    local whole_layout        = wibox.layout.flex.vertical()
    local top_layout          = wibox.layout.align.horizontal()
    local top_right_layout    = wibox.layout.fixed.horizontal()
    local top_left_layout     = wibox.layout.fixed.horizontal()
    local bottom_layout       = wibox.layout.align.horizontal()
    local bottom_right_layout = wibox.layout.fixed.horizontal()
    local bottom_left_layout  = wibox.layout.fixed.horizontal()

    local left, middle, right, top, bottom = 1, 2, 3, 1, 3
    s.mywibox:setup(
    {
        layout = whole_layout,
        [top] =
        {
            layout = top_layout,
            [left] =
            {
                layout = top_left_layout,
                mylauncher,
                s.mytaglist,
            },
            [middle] = nil,
            [right] =
            {
                layout = top_right_layout,
                separator,
                nm_icon, net_icon_down, mynet, net_icon_up, nm_widget, separator,
                mymem_icon, mymem, separator,
                my_cpu_icon, mythermal_cpu,
                --mythermal_hdd_icon, mythermal_hdd, separator,
                separator,
                mybright_icon, mybright, mybright_separator,
                mybat_icon, mybat, mybat_separator,
                volume.inputs[vin.qemu].imagebox,         volume.inputs[vin.qemu].textbox,
                volume.inputs[vin.radiotray].imagebox,    volume.inputs[vin.radiotray].textbox,
                volume.inputs[vin.flash_plugin].imagebox, volume.inputs[vin.flash_plugin].textbox,
                volume.inputs[vin.vlc].imagebox,          volume.inputs[vin.vlc].textbox,
                volume.inputs[vin.mplayer].imagebox,      volume.inputs[vin.mplayer].textbox,
                volume.inputs[vin.mpd].imagebox,          volume.inputs[vin.mpd].textbox,
                separator,
                volume.sinks[vss.ladspa].imagebox,
                volume.sinks[vss.speakers].imagebox,   volume.sinks[vss.speakers].textbox,   separator,
                volume.sinks[vss.headphones].imagebox, volume.sinks[vss.headphones].textbox, separator,
                myweather_icon, myweather, myweather_separator,
                mydate_icon, mydate,
                s.index == 1 and systray_layout or nil,
                s.mylayoutbox,
            },
        },
        [middle] = nil,
        [bottom] =
        {
            layout = bottom_layout,
            [left] =
            {
                layout = bottom_left_layout,
                mykeyboardlayout,
                s.mypromptbox,
            },
            [middle] = s.mytasklist,
            [right] =
            {
                layout = bottom_right_layout,
                myrem_icon, myrem,
                mympd_icon, mympd,
            },
        }
    })
--}}}
end)
-- }}}
--{{{ tyrannical
tyrannical.settings.block_children_focus_stealing = true
tyrannical.settings.group_children = true
--tyrannical.settings.no_focus_stealing_out = true
tyrannical.settings.default_layout = als.tabular
--{{{ tyrannical tags
mytags =
{
    {
        name      = "1",
        icon      = "terminal.png",
        class     = {"URxvt"},
        init      = true,
        volatile  = false,
    },
    {
        name      = "2",
        icon      = "ff.png",
        class     = {"Firefox", "Google-chrome"},
        --spawn     = 'browser',
        spawn     = 'google-chrome-stable',
    },
    {
        name      = "3",
        icon      = "idea.png",
        class     = {"jetbrains-idea"},
    },
    {
        name      = "4",
        icon      = "dict.png",
        class     = {"GoldenDict"},
        spawn     = 'goldendict',
        --no_focus_stealing_in = true,
    },
    {
        name      = "5",
        icon      = "mplayer.png",
        class     = {"mpv", "Vlc", "Gupnp-av-cp", "plugin-container", "Sxiv", "Geeqie"},
    },
    {
        name      = "6",
        icon      = "deluge.png",
        class     = {"Deluge"},
        spawn     = 'deluge-gtk',
    },
    {
        name      = "7",
        icon      = "audio.png",
        class     = {"cantata"},
        spawn     = 'cantata',
    },
    {
        name      = "8",
        icon      = "vim.png",
        class     = {"Emacs", "Gvim"},
    },
    {
        name      = "9",
        icon      = "pride.png",
        class     = {"Pride", "com.github.liaonau.Main"},
    },
    {
        name      = "0",
        icon      = "reader.png",
        class     = {"Zathura", "Djview", "Evince", "Qpdfview", "fbreader"},
    },
    {
        name      = "a",
        icon      = "emul.png",
        layout    = als.fair,
        instance  = {"Wine", "Remote-viewer", "Xephyr"},
    },
    {
        name      = "b",
        icon      = "logview.png",
        instance  = {"logTerminal"},
        spawn     = terminal.." -cr black -rv -name logTerminal -e /bin/sh -c '/usr/bin/journalctl -b -n 39 -f | ccze -A -m ansi'",
    },
    {
        name      = "c",
        icon      = "terminal-aux.png",
        instance  = {"urxvt-aux"},
        spawn     = 'urxvt-aux',
    },
    {
        name      = "g",
        icon      = "openmw.png",
        class     = {"Steam", "openmw"},
    },
    {
        name      = "i",
        icon      = "htop.png",
        instance  = {"htopTerminal"},
        spawn     = terminal.." -name htopTerminal -e htop",
    },
    {
        name      = "o",
        icon      = "oo.png",
        class     = {"OpenOffice"},
    },
    {
        name      = "p",
        icon      = "im.png",
        class     = {"Skype", "ViberPC", "Pidgin", "Telegram", "Xchat"},
        spawn     = 'Viber',
    },
    {
        name      = "q",
        icon      = "gear.png",
        class     = {"JavaFXSceneBuilder", "com-install4j-runtime", "Staruml", "com-mathworks-util-PostVMIni", "MATLAB"},
    },
    {
        name      = "t",
        icon      = "clock.png",
        class     = {"Pavucontrol", "Parcellite", "Blueman-manager"},
        init      = true,
        exclusive = false,
        volatile  = false,
    },
    {
        name      = "v",
        icon      = "apps.png",
        init      = true,
        exclusive = false,
        volatile  = false,
        fallback  = true,
    },
}

for k, v in pairs(mytags) do
    if (v.icon) then
        v.icon = beautiful.dirs.tags .. v.icon
    end
    v.screen = 1
    if (v.init      == nil) then v.init      = false    end
    if (v.volatile  == nil) then v.volatile  = true     end
    if (v.exclusive == nil) then v.exclusive = true     end
    if (v.key       == nil) then v.key       = v.name   end
end

tyrannical.tags = mytags
--}}}
--tyrannical.properties.intrusive = { "pinentry", "gtksu", }
--tyrannical.properties.floating = { "pinentry", "gtksu", }
--tyrannical.properties.ontop = { "Xephyr", }
--tyrannical.properties.placement = { kcalc = awful.placement.centered }
--tyrannical.properties.size_hints_honor = { xterm = false, URxvt = false }
--}}}
-- {{{ global mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function() mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
-- {{{ client mouse bindings
clientbuttons = awful.util.table.join(
    awful.button({        }, 1, function(c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)
-- }}}
-- {{{ clientkeys
clientkeys = awful.util.table.join(
    awful.key({ modkey, "Shift" }, "x",
    function(c)
        local text = ''
        if (c.class    ~= nil) then text=text..'\n'..markup.monospace(markup.g('class    '))..c.class    end
        if (c.instance ~= nil) then text=text..'\n'..markup.monospace(markup.b('instance '))..c.instance end
        if (c.role     ~= nil) then text=text..'\n'..markup.monospace(markup.y('role     '))..c.role     end
        if (c.window   ~= nil) then text=text..'\n'..markup.monospace(markup.m('Window   '))..c.window   end
        if (c.pid      ~= nil) then text=text..'\n'..markup.monospace(markup.m('PID      '))..c.pid      end
        naughty.notify({ icon='xorg', title='xprop', text=text, timeout=10 })
    end),
    awful.key({modkey,          }, "d",      function(c) c:kill() end),
    awful.key({modkey, "Control"}, "Return", function(c) c:swap(awful.client.getmaster()) end),
    awful.key({modkey,          }, "f",      function(c) c.fullscreen = not c.fullscreen; c:raise() end),
    awful.key({modkey, "Shift"  }, "f",      function(c )awful.client.floating.toggle(); c:geometry({x = 0, y = beautiful.main_wibox_height}) end),
    awful.key({modkey, "Control"}, "f",      function(c) c.ontop = not c.ontop end),
    awful.key({modkey, "Shift"  }, "n",      function(c) c.maximized = not c.maximized; c:raise() end),
    awful.key({modkey,          }, "n",      function(c) c.minimized = true end),
    awful.key({modkey, "Control"}, "r",      function(c) move_resize.callback(c, {modkey, "Control"}, "r") end)
)
-- }}}
-- {{{ globalkeys
globalkeys = awful.util.table.join(
--{{{ wibar, tray and menu
    awful.key({ modkey,           }, "s",
    function()
        awful.screen.connect_for_each_screen(function(s) s.mywibox.visible = not s.mywibox.visible end)
    end),
    awful.key({ modkey, "Shift"   }, "s",      systray.toggle),
    awful.key({ modkey, "Control" }, "s",      function() do_remind      = not do_remind;      setreminder()      end),
    awful.key({ modkey, "Mod1"    }, "s",      function() myweather_show = not myweather_show; myweather_update() end),
    awful.key({ modkey,           }, "Escape", function() mymainmenu:show({keygrabber=true})                      end),
    awful.key({ modkey, "Control" }, "Escape", menubar.show),
--}}}
-- {{{ layout and client
    awful.key({ modkey,           }, ".",   function() awful.client.focus.byidx( 1) end),
    awful.key({ modkey,           }, ",",   function() awful.client.focus.byidx(-1) end),
    awful.key({ modkey,           }, "Tab", function() awful.client.focus.history.previous(); if client.focus then client.focus:raise() end end),
    awful.key({ modkey,           }, "e",   function() awful.client.focus.history.previous(); if client.focus then client.focus:raise() end end),

    awful.key({ modkey, "Control" }, "n",   function() local c = awful.client.restore(); if c then client.focus = c; c:raise() end end),

    awful.key({ modkey, "Shift"   }, ".",         function() awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, ",",         function() awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, ".",         function() awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, ",",         function() awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u",         awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "BackSpace", function() awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "BackSpace", function() awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Control" }, "BackSpace",
    function()
        local name = awful.tag.selected().name
        --local layout = shifty.config.defaults.layout
        --if (shifty.config.tags[name].layout) then
            --layout = shifty.config.tags[name].layout
        --end
        --awful.layout.set(layout)
    end),
    awful.key({ modkey,           }, "backslash",
    function()
        local cl = awful.layout.get(mouse.screen)
        if (cl == als.tile.top) then
            awful.layout.set(als.tabular)
        else
            awful.layout.set(als.tile.top)
        end
    end),
-- }}}
-- {{{ Standard programs
    awful.key({ modkey,           }, "Return", function() awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "x",      awesome.restart),
-- }}}
-- {{{ tags
    awful.key({ modkey,           }, "h",     function() awful.tag.incmwfact( 0.05) end),
    awful.key({ modkey,           }, "l",     function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, "Shift"   }, "h",     function() awful.tag.incnmaster( 1, nil, true) end),
    awful.key({ modkey, "Shift"   }, "l",     function() awful.tag.incnmaster(-1, nil, true) end),
    awful.key({ modkey, "Control" }, "h",     function() awful.tag.incncol( 1, nil, true) end),
    awful.key({ modkey, "Control" }, "l",     function() awful.tag.incncol(-1, nil, true) end),
    awful.key({ modkey,           }, "Left",  awful.tag.viewprev),
    awful.key({ modkey,           }, "Right", awful.tag.viewnext),
    awful.key({ modkey,           }, "j",     awful.tag.viewprev),
    awful.key({ modkey,           }, "k",     awful.tag.viewnext),
    awful.key({ modkey,           }, "w",
    function()
        awful.tag.history.restore()
        if (awful.screen.focused().selected_tag == nil) then
            awful.tag.history.restore()
        end
    end),
-- }}}
-- {{{ Prompts
    awful.key({ modkey }, "r",
    function()
        awful.prompt.run(
        {
            prompt              = markup.bg("#88ffff", markup.d("Run: ")),
            font                = theme.font12,
            fg_cursor           = "black",
            bg_cursor           = "cyan",
            textbox             = awful.screen.focused().mypromptbox.widget,
            exe_callback        = awful.spawn.spawn,
            completion_callback = awful.completion.shell,
            history_path        = awful.util.get_cache_dir() .. "/history"
        })
    end),

    awful.key({ modkey }, "x",
    function()
        awful.prompt.run(
        {
            prompt       = markup.bg("#88ffff", markup.d("Run Lua code: ")),
            font         = theme.font12,
            fg_cursor    = "black",
            bg_cursor    = "cyan",
            textbox      = awful.screen.focused().mypromptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval"
        })
    end),
-- }}}
-- {{{ infoboxes
    awful.key({ modkey,           }, "z",
    function()
        local word = selection():gsub("^([^\n]*)\n.*", "%1"):gsub("^(%s+)", ""):gsub("<", "«"):gsub(">", "»")
        awful.spawn("goldendict '"..word.."'")
    end),
    awful.key({ modkey, "Control" }, "z", meteobox.toggle),
    awful.key({ modkey, "Shift"   }, "z", disksbox.toggle)
-- }}}
)
-- }}}
--{{{ tags keys для tyrannical
local function lookup_tag_by_name(s, n)
    for k, v in ipairs(s.tags) do
        if v.name == n then
            return v
        end
    end
end

local function lookup_tyrannical_tag_by_name(name, callback)
    for k, v in pairs(mytags) do
        if v.name == name then
            callback(v)
            break
        end
    end
end

local function tag_key(key, name)
    globalkeys = awful.util.table.join(
        globalkeys,
        awful.key({ modkey, }, key,
        function()
            local screen = awful.screen.focused()
            local tag = lookup_tag_by_name(screen, name)
            if tag then
                tag:view_only()
            else
                lookup_tyrannical_tag_by_name(name,
                function(v)
                    if (v.spawn) then
                        awful.tag.add(v.name, v)
                        awful.spawn(v.spawn)
                    end
                end)
            end
        end),
        awful.key({ modkey, "Control" }, key,
        function()
            local screen = awful.screen.focused()
            local tag = lookup_tag_by_name(screen, name)
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end),
        awful.key({ modkey, "Control", "Shift" }, name,
        function()
            if client.focus then
                local tag = lookup_tag_by_name(client.focus.screen, name)
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end),
        awful.key({ modkey, "Shift" }, key,
        function()
            if client.focus then
                local tag = lookup_tag_by_name(client.focus.screen, name)
                if not tag then
                    lookup_tyrannical_tag_by_name(name,
                    function(v)
                        tag = awful.tag.add(v.name, v)
                    end)
                end
                if tag then
                    client.focus:move_to_tag(tag)
                    --awful.tag.viewtoggle(tag)
                    tag:view_only()
                end
            end
        end)
    )
end
for k, v in pairs(mytags) do
    tag_key(v.key, v.name)
end
--}}}
--{{{ tabular_keys для эмуляции табов
local function tabular_keys(i)
    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, }, "F"..i, function() tabular.focus(i, mouse.screen) end))
end
for i= 1, 10 do
    tabular_keys(i)
end
--}}}
root.keys(globalkeys)
-- {{{ rules
local wm_class_remaps =
{
    ["^OpenOffice.*"] =         {newclass = "OpenOffice"},
    ["^com.github.liaonau.*"] = {newclass = "Pride"},
}

local function redecide_tag(c, pattern)
    --if (c.class:match(pattern)) then
        local newclass = wm_class_remaps[pattern].newclass
        local tag_name = wm_class_remaps[pattern].tag_name
        naughty.notify({ icon='xorg', title=c.class, text=newclass, timeout=10 })
        awful.spawn('xdotool set_window --class "'..newclass..'" '..c.window)
        if (tag_name == nil) then
            local stop = false
            for _, v in pairs(mytags) do
                if (v.class) then
                    for _, cls in pairs(v.class) do
                        if cls == newclass then
                            tag_name = v.name
                            wm_class_remaps[pattern].tag_name = tag_name
                            stop = true
                            break
                        end
                    end
                end
                if stop then
                    break
                end
            end
        end
        if (tag_name ~= nil) then
            local tag = lookup_tag_by_name(client.focus.screen, tag_name)
            if not tag then
                lookup_tyrannical_tag_by_name(tag_name, function(v) tag = awful.tag.add(v.name, v) end)
            end
            if tag then
                c:move_to_tag(tag)
                --awful.tag.history.restore(c.screen, 1)
                tag:view_only()
            end
        end
    --end
end

awful.rules.rules =
{
    {
        rule = {},
        properties =
        {
            border_width      = beautiful.border_width,
            border_color      = beautiful.border_normal,
            focus             = false,
            --focus             = awful.client.focus.filter,
            --raise             = true,
            keys              = clientkeys,
            buttons           = clientbuttons,
            screen            = awful.screen.preferred,
            placement         = awful.placement.no_overlap+awful.placement.no_offscreen,
            size_hints_honor  = false,
            titlebars_enabled = false,
        },
    },

    {
        rule_any = {type = {"dialog"}},
        properties = { ontop = true }
    },

    {
        rule = {class = "Zenity"},
        properties = { floating = true, above=true, intrusive=true, ontop=true, skip_taskbar=true }
    },

    {
        rule = {class = "GoldenDict"},
        properties = { intrusive=true,  skip_taskbar=true,  floating = true,  ontop = true }
    },
    {
        rule = {role = "GoldenDict_Main_Window"},
        properties = { intrusive=false, skip_taskbar=false, floating = false, ontop = false }
    },

    {
        rule_any = {name = {"Event Tester"}},
        properties = { intrusive = true, floating = true, ontop = true }
    },
}

for k, _ in pairs(wm_class_remaps) do
    table.insert(awful.rules.rules,
    {
        rule     = {class = k},
        callback = function(c) redecide_tag(c, k) end
    })
end
-- }}}
-- {{{ signals
--{{{ manage
client.connect_signal("manage",
function(c)
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)
--}}}
--{{{ titlebars
client.connect_signal("request::titlebars",
function(c)
    if (awful.titlebar(c).initialized) then
        return
    end
    local buttons = awful.util.table.join(
    awful.button({ }, 1,
    function()
        client.focus = c
        c:raise()
        awful.mouse.client.move(c)
    end),
    awful.button({ }, 3,
    function()
        client.focus = c
        c:raise()
        awful.mouse.client.resize(c)
    end)
    )

    awful.titlebar(c):setup
    {
        {
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        {
            {
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        {
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
    awful.titlebar(c).initialized = true
end)
--}}}
--{{{ focus
--sloppy focus
client.connect_signal("mouse::enter",
function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)
client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
--}}}
--{{{ floating clients with titlebars
client.connect_signal("property::floating",
function(c)
    if c.floating then
        c:emit_signal("request::titlebars")
        awful.titlebar.show(c)
    else
        awful.titlebar.hide(c)
    end
end)
--}}}
screen.connect_signal("property::geometry", set_wallpaper)
awesome.connect_signal("xkb::group_changed", update_keyboard_layout);

--local function reorder_tags(c)
    --naughty.notify({ title=c.class, text='', timeout=10 })
--end
--screen.connect_signal("client::tagged",   reorder_tags)
--screen.connect_signal("client::untagged", reorder_tags)
tabular.manage_reorder()
-- }}}
--{{{ initial calls
local function initial_calls()
    update_keyboard_layout()
end

initial_calls()
--}}}
-- {{{ suspend/resume hook
function suspend_hook()
end

function resume_hook()
    volume.update_all()
    myweather_update()
    update_brightness()
    nm_update_widget()
end
-- }}}
