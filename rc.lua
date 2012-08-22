-- {{{ Variable definitions, imports
os.setlocale("ru_RU.UTF8")
require("awful")
require("awful.autofocus")
require("awful.rules")
require("awful.remote")

require("beautiful")

require("vicious")
require("naughty")

-- меню
require('freedesktop.menu')
require('freedesktop.utils')
require('freedesktop.desktop')
-- погода
require("weather")

require("shifty")

-- Themes define colours, icons, and wallpapers
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init(awful.util.getdir("config") .. "/themes/theme.lua")

-- раскладка
require("kbdd")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local als = awful.layout.suit
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

tags_iconsdir = awful.util.getdir("config") .. "/themes/tags/"
-- }}}

--{{{ shifty
shifty.config.defaults = {
    layout = als.tile.top,
    exclusive = true,
--    run = function(tag) naughty.notify({ text = tag.name }) end,
}

shifty.config.tags = {
    ["1"] = {
        position = 1, icon = tags_iconsdir.."terminal.png",
        init = true, exclusive = false, layout = als.tabs,
    },
    ["2"] = {
        position = 2, icon = tags_iconsdir.."ff.png",
        spawn = "firefox",
    },
    ["3"] = {
        position = 3, icon = tags_iconsdir.."im.png",
        spawn = "pidgin",
    },
    ["4"] = {
        position = 4, icon = tags_iconsdir.."mplayer.png",
        spawn = "urxvt -name mplayer_term", layout = als.tabs,
    },
    ["5"] = {
        position = 5, icon = tags_iconsdir.."deluge.png",
        spawn = "deluge-gtk",
    },
    ["6"] = {
        position = 6, icon = tags_iconsdir.."gvim.png",
        spawn = "gvim --servername GVIM",
    },
    ["7"] = {
        position = 7, icon = tags_iconsdir.."dict.png",
        spawn = "stardict",
    },
    ["8"] = {
        position = 8, icon = tags_iconsdir.."geeqie.png",
    },
    ["9"] = {
        position = 9, icon = tags_iconsdir.."evince.png",
    },
    ["10"] = {
        position = 10,icon = tags_iconsdir.."fbreader.png",
        spawn = "fbreader",
    },
    ["wine"] = {
        position = 11, icon = tags_iconsdir.."wine.png",
    },
    ["lk"] = {
        position = 12, icon = tags_iconsdir.."browser.png",
        spawn = "browser",
    },
    ["htop"] = {
        position = 13, icon = tags_iconsdir.."htop.png", 
        spawn = "urxvt -name htopTerm -e htop",
    },
    ["mpd"] = {
        position = 14, icon = tags_iconsdir.."audio.png",
        spawn = "urxvt -name ncmpcTerm -e ncmpc",
    },
}

shifty.config.apps = {
    { match = {["type"] = "dialog"  }, ontop    = true, },
    { match = {"urxvt"              }, tag      = "1",  },
    { match = {"[Ff]irefox"         }, tag      = "2",  },
    { match = {"[Ss]kype", "[Xx]chat", "[Pp]idgin"      }, tag  = "3",  },
    { match = {"^conversation$"     }, nopopup  = true, },
    { match = {"^[Mm][Pp]layer", "[Vv]lc"               }, tag  = "4",  },
    { match = {"Deluge"             }, tag      = "5",  },
    { match = {"^[Gg]vim$"          }, tag      = "6",  },
    { match = {"^[Ss]tardict$"      }, tag      = "7",  },
    { match = {"geeqie", "[Gg]imp"  }, tag      = "8",  },
    { match = {"gimp%-image%-window"}, slave    = true, },
    { match = {"[Ee]vince"          }, tag      = "9",  },
    { match = {"[Ff][Bb]reader"     }, tag      = "10", },
    { match = {"^[Ll]uakit"         }, tag      = "lk", },
--    { match = {"[Pp]lugin-container"}, tag      = "ff", float = true, fullscreen = true, },
    { match = {"htopTerm"           }, tag      = "htop",   },
    { match = {"ncmpcTerm"          }, tag      = "mpd",    },
    { match = {"[Ww]ine"            }, tag      = "wine",   },
    { match = { ""                  }, honorsizehints=false },
}

shifty.init()
--}}}

