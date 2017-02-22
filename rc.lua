io.stderr:write(os.date("%Y-%m-%d %T W: ") .. "Starting Awesome WM\n")
os.setlocale(os.getenv("LANG"))
-- {{{ imports
awful      = require('awful')
naughty    = require('naughty')
pulse      = require('pulse')

local awful      = awful
local naughty    = naughty
local pulse      = pulse

local lgi           = require('lgi')
local lpeg          = require('lpeg')
local beautiful     = require('beautiful')
local gears         = require('gears')
local wibox         = require('wibox')
local client        = require('client')
local tyrannical    = require('tyrannical')
local menubar       = require('menubar')
local meteo         = require('meteo')
local makeup        = require('makeup')
local infobox       = require('infobox')
local tabular       = require('tabular')
local freedesktop   = require('freedesktop')
local autofocus     = require('awful.autofocus')
local move_resize   = require('move_resize')
local versed        = require('versed')

-- remote последним
awful.remote = require('awful.remote')
-- }}}
-- {{{ variable definitions, auxillary functions
modkey = "Mod4"

tabular.styler = function(text, n, c)
    local bg = "#338833"
    local fg = "white"
    local font_size = "11"
    return '<span font_desc="'..font_size..'" background="'..bg..'" foreground="'..fg..'"> '..n..' </span>'..text
end

lpeg.locale(lpeg)

beautiful.init(awful.util.getdir("config") .. "/themes/theme.lua")

naughty.config.icon_dirs = beautiful.dirs.naughty_icons
--naughty.config.defaults.opacity=0.6

terminal = "urxvt"
editor   = os.getenv("EDITOR") or "gvim"

--pulse.step = os.getenv("VOLUME_STEP") or 4
pulse.step = 1

local als   = awful.layout.suit
als.tabular = tabular.layout
layouts =
{
    als.tile.top,
    als.fair,
    als.floating,
    als.tabular,
    --als.tile, als.tile.left, als.tile.bottom, als.fair.horizontal, als.spiral, als.spiral.dwindle, als.max, als.max.fullscreen, als.magnifier,
    als.tile, als.tile.left, als.tile.bottom, als.tile.top, als.fair.horizontal, als.spiral, als.spiral.dwindle, als.max,
    als.max.fullscreen, als.magnifier, als.corner.nw, als.corner.ne, als.corner.sw, als.corner.se,
}
-- }}}
-- {{{ helper functions
notify = function(title, text, timeout, icon)
    local timeout = timeout or 10
    local title   = title   or ''
    local text    = text    or ''
    naughty.notify({icon=icon, title=tostring(title), text=tostring(text), timeout=tonumber(timeout)})
end

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

awful.spawn.easy_async_with_shell = function(cmd, callback)
    return awful.spawn.easy_async({awful.util.shell, "-c", cmd or ""}, callback)
end

read_file =
{
    Async = function(path, callback)
        lgi.Gio.Async.start(function(f)
            local file = lgi.Gio.File.new_for_path(f)
            local str
            local info = file:async_query_info('standard::size', 'NONE')
            if (info) then
                str = ''
                local size = info:get_size()
                if (size ~= 0) then
                    local stream = file:async_read()
                    str = stream:async_read_bytes(size).data
                    stream:async_close()
                end
            end
            callback(str)
        end)(path)
    end,

    Sync = function(path, callback)
        local f = io.open(path)
        local s
        if (f) then
            s = f:read('*a')
            f:close()
        end
        callback(s)
    end,
}

local function lookup_tag_by_name(s, n)
    for k, v in ipairs(s.tags) do
        if v.name == n then
            return v
        end
    end
end

local function lookup_tyrannical_tag_by_name(name, callback)
    for k, v in pairs(tags) do
        if v.name == name then
            callback(v)
            break
        end
    end
end

local function reorder_tags(c, t)
    local screen_tags = awful.screen.focused().tags
    local new_tags    = {}
    local keys        = {}
    local overload    = 1
    for i, t in pairs(screen_tags) do
        local n   = t.name
        local idx = tag_indexes[n]
        if (not idx) then
            idx = #screen_tags + overload
            overload = overload + 1
        end
        table.insert(new_tags, idx, t)
        table.insert(keys, idx)
    end
    table.sort(keys)
    for k, v in pairs(keys) do
        local tag = new_tags[v]
        if (tag) then
            tag.index = k
        end
    end
end
-- }}}
-- {{{ menu
menubar.utils.terminal = terminal
menubar.myiconpath = '/usr/share/icons/gnome/32x32/actions/'
mainmenu = freedesktop.menu.build(
{
    theme = {width = 250},
    before =
    {
    },
    after =
    {
        { "restart",  awesome.restart, menubar.utils.lookup_icon(menubar.myiconpath..'gtk-refresh.png') },
        { "quit",     awesome.quit,    menubar.utils.lookup_icon(menubar.myiconpath..'gtk-quit.png')    },
        { "terminal", terminal,        menubar.utils.lookup_icon('terminal') },
    }
})
-- }}}
-- {{{ infoboxes
-- {{{ info wibox с df
local disksbox = infobox(
function(ib)
    local text
    awful.spawn.easy_async("di -h -f MpTBv -x squashfs,aufs,rootfs,overlay",
    function(stdout, stderr, exitreason, exitcode)
        text = stdout
        text = string.gsub(text, "(/[^%s]*)",  makeup.b('%1'))
        text = string.gsub(text, "(%d+%%)",    makeup.g("%1"))
        text = string.gsub(text, "([78]%d%%)", makeup.y("%1"))
        text = string.gsub(text, "(9%d%%)",    makeup.r("%1"))
        text = string.gsub(text, "(100%%)",    makeup.r("%1"))
        text = string.gsub(text, "(tmpfs)",    makeup("#777777", "%1"))
        text = text:sub(1, -2)
        text = makeup.desc("monospace 11", text)
        ib.text.markup = text
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
            text = string.gsub(text, "([^%d]"..today.day.."[^%d])", makeup.b("%1"))
        end
        text = makeup.desc('monospace 12', text)
        ib.text.markup = text
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
    local text = makeup.b(caption)
    if (diff + meteo.lag < 0) then
        text = text..makeup.r("\nданные устарели\n\n")
    else
        text = text..'\n'..
        makeup.m(weather.description)..'\n'..
        'температура, °C     '..makeup.m(string.format("%3s", weather.temp))..'\n'..
        'давление, мм рт.ст. '..makeup.c(string.format("%3s", weather.pressure))..'\n'..
        'влажность, %        '..makeup.c(string.format("%3s", weather.humidity))..'\n'..
        'ветер, м/с         '..makeup.c(string.format("%4s", weather.wind):gsub(',', '.'))..'\n'..
        'облачность, %       '..makeup.c(string.format("%3s", weather.clouds))..'\n'..
        '\n'
    end
    return text
end

meteobox = infobox(
function(ib)
    title = makeup.desc('monospace 14', '\nпогода\n')
    ib.title.markup = title

    local dir_meteo     = os.getenv("HOME").."/.local/share/meteo/"
    local file_forecast = dir_meteo..'forecast.json'
    local file_weather  = dir_meteo..'weather.json'

    local now   = ''
    local later = ''

    meteo.forecast(file_forecast,
    function(forecast)
        if (forecast) then
            later = later..get_text_weather(forecast[3])
            later = later..get_text_weather(forecast[5])
            later = later..get_text_weather(forecast[9])
            later = later..get_text_weather(forecast[17])
            later = later:sub(1, -2)
            later = makeup.desc('monospace 10', later)
        end
        ib.text.markup = now..later
    end)

    meteo.weather(file_weather,
    function(weather)
        if (weather) then
            ib.icon.image = beautiful.dirs.weather..weather.icon..'.png'
            now = makeup.desc('monospace 12', get_text_weather(weather, 'сейчас'))
        else
            ib.icon.image = beautiful.dirs.weather..'01d.png'
        end
        ib.text.markup = now..later
    end)
end
)
-- }}}
-- }}}
--{{{ tyrannical
tyrannical.settings.block_children_focus_stealing = true
tyrannical.settings.group_children = true
--tyrannical.settings.no_focus_stealing_out = true
tyrannical.settings.default_layout = als.tabular
--{{{ tyrannical tags
tags =
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
        spawn     = 'browser',
        --spawn     = 'google-chrome-stable',
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
        spawn     = 'dictionary',
        --no_focus_stealing_in = true,
    },
    {
        name      = "5",
        icon      = "mpv.png",
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
        icon      = "apps.png",
        init      = true,
        exclusive = false,
        volatile  = false,
        fallback  = true,
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
        class     = {"Pavucontrol", "Parcellite", "Blueman-manager", "Nm-connection-editor"},
        init      = true,
        exclusive = false,
        volatile  = false,
    },
    {
        name      = "v",
        icon      = "emul.png",
        layout    = als.fair,
        class     = {"Remote-viewer", "Xephyr"},
    },
}
tag_indexes = {}

for k, v in pairs(tags) do
    tag_indexes[v.name] = k

    if (v.icon) then
        v.icon = beautiful.dirs.tags .. v.icon
    end
    v.screen = 1
    if (v.init      == nil) then v.init      = false    end
    if (v.volatile  == nil) then v.volatile  = true     end
    if (v.exclusive == nil) then v.exclusive = true     end
    if (v.key       == nil) then v.key       = v.name   end
end

tyrannical.tags = tags
--}}}
--tyrannical.properties.intrusive = { "pinentry", "gtksu", }
--tyrannical.properties.floating  = { "pinentry", "gtksu", }
--tyrannical.properties.ontop     = { "Xephyr", }
--tyrannical.properties.placement = { kcalc = awful.placement.centered }
--tyrannical.properties.size_hints_honor = { xterm = false, URxvt = false }
--}}}
-- {{{ wibar
-- {{{ tray
tray                = wibox.container.constraint()
tray.systray        = wibox.widget.systray()
tray.widget         = tray.systray
tray.stupid_bug     = drawin({})
tray.widget.visible = true
tray.toggle = function()
    tray.systray.visible = not tray.systray.visible
    if (tray.systray.visible) then
        tray.widget = tray.systray
    else
        awesome.systray(tray.stupid_bug, 0, 0, 10, true, "#000000")
        tray.widget = nil
    end
end
-- }}}
-- {{{ separator
separator       = wibox.widget.imagebox()
separator.image = beautiful.wibox.separator
-- }}}
--{{{ bar
bar = {}
bar.introspect = function()
    local wids = {}
    for k, v in pairs(bar) do
        if (type(v) == 'table' and v.versed) then
            table.insert(wids, tostring(k))
        end
    end
    table.sort(wids)
    table.insert(wids, '')
    table.insert(wids, 'volume.inputs')
    table.insert(wids, 'volume.sinks')
    notify('bar', table.concat(wids, '\n'), 10, 'info')
end
bar.launcher = awful.widget.launcher({image = beautiful.awesome_icon, menu = mainmenu})
--}}}
--{{{ keyboard layout
bar.keyboard_layout = versed(
{
    widgets =
    {
        wibox.widget.imagebox()
    },

    update = function(w)
        local current = awesome.xkb_get_layout_group();
        if (current == 0) then
            w[1].image = beautiful.kbd.us
        else
            w[1].image = beautiful.kbd.ru
        end
    end,
})
--}}}
-- {{{ часы
bar.date = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.date
        w[3].image = beautiful.wibox.separator
        i.for_each(function(w) w:connect_signal("mouse::leave", datebox.hide) end)
    end,

    update = function(w)
        w[2].markup = os.date(makeup.b("%a %d %b ")..makeup.c("%H:%M"))
    end,

    timeout = 10,

    buttons = awful.util.table.join(
        awful.button({ }, 1, datebox.show),
        awful.button({ }, 4, function() datebox.state.offset = datebox.state.offset - 1; datebox.update() end),
        awful.button({ }, 5, function() datebox.state.offset = datebox.state.offset + 1; datebox.update() end)
    ),
})
-- }}}
-- {{{ батарея
bar.power = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.battery["missing"]
        w[2].image = beautiful.wibox.separator

        i.devices =
        {
            'battery_BAT0',
            'line_power_AC',
        }
        local service   = 'org.freedesktop.UPower'
        local path      = '/org/freedesktop/UPower/devices/'
        local interface = 'org.freedesktop.UPower.Device'
        local signal    = 'org.freedesktop.DBus.Properties'

        for _, v in pairs(i.devices) do
            dbus.add_match("system", "path='"..path..v.."',member='PropertiesChanged'")
            i[v] = {}
        end

        local transform =
        {
            Percentage = tonumber,
            Online     = function(s) return s:match('true') end,
            State      = tonumber,
        }
        local transform_length = 0
        for k, f in pairs(transform) do
            transform_length = transform_length + 1
        end
        local done_counter = 0
        for _, v in pairs(i.devices) do
            for k, f in pairs(transform) do
                awful.spawn.easy_async('qdbus --system '..service..' '..path..v..' '..interface..'.'..k,
                function(s, e, reason, code)
                    if code ~= 0 or reason ~= 'exit' then
                        return
                    end
                    i[v][k] = f(s)
                    done_counter = done_counter + 1
                    if (done_counter == (transform_length * #i.devices)) then
                        i.update()
                    end
                end)
           end
        end

        dbus.connect_signal(signal,
        function(...)
            local data = {...}
            if (data[2] ~= interface) then
                return
            end
            local device = data[1].path:match('([^/]+)$')
            awful.util.table.crush(i[device], data[3], true)
            i.update()
        end)

        for _, v in pairs(i.devices) do
            awful.spawn('qdbus --system '..service..' '..path..v..' '..interface..'.Refresh')
        end
    end,

    update = function(w, i)
        local bat = i['battery_BAT0']
        local ac  = i['line_power_AC']

        if (bat.State == 4) then -- заряжено
            i.hide()
        else
            local level = bat.Percentage or 0
            local suf = (ac.Online) and '_c' or ''
            if     (level == 100)                then w[1].image = beautiful.wibox.battery["100"..suf]
            elseif (level >  80 and level < 100) then w[1].image = beautiful.wibox.battery["080"..suf]
            elseif (level >  60 and level <= 80) then w[1].image = beautiful.wibox.battery["060"..suf]
            elseif (level >  40 and level <= 60) then w[1].image = beautiful.wibox.battery["040"..suf]
            elseif (level >  20 and level <= 40) then w[1].image = beautiful.wibox.battery["020"..suf]
            elseif (                level <= 20) then w[1].image = beautiful.wibox.battery["000"..suf]
            end
            local perc_color = "#88ff88"
            local warn_level = 35
            local crit_level = 15
            if (level > crit_level and level <= warn_level) then
                perc_color = "#ffff88"
            elseif (level <= crit_level) then
                perc_color = "#ff8888"
            end
            w[2].markup = makeup(perc_color, level..'%')
            i.show()
        end
    end,
})
-- }}}
-- {{{ mpd
bar.mpd = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox()
    },

    init = function(w, i)
        w[1].image  = beautiful.wibox.mpd.music
        local host  = "127.0.0.1"
        local port  = "6600"
        local query = "'command_list_begin\nstatus\ncurrentsong\ncommand_list_end\nclose'"
        i.cmd       = "echo "..query.."|nc '"..host.."' '"..port.."'"
        i.for_each(function(w) w:connect_signal("mouse::leave", datebox.hide) end)
    end,

    update = function(w, i)
        awful.spawn.easy_async_with_shell(i.cmd,
        function(stdout, stderr, reason, code)
            if code ~= 0 or reason ~= 'exit' then
                return
            end
            local state = {}
            for k, v in string.gmatch(stdout, "([%w]+):[%s]([^\n]+)\n") do
                state[k] = awful.util.escape(v)
            end
            if     state.state == "stop" then
                w[1].image = beautiful.wibox.mpd.stop
                w[2].text = ''
            elseif state.state == "pause" then
                w[1].image = beautiful.wibox.mpd.pause
                w[2].text = ''
            else
                w[1].image = beautiful.wibox.mpd.play
                local color_title = "#eeff88"
                if (state.random == "1") then
                    color_title = "#88ff88"
                end
                local artist = state.Artist
                local title  = state.Title
                if (not artist) then
                    if (not state.Name) then
                        artist = state.file and state.file:gsub(".*/(.*)$", "%1") or 'Unknown Artist'
                    else
                        artist = state.Name
                    end
                end
                if (not title) then
                    title = '?'
                end
                w[2].markup = makeup("#00bbbb", artist)..' '..makeup(color_title, title)
            end
        end)
    end,

    buttons = awful.util.table.join(
        awful.button({ }, 1, function() awful.spawn("mpc toggle") end),
        awful.button({ }, 3, function() awful.spawn("mpc random") end),
        awful.button({ }, 4, function() awful.spawn("mpc prev"  ) end),
        awful.button({ }, 5, function() awful.spawn("mpc next"  ) end)
    )
})
-- }}}
-- {{{ память, диски
bar.memory = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.textbox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.mem
        w[3].text  = ' '
        w[5].image = beautiful.wibox.separator
        i.for_each(function(w) w:connect_signal("mouse::leave", disksbox.hide) end)
    end,

    update = function(w)
        read_file.Sync('/proc/meminfo',
        function(s)
            local m = { buf = {}, swp = {} }
            for line in s:gmatch"[^\n]+" do
                for k, v in string.gmatch(line, "([%a]+):[%s]+([%d]+).+") do
                    if     k == "MemTotal"  then m.total = math.floor(v/1024)
                    elseif k == "MemFree"   then m.buf.f = math.floor(v/1024)
                    elseif k == "Buffers"   then m.buf.b = math.floor(v/1024)
                    elseif k == "Cached"    then m.buf.c = math.floor(v/1024)
                    elseif k == "SwapTotal" then m.swp.t = math.floor(v/1024)
                    elseif k == "SwapFree"  then m.swp.f = math.floor(v/1024)
                    end
                end
            end

            m.free  = m.buf.f + m.buf.b + m.buf.c
            m.inuse = m.total - m.free
            m.bcuse = m.total - m.buf.f
            m.usep  = math.floor(m.inuse / m.total * 100)
            m.swp.inuse = m.swp.t - m.swp.f
            m.swp.usep  = math.floor(m.swp.inuse / m.swp.t * 100)

            w[2].markup = makeup.b(m.usep..'%')
            w[4].markup = makeup.c(m.swp.usep..'%')
            local show_swp = (m.swp.usep ~= 0)
            w[3].visible = show_swp
            w[4].visible = show_swp
        end)
    end,

    timeout = 10,

    buttons = awful.util.table.join(
        awful.button({ }, 1, disksbox.show)
    ),
})
-- }}}
-- {{{ яркость
bar.brightness = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.brightness
        w[3].image = beautiful.wibox.separator
        i.brightness_path = 'intel_backlight'
        --i.brightness_path = 'acpi_video0'
        read_file.Sync('/sys/class/backlight/'..i.brightness_path..'/max_brightness',
        function(s)
            i.max_brightness = tonumber(s)
            i.update()
        end)
    end,

    update = function(w, i)
        read_file.Sync('/sys/class/backlight/'..i.brightness_path..'/brightness',
        function(s)
            local level = tonumber(s)
            i.set_visible(i.max_brightness and level ~= i.max_brightness)
            w[2].markup = makeup.b(string.format("%.0f", 100*level/i.max_brightness)..'%')
        end)
    end,

    timeout = 10,
})
-- }}}
-- {{{ температура процессора
bar.thermal_cpu = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.cpu
    end,

    update = function(w, i)
        read_file.Sync('/sys/class/thermal/thermal_zone0/temp',
        function(s)
            local t = math.ceil(tonumber(s)/1000)
            local therm_color = "#88ff88"
            if ( t >= 79 ) then
                therm_color = "#ff8888"
            elseif ( t >= 70 ) then
                therm_color = "#ffff88"
            end
            w[2].markup = makeup(therm_color, t..'°')
        end)
    end,

    timeout = 5,
})
-- }}}
--{{{ температура дисков
bar.thermal_hdd = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.hdd
        w[3].image = beautiful.wibox.separator
        i.disks =
        {
            ['/dev/sda'] = {40, 45},
            ['/dev/sdb'] = {50, 55},
        }
        i.color_makeup = function(dev, tab)
            local t = tab[dev]
            if (t == nil) then
                --t = makeup("#88ff88", '∅')
                t = ''
            elseif ( t >= i.disks[dev][2] ) then
                t = makeup("#ff8888", t..'°')
            elseif ( t >= i.disks[dev][1] ) then
                t = makeup("#ffff88", t..'°')
            else
                t = makeup("#88ff88", t..'°')
            end
            return t
        end
    end,

    update = function(w, i)
        awful.spawn.easy_async('ncat -w 1 localhost 7634',
        function(s, e, reason, code)
            if code ~= 0 or reason ~= 'exit' then
                return
            end
            local tab = {}
            for d, t in string.gmatch(s, "|([%/%a%d]+)|.-|([%d]+)|[CF]+|") do
                tab[d] = tonumber(t)
            end

            local ta = i.color_makeup('/dev/sda', tab, 40, 45)
            local tb = i.color_makeup('/dev/sdb', tab, 50, 55)
            w[2].markup = ta..' '..tb
        end)
    end,

    timeout = 10,
})
--}}}
-- {{{ напоминание
bar.remind = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.remind
        i.need = false
    end,

    update = function(w, i)
        read_file.Sync(awful.util.getdir('cache')..'remind',
        function(s)
            local text = s and awful.util.escape(s:gsub("\n$", "")) or ''
            w[2].markup = makeup.r(text)
            i.set_visible(text ~= '')
        end)
    end,

    timeout = 30,
})
-- }}}
-- {{{ погода
bar.weather = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[3].image = beautiful.wibox.separator
        i.for_each(function(w) w:connect_signal("mouse::leave", meteobox.hide) end)
        i.file = os.getenv("HOME").."/.local/share/meteo/weather.json"
    end,

    update = function(w, i)
        meteo.weather(i.file,
        function(weather)
            if (not weather) then
                i.hide()
            else
                local time = os.time()
                local diff = weather.time - time

                if (diff + meteo.lag < 0) then -- данные устарели
                    i.hide()
                else
                    w[2].markup = makeup.b(weather.temp..'°')
                    w[1].image  = beautiful.dirs.weather..weather.icon..'t.png'
                    i.show()
                end
            end
        end)
    end,

    timeout = 300,

    buttons = awful.util.table.join(
        awful.button({ }, 1, meteobox.show)
    )
})
-- }}}
-- {{{ звук
bar.volume = {}

bar.volume.sinks = setmetatable(
    pulse.sinks(
    {
        ladspa     = "ladspa_sink",
        speakers   = "alsa_output.pci-0000_00_1b.0.analog-stereo",
        headphones = "alsa_output.usb-Logitech_Logitech_Wireless_Headset_000D44D39CAA-00.analog-stereo",
        --ladspa     = "ladspa_normalized_sink",
    },
    function(s)
        return string.format(makeup.b("%s"), s)
    end
    ),
    {
        __call = function(t, c)
            local tab = {}
            t.ladspa.widgets[2].visible = false
            table.insert(tab, t.ladspa())
            table.insert(tab, t.speakers())
            table.insert(tab, separator)
            table.insert(tab, t.headphones())
            table.insert(tab, separator)
            return
            {
                layout = wibox.layout.fixed.horizontal(),
                table.unpack(tab)
            }
        end
    }
)

bar.volume.inputs = setmetatable(
    pulse.inputs(
    {
        mpv  = "mpv Media Player",
        vlc  = "VLC media player (LibVLC 2.1.4)",
        qemu = "qemu-system-x86_64",
        mpd  = "Music Player Daemon",
    },
    function(s)
        return string.format(makeup.b("%s"), s)
    end
    ),
    {
        __call = function(t, c)
            local tab = {}
            table.insert(tab, t.mpv())
            table.insert(tab, t.vlc())
            table.insert(tab, t.qemu())
            table.insert(tab, t.mpd())
            table.insert(tab, separator)
            return
            {
                layout = wibox.layout.fixed.horizontal(),
                table.unpack(tab)
            }
        end
    }
)

bar.volume.update_sinks  = function() pulse.update_sinks(bar.volume.sinks)   end
bar.volume.update_inputs = function() pulse.update_inputs(bar.volume.inputs) end
bar.volume.update        = function()
    bar.volume.update_sinks()
    bar.volume.update_inputs()
end
--}}}
--{{{ скорость сети
bar.netspeed = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        i.iface = 'wlan0'

        w[1].image = beautiful.wibox.net.down
        w[3].image = beautiful.wibox.net.up
        w[5].image = beautiful.wibox.separator
        i.up_color   = "#88ff88"
        i.down_color = "#ff8888"


        i.round_net = function(num)
            local n = tonumber(num)
            if ((n < 1) and (n > 0)) then
                return 1
            end
            return math.floor(n + 0.5)
        end

        local num   = lpeg.digit^1 / tonumber
        local alnum = lpeg.C(lpeg.R("AZ", "az", "09")^1)
        local sps   = lpeg.space^1
        -- this is so cool
        local stats = lpeg.space^0 * lpeg.Cg(alnum, "iface") * ":" *
        sps * lpeg.Cg(num, "r_bytes")      * sps * lpeg.Cg(num, "r_packets")   *
        sps * lpeg.Cg(num, "r_errs")       * sps * lpeg.Cg(num, "r_drop")      *
        sps * lpeg.Cg(num, "r_fifo")       * sps * lpeg.Cg(num, "r_frame")     *
        sps * lpeg.Cg(num, "r_compressed") * sps * lpeg.Cg(num, "r_multicast") *
        sps * lpeg.Cg(num, "t_bytes")      * sps * lpeg.Cg(num, "t_packets")   *
        sps * lpeg.Cg(num, "t_errs")       * sps * lpeg.Cg(num, "t_drop")      *
        sps * lpeg.Cg(num, "t_fifo")       * sps * lpeg.Cg(num, "t_colls")     *
        sps * lpeg.Cg(num, "t_carrier")    * sps * lpeg.Cg(num, "t_compressed")

        i.grammar = lpeg.Ct(stats)

        i.time = 0
        i.recv = 0
        i.send = 0
        i.unit = 1024
    end,

    update = function(w, i)
        read_file.Sync('/proc/net/dev',
        function(s)
            for line in string.gmatch(s, "([^\n]+)\n") do
                local t = lpeg.match(i.grammar, line)
                if (t and t.iface == i.iface) then
                    local now  = os.time()
                    local diff = now - i.time

                    local down = i.round_net((t.r_bytes - i.recv) / (diff * i.unit))
                    local up   = i.round_net((t.t_bytes - i.send) / (diff * i.unit))
                    w[2].markup = makeup(i.down_color, down)
                    w[4].markup = makeup(i.up_color, up)

                    i.time = now
                    i.recv = t.r_bytes
                    i.send = t.t_bytes
                    break
                end
            end
        end)
    end,

    timeout = 5,
})
--}}}
-- {{{ точка доступа
bar.wifi = versed(
{
    widgets =
    {
        wibox.widget.imagebox(),
        wibox.widget.textbox(),
        wibox.widget.textbox(),
        wibox.widget.imagebox(),
    },

    init = function(w, i)
        w[1].image = beautiful.wibox.net.nm["none"]
        w[4].image = beautiful.wibox.separator
        i.interface = 'wlan0'

        i.client = lgi.NM.Client.new()
        i.ssid_to_utf8 = function(ssid) return (ssid) and lgi.NM.utils_ssid_to_utf8(ssid:get_data()) or '' end

        i.get_ap_info = function()
            local dev = i.client:get_device_by_iface(i.interface)
            local ap  = dev:get_active_access_point()
            if (not ap) then
                return nil
            end
            local frequency = ap:get_frequency()
            local info =
            {
                path      = ap:get_path(),
                ssid      = i.ssid_to_utf8(ap:get_ssid()),
                bssid     = ap:get_bssid(),
                frequency = frequency,
                channel   = lgi.NM.utils_wifi_freq_to_channel(frequency),
                mode      = ap:get_mode(),
                strength  = ap:get_strength(),
            }
            return info
        end

        dbus.add_match("system", "interface='org.freedesktop.NetworkManager',member='StateChanged'")
        dbus.add_match("system", "interface='org.freedesktop.NetworkManager.AccessPoint',member='PropertiesChanged'")

        dbus.connect_signal("org.freedesktop.NetworkManager",
        function(...)
            local data = {...}
            i.info  = i.get_ap_info()
            i.state = data[2]
            i.update()
        end)

        dbus.connect_signal("org.freedesktop.NetworkManager.AccessPoint",
        function(...)
            local data   = {...}
            local sender = data[1]
            local props  = data[2]
            if (i.info and i.info.path == sender.path) then
                for k, v in pairs(props) do
                    if (k == "Strength") then
                        v = string.byte(v)
                    end
                    i.info[k:lower()] = v
                end
                i.update()
            end
        end)

        i.info  = i.get_ap_info()
        i.state = (i.client.state == 'CONNECTED_GLOBAL') and 70 or 0
    end,

    update = function(w, i)
        if (not i.info or i.state ~= 70) then
            w[1].image   = beautiful.wibox.net.nm["none"]
            w[2].visible = false
            w[3].visible = false
            bar.netspeed.set_visible(false)
        else
            bar.netspeed.set_visible(true)
            local strength = i.info.strength
            local color
            if     strength <  25 then color = "#ff8888"; w[1].image = beautiful.wibox.net.nm["00"]
            elseif strength <  50 then color = "#ffff88"; w[1].image = beautiful.wibox.net.nm["25"]
            elseif strength <  75 then color = "#88cc88"; w[1].image = beautiful.wibox.net.nm["50"]
            elseif strength < 100 then color = "#88ff88"; w[1].image = beautiful.wibox.net.nm["75"]
            else                       color = "#88ff88"; w[1].image = beautiful.wibox.net.nm["100"]
            end
            w[2].markup  = makeup.c(i.info.ssid)
            w[3].markup  = makeup(color, ' '..i.info.strength..'%')
            w[2].visible = true
            w[3].visible = true
        end
    end,

    buttons = awful.util.table.join(
        awful.button({ }, 1, function() awful.spawn.with_shell('nm-applet 2>/dev/null') end),
        awful.button({ }, 2, function() awful.spawn('nm-connection-editor 2>/dev/null') end),
        awful.button({ }, 3, function() awful.spawn('killall nm-applet')                end)
    ),
})
-- }}}
awful.screen.connect_for_each_screen(
function(s)
    set_wallpaper(s)
--{{{ promptbox, layoutbox, taglist, tasklist
    s.promptbox = awful.widget.prompt()

    s.layoutbox = awful.widget.layoutbox(s)
    s.layoutbox:buttons(awful.util.table.join(
        awful.button({ }, 1, function() awful.layout.inc(layouts,  1) end),
        awful.button({ }, 3, function() awful.layout.inc(layouts, -1) end),
        awful.button({ }, 4, function() awful.layout.inc(layouts,  1) end),
        awful.button({ }, 5, function() awful.layout.inc(layouts, -1) end)
    ))

    s.taglist = awful.widget.taglist(
        s,
        awful.widget.taglist.filter.all,
        awful.util.table.join(
            awful.button({ },        1, function(t) t:view_only() end),
            awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
            awful.button({ },        3, awful.tag.viewtoggle),
            awful.button({ modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end),
            awful.button({ },        4, function(t) awful.tag.viewnext(t.screen) end),
            awful.button({ },        5, function(t) awful.tag.viewprev(t.screen) end)
        )
    )

    s.tasklist = awful.widget.tasklist(
        s,
        awful.widget.tasklist.filter.currenttags,
        awful.util.table.join(
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
        ),
        nil,
        tabular.taskupdate
    )
--}}}
--{{{ создание панели
    s.box = awful.wibar({ position = "top", screen = s, height = beautiful.main_wibox_height })

    local whole_layout         = wibox.layout.flex.vertical()
    local top_layout           = wibox.layout.align.horizontal()
    local top_right_layout     = wibox.layout.fixed.horizontal()
    local top_left_layout      = wibox.layout.fixed.horizontal()
    local bottom_layout        = wibox.layout.align.horizontal()
    local bottom_right_layout  = wibox.layout.fixed.horizontal()
    local bottom_left_layout   = wibox.layout.fixed.horizontal()

    local left, middle, right, top, bottom = 1, 2, 3, 1, 3
    s.box:setup(
    {
        layout = whole_layout,
        [top] =
        {
            layout = top_layout,
            [left] =
            {
                layout = top_left_layout,
                bar.launcher,
                s.taglist,
            },
            [middle] = nil,
            [right] =
            {
                layout = top_right_layout,
                separator,
                bar.wifi(),
                bar.netspeed(),
                bar.memory(),
                bar.thermal_cpu(),
                bar.thermal_hdd(),
                bar.brightness(),
                bar.power(),
                bar.volume.inputs(),
                bar.volume.sinks(),
                bar.weather(),
                bar.date(),
                s.index == 1 and tray,
                s.layoutbox,
            },
        },
        [middle] = nil,
        [bottom] =
        {
            layout = bottom_layout,
            [left] =
            {
                layout = bottom_left_layout,
                bar.keyboard_layout(),
                s.promptbox,
            },
            [middle] = s.tasklist,
            [right] =
            {
                layout = bottom_right_layout,
                bar.remind(),
                bar.mpd(),
            },
        }
    })
--}}}
end)
-- }}}
-- {{{ global mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function() mainmenu:toggle() end),
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
        if (c.class    ~= nil) then text=text..'\n'..makeup.monospace(makeup.g('class    '))..c.class    end
        if (c.instance ~= nil) then text=text..'\n'..makeup.monospace(makeup.b('instance '))..c.instance end
        if (c.role     ~= nil) then text=text..'\n'..makeup.monospace(makeup.y('role     '))..c.role     end
        if (c.window   ~= nil) then text=text..'\n'..makeup.monospace(makeup.m('Window   '))..c.window   end
        if (c.pid      ~= nil) then text=text..'\n'..makeup.monospace(makeup.m('PID      '))..c.pid      end
        notify('xprop', text, 10, 'xorg')
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
        awful.screen.connect_for_each_screen(function(s) s.box.visible = not s.box.visible end)
    end),
    awful.key({ modkey, "Shift"   }, "s",      tray.toggle),
    awful.key({ modkey, "Mod1"    }, "s",      bar.remind.toggle),
    awful.key({ modkey, "Control" }, "s",      bar.weather.toggle),
    awful.key({ modkey,           }, "Escape", function() mainmenu:show({keygrabber=true}) end),
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
        local tag = awful.screen.focused().selected_tag
        if (tag) then
            local name   = tag.name
            local layout = tyrannical.settings.default_layout
            lookup_tyrannical_tag_by_name(name,
            function(v)
                if (v.layout) then
                    layout = v.layout
                end
            end)
            awful.layout.set(layout)
        end
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
        local state = awful.screen.focused().selected_tags
        awful.tag.history.restore()
        if (#awful.screen.focused().selected_tags == 0) then
            awful.screen.focused().selected_tags = state
        end
    end),
-- }}}
-- {{{ Prompts
    awful.key({ modkey }, "r",
    function()
        awful.prompt.run(
        {
            prompt              = makeup.bg("#88ffff", makeup.d("Run: ")),
            font                = theme.font12,
            fg_cursor           = "black",
            bg_cursor           = "cyan",
            textbox             = awful.screen.focused().promptbox.widget,
            exe_callback        = awful.spawn.spawn,
            completion_callback = awful.completion.shell,
            history_path        = awful.util.get_cache_dir() .. "/history"
        })
    end),

    awful.key({ modkey }, "x",
    function()
        awful.prompt.run(
        {
            prompt       = makeup.bg("#88ffff", makeup.d("Run Lua code: ")),
            font         = theme.font12,
            fg_cursor    = "black",
            bg_cursor    = "cyan",
            textbox      = awful.screen.focused().promptbox.widget,
            exe_callback = awful.util.eval,
            history_path = awful.util.get_cache_dir() .. "/history_eval"
        })
    end),
-- }}}
-- {{{ infoboxes
    --awful.key({ modkey,   "Mod1"}, "z", --"x"
    --function()
        --reminder!
    --end),
    awful.key({ modkey,           }, "z", datebox.toggle ),
    awful.key({ modkey, "Control" }, "z", meteobox.toggle),
    awful.key({ modkey, "Shift"   }, "z", disksbox.toggle)
-- }}}
)
-- }}}
--{{{ tags keys для tyrannical
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
for k, v in pairs(tags) do
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
        awful.spawn('xdotool set_window --class "'..newclass..'" '..c.window)
        if (tag_name == nil) then
            local stop = false
            for _, v in pairs(tags) do
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
awesome.connect_signal("xkb::group_changed", bar.keyboard_layout.update);

client.connect_signal("tagged",   reorder_tags)
client.connect_signal("untagged", reorder_tags)

tabular.manage_reorder()
-- }}}
-- {{{ suspend/resume hook
function suspend_hook()
end

function resume_hook()
    bar.volume.update()
    bar.wifi.update()
    bar.weather.update()
end
-- }}}
