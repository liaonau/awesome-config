local wibox = require("wibox")
local setmetatable = setmetatable
local rawset = rawset

local txt = { mt = {} }

local function new(...)
    local ret    = { mt = {} }
    ret.textbox  = wibox.widget.textbox(...)

    ret.mt.visible = true
    ret.mt.text    = ''
    ret.mt.set_markup = function(t, m)
        t.mt.text = m
        if (t.mt.visible) then
            t.textbox:set_markup(m)
        end
    end
    ret.mt.set_text = function(t, m)
        t.mt.text = m
        if (t.mt.visible) then
            t.textbox:set_text(m)
        end
    end

    ret.mt.__index = function(t, k)
        if (k == "visible"    or
            k == "text"       or
            k == "set_markup" or
            k == "set_text") then
            return t.mt[k]
        end
        return t.textbox[k]
    end

    ret.mt.__newindex = function(t, k, v)
        if (k == "visible") then
            t.mt.visible = v
            if (v) then
                t.textbox:set_markup(t.mt.text)
            else
                t.textbox:set_text('')
            end
        elseif (k == "text") then
            t.mt.set_markup(t, v)
        else
            rawset(t.textbox, k, v)
        end
    end

    return setmetatable(ret, ret.mt)
end

function txt.mt:__call(...)
    return new(...)
end

return setmetatable(txt, txt.mt)