-- {{{ Menu
freedesktop.utils.terminal      = terminal  -- default: "xterm"
freedesktop.utils.icon_theme    = 'gnome'   -- look inside /usr/share/icons/, default: nil (don't use icon theme)

menu_items = freedesktop.menu.new()
myawesomemenu = {
    { "manual",     terminal .. " -e man awesome",          freedesktop.utils.lookup_icon({ icon = 'help' })                },
    { "edit config",editor_cmd .. " " .. awesome.conffile,  freedesktop.utils.lookup_icon({ icon = 'package_settings' })    },
    { "restart",    awesome.restart,                        freedesktop.utils.lookup_icon({ icon = 'gtk-refresh' })         },
    { "quit",       awesome.quit,                           freedesktop.utils.lookup_icon({ icon = 'gtk-quit' })            },
}
table.insert(menu_items, { "awesome",       myawesomemenu,  beautiful.awesome_icon })
table.insert(menu_items, { "open terminal", terminal,       freedesktop.utils.lookup_icon({icon = 'terminal'}) })

mymainmenu = awful.menu.new({ items = menu_items, width = 150 })
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

--for s = 1, screen.count() do
--    freedesktop.desktop.add_applications_icons(   {screen = s, showlabels = true})
--    freedesktop.desktop.add_dirs_and_files_icons( {screen = s, showlabels = true})
--end
-- }}}

--{{{ Naughty
--{{{ перевод
local sdcv = nil

local function remove_sdcv()
    naughty.destroy(sdcv)
    sdcv = nil
end

function add_sdcv(expr)
    if (sdcv and sdcv.box.screen) then
        remove_sdcv()
    else
        if (sdcv) then
            remove_sdcv()
        end
        if (expr) then
            sdcv_word = awful.util.pread("slovnik " .. expr)
        else
            sdcv_word = awful.util.pread("slovnik")
        end
        sdcv_word = string.gsub(sdcv_word, "Найдено (%d*) слов, похожих на ([^\n]*)\.\n", " <span fgcolor='#00bb00'>%2</span>: %1\n")
        sdcv_word = string.gsub(sdcv_word, "Ничего похожего на (.*), извините .*", " <span fgcolor='#00bb00'>%1</span>: не найдено\n")
        sdcv_word = string.gsub(sdcv_word, "\n([^ ]*)\n", "\n<span fgcolor='#00bbbb'>%1</span>\n")
        sdcv_word = string.gsub(sdcv_word, "\n        ", "\n  ")
        sdcv = naughty.notify({
            text = string.format( "<span font_desc='monospace 12'>%s</span>", sdcv_word ),
            title='перевод',
            timeout=0,
        })
    end
end
--}}}

--{{{ календарь
local calendar = nil
local calendar_offset = 0

function remove_calendar()
    if calendar ~= nil then
        naughty.destroy(calendar)
        calendar = nil
        calendar_offset = 0
    end
end

function add_calendar(inc_offset)
    if (not inc_offset) then inc_offset = 0 end
    local save_offset = calendar_offset
    remove_calendar()
    calendar_offset = save_offset + inc_offset
    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + calendar_offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = string.gsub(awful.util.pread("cal -m "..datespec), "^%s*(.-)%s*$", "%1")
    calendar = naughty.notify({
        text = string.format( "<span font_desc='monospace 12'>%s</span>", cal ),
        title='календарь',
        icon=awful.util.getdir('config')..'/themes/icons/time.png',
        timeout=0,
    })
end
--}}}

--{{{ диск
local disks_free = nil

local function remove_disks_free()
    naughty.destroy(disks_free)
    disks_free = nil
end

local function remove_check_disks_free()
    if (disks_free ~= nil) then remove_disks_free() end
end

function add_disks_free()
    if (disks_free and disks_free.box.screen) then
        remove_disks_free()
    else
        if (disks_free) then
            remove_disks_free()
        end
        local disks_text = awful.util.pread("di -h -f MpTBv -x squashfs,aufs,rootfs")
        disks_text = string.gsub(disks_text, "(/[^%s]*)", "<span fgcolor='#8888ff'>%1</span>")
        disks_text = string.gsub(disks_text, "(%d+%%)", "<span fgcolor='#88ff88'>%1</span>")
        disks_text = string.gsub(disks_text, "([78]%d%%)", "<span fgcolor='#ffff88'>%1</span>")
        disks_text = string.gsub(disks_text, "(9%d%%)", "<span fgcolor='#ff8888'>%1</span>")
        disks_text = string.gsub(disks_text, "(100%%)", "<span fgcolor='#ff8888'>%1</span>")
        disks_text = string.gsub(disks_text, "(tmpfs)", "<span fgcolor='#777777'>%1</span>")
        disks_free = naughty.notify({
            text = string.format( "<span font_desc='monospace 11'>%s</span>", disks_text ),
            title='df',
            icon=awful.util.getdir('config')..'/themes/icons/drive.png',
            timeout=0,
        })
    end
end
--}}}

--{{{ deluge
local deluge_status = nil

local function remove_deluge()
    naughty.destroy(deluge_status)
    deluge_status = nil
end

local function remove_check_deluge()
    if (deluge_status ~= nil) then remove_deluge() end
end

function add_deluge()
    if (deluge_status and deluge_status.box.screen) then
        remove_deluge()
    else
        if (deluge_status) then
            remove_deluge()
        end
        local deluge_status_text = awful.util.pread("deluge_status.py")
        deluge_status_text = string.gsub(deluge_status_text, "^([^\n]+)", "<span fgcolor='#8888ff'>%1</span>")
        deluge_status_text = string.gsub(deluge_status_text, "\n\n([^\n]+)", "\n\n<span fgcolor='#8888ff'>%1</span>")
        deluge_status_text = string.gsub(deluge_status_text, "\n(Downloading)\n", "\n<span fgcolor='#88ff88'>%1</span>\n")
        deluge_status_text = string.gsub(deluge_status_text, "\n(Seeding)\n", "\n<span fgcolor='#88ff88'>%1</span>\n")
        deluge_status_text = string.gsub(deluge_status_text, "\n(Paused)\n", "\n<span fgcolor='#777777'>%1</span>\n")
        deluge_status_text = string.gsub(deluge_status_text, "\n(Queued)\n", "\n<span fgcolor='#ffff88'>%1</span>\n")
        deluge_status_text = string.gsub(deluge_status_text, "\n(Unlnown)\n", "\n<span fgcolor='#ff8888'>%1</span>\n")
        deluge_status_text = string.gsub(deluge_status_text, "(ETA:)([^\n]+)\n", "%1<span fgcolor='#ff8888'>%2</span>\n")
        deluge_status_text = string.gsub(deluge_status_text, " (%d+.%d*%%)", " <span fgcolor='#88ffff'>%1</span>")
        deluge_status_text = string.gsub(deluge_status_text, "&", "&amp;")
        deluge_status = naughty.notify({
            text = string.format( "<span font_desc='monospace 10'>%s</span>", deluge_status_text ),
            title='deluge',
            icon= image(beautiful.wibox_deluge),
            timeout=0,
        })
    end
end
--}}}

--{{{ погода
local weather_status = nil

local function remove_weather()
    naughty.destroy(weather_status)
    weather_status = nil
end

local function remove_check_weather()
    if (weather_status ~= nil) then remove_weather() end
end

function add_weather()
    if (weather_status and weather_status.box.screen) then
        remove_weather()
    else
        if (weather_status) then
            remove_weather()
        end
        local text_weather = ''
        local icon_weather
        local gw = get_weather()
        for c = 1,4 do
            local gm = gw[c]
            if (c == 1 and gm['icon']) then
                icon_weather = awful.util.getdir('config')..'/themes/weather/'..gm['icon']
            end
            text_weather = text_weather ..
            '<span fgcolor="#8888ff">'..gm['day']..':</span>\n'..
            gm['cloudiness']..', '..gm['precipitation']..'\n'..
            'температура:   '..gm['temperature']..'°\n'..
            'ощущается как: '..gm['heat']..'°\n'..
            'ветер:         '..gm['wind']..' м/с\n'..
            'давление:      '..gm['pressure']..' мм.рт.ст.\n\n'
        end
        weather_status = naughty.notify({
            text = string.format( "<span font_desc='monospace 12'>%s</span>", text_weather ),
            title='погода',
            icon=icon_weather,
            timeout=0,
        })
    end
end
--}}}
--}}}

-- {{{ Wibox
mywibox = {}

mysystray = widget({ type = "systray" })
mypromptbox = {}
mylayoutbox = {}
--{{{ separator
--separator = widget({ type = "textbox" })
--separator.text = ' '
separator = widget({ type = "imagebox" })
separator.image = image(beautiful.wibox_separator)
--}}}
--{{{ taglist, +мышь
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
    awful.button({ }, 1, awful.tag.viewonly),
    awful.button({ modkey }, 1, awful.client.movetotag),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, awful.client.toggletag),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
)
shifty.taglist = mytaglist
--}}}
--{{{ tasklist, +мышь
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
    awful.button({ }, 1, function (c)
        if c == client.focus then
            c.minimized = true
        else
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
            instance = awful.menu.clients({ width=250 })
        end
    end),
    awful.button({ }, 4, function ()
        awful.client.focus.byidx(1)
        if client.focus then client.focus:raise() end
    end),
    awful.button({ }, 5, function ()
        awful.client.focus.byidx(-1)
        if client.focus then client.focus:raise() end
    end)
)
--}}}

--{{{ часы
mydate_icon = widget({type = "imagebox"})
mydate_icon.image = image(beautiful.wibox_date)

mydate = widget({ type = "textbox" })
vicious.register(mydate, vicious.widgets.date, '<span fgcolor="#8888ff">'.."%a %d %b %H:%M"..'</span>')

--    mydate:add_signal("mouse::enter", function() add_calendar(0) end)
mydate:add_signal("mouse::leave", remove_calendar )

mydate:buttons(awful.util.table.join(
    awful.button({ }, 1, function() add_calendar(0) end),
    awful.button({ }, 4, function() if calendar ~= nil then add_calendar(-1) end end),
    awful.button({ }, 5, function() if calendar ~= nil then add_calendar(1)  end end)
))
--}}}

--{{{ звук
myvolume_icon = widget({type = "imagebox"})
myvolume_icon.image = image(beautiful.wibox_volume)

myvolume = widget({ type = "textbox" })
vicious.register(myvolume, vicious.widgets.volume,
    function(widget, args)
        if (args.mute) then
            myvolume_icon.image = image(beautiful.wibox_novolume)
            return ''
        else
            myvolume_icon.image = image(beautiful.wibox_volume)
            return '<span fgcolor="#8888ff">'..args.volume..'%</span>'
        end
    end,
10, "Master")

local volume_control = awful.util.table.join(
    awful.button({ }, 1, function()
        os.execute('amixer -c 0 -- sset Master toggle')
        vicious.force({myvolume})
    end),
    awful.button({ }, 4, function()
        os.execute('amixer -c 0 -- sset Master 3%+')
        vicious.force({myvolume})
    end),
    awful.button({ }, 5, function()
        os.execute('amixer -c 0 -- sset Master 3%-')
        vicious.force({myvolume})
    end)
)
myvolume:buttons(volume_control)
myvolume_icon:buttons(volume_control)
--}}}

--{{{ батарея
mybat_icon = widget({type = "imagebox"})
mybat_icon.image = image(beautiful.wibox_bat)

mybat = widget({ type = "textbox" })
vicious.register(mybat, vicious.widgets.bat,
    function (widget, args)
        local perc_color = "#88ff88"
        if ( args[1] == '↯' or args[1] == '⌁' ) then -- заряжено
            return '<span fgcolor="#ffff88">'..args[1]..'</span>'
        else
            if ( args[1] == '-' ) then args[1] = '–' end -- минус маленький U2013
            if ( args[2] < 30 ) then
                perc_color = "#ffff88"
            elseif ( args[2] < 10 ) then
                perc_color = "#ff8888"
            end
            return '<span fgcolor="#ffff88">'..args[1]..'</span> <span fgcolor="'..perc_color..'">'..args[2]..'%</span>'
        end
    end,
3, "BAT0")
--}}}

--{{{ температура
mythermal_icon = widget({type = "imagebox"})
mythermal_icon.image = image(beautiful.wibox_thermal)

mythermal = widget({ type = "textbox" })
vicious.register(mythermal, vicious.widgets.thermal,
function (widget, args)
    local therm_color = "#88ff88"
    if ( args[1] > 75 ) then
        therm_color = "#ff8888"
    elseif ( args[1] > 65 ) then
        therm_color = "#ffff88"
    end
    return '<span fgcolor="'..therm_color..'">'..args[1]..'°</span>'
end,
10, "thermal_zone0", "sys")
--}}}

--{{{ память, диски
mymem_icon = widget({type = "imagebox"})
mymem_icon.image = image(beautiful.wibox_mem)

mymem = widget({ type = "textbox" })
vicious.register(mymem, vicious.widgets.mem,
function (widget, args)
    local mem, swp = '<span fgcolor="#8888ff">'..args[1]..'%</span>', ''
    if (args[5] ~= 0) then swp = ' <span fgcolor="#ff8888">'..args[5]..'%</span>' end
    return mem..swp
end,
10)

mymem:add_signal("mouse::leave", remove_check_disks_free )
mymem_icon:add_signal("mouse::leave", remove_check_disks_free )

local disks_free_control = awful.util.table.join(
    awful.button({ }, 1, function() add_disks_free() end)
)

mymem:buttons(disks_free_control)
mymem_icon:buttons(disks_free_control)
--}}}

--{{{ mpd
mympd_icon = widget({type = "imagebox"})
mympd_icon.image = image(beautiful.wibox_mpd)

mympd = widget({ type = "textbox" })
vicious.register(mympd, vicious.widgets.mpd,
function (widget, args)
    local color_title = "#ff8888"
    if args["{random}"] == 1 then
        color_title = "#88ff88"
    end
    if args["{state}"] == "Stop" then
        return '<span fgcolor="#00bbbb">stoped</span>'
    elseif args["{state}"] == "Pause" then
        return '<span fgcolor="#00bbbb">paused</span>'
    else
        local artist, title, name, file = args["{Artist}"], args["{Title}"], args["{Name}"], args["{file}"]
        if (name == 'N/A')   then name = nil            end
        if (artist == 'N/A') then artist = ''           end
        if (title == 'N/A')  then title  = name or string.gsub(file, ".*/([^/]*)", "%1") end
        if (file:match('^http://')) then
            local f  = io.popen("echo '"..title.."'|iconv -t LATIN1|iconv -f CP1251")
            local tc = f:read("*a")
            f:close()
            artist = 'radio'
            title = tc or title
        end
        return  '<span fgcolor="#00bbbb">'..artist..'</span>'..' '..
                '<span fgcolor="'..color_title..'">'..title..'</span>'
    end
end, 10)
local mpd_control = awful.util.table.join(
    awful.button({ }, 1, function()
        os.execute("mpc toggle")
        vicious.force({mympd})
    end),
    awful.button({ }, 3, function()
        os.execute("mpc random")
        vicious.force({mympd})
    end),
    awful.button({ }, 4, function()
        os.execute("mpc prev")
        vicious.force({mympd})
    end),
    awful.button({ }, 5, function()
        os.execute("mpc next")
        vicious.force({mympd})
    end)
)
mympd:buttons(mpd_control)
mympd_icon:buttons(mpd_control)
--}}}

--{{{ сеть
mynet_icon_up = widget({type = "imagebox"})
mynet_icon_up.image = image(beautiful.wibox_net_up)
mynet_icon_down = widget({type = "imagebox"})
mynet_icon_down.image = image(beautiful.wibox_net_down)

mynet = widget({ type = "textbox" })
vicious.register(mynet, vicious.widgets.net,
function (widget, args)
    local up_color = "#88ff88"
    local down_color = "#ff8888"
    return '<span fgcolor="'..down_color..'">'..args["{wlan0 down_kb}"]..'</span> <span fgcolor="'..up_color..'">'..args["{wlan0 up_kb}"]..'</span>'
end,
5, "wlan0")
--}}}

--{{{ deluge
mydeluge_icon = widget({type = "imagebox"})
mydeluge_icon.image = image(beautiful.wibox_deluge)

mydeluge = widget({ type = "textbox" })
vicious.register(mydeluge, vicious.widgets.deluge,
function (widget, args)
    local down_color = "#88ff88"
    local up_color = "#ff8888"
    if (args.max_active_seeding == 0) and (args.max_active_downloading == 0) then
        return '<span fgcolor="#ff8888">off</span>'
    else
        return '<span fgcolor="#88ff88">on</span>'
    end
end,
3600)

mydeluge:add_signal(        "mouse::leave", remove_check_deluge)
mydeluge_icon:add_signal(   "mouse::leave", remove_check_deluge)

local deluge_control = awful.util.table.join(
    awful.button({ }, 1, function() add_deluge() end),
    awful.button({ }, 2, function() os.execute("delugecontrol -c") vicious.force({mydeluge}) end),
    awful.button({ }, 3, function() remove_check_deluge() awful.util.spawn("deluge-gtk") end)
)
mydeluge:buttons(deluge_control)
mydeluge_icon:buttons(deluge_control)
--}}}

for s = 1, screen.count() do
--{{{ promptbox, layoutbox, tablist tasklist
mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
mylayoutbox[s] = awful.widget.layoutbox(s)
mylayoutbox[s]:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
    awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
    awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)
))
mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)
mytasklist[s] = awful.widget.tasklist(
    function(c) return awful.widget.tasklist.label.currenttags(c, s) end,
    mytasklist.buttons
)
--}}}

