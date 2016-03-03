--function cityscape.clone_node(name)
--	local node = minetest.registered_nodes[name]
--	local node2 = cityscape.table_copy(node)
--	return node2
--end

minetest.register_node("cityscape:silver_glass", {
	description = "Plate Glass",
	drawtype = "glasslike",
	paramtype = "light",
	sunlight_propagates = true,
	tiles = {"cityscape_plate_glass.png"},
	inventory_image = minetest.inventorycube("cityscape_plate_glass.png"),
	light_source = 1,
	use_texture_alpha = true,
	is_ground_content = false,
	groups = {cracky = 3, level=2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cityscape:road", {
	description = "Road",
	tiles = {"default_obsidian.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1},
})

stairs.register_stair_and_slab("road", "cityscape:road",
	{cracky = 1, level = 1},
	{"default_obsidian.png"},
	"Ramp",
	"Tarmac",
	default.node_sound_stone_defaults())

default.register_fence("cityscape:fence_steel", {
	description = "Saftey Rail",
	texture = "default_steel_block.png",
	material = "default:steel",
	groups = {cracky = 1, level = 2},
	sounds = default.node_sound_stone_defaults(),
})

