-- прогноз погоды с OpenWeatherMap
local json = require("cjson")
local math = require("math")

local meteo = {}

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

local function read_file(file)
    local f = io.open(file)
    local r = f:read("*a")
    f:close()
    return r
end

meteo.weather = function(file)
    local weather_str = read_file(file)
    local weather = get_entry(json.decode(weather_str))
    return weather
end

meteo.forecast = function(file)
    local forecast_str = read_file(file)
    local forecast = {}
    for k, v in pairs(json.decode(forecast_str)["list"]) do
        table.insert(forecast, get_entry(v))
    end
    return forecast
end

return meteo
