-- Check for necessary mod functions and abort if they aren't available.
if not minetest.get_biome_id then
	minetest.log()
	minetest.log("* Not loading Cityscape *")
	minetest.log("Cityscape requires mod functions which are")
	minetest.log(" not exposed by your Minetest build.")
	minetest.log()
	return
end

cityscape = {}
cityscape.version = "1.0"
cityscape.path = minetest.get_modpath(minetest.get_current_modname())
cityscape.first_flag = 0

cityscape.vacancies = tonumber(minetest.setting_get('cityscape_vacancies')) or 0
if cityscape.vacancies < 0 or cityscape.vacancies > 10 then
	cityscape.vacancies = 0
end
cityscape.desolation = tonumber(minetest.setting_get('cityscape_desolation')) or 0
if cityscape.desolation < 0 or cityscape.desolation > 10 then
	cityscape.desolation = 0
end
cityscape.suburbs = tonumber(minetest.setting_get('cityscape_suburbs')) or 3
if cityscape.suburbs < 0 or cityscape.suburbs > 10 then
	cityscape.suburbs = 3
end


minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="valleys"})
	minetest.setting_set("mg_valleys_lava_features", 0)
	minetest.setting_set("mg_valleys_water_features", 0)
end)

-- Modify a node to add a group
function minetest.add_group(node, groups)
	local def = minetest.registered_items[node]
	if not def then
		return false
	end
	local def_groups = def.groups or {}
	for group, value in pairs(groups) do
		if value ~= 0 then
			def_groups[group] = value
		else
			def_groups[group] = nil
		end
	end
	minetest.override_item(node, {groups = def_groups})
	return true
end

function cityscape.clone_node(name)
	local node = minetest.registered_nodes[name]
	local node2 = table.copy(node)
	return node2
end

function cityscape.node(name)
	if not cityscape.node_cache then
		cityscape.node_cache = {}
	end

	if not cityscape.node_cache[name] then
		cityscape.node_cache[name] = minetest.get_content_id(name)
		if name ~= "ignore" and cityscape.node_cache[name] == 127 then
			print("*** Failure to find node: "..name)
		end
	end

	return cityscape.node_cache[name]
end

function cityscape.breaker(node)
	local sr = math.random(50)
	if sr <= cityscape.desolation then
		return "air"
	elseif cityscape.desolation > 0 and sr / 5 <= cityscape.desolation then
		return string.gsub(node, ".*:", "cityscape:").."_broken"
	else
		return node
	end
end


dofile(cityscape.path .. "/nodes.lua")
dofile(cityscape.path .. "/deco.lua")
dofile(cityscape.path .. "/deco_rocks.lua")
dofile(cityscape.path .. "/mapgen.lua")
dofile(cityscape.path .. "/buildings.lua")
dofile(cityscape.path .. "/houses.lua")
dofile(cityscape.path .. "/molotov.lua")

cityscape.players_to_check = {}

function cityscape.respawn(player)
	cityscape.players_to_check[#cityscape.players_to_check+1] = player:get_player_name()
end

function cityscape.unearth(dtime)
	for i, player_name in pairs(cityscape.players_to_check) do
		local player = minetest.get_player_by_name(player_name)
		if not player then
			return
		end
		local pos = player:getpos()
		if not pos then
			return
		end
		local count = 0
		local node = minetest.get_node_or_nil(pos)
		while node do
			if node.name == 'air' then
				player:setpos(pos)
				table.remove(cityscape.players_to_check, i)
				if count > 1 then
					print("*** Cityscape unearthed "..player_name.." from "..count.." meters below.")
				end
				return
			elseif node.name == "ignore" then
				return
			else
				pos.y = pos.y + 1
				count = count + 1
			end
			node = minetest.get_node_or_nil(pos)
			end
	end
end

minetest.register_on_newplayer(cityscape.respawn)
minetest.register_on_respawnplayer(cityscape.respawn)
minetest.register_on_generated(cityscape.generate)
minetest.register_globalstep(cityscape.unearth)
