local node = cityscape.node
local breaker = cityscape.breaker

local max_alt_range = 10
local mx, mz = 2, 2
local streetw = 5    -- street width
local sidewalk = 2   -- sidewalk width
local river_size = 5 / 100
local beach_level = 5

local good_nodes, grassy = {}, {}
do
	local t = { "cityscape:concrete", "cityscape:concrete2",
	"cityscape:concrete3", "cityscape:concrete4", "cityscape:concrete5",
	"cityscape:sidewalk", "cityscape:floor_ceiling", "cityscape:roof",
	"default:brick", "default:sandstonebrick", "default:stonebrick",
	"default:desert_stonebrick", "cityscape:concrete_broken",
	"cityscape:concrete2_broken", "cityscape:concrete3_broken",
	"cityscape:concrete4_broken", "cityscape:concrete5_broken",
	"cityscape:sidewalk_broken", "cityscape:sandstonebrick_broken",
	"cityscape:stonebrick_broken", "cityscape:desert_stonebrick_broken",
	"cityscape:floor_ceiling_broken", "cityscape:road", "cityscape:road_broken",
	"cityscape:road_yellow_line", "cityscape:plate_glass", }
	for _, i in pairs(t) do
		good_nodes[node(breaker(i))] = true
	end

	t = { "cityscape:concrete_broken", "cityscape:sidewalk_broken", }
	for _, i in pairs(t) do
		grassy[node(breaker(i))] = true
	end
end

-- Read the noise parameters from the actual mapgen.
function cityscape.get_cpp_setting_noise(name, default)
	local noise
	local n = minetest.setting_get(name)

	if n then
		local parse = {spread = {}}
		local n1, n2, n3, n4, n5, n6, n7, n8, n9

		n1, n2, n3, n4, n5, n6, n7, n8, n9 = string.match(n, "([%d%.%-]+), ([%d%.%-]+), %(([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+)%), ([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+), ([%d%.%-]+)")
		if n9 then
			noise = {offset = tonumber(n1), scale = tonumber(n2), seed = tonumber(n6), spread = {x = tonumber(n3), y = tonumber(n4), z = tonumber(n5)}, octaves = tonumber(n7), persist = tonumber(n8), lacunarity = tonumber(n9)}
		end
	end

	-- Use the default otherwise.
	if not noise then
		noise = default
	end

	return noise
end
local get_cpp_setting_noise = cityscape.get_cpp_setting_noise

dofile(cityscape.path .. "/valleys.lua")
local noises = cityscape.noises
local get_elevation = cityscape.get_elevation

local plot_buf = {}  -- passed to functions to build houses/buildings in
local p2_buf = {}  -- passed to functions to store rotation data
local p2data = {}  -- vm rotation data buffer
local schem_data = {}


local function clear_bd(plot_buf, plot_sz_x, dy, plot_sz_z)
	for k = 0, plot_sz_x + 1 do
		if not plot_buf[k] then
			plot_buf[k] = {}
		end
		for l = 0, dy do
			if not plot_buf[k][l] then
				plot_buf[k][l] = {}
			end
			for m = 0, plot_sz_z + 1 do
				plot_buf[k][l][m] = nil
			end
		end
	end
end

local function height_index(x, z, csize)
	return (z - 1) * csize.x + (x - 1) + 1
end

local function get_height(x, z, heightmap, csize, minp, maxp)
	local h
	if x > maxp.x or x < minp.x or z > maxp.z or z < minp.z then
		h = get_elevation({x=x, z=z})
	else
		h = heightmap[height_index(x - minp.x + 1, z - minp.z + 1, csize)]

		if not h or h >= maxp.y or h <= minp.y then
			h = get_elevation({x=x, z=z})
		end
	end

	return h
end

