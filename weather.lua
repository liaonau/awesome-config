--  прогноз погоды с GisMeteo
local lxp = require "lxp"

local weather = {}

local file = "/home/liaonau/tmp/weather.xml"
-- {{{ парсер, forecast — табличное представление xml
local function parse(file)
    local forecast = {}
    local c = 0
    local inside_forecast = false
    -- {{{ заполнитель forecast
    local function add_data (table, name, attrs)
        local name = name
        local table = table
        name = string.lower(name)
        if not (name == 'forecast') then
            table[name] = {}
            table = table[name]
        end
        for _, v in ipairs(attrs) do
            table[v] = attrs[v]
        end
    end
    -- }}}
    -- {{{ callbacks парсера
    local callbacks = {
        StartElement = function (parser, name, attributes)
            if (name == 'FORECAST') then
                inside_forecast = true
                c = c + 1
                forecast[c] = {}
            end
            if (inside_forecast) then
                add_data(forecast[c], name, attributes)
            end
        end,
        EndElement = function (parser, name, attributes)
            if (name == 'FORECAST') then inside_forecast = false end
        end,
    }
    -- }}}
    local parser = lxp.new(callbacks)
    for line in io.lines(file) do
        parser:parse(line)
    end
    parser:close()
    return forecast
end
-- }}}

-- {{{ в weather — человечески понятные значения
local function humanize(forecast)
    local weather = {}
    for c, fc in ipairs(forecast) do
        local time = {}
        for k, v in pairs(fc) do
            if (k=='pressure' or k=='temperature' or k=='relwet' or k=='wind' or k=='heat') then
                time[k] = ( v['max'] + v['min'])/2
            elseif (k=='phenomena') then
                local spref, rpref = '', ''
                if (v['spower'] == '0') then spref = 'возможна ' end
                if (v['rpower'] == '0') then rpref = 'возможен ' end
                if      (v['precipitation'] == '4') then
                    time['precipitation'] = rpref..'дождь'
                    if not time['icon'] then time['icon'] = 'rain.png' end
                elseif  (v['precipitation'] == '5') then
                    time['precipitation'] = rpref..'ливень'
                    if not time['icon'] then time['icon'] = 'rain.png' end
                elseif  (v['precipitation'] == '6' or v['precipitation'] == '7') then
                    time['precipitation'] = rpref..'снег'
                    if not time['icon'] then time['icon'] = 'snow.png' end
                elseif  (v['precipitation'] == '8') then
                    time['precipitation'] = spref..'гроза'
                    if not time['icon'] then time['icon'] = 'lightning.png' end
                elseif  (v['precipitation'] == '10') then
                    time['precipitation'] = 'без осадков'
                else
                    time['precipitation'] = nil
                end
                if      (v['cloudiness'] == '0') then
                    time['cloudiness'] = 'ясно'
                    if not time['icon'] then time['icon'] = 'sun.png' end
                elseif  (v['cloudiness'] == '1') then
                    time['cloudiness'] = 'малооблачно'
                    if not time['icon'] then time['icon'] = 'cloudy.png' end
                elseif  (v['cloudiness'] == '2') then
                    time['cloudiness'] = 'облачно'
                    if not time['icon'] then time['icon'] = 'cloud.png' end
                elseif  (v['cloudiness'] == '3') then
                    time['cloudiness'] = 'пасмурно'
                    if not time['icon'] then time['icon'] = 'clouds.png' end
                else
                    time['cloudiness'] = nil
                end
            end
        end
        if      (fc['tod'] == '0') then time['day'] = 'ночь'
        elseif  (fc['tod'] == '1') then time['day'] = 'утро'
        elseif  (fc['tod'] == '2') then time['day'] = 'день'
        elseif  (fc['tod'] == '3') then time['day'] = 'вечер'
        end
        local month = (function(n)
            if n == "01" then return "января"     end
            if n == "02" then return "февряля"    end
            if n == "03" then return "марта"      end
            if n == "04" then return "апреля"     end
            if n == "05" then return "мая"        end
            if n == "06" then return "июня"       end
            if n == "07" then return "июль"       end
            if n == "08" then return "августа"    end
            if n == "09" then return "сентября"   end
            if n == "10" then return "октября"    end
            if n == "11" then return "ноября"     end
            if n == "12" then return "декабря"    end
            return "нулябрь"
        end)(forecast[1].month)
        weather.date = forecast[1].day .. " " .. month .. " " .. forecast[1].year
        weather[c] = time
    end
    return weather
end
-- }}}

function weather.get()
    local fc = parse(file)
    local wt = humanize(fc)
    return wt
end

return weather
--  vim: foldmethod=marker
