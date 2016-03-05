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
	tiles = {"default_sandstone.png^[colorize:#FFFFFF:FF"},
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
	tiles = {"default_stone.png"},
	groups = {cracky = 3, stone = 1},
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})

default.register_fence("cityscape:fence_steel", {
	description = "Saftey Rail",
	texture = "cityscape_blue_paint.png",
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
	groups = {cracky = 3, stone = 1},
	drop = 'default:cobble',
	on_place = minetest.rotate_and_place,
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("cityscape:streetlight", {
	description = "Streetlight",
	tiles = {"cityscape_dark_blue_paint.png"},
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
	tiles = {"default_sandstone.png"},
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

-- attempt to fix tree intrusions
minetest.register_node("cityscape:treebot_road", {
	description = "Road",
	tiles = {"cityscape_tarmac.png"},
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1},
})

minetest.register_node("cityscape:treebot_road_yellow_line", {
	description = "Road",
	tiles = {"cityscape_tarmac_yellow_line.png"},
	paramtype2 = "facedir",
	sounds = default.node_sound_stone_defaults(),
	groups = {cracky = 1, level = 1},
})

minetest.register_node("cityscape:treebot_concrete", {
	description = "Concrete",
	tiles = {"default_stone.png"},
	groups = {cracky = 3, stone = 1},
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_abm({
	nodenames = {"cityscape:treebot_road_yellow_line", "cityscape:treebot_road", "cityscape:treebot_concrete"},
	interval = 5,
	chance = 1,
	action = function(pos)
		local node = minetest.get_node_or_nil(pos)
		local name = node.name
		local param2 = node.param2
		local p2 = {}
		local responses = {}
		for y = pos.y - 10, pos.y + 40 do
			p2.x = pos.x
			p2.y = y
			p2.z = pos.z
			node = minetest.get_node_or_nil(p2)
			if node then
				node = node.name
				if node then
					if not responses[node] then
						responses[node] = minetest.get_item_group(node, "tree") + minetest.get_item_group(node, "leaves")
					end
					if responses[node] ~= 0 then
						minetest.remove_node(p2)
					end
				else
					--return
				end
			else
				--return
			end
		end

		if name == 'cityscape:treebot_road' then
			minetest.set_node(pos, {name="cityscape:road"})
		elseif name == 'cityscape:treebot_road_yellow_line' then
			minetest.set_node(pos, {name="cityscape:road_yellow_line", param2=param2})
		else
			minetest.set_node(pos, {name="cityscape:concrete"})
		end
	end
})  