function get_q_data(qx, qz, minp, maxp, road_map, heightmap, csize)
	local div_sz_x = math.floor(csize.x / mx)
	local div_sz_z = math.floor(csize.z / mz)
	local i_road = csize.x + 4
	local avg = 0
	local avg_c = 0
	local min = 31000
	local max = -31000
	local city = 0
	local road_p = false
	-- You can check for road by checking the noise sign at each corner.
	-- If any are different, there's a road.
	-- However, two parallel roads through the middle would defeat that.
	-- Checking the middle of each side as well would reduce the odds a lot.
	for z = minp.z + ((qz - 1) * div_sz_z), minp.z + (qz * div_sz_z) do
		for x = minp.x + ((qx - 1) * div_sz_x), minp.x + (qx * div_sz_x) do
			i_road = (z - minp.z + 1) * (csize.x + 2) + (x - minp.x + 1) + 1

			local road_n = road_map[i_road]
			local last_road_nx = road_map[i_road - 1]
			local last_road_nz = road_map[i_road - (csize.x + 2)]

			local highway = ((last_road_nx < 0 or last_road_nz < 0) and road_n > 0) or ((last_road_nx > 0 or last_road_nz > 0) and road_n < 0)
			if highway then
				road_p = true
			end

			if math.abs(road_n) < 10 then
				city = city + 1
			end

			local height = get_height(x, z, heightmap, csize, minp, maxp)

			if height > maxp.y or height < minp.y then
				-- nop
			else
				avg = avg + height
				avg_c = avg_c + 1
				if max < height then
					max = height
				end
				if min > height then
					min = height
				end
			end
		end
	end

	city = city / div_sz_x / div_sz_z
	local city_p = city > 0.5
	local side_road = city > 0

	if avg_c > 0 then
		avg = math.floor(avg / avg_c + 0.5)
	end

	local anchor = get_elevation({x = (qx - 1) * div_sz_x + minp.x, z = (qz - 1) * div_sz_z + minp.z})
	local anchor_x = get_elevation({x = qx * div_sz_x + minp.x, z = (qz - 1) * div_sz_z + minp.z})
	local anchor_z = get_elevation({x = (qx - 1) * div_sz_x + minp.x, z = qz * div_sz_z + minp.z})

	local range = (math.max(math.abs(anchor - anchor_x), math.abs(anchor - anchor_z)))
	if road_p or range > max_alt_range or anchor <= beach_level or anchor < minp.y or anchor > maxp.y - 20 then
		city_p = false
	end

	return {alt=anchor, range=range, ramp_x=anchor_x, ramp_z=anchor_z, max=max, min=min, highway=road_p, city=city_p, road=side_road}
end

local function place_schematic(a, data, pos, schem)
	local yslice = {}
	if schem.yslice_prob then
		for _, ys in pairs(schem.yslice_prob) do
			yslice[ys.ypos] = ys.prob
		end
	end

	pos.x = pos.x - math.floor(schem.size.x / 2)
	pos.z = pos.z - math.floor(schem.size.z / 2)

	for z = 0, schem.size.z - 1 do
		for x = 0, schem.size.x - 1 do
			local ivm = a:index(pos.x + x, pos.y, pos.z + z)
			local isch = z * schem.size.y * schem.size.x + x + 1
			for y = 0, schem.size.y - 1 do
				if yslice[y] or 255 >= math.random(255) then
					local prob = schem.data[isch].prob or schem.data[isch].param1 or 255
					if prob >= math.random(255) then
						data[ivm] = node(schem.data[isch].name)
					end
				end
				ivm = ivm + a.ystride
				isch = isch + schem.size.x
			end
		end
	end
end


-- Create a table of biome ids, so I can use the biomemap.
if not cityscape.biome_ids then
	local i
	cityscape.biome_ids = {}
	for name, desc in pairs(minetest.registered_biomes) do
		i = minetest.get_biome_id(desc.name)
		cityscape.biome_ids[i] = desc.name
	end
end

local tree_biomes = {}
tree_biomes["deciduous_forest"] = {"deciduous_trees"}
tree_biomes["coniferous_forest"] = {"conifer_trees"}
tree_biomes["rainforest"] = {"jungle_trees"}


