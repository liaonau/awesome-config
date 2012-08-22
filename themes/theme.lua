---------------------------
-- Default awesome theme --
---------------------------

theme   = {}
config  = awful.util.getdir("config").."/themes/"
wibox   = 'wibox/'

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

--theme.taglist_bg_focus = "#333388"
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
theme.taglist_squares_sel   = config .. "taglist/squarefw.png"
theme.taglist_squares_unsel = config .. "taglist/squarew.png"

theme.tasklist_floating_icon = config .. "tasklist/floatingw.png"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = config .. "submenu.png"
theme.menu_height       = "15"
theme.menu_width        = "100"

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.titlebar_close_button_normal = config .. "titlebar/close_normal.png"
theme.titlebar_close_button_focus  = config .. "titlebar/close_focus.png"

theme.titlebar_ontop_button_normal_inactive     = config .. "titlebar/ontop_normal_inactive.png"
theme.titlebar_ontop_button_focus_inactive      = config .. "titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_active       = config .. "titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_active        = config .. "titlebar/ontop_focus_active.png"

theme.titlebar_sticky_button_normal_inactive    = config .. "titlebar/sticky_normal_inactive.png"
theme.titlebar_sticky_button_focus_inactive     = config .. "titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_active      = config .. "titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_active       = config .. "titlebar/sticky_focus_active.png"

theme.titlebar_floating_button_normal_inactive  = config .. "titlebar/floating_normal_inactive.png"
theme.titlebar_floating_button_focus_inactive   = config .. "titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_active    = config .. "titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_active     = config .. "titlebar/floating_focus_active.png"

theme.titlebar_maximized_button_normal_inactive = config .. "titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive  = config .. "titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active   = config .. "titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active    = config .. "titlebar/maximized_focus_active.png"

theme.wibox_separator   = config .. wibox .. "separator.png"
theme.wibox_mpd         = config .. wibox .. "music.png"
theme.wibox_net_up      = config .. wibox .. "up.png"
theme.wibox_net_down    = config .. wibox .. "down.png"
theme.wibox_thermal     = config .. wibox .. "temp.png"
theme.wibox_bat         = config .. wibox .. "bat.png"
theme.wibox_volume      = config .. wibox .. "vol.png"
theme.wibox_novolume    = config .. wibox .. "volmute.png"
theme.wibox_date        = config .. wibox .. "time.png"
theme.wibox_deluge      = config .. wibox .. "deluge.png"
theme.wibox_mem         = config .. wibox .. "mem.png"
theme.wibox_weather     = config .. wibox .. "weather/cloud.png"
theme.kbdd = {
    ru = config .. "kbdd/ru.png",
    us = config .. "kbdd/us.png"
}

-- You can use your own command to set your wallpaper
theme.wallpaper_cmd = { "awsetbg " .. config .. "wallpaper/vladstudio-1.jpg" }

-- You can use your own layout icons like this:
theme.layout_fairh      = config .. "layouts/fairhw.png"
theme.layout_fairv      = config .. "layouts/fairvw.png"
theme.layout_floating   = config .. "layouts/floatingw.png"
theme.layout_magnifier  = config .. "layouts/magnifierw.png"
theme.layout_tabs       = config .. "layouts/tabs.png"
theme.layout_static     = config .. "layouts/spiralw.png"
theme.layout_max        = config .. "layouts/maxw.png"
theme.layout_fullscreen = config .. "layouts/fullscreenw.png"
theme.layout_tilebottom = config .. "layouts/tilebottomw.png"
theme.layout_tileleft   = config .. "layouts/tileleftw.png"
theme.layout_tile       = config .. "layouts/tilew.png"
theme.layout_tiletop    = config .. "layouts/tiletopw.png"
theme.layout_spiral     = config .. "layouts/spiralw.png"
theme.layout_dwindle    = config .. "layouts/dwindlew.png"

theme.awesome_icon = "/usr/share/awesome/icons/awesome16.png"

return theme
-- vim: filetype=lua:foldmethod=marker
