cityscape = {}
cityscape.version = "1.0"

cityscape.path = minetest.get_modpath("cityscape")
cityscape.vacancies = tonumber(minetest.setting_get('cityscape_vacancies'))
if cityscape.vacancies < 0 or cityscape.vacancies > 10 then
	cityscape.vacancies = 0
end

dofile(cityscape.path .. "/nodes.lua")
dofile(cityscape.path .. "/mapgen.lua")
dofile(cityscape.path .. "/buildings.lua")

minetest.register_on_generated(cityscape.generate)
