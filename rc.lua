-- {{{ Variable definitions, imports
io.stderr:write("Starting Awesome WM\n")
os.setlocale(os.getenv("LANG"))

local awful  = require("awful")
require("awful.autofocus")
awful.rules  = require("awful.rules")
awful.common = require("awful.widget.common")
keygrabber   = require("awful.keygrabber")

vicious = require("vicious")
pulse   = require("pulse")
shifty  = require("shifty")
gears   = require("gears")
timer   = require("timer")
naughty = require("naughty")
naughty.config.icon_dirs = {
    awful.util.getdir("config").."/themes/naughty/",
    "/usr/share/pixmaps/",
    "/usr/share/icons/gnome/16x16/status/",
}
--naughty.config.defaults.opacity=0.6
local wibox     = require("wibox")
local beautiful = require("beautiful")
local weather   = require("weather")

local cosy      = require("cosy")
local markup    = cosy.markup
local infobox   = require("infobox")

local tabs      = require("tabs")
tabs.styler = function(text, n, c)
    local fg   = "black"
    local bg   = "lightcyan"
    bg = "#338833"
    fg = "white"
    local font = "11"
    --if (client.focus == c) then
        --bg = "cyan"
        --fg = "black"
    --end
return '<span font_desc="'..font..'" background="'..bg..'" foreground="'..fg..'"> '..n..' </span>'..text
end

local freedesktop   = {}
freedesktop.menu    = require('freedesktop.menu')
freedesktop.utils   = require('freedesktop.utils')
freedesktop.desktop = require('freedesktop.desktop')

-- remote последним
awful.remote = require("awful.remote")

-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor   = "emacsclient -d "..os.getenv("DISPLAY").." -a vim"

-- Default modkey.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local als = awful.layout.suit
als.tabs  = tabs.layout
layouts =
{
    als.tile.top,
--    als.tile,
--    als.tile.left,
--    als.tile.bottom,
    als.fair,
--    als.fair.horizontal,
    als.floating,
--    als.spiral,
--    als.spiral.dwindle,
--    als.max,
--    als.max.fullscreen,
--    als.magnifier,
    als.tabs,
}

-- java AWT/swing fix
awful.util.spawn("wmname LG3D")
-- }}}
-- {{{ shifty
shifty.config.defaults = {
    layout = als.tile.top,
    exclusive = true,
}

shifty.config.tags = {
    ["1"] = {
        position = 1, icon = "terminal.png",
        exclusive = true,
        init = true, layout = als.tabs,
    },
    ["2"] = {
        position = 2, icon = "ff.png", layout = als.tabs,
        --spawn = "firefox",
        spawn = "browser",
    },
    ["3"] = {
        position = 3, icon = "emacs.png",
        layout = als.tabs,
        spawn = editor .. " -c",
    },
    ["4"] = {
        position = 4, icon = "dict.png",
        spawn = "goldendict",
    },
    ["5"] = {
        position = 5, icon = "mplayer.png",
        layout = als.tabs,
    },
    ["6"] = {
        position = 6, icon = "deluge.png",
        spawn = "deluge-gtk",
    },
    ["7"] = {
        position = 7, icon = "audio.png",
        spawn = "cantata",
    },
    ["8"] = {
        position = 8, icon = "image.png",
    },
    ["9"] = {
        position = 9, icon = "evince.png",
    },
    ["10"] = {
        position = 10,icon = "fbreader.png",
        spawn = "fbreader",
    },
    ["fm"] = {
        position = 11, icon = "file.png",
        spawn = "spacefm",
    },
    ["htop"] = {
        position = 12, icon = "htop.png",
        spawn = terminal.." -name htopTerm -e htop",
    },
    ["emul"] = {
        position = 13, icon = "emul.png",
        layout = als.fair,
    },
    ["dev"] = {
        position = 14, icon = "gear.png",
        layout = als.tabs,
    },
    ["im"] = {
        position = 15, icon = "im.png",
        mwfact   = 0.7,
        nmaster  = 1,
        ncol     = 1,
        layout   = als.tile.left,
    },
    ["rss"] = {
        position = 17, icon = "rss.png",
        spawn = "liferea",
    },
    ["log"] = {
        position = 18, icon = "logview.png",
        spawn = terminal.." -cr black -rv -name logTerm -e /bin/sh -c '/usr/bin/journalctl -b -n 39 -f | ccze -A -m ansi'",
    },
    ["mw"] = {
        position = 20, icon = "openmw.png",
    },
}
for k, v in pairs(shifty.config.tags) do
    if (v.icon) then
        v.icon = awful.util.getdir("config").."/themes/tags/"..v.icon
    end
end

shifty.config.apps = {
    { match = { ["type"]  = {"dialog"} }, ontop = true, },
    {
      match = { instance = {"pavucontrol"}},
      float = true, geometry = {223, beautiful.main_wibox_height, 800, 730},
      ontop = true, skip_taskbar = true, intrusive = true,
    },

    { match = { class    = {"^URxvt$"                }, }, tag = "1",        },
    { match = { class    = {"^Firefox$"              }, }, tag = "2",        },
    { match = { class    = {"^luakit$"               }, }, tag = "2",        },
    { match = { class    = {"^Uzbl.*$"               }, }, tag = "2",        },
    { match = { class    = {"^Dwb$"                  }, }, tag = "2",        },
    { match = { class    = {"^Emacs$"                }, }, tag = "3",        },
    { match = { class    = {"^Gvim$"                 }, }, tag = "3",        },
    { match = { class    = {"^Goldendict$"           }, },            skip_taskbar = true,  intrusive = true,  },
    { match = { role     = {"GoldenDict_Main_Window" }, }, tag = "4", skip_taskbar = false, intrusive = false, },
    { match = { class    = {"^mpv$", "Vlc", "^Gupnp%-av%-cp$", "^org%-tinymediamanager*" },
              }, tag = "5",
    },
    { match = { class    = {"^plugin%-container$"    }, }, tag = "5",        },
    { match = { instance = {"^mpvTerm$"              }, }, tag = "5",        },
    { match = { class    = {"^Deluge$"               }, }, tag = "6",        },
    { match = { class    = {"^Cantata$"              }, }, tag = "7",        },
    { match = { class    = {"^Sxiv$"                 }, }, tag = "8",        },
    { match = { class    = {"^Geeqie$"               }, }, tag = "8",        },
    { match = { class    = {"^Zathura$"              }, }, tag = "9",        },
    { match = { class    = {"^Fbreader$"             }, }, tag = "10",       },
    { match = { class    = {"^Spacefm$"              }, }, tag = "fm",       },
    { match = { class    = {"^openmw", "Opencs"      }, }, tag = "mw",       },
    { match = { instance = {"^htopTerm$"             }, }, tag = "htop",     },
    { match = { instance = {"^logTerm$"              }, }, tag = "log",      },
    { match = { class    = {"^Wine$", "^qemu-.*", "^Spicec$", "^Xephyr$", "^org%-serviio%-console%-ServiioConsole$" },
              }, tag = "emul",
    },
    { match = { class    = {"^SDL_App$"              }, }, tag = "emul",     },
    { match = { class    = {"^Blueman%-.*"           }, }, tag = "emul",     },
    { match = { class    = {"^jetbrains%-idea%-.*"   }, }, tag = "dev",      },
    { match = { class    = {"^jetbrains%-android%-.*"}, }, tag = "dev",      },
    { match = { instance = {"^sun%-awt%-X11%-.*"     }, }, tag = "dev",      },
    { match = { class    = {"^Devhelp$"              }, }, tag = "dev",      },
    { match = { class    = {"^Liferea$"              }, }, tag = "rss",      },
    { match = { class    = {"^Skype$", "^Xchat$", "^Pidgin$", }
              }, tag = "im",
    },
    { match = { class    = {"^Pidgin$"}, role = {"^conversation$"}, }, nopopup = true, slave = false },
    { match = { class    = {"^Pidgin$"}, role = {"^buddy_list$"  }, }, slave = true },

    { match = { "" }, honorsizehints=false },
}

shifty.init()
-- }}}
-- {{{ Menu
freedesktop.utils.terminal      = terminal
freedesktop.utils.icon_theme    = 'gnome'   -- look inside /usr/share/icons/, default: nil (don't use icon theme)

menu_items = freedesktop.menu.new()
myawesomemenu = {
    { "manual",      terminal .. " -e man awesome",       freedesktop.utils.lookup_icon({ icon = 'help' })            },
    { "edit config", editor   .. " " .. awesome.conffile, freedesktop.utils.lookup_icon({ icon = 'package_settings' })},
    { "restart",     awesome.restart,                     freedesktop.utils.lookup_icon({ icon = 'gtk-refresh' })     },
    { "quit",        awesome.quit,                        freedesktop.utils.lookup_icon({ icon = 'gtk-quit' })        },
}
table.insert(menu_items, { "awesome",       myawesomemenu,  beautiful.awesome_icon })
table.insert(menu_items, { "open terminal", terminal,       freedesktop.utils.lookup_icon({icon = 'terminal'}) })

mymainmenu = awful.menu.new({ items = menu_items, theme = {width = 150 } })
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })
-- }}}
-- {{{{{{ info wiboxes
-- {{{ info wibox с df
local disks = infobox(
function ()
    local text = awful.util.pread("di -h -f MpTBv -x squashfs,aufs,rootfs")
    text = string.gsub(text, "(/[^%s]*)",  markup.b('%1'))
    text = string.gsub(text, "(%d+%%)",    markup.g("%1"))
    text = string.gsub(text, "([78]%d%%)", markup.y("%1"))
    text = string.gsub(text, "(9%d%%)",    markup.r("%1"))
    text = string.gsub(text, "(100%%)",    markup.r("%1"))
    text = string.gsub(text, "(tmpfs)",    markup("#777777", "%1"))
    text = text:sub(1, -2)
    text = markup.font_desc("monospace 11", text)
    return {text = text}
end, nil,
beautiful.wibox.disks, 'df'
)
-- }}}
-- {{{ info wibox с календарем
local date = infobox(
function (s)
    local today = os.date('*t')
    local m     = today.year * 12 + today.month + s.offset - 1
    local month = m % 12 + 1
    local year  = math.floor(m / 12)
    local text  = awful.util.pread("/usr/bin/cal " .. month .. ' ' .. year):sub(1, -2)
    if (s.offset == 0) then
        text = string.gsub(text, "([^%d]"..today.day.."[^%d])", markup.b("%1"))
    end
    text = markup.font_desc('monospace 12', text)
    return {text = text}
end,
{offset = 0},
beautiful.wibox.calendar, 'календарь'
)
date.on_hide = function(s)
    s.offset = 0
end
date.on_show = function(s)
    s.offset = 0
end
-- }}}
-- {{{ info wibox с погодой
local gismeteo = infobox(
function ()
    local text_weather = ''
    local icon_weather
    local gw = weather.get()
    for c = 1,4 do
        local gm = gw[c]
        if (c == 1 and gm['icon']) then
            icon_weather = awful.util.getdir('config')..'/themes/weather/'..gm['icon']
        end
        text_weather = text_weather ..
        markup.b(gm['day']..':\n')..
        gm['cloudiness']..', '..gm['precipitation']..'\n'..
        'температура:   '..gm['temperature']..'°\n'..
        'ощущается как: '..gm['heat']..'°\n'..
        'ветер:         '..gm['wind']..' м/с\n'..
        'давление:      '..gm['pressure']..' мм.рт.ст.\n'
    end
    text_weather = text_weather:sub(1, -2)
    text_weather = markup.font_desc('monospace 12', text_weather)
    return {
        text = text_weather,
        title = 'погода ' .. gw.date,
        icon = icon_weather,
    }
end
)
-- }}}
-- }}}}}}
-- {{{{{{ main wibox
mywibox = {}
mywibox.toggle = function () mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible end
-- {{{ tray
systray = wibox.widget.systray()
systray.stupid_bug = drawin({})
systray_layout = wibox.layout.constraint()
systray_layout:set_widget(systray)
systray.visible = true
systray.toggle  = function()
    systray.visible = not systray.visible
    if (systray.visible) then
        systray_layout:set_widget(systray)
    else
        -- To hide the systray (actually "to move the systray into the drawin called
        -- stupid_bug which is not visible and making sure it does not get moved back")
        awesome.systray(systray.stupid_bug, 0, 0, 10, true, "#000000")
        systray_layout:set_widget(nil)
    end
end
-- }}}
-- {{{ separator
separator = wibox.widget.imagebox()
separator:set_image(beautiful.wibox.separator)
-- }}}
-- {{{ taglist, +мышь
mytaglist = {}
shifty.taglist = mytaglist
mytaglist.buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, awful.client.toggletag),
    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)

)
-- }}}
-- {{{ tasklist, +мышь
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
awful.button({ }, 1, function (c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() then
            awful.tag.viewonly(c:tags()[1])
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end),
awful.button({ }, 3, function ()
    if instance then
        instance:hide()
        instance = nil
    else
        instance = awful.menu.clients({
            theme = { width = 250 }
        })
    end
end),
awful.button({ }, 4, function ()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
end),
awful.button({ }, 5, function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
end))
-- }}}
-- {{{ часы
mydate_icon = wibox.widget.imagebox()
mydate_icon:set_image(beautiful.wibox.date)

mydate = wibox.widget.textbox()
vicious.register(mydate, vicious.widgets.date, markup.b("%a %d %b %H:%M"), 10)

mydate:connect_signal(     "mouse::leave", date.hide )
mydate_icon:connect_signal("mouse::leave", date.hide )
local date_control = awful.util.table.join(
    awful.button({ }, 1, date.show),
    awful.button({ }, 4,
    function()
        date.state.offset = date.state.offset - 1
        date.update()
    end),
    awful.button({ }, 5,
    function()
        date.state.offset = date.state.offset + 1
        date.update()
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
    }
vss =
    {
        headphones = "alsa_output.usb-Logitech_Logitech_Wireless_Headset_000D44D39CAA-00-Headset.analog-stereo",
        speakers   = "alsa_output.pci-0000_00_1b.0.analog-stereo",
    }
volume =
    {
        sinks  = pulse.sinks({vss.headphones, vss.speakers}),
        inputs = pulse.inputs({vin.mpd, vin.mplayer, vin.flash_plugin, vin.radiotray, vin.qemu})
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
awful.util.spawn_with_shell('qdbus --system org.freedesktop.UPower 1>/dev/null')
dbus.add_match("system", "path='/org/freedesktop/UPower/devices/battery_BAT0',member='PropertiesChanged'")
dbus.add_match("system", "path='/org/freedesktop/UPower/devices/line_power_AC',member='PropertiesChanged'")

mybat_icon = cosy.widget.img()
mybat_icon.image = beautiful.wibox.battery["missing"]
mybat_separator = cosy.widget.img()
mybat_separator.image = beautiful.wibox.separator
mybat = cosy.widget.txt()
vicious.register(mybat, vicious.widgets.bat,
    function (widget, args)
        local sign, level = args[1], args[2]

        if     (sign == '↯') then -- заряжено
            mybat_icon.visible      = false
            mybat.visible           = false
            mybat_separator.visible = false
        else
            if     (sign == '⌁') then -- неизвестно
                mybat_icon.image = beautiful.wibox.battery["missing"]
            elseif (sign == '-' or sign == '+') then
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
        local warn_level = 40
        local crit_level = 20
        if (level > crit_level and level <= warn_level) then
            perc_color = "#ffff88"
        elseif (level <= crit_level) then
            perc_color = "#ff8888"
        end
        local text = markup(perc_color, level..'%')
        --if ( sign == '-' ) then sign = '–' end -- минус маленький U2013
        --local text = markup.y(sign) .. markup(perc_color, level..'%')
        return text
    end,
0, "BAT0")
dbus.connect_signal("org.freedesktop.DBus.Properties",
function(...)
    local data = {...}
    if (data[2] ~= "org.freedesktop.UPower.Device") then return end
    vicious.force({mybat})
end)
vicious.force({mybat})
-- }}}
-- {{{ rss liferea
myrss_icon       = cosy.widget.img()
myrss_icon.image = beautiful.wibox.rss
myrss_separator       = cosy.widget.img()
myrss_separator.image = beautiful.wibox.separator
myrss = cosy.widget.txt()

local update_rss = function(unread, new)
    myrss.text = markup("#aaaaff", unread)
    if ( unread == 0 ) then
        myrss_icon.visible      = false
        myrss.visible           = false
        myrss_separator.visible = false
    else
        myrss_icon.visible      = true
        myrss.visible           = true
        myrss_separator.visible = true
    end
end

dbus.add_match("session", "interface='org.gnome.feed.Reader',member='ItemsChanged'")
dbus.connect_signal("org.gnome.feed.Reader",
function(...)
    local data = {...}
    local sender = data[1]
    local state  = data[2]
    update_rss(state.Unread, state.New)
end)
-- can't wait first event after initializing awesome
update_rss(
   tonumber(awful.util.pread('qdbus org.gnome.feed.Reader /org/gnome/feed/Reader org.gnome.feed.Reader.GetUnreadItems 2>/dev/null')) or 0,
   tonumber(awful.util.pread('qdbus org.gnome.feed.Reader /org/gnome/feed/Reader org.gnome.feed.Reader.GetNewItems    2>/dev/null')) or 0
)
-- }}}
-- {{{ температура
my_cpu_icon = wibox.widget.imagebox()
my_cpu_icon:set_image(beautiful.wibox.cpu)
mythermal_cpu = wibox.widget.textbox()
vicious.register(mythermal_cpu, vicious.widgets.thermal,
function (widget, args)
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
vicious.register(mythermal_hdd, vicious.widgets.hddtemp,
function (widget, args)
    local t = args["{/dev/sda}"]
    if (t == nil) then return markup.y("?") end
    local therm_color = "#88ff88"
    if ( t >= 50 ) then
        therm_color = "#ff8888"
    elseif ( t >= 55 ) then
        therm_color = "#ffff88"
    end
    return markup(therm_color, t..'°')
end,
10, 7634)
-- }}}
-- {{{ память, диски
mymem_icon = wibox.widget.imagebox()
mymem_icon:set_image(beautiful.wibox.mem)

mymem = wibox.widget.textbox()
vicious.register(mymem, vicious.widgets.mem,
function (widget, args)
    local mem, swp = markup.b(args[1]..'%'), ''
    if (args[5] ~= 0) then swp = markup.c(' '..args[5]..'%') end
    return mem..swp
end,
10)

mymem:connect_signal(     "mouse::leave", disks.hide )
mymem_icon:connect_signal("mouse::leave", disks.hide )

local disks_control = awful.util.table.join(
    awful.button({ }, 1, disks.show)
)

mymem:buttons(disks_control)
mymem_icon:buttons(disks_control)
-- }}}
-- {{{ mpd
mympd_icon = wibox.widget.imagebox()
mympd_icon:set_image(beautiful.wibox.mpd.music)

mympd = wibox.widget.textbox()
vicious.register(mympd, vicious.widgets.mpd,
    function (widget, args)
        if args["{state}"] == "Stop" then
            mympd_icon:set_image(beautiful.wibox.mpd.stop)
            return ''
        elseif args["{state}"] == "Pause" then
            mympd_icon:set_image(beautiful.wibox.mpd.pause)
            return ''
        else
            local color_title = "#ff8888"
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
        awful.util.spawn("mpc toggle")
        -- no need in explicit forcing of vicious widget's update since using mpdcron
        --vicious.force({mympd})
    end),
    awful.button({ }, 3, function()
        awful.util.spawn("mpc random")
    end),
    awful.button({ }, 4, function()
        awful.util.spawn("mpc prev")
    end),
    awful.button({ }, 5, function()
        awful.util.spawn("mpc next")
    end)
)
mympd:buttons(mpd_control)
mympd_icon:buttons(mpd_control)
-- }}}
-- {{{ сеть
nm_widget = cosy.widget.txt()
nm_icon = wibox.widget.imagebox()
nm_icon:set_image(beautiful.wibox.net.nm["none"])

net_icon_up   = cosy.widget.img()
net_icon_down = cosy.widget.img()
net_icon_up.image   = beautiful.wibox.net.up
net_icon_down.image = beautiful.wibox.net.down
mynet = cosy.widget.txt()

local round_net = function(num)
    local n = tonumber(num)
    if ((n < 1) and (n > 0)) then return 1 end
    return math.floor(n + 0.5)
end
vicious.register(mynet, vicious.widgets.net,
function (widget, args)
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
        nm_icon:set_image(beautiful.wibox.net.nm["none"])
    else
        local s = tonumber(nm_ac_table.Strength)
        local c
        if s < 25 then
            c = "#ff8888" -- bad
            nm_icon:set_image(beautiful.wibox.net.nm["00"])
        elseif s < 50 then
            c = "#ffff88" -- quite bad
            nm_icon:set_image(beautiful.wibox.net.nm["25"])
        elseif s < 75 then
            c = "#88cc88" -- medium
            nm_icon:set_image(beautiful.wibox.net.nm["50"])
        elseif s < 100 then
            c = "#88ff88" -- good
            nm_icon:set_image(beautiful.wibox.net.nm["75"])
        else
            c = "#88ff88" -- good
            nm_icon:set_image(beautiful.wibox.net.nm["100"])
        end
        net_icon_up.visible   = true
        net_icon_down.visible = true
        mynet.visible         = true
        nm_widget.text = markup.c(nm_ac_table.Ssid)..' '..markup(c, nm_ac_table.Strength..'%')
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
myrem      = cosy.widget.txt()
myrem_icon = cosy.widget.img()
myrem_icon.image = beautiful.wibox.rem
do_remind = false
local setreminder = function()
    if (not do_remind) then
        myrem_icon.visible = false
        myrem.visible      = false
        return
    end
    local text = ''
    local file = io.open(os.getenv("HOME")..'/tmp/remind')
    if file then
        text = file:read("*a")
        text = text:gsub("\n$", "")
        io.close(file)
    end
    myrem:set_markup(markup.r(text))
    if (text == '') then
        myrem_icon.visible = false
        myrem.visible      = false
    else
        myrem_icon.visible = true
        myrem.visible      = true
    end
end
myrem_timer = timer({timeout = 10})
myrem_timer:connect_signal("timeout", setreminder)
setreminder()
myrem_timer:start()
-- }}}
mypromptbox = {}
mylayoutbox = {}
for s = 1, screen.count() do
-- set wallpaper
gears.wallpaper.maximized(beautiful.wallpaper, s, true)
-- {{{ promptbox, layoutbox, tablist tasklist
mypromptbox[s] = awful.widget.prompt()
mylayoutbox[s] = awful.widget.layoutbox(s)
mylayoutbox[s]:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc(layouts,  1) end),
    awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 4, function () awful.layout.inc(layouts,  1) end),
    awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
))
mytaglist[s]  = awful.widget.taglist( s, awful.widget.taglist.filter.all,          mytaglist.buttons)
--mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)
mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons, nil, tabs.taskupdate)
-- }}}
-- {{{ создание панели
mywibox[s] = awful.wibox({ position = "top", screen = s, height = beautiful.main_wibox_height })

local layout              = wibox.layout.flex.vertical()
local top_layout          = wibox.layout.align.horizontal()
local top_right_layout    = wibox.layout.fixed.horizontal()
local top_left_layout     = wibox.layout.fixed.horizontal()
local bottom_layout       = wibox.layout.align.horizontal()
local bottom_right_layout = wibox.layout.fixed.horizontal()
local bottom_left_layout  = wibox.layout.fixed.horizontal()

local mywidgets = {
    [top_layout] = {-- верх
        [top_left_layout] = {-- верх слева
            mylauncher,
            mytaglist[s],
        },
        [top_right_layout] = {-- верх справа
        separator,
        nm_icon, net_icon_down, mynet, net_icon_up, nm_widget, separator,
        mymem_icon, mymem, separator,
        myrss_icon, myrss, myrss_separator,
        my_cpu_icon, mythermal_cpu, mythermal_hdd_icon, mythermal_hdd, separator,
        mybat_icon, mybat, mybat_separator,
        volume.inputs[vin.qemu].imagebox,      volume.inputs[vin.qemu].textbox,          volume.inputs[vin.radiotray].imagebox,
        volume.inputs[vin.radiotray].textbox,  volume.inputs[vin.flash_plugin].imagebox, volume.inputs[vin.flash_plugin].textbox,
        volume.inputs[vin.mplayer].imagebox,   volume.inputs[vin.mplayer].textbox,       volume.inputs[vin.mpd].imagebox,
        volume.inputs[vin.mpd].textbox,        separator,
        volume.sinks[vss.speakers].imagebox,   volume.sinks[vss.speakers].textbox,   separator,
        volume.sinks[vss.headphones].imagebox, volume.sinks[vss.headphones].textbox, separator,
        mydate_icon, mydate, separator,
        s == 1 and systray_layout or nil,
        mylayoutbox[s],
        },
    },
    [bottom_layout] = {-- низ
        [bottom_left_layout] = {-- низ слева
            mypromptbox[s],
            mytasklist[s],
        },
        [bottom_right_layout] = {-- низ справа
            myrem_icon, myrem,
            mympd_icon, mympd,
        },
    },
}
for _, a in pairs(mywidgets) do
    for k, b in pairs(a) do
        for _, v in pairs(b) do
            if (v) then k:add(v) end
        end
    end
end
top_layout:set_right(top_right_layout)
top_layout:set_left(top_left_layout)

bottom_layout:set_middle(bottom_left_layout)
bottom_layout:set_right(bottom_right_layout)

layout:add(top_layout)
layout:add(bottom_layout)
mywibox[s]:set_widget(layout)
-- }}}
end
-- }}}}}} Wibox
-- {{{ global mouse buttons
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:show() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}
-- {{{ clientbuttons
clientbuttons = awful.util.table.join(
    awful.button({        }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)
-- }}}
-- {{{ clientkeys
clientkeys = awful.util.table.join(
    awful.key({ modkey, "Shift"   }, "x",
    function (c)
        local text = markup.monospace(markup.g('class    '))..c.class
        if (c.instance ~= nil) then text=text..'\n'..markup.monospace(markup.b('instance '))..c.instance end
        if (c.role ~= nil) then text=text..'\n'..markup.monospace(markup.y('role     '))..c.role end
        naughty.notify({title='xprop', text=text, timeout=10})
    end),
    awful.key({ modkey,           }, "f",         function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "d",         function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "backslash", awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return",    function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "t",         function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
    function (c)
        -- The client currently has the input focus, so it cannot be
        -- minimized, since minimized clients can't have the focus.
        c.minimized = true
    end),
    awful.key({ modkey,           }, "m",
    function (c)
        c.maximized_horizontal = not c.maximized_horizontal
        c.maximized_vertical   = not c.maximized_vertical
    end)
)
shifty.config.clientkeys = clientkeys
-- }}}
-- {{{ rules
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus        = true,
            keys         = clientkeys,
            buttons      = clientbuttons
        }
    },
}
-- }}}
-- {{{{{{ globalkeys
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "s",      mywibox.toggle),
    awful.key({ modkey, "Shift"   }, "s",      systray.toggle),
    awful.key({ modkey, "Control" }, "s",      function () do_remind = not do_remind; setreminder() end),
    awful.key({ modkey, "Control" }, "k",      function () awful.util.spawn("xkill") end),
    awful.key({ modkey,           }, "Escape", function () mymainmenu:show({keygrabber=true}) end),
-- {{{ layout and client
    awful.key({ modkey,           }, ".",
    function ()
        awful.client.focus.byidx( 1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, ",",
    function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "Tab",
    function ()
        awful.client.focus.history.previous()
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey,           }, "e",
    function ()
        awful.client.focus.history.previous()
        if client.focus then client.focus:raise() end
    end),
    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    awful.key({ modkey, "Shift"   }, ".",         function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, ",",         function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, ".",         function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, ",",         function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u",         awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "BackSpace", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "BackSpace", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Control" }, "BackSpace", function () awful.layout.set(shifty.config.tags[awful.tag.selected().name].layout) end),
    awful.key({ modkey,           }, "backslash",
    function ()
        local cl = awful.layout.get(mouse.screen)
        if (cl == als.tile.top) then
            awful.layout.set(als.tabs)
        else
            awful.layout.set(als.tile.top)
        end
    end),
-- }}}
-- {{{ Standard programs
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control"          }, "r",      awesome.restart),
    awful.key({ modkey, "Shift", "Control" }, "r",      awesome.quit),
-- }}}
-- {{{ tags
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05) end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)   end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)   end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)      end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)      end),
    awful.key({ modkey,           }, "Left",  awful.tag.viewprev),
    awful.key({ modkey,           }, "Right", awful.tag.viewnext),
    awful.key({ modkey,           }, "j",     awful.tag.viewprev),
    awful.key({ modkey,           }, "k",     awful.tag.viewnext),
    awful.key({ modkey,           }, "w",     awful.tag.history.restore),
-- }}}
-- {{{ Prompts
    awful.key({ modkey }, "r",
    function ()
        awful.prompt.run(
        {
            prompt    = markup.bg("#88ffff", markup.d("Run: ")),
            font      = theme.font12,
            fg_cursor = "black",
            bg_cursor = "cyan",
        },
        mypromptbox[mouse.screen].widget,
        awful.util.spawn, awful.completion.shell,
        awful.util.getdir("cache") .. "/history")
    end),

    awful.key({ modkey }, "x",
    function ()
        awful.prompt.run(
        {
            prompt    = markup.bg("#88ffff", markup.d("Run Lua code: ")),
            font      = theme.font12,
            fg_cursor = "black",
            bg_cursor = "cyan",
        },
        mypromptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
    end),
-- }}}
-- {{{ infoboxes
    awful.key({ modkey, }, "z",
    function()
        local word = selection():gsub("^([^\n]*)\n.*", "%1"):gsub("^(%s+)", ""):gsub("<", "«"):gsub(">", "»")
        awful.util.spawn("goldendict '"..word.."'")
    end),
    awful.key({ modkey, }, "g", gismeteo.toggle)
-- }}}
)
-- {{{ tag_keys для shifty
local function tags_keys(i, p)
    globalkeys = awful.util.table.join(
        globalkeys,
        awful.key({ modkey, }, i,
        function ()
            local t = awful.tag.viewonly(shifty.getpos(p))
        end),
        awful.key({ modkey, "Control" }, i,
        function ()
            local t = shifty.getpos(p)
            t.selected = not t.selected
        end),
        awful.key({ modkey, "Control", "Shift" }, i,
        function ()
            if client.focus then
                awful.client.toggletag(shifty.getpos(p))
            end
        end),
        -- move clients to other tags
        awful.key({ modkey, "Shift" }, i,
        function ()
            if client.focus then
                local t = shifty.getpos(p)
                awful.client.movetotag(t)
                awful.tag.viewonly(t)
            end
        end)
    )
end
for i=1,9 do
    tags_keys(i, i)
end
tags_keys(0  , 10)
tags_keys("b", 11)
tags_keys("i", 12)
tags_keys("a", 13)
tags_keys("q", 14)
tags_keys("p", 15)
tags_keys("c", 17)
tags_keys("v", 18)
tags_keys("o", 20)
-- }}}
--{{{ tabs_keys для эмуляции табов
local function tabs_keys(i)
    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, }, "F"..i, function() tabs.focus(i, mouse.screen) end))
end
for i=1,12 do
    tabs_keys(i)
end
--}}}
root.keys(globalkeys)
shifty.config.globalkeys = globalkeys
-- }}}}}}
-- {{{ Signals
-- Signal function to execute when a new client appears.
--client.connect_signal("manage",  function(c, startup) end)
--client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
--client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
tabs.manage_reorder()
-- }}}
-- vim: foldmethod=marker:filetype=lua
