---------------------------
-- Default awesome theme --
---------------------------

theme   = {}

local awful = require("awful")

local setmetatable = setmetatable
local type = type
local rawset = rawset
local path = awful.util.getdir("config").."themes/"
local wb   = path..'wibox/'

theme.main_wibox_height = "40"

theme.font          = "Bitstream Vera sans 10"
theme.bg_normal     = "#222222"
theme.bg_focus      = "#535d6c"
theme.bg_urgent     = "#A36666"
theme.bg_minimize   = "#333300"

theme.fg_normal     = "#dddddd"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = "#ffffff"

theme.border_width  = "1"
theme.border_normal = "#000000"
theme.border_focus  = "#535d6c"
theme.border_marked = "#91231c"

theme.taglist_bg_focus = "#338833"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Display the taglist squares
theme.taglist_squares_sel   = path.."taglist/squarefw.png"
theme.taglist_squares_unsel = path.."taglist/squarew.png"

theme.tasklist_floating_icon = path.."tasklist/floatingw.png"
theme.tasklist_bg_focus    = "#dcdad5"
theme.tasklist_fg_focus    = "#222222"
theme.tasklist_bg_normal   = "#777766"
theme.tasklist_fg_normal   = "#222222"
theme.tasklist_bg_urgent   = "#A36666"
theme.tasklist_bg_minimize = "#555500"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = path.."submenu.png"
theme.menu_height       = "15"
theme.menu_width        = "100"

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = path.."titlebar/close_normal.png"
theme.titlebar_close_button_focus  = path.."titlebar/close_focus.png"

theme.titlebar_ontop_button_normal_inactive     = path.."titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive      = path.."titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active       = path.."titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active        = path.."titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive    = path.."titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive     = path.."titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active      = path.."titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active       = path.."titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive  = path.."titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive   = path.."titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active    = path.."titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active     = path.."titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = path.."titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = path.."titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   = path.."titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    = path.."titlebar/maximized_focus_active.png"

theme.wibox = {}
theme.wibox.separator = wb.."separator.svg"
theme.wibox.mpd = {
    ["music"]   = wb.."player/music.png",
    ["play"]    = wb.."player/start.png",
    ["pause"]   = wb.."player/pause.png",
    ["stop"]    = wb.."player/stop.png",
    ["shuffle"] = wb.."player/shuffle.png",
    ["repeat"]  = wb.."player/repeat.png",
}
theme.wibox.cpu  = wb.."processor.png"
theme.wibox.hdd  = wb.."drive.png"
theme.wibox.rss  = wb.."rss.png"
theme.wibox.mail = wb.."mail.png"
theme.wibox.battery = {
    ["000"]     = wb.."battery/000.png",
    ["000_c"]   = wb.."battery/000_c.png",
    ["020_c"]   = wb.."battery/020_c.png",
    ["020"]     = wb.."battery/020.png",
    ["040_c"]   = wb.."battery/040_c.png",
    ["040"]     = wb.."battery/040.png",
    ["060_c"]   = wb.."battery/060_c.png",
    ["060"]     = wb.."battery/060.png",
    ["080_c"]   = wb.."battery/080_c.png",
    ["080"]     = wb.."battery/080.png",
    ["100_c"]   = wb.."battery/100_c.png",
    ["100"]     = wb.."battery/100.png",
    ["missing"] = wb.."battery/missing.png",
}
theme.wibox.brightness = wb.."brightness.png"
theme.wibox.net = {
    nm = {
        ["none"] = wb.."net/nm/none.png",
        ["00"]   = wb.."net/nm/00.png",
        ["25"]   = wb.."net/nm/25.png",
        ["50"]   = wb.."net/nm/50.png",
        ["75"]   = wb.."net/nm/75.png",
        ["100"]  = wb.."net/nm/100.png",
    },
    up   = wb.."net/up.png",
    down = wb.."net/down.png",
}
theme.wibox.volume = {
    volume  = wb.."volume/vol.png",
    mute    = wb.."volume/vol-mute.png",
    dim     = wb.."volume/vol-dim.png",
    mutedim = wb.."volume/vol-mute-dim.png",
    -- headphones
    ["alsa_output.usb-Logitech_Logitech_Wireless_Headset_000D44D39CAA-00.analog-stereo"] =
    {
        volume  = wb.."volume/headphones.png",
        mute    = wb.."volume/headphones-mute.png",
        dim     = wb.."volume/headphones-dim.png",
        mutedim = wb.."volume/headphones-mute-dim.png",
    },
    ["ladspa_sink"] =
    {
        volume  = wb.."volume/ladspa.png",
        mute    = wb.."volume/ladspa-mute.png",
        dim     = wb.."volume/ladspa-dim.png",
        mutedim = wb.."volume/ladspa-mute-dim.png",
    },
    ["ladspa_normalized_sink"] =
    {
        volume  = wb.."volume/ladspa.png",
        mute    = wb.."volume/ladspa-mute.png",
        dim     = wb.."volume/ladspa-dim.png",
        mutedim = wb.."volume/ladspa-mute-dim.png",
    },
    clients =
    {
        ["Music Player Daemon"]             = wb.."volume/clients/music.png",
        ["mpv Media Player"]                = wb.."volume/clients/mpv.png",
        ["ALSA plug-in [plugin-container]"] = wb.."volume/clients/ff.png",
        ["radiotray"]                       = wb.."volume/clients/radiotray.png",
        ["qemu-system-x86_64"]              = wb.."volume/clients/qemu.png",
        ["VLC media player (LibVLC 2.1.4)"] = wb.."volume/clients/vlc.png",
    },
}
theme.wibox.date        = wb.."time.png"
theme.wibox.deluge      = wb.."deluge.png"
theme.wibox.mem         = wb.."mem.png"
theme.wibox.calendar    = wb.."calendar.png"
theme.wibox.disks       = wb.."drive.png"
theme.wibox.usb         = wb.."usb.png"
theme.wibox.cdrom       = wb.."cdrom.png"
theme.wibox.log         = wb.."logview.png"
theme.wibox.dict        = wb.."dict.png"
theme.wibox.remind      = wb.."remind.png"

