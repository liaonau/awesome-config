-- прогноз погоды с GisMeteo
require "lxp"

local file = "/var/tmp/weather/weather.xml"

--{{{ парсер, forecast — табличное представление xml
local function parse(file)
	local forecast = {}
	local c = 0
	local inside_forecast = false
	
	--{{{ заполнитель forecast
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
	--}}}

	--{{{ callbacks парсера
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
	--}}}

	local parser = lxp.new(callbacks)
	for line in io.lines(file) do
		parser:parse(line)
	end
	parser:close()
	return forecast
end
--}}}

--{{{ в weather — человечески понятные значения
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
				if		(v['precipitation'] == '4') then
							time['precipitation'] = rpref..'дождь'
							if not time['icon'] then time['icon'] = 'rain.png' end
				elseif	(v['precipitation'] == '5') then
							time['precipitation'] = rpref..'ливень'
							if not time['icon'] then time['icon'] = 'rain.png' end
				elseif	(v['precipitation'] == '6' or v['precipitation'] == '7') then
							time['precipitation'] = rpref..'снег'
							if not time['icon'] then time['icon'] = 'snow.png' end
				elseif	(v['precipitation'] == '8') then
							time['precipitation'] = spref..'гроза'
							if not time['icon'] then time['icon'] = 'lightning.png' end
				elseif	(v['precipitation'] == '10') then
							time['precipitation'] = 'без осадков'
				else
							time['precipitation'] = nil
				end
				if		(v['cloudiness'] == '0') then
							time['cloudiness'] = 'ясно'
							if not time['icon'] then time['icon'] = 'sun.png' end
				elseif	(v['cloudiness'] == '1') then
							time['cloudiness'] = 'малооблачно'
							if not time['icon'] then time['icon'] = 'cloudy.png' end
				elseif	(v['cloudiness'] == '2') then
							time['cloudiness'] = 'облачно'
							if not time['icon'] then time['icon'] = 'cloud.png' end
				elseif	(v['cloudiness'] == '3') then
							time['cloudiness'] = 'пасмурно'
							if not time['icon'] then time['icon'] = 'clouds.png' end
				else
							time['cloudiness'] = nil
				end
			end
		end
		if		(fc['tod'] == '0') then time['day'] = 'ночь'
		elseif	(fc['tod'] == '1') then time['day'] = 'утро'
		elseif	(fc['tod'] == '2') then time['day'] = 'день'
		elseif	(fc['tod'] == '3') then time['day'] = 'вечер'
		end
		weather[c] = time
	end
	return weather
end
--}}}

function get_weather()
	local fc = parse(file)
	local wt = humanize(fc)
	return wt
end

-- vim: foldmethod=marker
