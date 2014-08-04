local wibox = require("wibox")
local setmetatable = setmetatable
local rawset = rawset

local img = { mt = {} }

local function new(...)
    local ret    = { mt = {} }
    ret.imagebox = wibox.widget.imagebox(...)

    ret.mt.visible = true
    ret.mt.image   = nil

    ret.mt.__index = function(t, k)
        if (k == "visible") then
            return ret.mt.visible
        elseif (k == "image") then
            return t.mt.image
        else
            return ret.imagebox[k]
        end
    end

    ret.mt.__newindex = function(t, k, v)
        if (k == "visible") then
            t.mt.visible = v
            if (v == true) then
                t.imagebox:set_image(t.mt.image)
            else
                ret.imagebox:set_image(nil)
            end
        elseif (k == "image") then
            t.mt.image = v
            t.imagebox:set_image(v)
        else
            ret.imagebox[k] = v
        end
    end

    return setmetatable(ret, ret.mt)
end

function img.mt:__call(...)
    return new(...)
end

return setmetatable(img, img.mt)