--{{{ создание панели
mywibox[s] = awful.wibox({ position = "top", screen = s, height = 38 })
mywibox[s].widgets = {
    {-- верх
        {-- верх слева
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright,
        },
        {-- верх справа
            mylayoutbox[s],
            s == 1 and mysystray or nil,
            separator, mydate, mydate_icon,
            separator, myvolume, myvolume_icon,
            separator, kbdwidget,
            separator, mydeluge, mydeluge_icon,
            separator, mybat, mybat_icon,
            separator, mythermal, mythermal_icon,
            separator, mymem, mymem_icon,
            separator, mynet_icon_up, mynet, mynet_icon_down,
            separator, mympd, mympd_icon,
            layout = awful.widget.layout.horizontal.rightleft,
        },
    },
    {-- низ
        {-- низ слева
            layout = awful.widget.layout.horizontal.leftright,
        },
        {-- низ справа
            mytasklist[s],
            layout = awful.widget.layout.horizontal.leftright,
        },
    },
    layout = awful.widget.layout.vertical.flex,
    }
--}}}
end
-- }}}

-- {{{ global mouse buttons
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ clientbuttons
clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize)
)
--}}}

-- {{{ clientkeys
clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey,           }, "d",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
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
    { rule = { },
    properties = {
        border_width = beautiful.border_width,
        border_color = beautiful.border_normal,
        focus = true,
        keys = clientkeys,
        buttons = clientbuttons }
    },
}
-- }}}

