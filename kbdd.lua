
-- {{{ Variable definitions
--kbd_dbus_sw_cmd   = "qdbus ru.gentoo.KbddService /ru/gentoo/KbddService  ru.gentoo.kbdd.set_layout "
--kbd_dbus_prev_cmd = "qdbus ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.prev_layout"
--kbd_dbus_next_cmd = "qdbus ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.next_layout"
local kbd_dbus_sw_cmd   = "dbus-send --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.set_layout uint32:"
local kbd_dbus_prev_cmd = "dbus-send --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.prev_layout"
local kbd_dbus_next_cmd = "dbus-send --dest=ru.gentoo.KbddService /ru/gentoo/KbddService ru.gentoo.kbdd.next_layout"
local kbd_img_path = beautiful.kbdd
-- }}}

-- {{{ Keyboard layout widgets
--- Create a menu
--local kbdmenu =awful.menu(
--    { items = {
--        { "English", kbd_dbus_sw_cmd .. "0", kbd_img_path.us },
--        { "Русский", kbd_dbus_sw_cmd .. "1", kbd_img_path.ru },
--    }
--})

-- Create simple text widget
kbdwidget = widget({type = "textbox", name = "kbdwidget"})
-- kbdwidget.border_width = 1
-- kbdwidget.border_color = beautiful.fg_normal
kbdwidget.align="center"
--kbdwidget.text = "<span fgcolor='#000000'><b>Eng</b></span>"
kbdwidget.text = ' '
kbdwidget.bg_image = image (kbd_img_path.us)
kbdwidget.bg_align = "center"
kbdwidget.bg_resize = true
awful.widget.layout.margins[kbdwidget] = { left = 0, right = 7 }
--kbdwidget:buttons(awful.util.table.join(
--    awful.button({ }, 1, function() os.execute(kbd_dbus_prev_cmd) end),
--    awful.button({ }, 2, function() os.execute(kbd_dbus_next_cmd) end),
--    awful.button({ }, 3, function() kbdmenu:toggle () end)
--))
-- }}}

-- {{{ Signals
dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.add_signal("ru.gentoo.kbdd", function(...)
    local data = {...}
    local layout = data[2]
    local lts = {[0] = "Eng", [1] = "Рус"}
    local lts_img = {[0] = kbd_img_path.us, [1] = kbd_img_path.ru,}
--    kbdwidget.text = "<b>"..lts[layout].."</b>"
    kbdwidget.bg_image = image(lts_img[layout])
    end)
-- }}}

