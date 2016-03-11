minetest.register_node("cityscape:silver_glass", {
	description = "Plate Glass",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"cityscape_plate_glass.png"},
	light_source = 1,
	use_texture_alpha = true,
	is_ground_content = false,
	groups = {cracky = 3, level=1},
	sounds = default.node_sound_stone_defaults(),
})
newnode = cityscape.clone_node("cityscape:silver_glass")
newnode.tiles = {"cityscape_plate_glass_broken.png"}
newnode.walkable = false
minetest.register_node("cityscape:silver_glass_broken", newnode)

minetest.register_node("cityscape:road", {
	description = "Road",
	tiles = {"cityscape_tarmac.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 2, level = 1},
})

minetest.register_node("cityscape:road_broken", {
	description = "Road",
	tiles = {"cityscape_tarmac.png^cityscape_broken_3.png"},
	paramtype = "light",
	drawtype = "nodebox",
	node_box = { type = "fixed",
		fixed = {
			{0.5, 0.3, 0.5, -0.5, -0.5, -0.5}
		}
	},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 2, level = 1},
})

minetest.register_node("cityscape:road_yellow_line", {
	description = "Road",
	tiles = {"cityscape_tarmac_yellow_line.png"},
	paramtype2 = "facedir",
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 2, level = 1},
})

minetest.register_node("cityscape:plaster", {
	description = "Plaster",
	tiles = {"default_desert_stone.png^[colorize:#8C8175:225"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 3, level = 0, oddly_breakable_by_hand = 1},
})
newnode = cityscape.clone_node("cityscape:plaster")
newnode.tiles = {"(default_desert_stone.png^[colorize:#8C8175:225)^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:plaster_broken", newnode)

stairs.register_stair_and_slab("road", "cityscape:road",
	{cracky = 2, level = 1},
	{"cityscape_tarmac.png"},
	"Ramp",
	"Tarmac",
	default.node_sound_stone_defaults())

minetest.register_node("cityscape:concrete", {
	description = "Concrete",
	tiles = {"default_stone.png"},
	groups = {cracky = 3, level=1, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})
newnode = cityscape.clone_node("cityscape:concrete")
newnode.tiles = {"default_stone.png^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:concrete_broken", newnode)

local newnode = cityscape.clone_node("cityscape:concrete")
newnode.tiles = {"default_stone.png^[colorize:#964B00:40"}
minetest.register_node("cityscape:concrete2", newnode)
newnode.tiles = {"default_stone.png^[colorize:#FF0000:20"}
minetest.register_node("cityscape:concrete3", newnode)
newnode.tiles = {"default_stone.png^[colorize:#4682B4:10"}
minetest.register_node("cityscape:concrete4", newnode)
newnode.tiles = {"default_stone.png^[colorize:#000000:40"}
minetest.register_node("cityscape:concrete5", newnode)

local newnode = cityscape.clone_node("cityscape:concrete_broken")
newnode.tiles = {"default_stone.png^[colorize:#964B00:40^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:concrete2_broken", newnode)
newnode.tiles = {"default_stone.png^[colorize:#FF0000:20^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:concrete3_broken", newnode)
newnode.tiles = {"default_stone.png^[colorize:#4682B4:10^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:concrete4_broken", newnode)
newnode.tiles = {"default_stone.png^[colorize:#000000:40^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:concrete5_broken", newnode)

minetest.register_node("cityscape:floor_ceiling", {
	description = "Floor/Ceiling",
	tiles = {"cityscape_floor.png", "cityscape_ceiling.png", "default_stone.png"},
	paramtype2 = "facedir",
	groups = {cracky = 3, level=1, stone = 1},
	drop = "default:cobble",
	drop = {
		max_items = 3,
		items = {
			{
				items = {"default:cobble",},
				rarity = 1,
			},
			{
				items = {"default:copper_ingot",},
				rarity = 6,
			},
		},
	},
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})
newnode = cityscape.clone_node("cityscape:floor_ceiling")
newnode.tiles = {"cityscape_floor.png^cityscape_broken_3.png", "cityscape_ceiling.png^cityscape_broken_3.png", "default_stone.png^cityscape_broken_3.png"}
minetest.register_node("cityscape:floor_ceiling_broken", newnode)

minetest.register_node("cityscape:sidewalk", {
	description = "Sidewalk",
	tiles = {"cityscape_sidewalk.png"},
	groups = {cracky = 3, level=1, stone = 1},
	drop = "default:cobble",
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
})
newnode = cityscape.clone_node("cityscape:sidewalk")
newnode.tiles = {"cityscape_sidewalk.png^cityscape_broken_3.png"}
minetest.register_node("cityscape:sidewalk_broken", newnode)

minetest.register_node("cityscape:roof", {
	description = "Roof",
	tiles = {"cityscape_tarmac.png", "cityscape_ceiling.png", "default_stone.png"},
	paramtype2 = "facedir",
	groups = {cracky = 3, level=1, stone = 1},
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
	tiles = {"default_stone.png^[colorize:#000000:60"},
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
	groups = {cracky = 3, level=1, stone = 1},
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
	groups = {cracky = 2, level=2},
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})
newnode = cityscape.clone_node("cityscape:streetlight")
newnode.light_source = 0
minetest.register_node("cityscape:streetlight_broken", newnode)

minetest.register_node("cityscape:light_panel", {
	description = "Light Panel",
	tiles = {"default_sandstone.png"},
	light_source = 14,
	paramtype = "light",
	paramtype2 = "facedir",
	drawtype = "nodebox",
	node_box = { type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.48, 0.5},
		} },
	groups = {cracky = 3, level=1, oddly_breakable_by_hand = 1},
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})
newnode = cityscape.clone_node("cityscape:light_panel")
newnode.light_source = 0
minetest.register_node("cityscape:light_panel_broken", newnode)

newnode = cityscape.clone_node("default:brick")
newnode.tiles = {"default_brick.png^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:brick_broken", newnode)

newnode = cityscape.clone_node("default:sandstonebrick")
newnode.tiles = {"default_sandstone_brick.png^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:sandstonebrick_broken", newnode)

newnode = cityscape.clone_node("default:stonebrick")
newnode.tiles = {"default_stone_brick.png^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:stonebrick_broken", newnode)

newnode = cityscape.clone_node("default:desert_stonebrick")
newnode.tiles = {"default_desert_stone_brick.png^cityscape_broken_3_low.png"}
minetest.register_node("cityscape:desert_stonebrick_broken", newnode)

minetest.register_node("cityscape:car", {
	description = "Car",
	drawtype = 'mesh',
	tiles = {"cityscape_car_blue.png"},
	use_texture_alpha = true,
	mesh = "cityscape_car.obj",
	selection_box = { type = "fixed",
		fixed = {
			{-0.9, -0.5, -1.5, 0.9, 0.6, 1.5},
		} },
	paramtype = "light",
	paramtype2 = "facedir",
	drop = {
		max_items = 3,
		items = {
		{
			items = {"default:steel_ingot 3",},
			rarity = 1,
		},
		{
			items = {"default:copper_ingot",},
			rarity = 6,
		},
	},
},
	groups = {cracky = 1, level = 2},
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})
newnode = cityscape.clone_node("cityscape:car")
newnode.tiles = {"cityscape_car_wreck.png"}
minetest.register_node("cityscape:car_broken", newnode)