function cityscape.generate(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	p2data = vm:get_param2_data()
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)
	local heightmap = minetest.get_mapgen_object("heightmap")
	local biomemap = minetest.get_mapgen_object("biomemap")

	-- divide the block into this many buildings
	local div_sz_x = math.floor(csize.x / mx)  -- size of each division with streets
	local div_sz_z = math.floor(csize.z / mz)

	local write = false

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 300 then
		print("Manually collecting garbage...")
		collectgarbage("collect")
	end

	-- use the same seed (based on perlin noise).
	local seed_noise = minetest.get_perlin({offset = 0, scale = 32768,
	seed = 5202, spread = {x = 80, y = 80, z = 80}, octaves = 2,
	persist = 0.4, lacunarity = 2})
	math.randomseed(seed_noise:get2d({x=minp.x, y=minp.z}))

	local road_map = minetest.get_perlin_map(noises[7], {x=csize.x + 2, y=csize.z + 2}):get2dMap_flat({x=minp.x - 1, y=minp.z - 1})
	local rivers = minetest.get_perlin_map(noises[2], {x=csize.x, y=csize.z}):get2dMap_flat({x=minp.x, y=minp.z})
	local road_n
	local last_road_nx
	local last_road_nz

	local suburb = false

	local plot_sz_x = math.floor((div_sz_x - streetw - sidewalk * 2) / (suburb and 2 or 1))
	local plot_sz_z = math.floor((div_sz_z - streetw - sidewalk * 2) / (suburb and 4 or 1))
	local rem_x = 0
	local rem_z = 0

	local p2, p2_ct  -- param2 (rotation) value and count
	local mm  -- which direction to build houses so they face the street

	local i_road = csize.x + 4
	local index = 1
	for qz = 1, mz do
		for qx = 1, mx do
			local q_data = get_q_data(qx, qz, minp, maxp, road_map, heightmap, csize)

			for dz = 0, div_sz_z - 1 do
				for dx = 0, div_sz_x - 1 do
					local x = minp.x + ((qx - 1) * div_sz_x) + dx
					local z = minp.z + ((qz - 1) * div_sz_z) + dz
					local i_road = (z - minp.z + 1) * (csize.x + 2) + (x - minp.x + 1) + 1
					local index = (z - minp.z) * csize.x + (x - minp.x) + 1
					road_n = road_map[i_road]
					last_road_nx = road_map[i_road - 1]
					last_road_nz = road_map[i_road - (csize.x + 2)]
					local highway = ((last_road_nx < 0 or last_road_nz < 0) and road_n > 0) or ((last_road_nx > 0 or last_road_nz > 0) and road_n < 0)
					local clear = false
					local city = q_data.city
					local height = get_height(x, z, heightmap, csize, minp, maxp)
					if math.abs(rivers[index]) < river_size then
						height = get_elevation({x=x, z=z})
					end
					local y = math.max(height, 1)

					if highway and y <= maxp.y and y >= minp.y then
						for z1 = -4, 4 do
							for x1 = -4, 4 do
								local r2 = (math.abs(x1)) ^ 2 + (math.abs(z1)) ^ 2
								if r2 <= 21 then
									local vi = a:index(x + x1, y, z + z1)
									if r2 <= 13 and data[vi] ~= node(breaker("cityscape:road")) and data[vi] ~= node(breaker("cityscape:road_white")) then
										if (y > minp.y and data[vi - a.ystride] == node(breaker("cityscape:road_white"))) or (y < maxp.y and data[vi + a.ystride] == node(breaker("cityscape:road_white"))) then
											data[vi] = node(breaker("cityscape:road_white"))
										else
											data[vi] = node(breaker("cityscape:road"))
										end
									end
									for y1 = 1, maxp.y - y do
										vi = vi + a.ystride
										if data[vi] ~= node(breaker("cityscape:road")) and data[vi] ~= node(breaker("cityscape:road_white")) then
											data[vi] = node("air")
										end
									end
								end
							end
						end

						local ivm = a:index(x, height, z)
						data[ivm] = node(breaker("cityscape:road_white"))
						write = true
					end

					if q_data.city and (dx < 5 or dz < 5) then
						local height = q_data.alt
						if dx < 5 then
							local d = q_data.ramp_z - q_data.alt
							local idz = div_sz_z - dz - 1
							if d < 0 then
								d = math.min(d + idz, 0)
							elseif d > 0 then
								d = math.max(d - idz, 0)
							end
							height = height + d
						elseif dz < 5 then
							local d = q_data.ramp_x - q_data.alt
							local idx = div_sz_x - dx - 1
							if d < 0 then
								d = math.min(d + idx, 0)
							elseif d > 0 then
								d = math.max(d - idx, 0)
							end
							height = height + d
						end

						if height > beach_level and height <= maxp.y and height >= minp.y then
							local floor = math.min(q_data.alt, q_data.ramp_x, q_data.ramp_z)
							floor = math.max(floor, minp.y - 15)
							floor = minp.y - 15
							local ivm = a:index(x, floor, z)
							for y = floor, math.min(height + 20, maxp.y) do
								if y < height then
									data[ivm] = node("default:stone")
								elseif y == height then
									data[ivm] = node(breaker("cityscape:road"))
								else
									data[ivm] = node("air")
								end
								ivm = ivm + a.ystride
							end
						end

						write = true
					elseif q_data.road and (dx < 5 or dz < 5) then
						local height = -32000

						if dx < 5 then
							height = math.max(height, math.floor((q_data.ramp_z - q_data.alt) * dz / div_sz_z + q_data.alt + 0.5))
						end
						if dz < 5 then
							height = math.max(height, math.floor((q_data.ramp_x - q_data.alt) * dx / div_sz_x + q_data.alt + 0.5))
						end

						if height > beach_level and height <= maxp.y and height >= minp.y then
							local ivm = a:index(x, height, z)
							data[ivm] = node(breaker("cityscape:road"))
							for y = height + 1, math.min(height + 20, maxp.y) do
								ivm = ivm + a.ystride
								if data[ivm] ~= node(breaker("cityscape:road")) then
									data[ivm] = node("air")
								end
							end
						end

						write = true
					end

					i_road = i_road + 1
					index = index + 1
				end
				i_road = i_road + 2
			end

			local height, range
			if q_data then
				height, range = q_data.alt, q_data.range
			end

			if q_data.city then
				for dz = 5, div_sz_z - 1 do
					for dx = 5, div_sz_x - 1 do
						local floor = math.max(minp.y, height - 20)
						local ivm = a:index(((qx - 1) * div_sz_x) + dx + minp.x, floor, ((qz - 1) * div_sz_z) + dz + minp.z)
						for y = floor, maxp.y do
							if y == height then
								data[ivm] = node(breaker("cityscape:sidewalk"))
							elseif y < height then
								data[ivm] = node("default:stone")
							else
								data[ivm] = node("air")
							end
							ivm = ivm + a.ystride
						end
					end
				end
			end

			if q_data.city then
				local alt = q_data.alt
				for mir = 1, (suburb and 2 or 1) do
					clear_bd(plot_buf, plot_sz_x, (maxp.y - alt + 2), plot_sz_z)

					if suburb then
						p2_ct = cityscape.house(plot_buf, p2_buf, plot_sz_x, maxp.y - alt, plot_sz_z, mir)
					else
						p2_ct = cityscape.build(plot_buf, p2_buf, plot_sz_x, maxp.y - alt, plot_sz_z)
					end

					for iz = 0, plot_sz_z + 1 do
						for ix = 0, plot_sz_x + 1 do
							mm = 1
							if mir == 2 then
								mm = -1
							end
							local ivm = a:index(minp.x + (qx + mir - 2) * div_sz_x + (2 - mir) * (streetw + sidewalk) + rem_x + (mm * ix) - 1, alt, minp.z + (qz - 1) * (suburb and plot_sz_z or div_sz_z) + streetw + sidewalk + rem_z + iz - 1)
							for y = 0, (maxp.y - alt + 1) do
								if plot_buf[ix][y][iz] then
									data[ivm] = plot_buf[ix][y][iz]
								elseif y > 0 then
									data[ivm] = node("air")
								end
								ivm = ivm + a.ystride
							end
						end
					end

					if p2_ct > 0 then
						for i = 1, p2_ct do
							p2 = p2_buf[i]
							local ivm = a:index(minp.x + (qx + mir - 2) * div_sz_x + (2 - mir) * (streetw + sidewalk) + rem_x + (mm * p2[1]) - 1, alt + p2[2], minp.z + (qz - 1) * (suburb and plot_sz_z or div_sz_z) + streetw + sidewalk + rem_z + p2[3] - 1)
							p2data[ivm] = p2[4]
						end
					end
				end
			elseif not q_data.road then
				local sx = minp.x + ((qx - 1) * div_sz_x) - 1
				local sz = minp.z + ((qz - 1) * div_sz_z) - 1
				for dz = 0, 35, 5 do
					for dx = 0, 35, 5 do
						if math.random(2) == 1 then
							local x = sx + dx + math.random(5)
							local z = sz + dz + math.random(5)
							local y = get_height(x, z, heightmap, csize, minp, maxp)
							local ivm = a:index(x, y, z)
							if data[ivm + a.ystride] == node("air") and (data[ivm] == node("default:dirt") or data[ivm] == node("default:dirt_with_grass") or data[ivm] == node("default:dirt_with_snow")) then
								local index_2d = dz * csize.x + dx + 1
								local biome = cityscape.biome_ids[biomemap[index_2d]]
								if tree_biomes[biome] and y >= minp.y and y <= maxp.y then
									local tree_type = tree_biomes[biome][math.random(#tree_biomes[biome])]
									local schem = cityscape.schematics[tree_type][math.random(#cityscape.schematics[tree_type])]
									local pos = {x=x, y=y, z=z}
									-- This is bull****. The schematic functions do not work.
									-- Place them programmatically since the lua api is ****ed.
									place_schematic(a, data, pos, schem)
								end
							end
						end
					end
				end

				write = true
			end
		end
	end

	if write then
		vm:set_data(data)
		vm:set_param2_data(p2data)
		vm:set_lighting({day = 0, night = 0})
		vm:calc_lighting()
		vm:update_liquids()
		vm:write_to_map()
	end
end
