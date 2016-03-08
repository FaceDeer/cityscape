minetest.register_node("cityscape:silver_glass", {
	description = "Plate Glass",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"cityscape_plate_glass.png"},
	light_source = 1,
	use_texture_alpha = true,
	is_ground_content = false,
	groups = {cracky = 3, level=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cityscape:road", {
	description = "Road",
	tiles = {"cityscape_tarmac.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1},
})

minetest.register_node("cityscape:road_yellow_line", {
	description = "Road",
	tiles = {"cityscape_tarmac_yellow_line.png"},
	paramtype2 = "facedir",
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1},
})

minetest.register_node("cityscape:plaster", {
	description = "Plaster",
	tiles = {"cityscape_plaster.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1, oddly_breakable_by_hand = 1},
})

stairs.register_stair_and_slab("road", "cityscape:road",
	{cracky = 1, level = 1},
	{"cityscape_tarmac.png"},
	"Ramp",
	"Tarmac",
	default.node_sound_stone_defaults())

minetest.register_node("cityscape:concrete", {
	description = "Concrete",
	tiles = {"cityscape_concrete.png"},
	groups = {cracky = 3, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})

local newnode = cityscape.clone_node("cityscape:concrete")
newnode.tiles = {"cityscape_concrete.png^[colorize:#964B00:40"}
minetest.register_node("cityscape:concrete2", newnode)
newnode.tiles = {"cityscape_concrete.png^[colorize:#FF0000:20"}
minetest.register_node("cityscape:concrete3", newnode)
newnode.tiles = {"cityscape_concrete.png^[colorize:#4682B4:10"}
minetest.register_node("cityscape:concrete4", newnode)
newnode.tiles = {"cityscape_concrete.png^[colorize:#000000:40"}
minetest.register_node("cityscape:concrete5", newnode)

minetest.register_node("cityscape:floor_ceiling", {
	description = "Floor/Ceiling",
	tiles = {"cityscape_floor.png", "cityscape_ceiling.png", "cityscape_concrete.png"},
	paramtype2 = "facedir",
	groups = {cracky = 3, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})


minetest.register_node("cityscape:sidewalk", {
	description = "Sidewalk",
	tiles = {"cityscape_sidewalk.png"},
	groups = {cracky = 3, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})

minetest.register_node("cityscape:roof", {
	description = "Roof",
	tiles = {"cityscape_tarmac.png", "cityscape_ceiling.png", "cityscape_concrete.png"},
	paramtype2 = "facedir",
	groups = {cracky = 3, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})

default.register_fence("cityscape:fence_steel", {
	description = "Saftey Rail",
	texture = "cityscape_safety_rail.png",
	material = "default:steel",
	groups = {cracky = 1, level = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cityscape:gargoyle", {
	description = "Concrete",
	tiles = {"cityscape_statue.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = { type = "fixed",
		fixed = {
			{0.2, 0.23, -0.17, -0.1, -0.5, 0.17},   -- body f
			{-0.1, -0.07, -0.17, -0.27, -0.5, 0.17},   -- body r
			{0.17, 0.5, -0.07, 0, 0.23, 0.07}, -- head
			{0.27, 0.2, 0.1, 0.13, -0.5, 0.23}, -- leg fl
			{0.27, 0.2, -0.23, 0.13, -0.5, -0.1}, -- leg fr
			{0.03, -0.1, 0.17, -0.2, -0.5, 0.27}, -- leg rl
			{0.03, -0.1, -0.27, -0.2, -0.5, -0.17}, -- leg rl
			{-0.1, 0.23, -0.4, -0.17, 0.13, 0.4}, -- wing u
			{-0.1, 0.13, -0.3, -0.17, 0.03, 0.3}, -- wing u
		} },
	groups = {cracky = 3, stone = 1},
	drop = "default:cobble",
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cityscape:streetlight", {
	description = "Streetlight",
	tiles = {"cityscape_streetlight.png"},
	paramtype = "light",
	light_source = 14,
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = { type = "fixed",
		fixed = {
			{0.1, 2.5, -0.1, -0.1, -0.5, 0.1},
			{0.05, 2.5, -0.5, -0.05, 2.4, -0.1},
			{0.1, 2.5, -0.7, -0.1, 2.35, -0.5},
		} },
	groups = {cracky = 3, stone = 1},
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cityscape:light_panel", {
	description = "Light Panel",
	tiles = {"cityscape_light_panel.png"},
	light_source = 14,
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = { type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.48, 0.5},
		} },
	groups = {cracky = 3, stone = 1},
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})
