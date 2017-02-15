local tostring     = tostring
local setmetatable = setmetatable

local markup = {}

local fg = {}
local bg = {}
function markup.bold(text)      return '<b>'     .. tostring(text) .. '</b>'     end
function markup.italic(text)    return '<i>'     .. tostring(text) .. '</i>'     end
function markup.strike(text)    return '<s>'     .. tostring(text) .. '</s>'     end
function markup.underline(text) return '<u>'     .. tostring(text) .. '</u>'     end
function markup.monospace(text) return '<tt>'    .. tostring(text) .. '</tt>'    end
function markup.big(text)       return '<big>'   .. tostring(text) .. '</big>'   end
function markup.small(text)     return '<small>' .. tostring(text) .. '</small>' end

function markup.r(text) return '<span foreground="#ff8888">' .. tostring(text) .. '</span>' end
function markup.g(text) return '<span foreground="#88ff88">' .. tostring(text) .. '</span>' end
function markup.b(text) return '<span foreground="#8888ff">' .. tostring(text) .. '</span>' end
function markup.c(text) return '<span foreground="#88ffff">' .. tostring(text) .. '</span>' end
function markup.y(text) return '<span foreground="#ffff88">' .. tostring(text) .. '</span>' end
function markup.m(text) return '<span foreground="#ff88ff">' .. tostring(text) .. '</span>' end
function markup.d(text) return '<span foreground="#000000">' .. tostring(text) .. '</span>' end
function markup.w(text) return '<span foreground="#ffffff">' .. tostring(text) .. '</span>' end

function markup.font_desc(font, text)
  return '<span font_desc="'  .. tostring(font)  .. '">' .. tostring(text) ..'</span>'
end
function markup.font(font, text)
  return '<span font="'  .. tostring(font)  .. '">' .. tostring(text) ..'</span>'
end
function fg.color(color, text)
  return '<span foreground="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end
function bg.color(color, text)
  return '<span background="' .. tostring(color) .. '">' .. tostring(text) .. '</span>'
end
markup.fg = fg
markup.bg = bg

setmetatable(markup.fg, { __call = function(_, ...) return markup.fg.color(...) end })
setmetatable(markup.bg, { __call = function(_, ...) return markup.bg.color(...) end })

return setmetatable(markup, { __call = function(_, ...) return markup.fg.color(...) end })
