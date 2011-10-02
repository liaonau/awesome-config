---------------------------------------------------
-- Licensed under the GNU General Public License v2
--  * (c) 2010, Adrian C. <anrxc@sysphere.org>
---------------------------------------------------

-- {{{ Grab environment
local io = {popen = io.popen}
local setmetatable = setmetatable
local tonumber = tonumber
local string = {
    gmatch = string.gmatch,
}
-- }}}

module("vicious.widgets.deluge")

options = {}

-- {{{ Operating system widget type
local function worker()

local f = io.popen("delugecontrol")
local config = f:read("*a")
f:close()
for k, v in string.gmatch(config, "([%w_]+)=(%d+)") do options[k] = tonumber(v) end

return options
end
-- }}}

setmetatable(_M, { __call = function(_, ...) return worker(...) end })