-- {{{ globalkeys
globalkeys = awful.util.table.join(
    awful.key({ modkey }, "s", function () mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible end),

    awful.key({                   }, "Print",  nil),

    awful.key({modkey, "Control"  }, "k",      function() awful.util.spawn("xkill") end),

    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "j",      awful.tag.viewprev       ),
    awful.key({ modkey,           }, "k",      awful.tag.viewnext       ),
    awful.key({ modkey,           }, "w",      awful.tag.history.restore),
    awful.key({ modkey,           }, "e",      awful.tag.history.restore),

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
        awful.key({ modkey,           }, "Escape", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, ".", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, ",", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, ".", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, ",", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
    function ()
        awful.client.focus.history.previous()
        if client.focus then
            client.focus:raise()
        end
    end),

    -- Standard programs
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "BackSpace", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "BackSpace", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey, "Control" }, "BackSpace", function () awful.layout.set(shifty.config.tags[awful.tag.selected().name].layout) end),
    awful.key({ modkey,           }, "space",
    function ()
        local cl = awful.layout.get(mouse.screen)
        if (cl == als.tile.top) then
            awful.layout.set(als.tabs)
        else
            awful.layout.set(als.tile.top)
        end
    end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey }, "r",
    function ()
        awful.prompt.run({ prompt = "Run: " },
        mypromptbox[mouse.screen].widget,
        awful.util.spawn, awful.completion.shell,
        awful.util.getdir("cache") .. "/history")
    end),

    awful.key({ modkey }, "x",
    function ()
        awful.prompt.run({ prompt = "Run Lua code: " },
        mypromptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
    end),

    awful.key({ modkey }, "c",
    function ()
        awful.prompt.run({ prompt = "перевод: " },
        mypromptbox[mouse.screen].widget,
        function (expr)
            add_sdcv(expr)
        end, nil,
        awful.util.getdir("cache") .. "/translate")
    end)
)
-- }}}

-- {{{ tag_keys для shifty
local function tags_keys(i, p)
    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey }, i,
    function ()
        local t = awful.tag.viewonly(shifty.getpos(p))
    end))
    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Control" }, i,
    function ()
        local t = shifty.getpos(p)
        t.selected = not t.selected
    end))
    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Control", "Shift" }, i,
    function ()
        if client.focus then
            awful.client.toggletag(shifty.getpos(p))
        end
    end))
    -- move clients to other tags
    globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Shift" }, i,
    function ()
        if client.focus then
            local t = shifty.getpos(p)
            awful.client.movetotag(t)
            awful.tag.viewonly(t)
        end
    end))
end
for i=1,9 do
    tags_keys(i, i)
end
tags_keys(0, 10)
tags_keys("b", 12)
tags_keys("i", 13)
tags_keys("z", 14)
-- }}}

root.keys(globalkeys)
shifty.config.globalkeys = globalkeys

-- {{{ Signals
-- }}}

-- vim: foldmethod=marker:filetype=lua
