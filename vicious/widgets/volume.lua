---------------------------------------------------
-- Licensed under the GNU General Public License v2
--  * (c) 2010, Adrian C. <anrxc@sysphere.org>
---------------------------------------------------

-- {{{ Grab environment
local tonumber = tonumber
local io = { popen = io.popen }
local setmetatable = setmetatable
local string = { match = string.match }
-- }}}


-- Volume: provides volume levels and state of requested ALSA mixers
module("vicious.widgets.volume")


-- {{{ Volume widget type
local function worker(format, warg)
    if not warg then return end

    -- Get mixer control contents
    local f = io.popen("amixer get " .. warg)
    local mixer = f:read("*all")
    f:close()

    -- Capture mixer control state:          [5%] ... ... [on]
    local volu, mute = string.match(mixer, "([%d]+)%%.*%[([%l]*)")
    -- Handle mixers without data
    if volu == nil then
       return {0, true}
    end

    -- Handle mixers without mute
    if mute == "" and volu == "0"
    -- Handle mixers that are muted
    or mute == "off" then
       mute = true
    else
       mute = false
    end

    return {volume = tonumber(volu), mute = mute}
end
-- }}}

setmetatable(_M, { __call = function(_, ...) return worker(...) end })
