require("luarocks.loader")
local rex = require("rex_pcre")
local beautiful = require("beautiful")

local translate = {mt = {}}
local markup = {--{{{
["xx-small"] = function (text) return '<span size="xx-small">'..text..'</span>'  end,
["x-small"]  = function (text) return '<span size="x-small" >'..text..'</span>'  end,
["small"]    = function (text) return '<span size="small"   >'..text..'</span>'  end,
["medium"]   = function (text) return '<span size="medium"  >'..text..'</span>'  end,
["large"]    = function (text) return '<span size="large"   >'..text..'</span>'  end,
["x-large"]  = function (text) return '<span size="x-large" >'..text..'</span>'  end,
["xx-large"] = function (text) return '<span size="xx-large">'..text..'</span>'  end,
["smaller"]  = function (text) return '<span size="smaller" >'..text..'</span>'  end,
["larger"]   = function (text) return '<span size="larger"  >'..text..'</span>'  end,
red       = function (text) return '<span fgcolor="#ff8888">'..text..'</span>'  end,
green     = function (text) return '<span fgcolor="#88ff88">'..text..'</span>'  end,
blue      = function (text) return '<span fgcolor="#8888ff">'..text..'</span>'  end,
yellow    = function (text) return '<span fgcolor="#ffff88">'..text..'</span>'  end,
cyan      = function (text) return '<span fgcolor="#88ffff">'..text..'</span>'  end,
magenta   = function (text) return '<span fgcolor="#ff88ff">'..text..'</span>'  end,
gray      = function (text) return '<span fgcolor="#888888">'..text..'</span>'  end,
white     = function (text) return '<span fgcolor="#ffffff">'..text..'</span>'  end,
black     = function (text) return '<span fgcolor="#000000">'..text..'</span>'  end,
bold      = function (text) return '<b>'    ..text..'</b>'     end,
italic    = function (text) return '<i>'    ..text..'</i>'     end,
strike    = function (text) return '<s>'    ..text..'</s>'     end,
underline = function (text) return '<u>'    ..text..'</u>'     end,
monospace = function (text) return '<tt>'   ..text..'</tt>'    end,
delete    = function (text) return '' end,
tr        = function (text) return '['..text..']' end,

skip      = function (text) return text end,
}--}}}
local tags = {--{{{
    "k","b","i","c","tr","opt","gr","kref","rref","dtrn","abr","mrkd","ex","co","sr","sup","sub","big","small","blockquote",
    "syn",
}
--}}}
local function escape(...)--{{{
    -- based on shell.lua, by Peter Odding
    local command = type(...) == 'table' and ... or { ... }
    for i, s in ipairs(command) do
        s = (tostring(s) or ''):gsub('"', '\\"')
        if s:find '[^A-Za-z0-9_."/-]' then
            s = '"' .. s .. '"'
        elseif s == '' then
            s = '""'
        end
        command[i] = s
    end
    return table.concat(command, ' ')
end--}}}
local function process_tag(tag, v, line)--{{{
    local reg = rex.new('<'..tag..'>(.*?)</'..tag..'>')
    if (rex.match(line, reg)) then
        return rex.gsub(line, reg,
        function(t)
            for _, f in ipairs(v) do
                repeat
                    if (not f) then do break end end;
                    t = markup[f](t)
                until true
            end
            return t
        end
        )
    end
    return line
end--}}}
local function convert(conversion, line)--{{{
    for k, v in pairs(conversion) do
        if (type(v) == "string") then v = {v} end
        line = process_tag(k, v, line)
    end
    return line
end--}}}
local function new(conversion, ...)--{{{
    if (not conversion) then
        conversion = {}
    end
    for _, k in ipairs(tags) do
        if (not conversion[k]) then
            conversion[k] = 'skip'
        end
    end
    local word = escape(...)
    local dict
    if (word:find('[a-zA-Z]')) then dict = "LingvoEnRu" end
    if (word:find('[а-яА-Я]')) then dict = "LingvoRuEn" end
    if (not dict) then return end

    local command = "/usr/bin/dict -d "..dict.." "..word.." 2>/dev/null"

    local pass = {
        empty  = rex.new('^[\\s,-]*$'),
        header = rex.new('^((From '..dict..' \\['..dict..'\\]:)|(\\d+ definitions? found))$'),
        qeer   = rex.new('^\\s*(•)+$'),
    }
    local trans = {
        [rex.new("^(\\s+)")]                   = "", -- leading space
        [rex.new("(<nu />('|\\[/?\\&apos;\\]|</?opt>)<nu />)")] = "", -- accent
        [rex.new('^\\s*<b>Syn:</b>$')] = "<syn>syn:</syn>", -- syn
        [rex.new('^\\s*<b>Ant:</b>$')] = "<syn>ant:</syn>", -- ant
    }
    local empty_tags = rex.new("(<[^/][^<>]*></[^<>]*>)")

    local synant_new = rex.new('>(syn:|ant:)<')

    local translation = ''
    local f, err = io.popen(command, 'r')
    if (not f) then return end
    for line in f:lines() do
    repeat
        local do_pass = false
        for k, v in pairs(pass) do
            if (rex.match(line, v)) then
                do_pass = true
                break
            end
        end
        if (do_pass) then
            do break end
        end
        for k, v in pairs(trans) do
            line = rex.gsub(line, k, v)
        end
        line = rex.gsub(line, empty_tags, '')
        line = convert(conversion, line)
        if (not rex.match(line, pass.empty)) then
            translation = translation .. line
            if (rex.match(line, synant_new)) then
                translation = translation .. " "
            else
                translation = translation .. "\n"
            end
        end
    until true
    end
    f:close()

    translation = translation:gsub("\n$", "")
    return translation
end--}}}

function translate.mt:__call(conversion, ...)
    return new(conversion, ...)
end

return setmetatable(translate, translate.mt)
