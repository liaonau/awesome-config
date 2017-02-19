-- прогноз погоды с OpenWeatherMap
local json  = require("cjson")
local math  = require("math")
local awful = require("awful")

local meteo = {}

meteo.lag = 7200

local function round(num, pow)
    local p = 10^(pow or 0)
    return math.floor(num * p + 0.5) / p
end

local hPa2Hg = (100*760/101325)
local function get_entry(entry)
    local moment = {}
    moment.time        = entry.dt
    moment.temp        = round(entry.main.temp)
    moment.temp_min    = round(entry.main.temp_min)
    moment.temp_max    = round(entry.main.temp_max)
    moment.pressure    = round(entry.main.pressure * hPa2Hg)
    moment.humidity    = entry.main.humidity
    moment.description = entry.weather[1].description
    moment.main        = entry.weather[1].main
    moment.icon        = entry.weather[1].icon
    moment.wind        = round(entry.wind.speed, 1)
    moment.clouds      = entry.clouds.all
    moment.time_txt    = entry.dt_txt
    return moment
end

local function get_weather(str)
    local weather = get_entry(json.decode(str))
    return weather
end

local function get_forecast(str)
    local forecast = {}
    for k, v in pairs(json.decode(str)["list"]) do
        table.insert(forecast, get_entry(v))
    end
    return forecast
end

local function get_with_callback(file, callback, fn)
    awful.spawn.easy_async('cat '..file,
    function(s, e, reason, code)
        local result
        if (code == 0 and reason == 'exit') then
            pcall(function() result = fn(s) end)
        end
        callback(result)
    end)
end

meteo.weather  = function(file, callback) get_with_callback(file, callback, get_weather)  end
meteo.forecast = function(file, callback) get_with_callback(file, callback, get_forecast) end

return meteo
