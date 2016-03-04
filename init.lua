cityscape = {}
cityscape.version = "1.0"

cityscape.path = minetest.get_modpath("cityscape")


dofile(cityscape.path .. "/nodes.lua")
dofile(cityscape.path .. "/mapgen.lua")
dofile(cityscape.path .. "/buildings.lua")

minetest.register_on_generated(cityscape.generate)