--theme.wallpaper = path.."wallpaper/earthwater.jpg"
theme.wallpaper = path.."wallpaper/youbeta.jpg"

-- You can use your own layout icons like this:
theme.layout_fairh      = path.."layouts/fairhw.png"
theme.layout_fairv      = path.."layouts/fairvw.png"
theme.layout_floating   = path.."layouts/floatingw.png"
theme.layout_magnifier  = path.."layouts/magnifierw.png"
theme.layout_tabular    = path.."layouts/tabular.svg"
theme.layout_static     = path.."layouts/spiralw.png"
theme.layout_max        = path.."layouts/maxw.png"
theme.layout_fullscreen = path.."layouts/fullscreenw.png"
theme.layout_tilebottom = path.."layouts/tilebottomw.png"
theme.layout_tileleft   = path.."layouts/tileleftw.png"
theme.layout_tile       = path.."layouts/tilew.png"
theme.layout_tiletop    = path.."layouts/tiletopw.png"
theme.layout_spiral     = path.."layouts/spiralw.png"
theme.layout_dwindle    = path.."layouts/dwindlew.png"

theme.kbd =
{
    us = path.."/kbd/us.png",
    ru = path.."/kbd/ru.png",
}

theme.awesome_icon = "/usr/share/awesome/icons/awesome16.png"

theme.infobox_bg = "#000000"

theme.dialog_ok     = path.."dialog/ok.png"
theme.dialog_cancel = path.."dialog/cancel.png"

theme.dirs = {}

local icon_size = 32
theme.dirs.naughty_icons = {
    path..'naughty/',
    "/usr/share/pixmaps/",
}
local idirs = {"actions", "animations", "apps", "categories", "devices", "emblems", "emotes", "mimetypes", "places", "status", "stock"}
for _, d in ipairs(idirs) do
    table.insert(theme.dirs.naughty_icons, '/usr/share/icons/gnome/'..icon_size..'x'..icon_size..'/'..d..'/')
    table.insert(theme.dirs.naughty_icons, '/usr/share/icons/Faenza/'..d..'/'..icon_size..'/')
end

theme.dirs.tags = path..'tags/'
theme.dirs.weather = path..'weather/'

theme.icon_theme = 'gnome'

return theme
-- vim: filetype=lua:foldmethod=marker
