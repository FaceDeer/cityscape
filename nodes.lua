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

minetest.register_node("cityscape:concrete", {
	description = "Concrete",
	tiles = {"default_stone.png"},
	groups = {cracky = 3, stone = 1},
	drop = 'default:cobble',
	sounds = default.node_sound_stone_defaults(),
})

default.register_fence("cityscape:fence_steel", {
	description = "Saftey Rail",
	texture = "default_steel_block.png",
	material = "default:steel",
	groups = {cracky = 1, level = 2},
	sounds = default.node_sound_stone_defaults(),
})

-- attempt to fix tree intrusions
minetest.register_node("cityscape:treebot_road", {
	description = "Road",
	tiles = {"default_obsidian.png"},
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
	nodenames = {"cityscape:treebot_road", "cityscape:treebot_concrete"},
	interval = 5,
	chance = 1,
	action = function(pos)
		local name = minetest.get_node_or_nil(pos).name
		local p2 = {}
		local node
		local responses = {}
		for y = pos.y - 10, pos.y + 80 do
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
					return
				end
			else
				return
			end
		end

		if name == 'cityscape:treebot_road' then
			minetest.set_node(pos, {name="cityscape:road"})
		else
			minetest.set_node(pos, {name="cityscape:concrete"})
		end
	end
})  
