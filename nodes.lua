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

