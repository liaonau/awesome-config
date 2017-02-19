local tostring     = tostring
local setmetatable = setmetatable

local makeup = {}

local fg = {}
local bg = {}
function makeup.bold(text)      return '<b>'     .. tostring(text) .. '</b>'     end
function makeup.italic(text)    return '<i>'     .. tostring(text) .. '</i>'     end
function makeup.strike(text)    return '<s>'     .. tostring(text) .. '</s>'     end
function makeup.underline(text) return '<u>'     .. tostring(text) .. '</u>'     end
function makeup.monospace(text) return '<tt>'    .. tostring(text) .. '</tt>'    end
function makeup.big(text)       return '<big>'   .. tostring(text) .. '</big>'   end
function makeup.small(text)     return '<small>' .. tostring(text) .. '</small>' end

function makeup.r(text) return '<span foreground="#ff8888">' .. tostring(text) .. '</span>' end
function makeup.g(text) return '<span foreground="#88ff88">' .. tostring(text) .. '</span>' end
function makeup.b(text) return '<span foreground="#8888ff">' .. tostring(text) .. '</span>' end
function makeup.c(text) return '<span foreground="#88ffff">' .. tostring(text) .. '</span>' end
function makeup.y(text) return '<span foreground="#ffff88">' .. tostring(text) .. '</span>' end
function makeup.m(text) return '<span foreground="#ff88ff">' .. tostring(text) .. '</span>' end
function makeup.d(text) return '<span foreground="#000000">' .. tostring(text) .. '</span>' end
function makeup.w(text) return '<span foreground="#ffffff">' .. tostring(text) .. '</span>' end

function makeup.desc(font, text)
  return '<span font_desc="'  .. tostring(font)  .. '">' .. tostring(text) ..'</span>'
end
function makeup.font(font, text)
  return '<span font="'  .. tostring(font)  .. '">' .. tostring(text) ..'</span>'
end
function fg.color(color, text)
  return '<span foreground="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end
function bg.color(color, text)
  return '<span background="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end
makeup.fg = fg
makeup.bg = bg

setmetatable(makeup.fg, { __call = function(_, ...) return makeup.fg.color(...) end })
setmetatable(makeup.bg, { __call = function(_, ...) return makeup.bg.color(...) end })

return setmetatable(makeup, { __call = function(_, ...) return makeup.fg.color(...) end })
