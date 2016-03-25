local node = cityscape.node

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
		good_nodes[node(i)] = true
	end

	t = { "cityscape:concrete_broken", "cityscape:sidewalk_broken", }
	for _, i in pairs(t) do
		grassy[node(i)] = true
	end
end

-- Read the noise parameters from the actual mapgen.
local function get_cpp_setting_noise(name, default)
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

local noises = {
	{offset = -10, scale = 50, seed = 5202, spread = {x = 1024, y = 1024, z = 1024}, octaves = 6, persist = 0.4, lacunarity = 2},
	{offset = 0, scale = 1, seed = -6050, spread = {x = 256, y = 256, z = 256}, octaves = 5, persist = 0.6, lacunarity = 2},
	{offset = 5, scale = 4, seed = -1914, spread = {x = 512, y = 512, z = 512}, octaves = 1, persist = 1, lacunarity = 2},
	{offset = 0.6, scale = 0.5, seed = 777, spread = {x = 512, y = 512, z = 512}, octaves = 1, persist = 1, lacunarity = 2},
	{offset = 0.5, scale = 0.5, seed = 746, spread = {x = 128, y = 128, z = 128}, octaves = 1, persist = 1, lacunarity = 2},
	{offset = 0, scale = 1, seed = 1993, spread = {x = 256, y = 512, z = 256}, octaves = 6, persist = 0.8, lacunarity = 2},
}

noises[1] = get_cpp_setting_noise("mg_valleys_np_terrain_height", noises[1])
noises[2] = get_cpp_setting_noise("mg_valleys_np_rivers", noises[2])
noises[3] = get_cpp_setting_noise("mg_valleys_np_valley_depth", noises[3])
noises[4] = get_cpp_setting_noise("mg_valleys_np_valley_profile", noises[4])
noises[5] = get_cpp_setting_noise("mg_valleys_np_inter_valley_slope", noises[5])
noises[6] = get_cpp_setting_noise("mg_valleys_np_inter_valley_fill", noises[6])
noises[7] = table.copy(noises[1])
--noises[7].scale = 1
--noises[7].offset = -0.2
noises[7].octaves = noises[6].octaves - 1
--noises[7].persist = noises[6].persist - 0.1

local function get_noise(pos, i)
	local noise = minetest.get_perlin(noises[i])
	if i == 6 then
		return noise:get3d(pos)
	else
		return noise:get2d({x=pos.x, y=pos.z})
	end
end

local river_size = 5 / 100

local function get_elevation(pos)
	local v1 = get_noise(pos, 1) -- base ground
	local v2 = math.abs(get_noise(pos, 2)) - river_size -- valleys
	local v3 = get_noise(pos, 3) ^ 2 -- valleys depth
	local base_ground = v1 + v3
	if v2 < 0 then -- river
		return math.ceil(base_ground), true, math.ceil(base_ground)
	end
	local v4 = get_noise(pos, 4) -- valleys profile
	local v5 = get_noise(pos, 5) -- inter-valleys slopes
	-- Same calculation than in cityscape.generate
	local base_ground = v1 + v3
	local valleys = v3 * (1 - math.exp(- (v2 / v4) ^ 2))
	local mountain_ground = base_ground + valleys
	local pos = {x=pos.x, y=math.floor(mountain_ground + 0.5), z=pos.z} -- For now we don't know the elevation. We will test some y values. Set the position to montain_ground which is the most probable value.
	local slopes = v5 * valleys
	if get_noise(pos, 6) * slopes > pos.y - mountain_ground then -- Position is in the ground, so look for air higher
		pos.y = pos.y + 1
		while get_noise(pos, 6) * slopes > pos.y - mountain_ground do
			pos.y = pos.y + 1
		end -- End of the loop when there is air
		return pos.y, false, mountain_ground -- Return position of the first air node, and false because that's not a river
	else -- Position is not in the ground, so look for dirt lower
		pos.y = pos.y - 1
		while get_noise(pos, 6) * slopes <= pos.y - mountain_ground do
			pos.y = pos.y - 1
		end -- End of the loop when there is dirt (or any ground)
		pos.y = pos.y + 1 -- We have the latest dirt node and we want the first air node that is just above
		return pos.y, false, mountain_ground -- Return position of the first air node, and false because that's not a river
	end
end

local function on_route(a, b, c, approx)
	if a.z == c.z then
		return math.abs(b.z - a.z) < approx
	end

	local k = (a.x - c.x) / (a.z - c.z)
	local x = a.x - (k * (a.z - b.z))
	return math.abs(x - b.x) < approx
end

local function dist(a, b)
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

local function xon_route(a, b, c)
	local approx = 1
	local dist_a_b = dist(a, b)
	local dist_a_c = dist(a, c)

	if dist_a_b + dist(b, c) <= dist_a_c + approx and dist_a_b < dist_a_c then
		return true
	end

	return false
end

local function x_comp(a, b)
	return a.x < b.x
end

local function z_comp(a, b)
	return a.z < b.z
end

local plot_buf = {}  -- passed to functions to build houses/buildings in
local p2_buf = {}  -- passed to functions to store rotation data
local p2data = {}  -- vm rotation data buffer


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
	local mx, mz = 2, 2
	local div_sz_x = math.floor(csize.x / mx)
	local div_sz_z = math.floor(csize.z / mz)
	local i_road = csize.x + 4
	local avg = 0
	local min = 31000
	local max = -31000
	local city = 0
	for z = minp.z + ((qz - 1) * div_sz_z), minp.z + (qz * div_sz_z) do
		for x = minp.x + ((qx - 1) * div_sz_x), minp.x + (qx * div_sz_x) do
			i_road = (z - minp.z + 1) * (csize.x + 2) + (x - minp.x + 1) + 1

			local road_n = road_map[i_road]
			local last_road_nx = road_map[i_road - 1]
			local last_road_nz = road_map[i_road - (csize.x + 2)]

			local road = ((last_road_nx < 0 or last_road_nz < 0) and road_n > 0) or ((last_road_nx > 0 or last_road_nz > 0) and road_n < 0)
			if road then
				--print("("..minp.x..","..minp.z.."): road is true")
				return nil
			end

			if math.abs(road_n) < 10 then
				city = city + 1
			end

			local height = get_height(x, z, heightmap, csize, minp, maxp)

			if height > maxp.y or height < minp.y then
				--print("("..minp.x..","..minp.z.."): surface is out of bounds")
				return nil
			else
				avg = avg + height
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
	if city < 0.5 then
		--print("("..minp.x..","..minp.z.."): not enough city")
		return nil
	end
	avg = math.floor(avg / div_sz_x / div_sz_z + 0.5)

	return avg, (max - min)
end


function cityscape.generate(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	p2data = vm:get_param2_data()
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)
	local heightmap = minetest.get_mapgen_object("heightmap")

	-- divide the block into this many buildings
	local mx, mz = 2, 2
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

	local q_data = {{{}, {}}, {{}, {}}}
	local ramp_data = {{{}, {}}, {{}, {}}}

	local road_map = minetest.get_perlin_map(noises[7], {x=csize.x + 2, y=csize.z + 2}):get2dMap_flat({x=minp.x - 1, y=minp.z - 1})
	local road_n
	local last_road_nx
	local last_road_nz

	for qz = 1, mz do
		for qx = 1, mx do
			q_data[qx][qz].alt, q_data[qx][qz].range = get_q_data(qx, qz, minp, maxp, road_map, heightmap, csize)
		end
	end

	ramp_data[1][1][1] = get_height(minp.x + 1, minp.z + 3, heightmap, csize, minp, maxp)
	ramp_data[1][1][2] = get_height(minp.x + 41, minp.z + 3, heightmap, csize, minp, maxp)
	ramp_data[1][1][3] = get_height(maxp.x, minp.z + 3, heightmap, csize, minp, maxp)
	ramp_data[1][2][1] = get_height(minp.x + 1, minp.z + 43, heightmap, csize, minp, maxp)
	ramp_data[1][2][2] = get_height(minp.x + 41, minp.z + 43, heightmap, csize, minp, maxp)
	ramp_data[1][2][3] = get_height(maxp.x, minp.z + 43, heightmap, csize, minp, maxp)
	ramp_data[2][1][1] = get_height(minp.x + 3, minp.z + 1, heightmap, csize, minp, maxp)
	ramp_data[2][1][2] = get_height(minp.x + 3, minp.z + 41, heightmap, csize, minp, maxp)
	ramp_data[2][1][3] = get_height(minp.x + 3, maxp.z, heightmap, csize, minp, maxp)
	ramp_data[2][2][1] = get_height(minp.x + 43, minp.z + 1, heightmap, csize, minp, maxp)
	ramp_data[2][2][2] = get_height(minp.x + 43, minp.z + 41, heightmap, csize, minp, maxp)
	ramp_data[2][2][3] = get_height(minp.x + 43, maxp.z, heightmap, csize, minp, maxp)

	-- Try to connect +x road to +x with a ramp.
	-- Try to connect +z road to +z with a ramp.
	-- Try to connect -x-z corner to -x with two ramps.
	--   If not possible, try -z.

	local connect_xpl, connect_xph
	local ivml = a:index(maxp.x + 1, minp.y, minp.z + 3)
	local ivmh = a:index(maxp.x + 1, minp.y, minp.z + 43)
	for y = minp.y, maxp.y do
		if good_nodes[data[ivml]] then
			connect_xpl = y
		end
		if good_nodes[data[ivmh]] then
			connect_xph = y
		end
		ivm = ivml + a.ystride
		ivm = ivmh + a.ystride
	end

	local suburb = false
	local streetw = 5    -- street width
	local sidewalk = 2   -- sidewalk width

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
			for dz = 0, div_sz_z - 1 do
				for dx = 0, div_sz_x - 1 do
					local x = minp.x + ((qx - 1) * div_sz_x) + dx
					local z = minp.z + ((qz - 1) * div_sz_z) + dz
					local i_road = (z - minp.z + 1) * (csize.x + 2) + (x - minp.x + 1) + 1
					local index = (z - minp.z) * csize.x + (x - minp.x) + 1
					road_n = road_map[i_road]
					last_road_nx = road_map[i_road - 1]
					last_road_nz = road_map[i_road - (csize.x + 2)]
					local road = ((last_road_nx < 0 or last_road_nz < 0) and road_n > 0) or ((last_road_nx > 0 or last_road_nz > 0) and road_n < 0)
					local clear = false
					--local city = math.abs(road_n) < 10
					local city = q_data[qx][qz] ~= nil
					local height = get_height(x, z, heightmap, csize, minp, maxp)
					local y = math.max(height, 1)

					if road and y <= maxp.y and y >= minp.y then
						for z1 = -4, 4 do
							for x1 = -4, 4 do
								local r2 = (math.abs(x1)) ^ 2 + (math.abs(z1)) ^ 2
								if r2 <= 21 then
									local vi = a:index(x + x1, y, z + z1)
									if r2 <= 13 and data[vi] ~= node("cityscape:road") and data[vi] ~= node("cityscape:road_white") then
										if (y > minp.y and data[vi - a.ystride] == node("cityscape:road_white")) or (y < maxp.y and data[vi + a.ystride] == node("cityscape:road_white")) then
											data[vi] = node("cityscape:road_white")
										else
											data[vi] = node("cityscape:road")
										end
									end
									for y1 = 1, maxp.y - y do
										vi = vi + a.ystride
										if data[vi] ~= node("cityscape:road") and data[vi] ~= node("cityscape:road_white") then
											data[vi] = node("air")
										end
									end
								end
							end
						end

						local ivm = a:index(x, height, z)
						data[ivm] = node("cityscape:road_white")
						write = true
					end

					if city and q_data[qx][qz] and q_data[qx][qz].alt and ((x - minp.x) % div_sz_x < 5 or (z - minp.z) % div_sz_z < 5) then
						local height = q_data[qx][qz].alt
						if height > 1 and height <= maxp.y and height >= minp.y then
							local ivm = a:index(x, height - 20, z)
							for y = height - 20, math.min(height + 20, maxp.y) do
								if y < height then
									data[ivm] = node("default:stone")
								elseif y == height then
									data[ivm] = node("cityscape:road")
								else
									data[ivm] = node("air")
								end
								ivm = ivm + a.ystride
							end
						end

						write = true
					elseif city and ((x - minp.x) % div_sz_x < 5 or (z - minp.z) % div_sz_z < 5) then
						local height = -32000
						if x - minp.x < 5 and z - minp.z < div_sz_z then
							height = math.max(height, math.floor((ramp_data[2][1][2] - ramp_data[2][1][1]) * (((z - minp.z) % div_sz_z) / div_sz_z) + ramp_data[2][1][1] + 0.5))
						end
						if x - minp.x < 5 and z - minp.z >= div_sz_z then
							height = math.max(height, math.floor((ramp_data[2][1][3] - ramp_data[2][1][2]) * (((z - minp.z) % div_sz_z) / div_sz_z) + ramp_data[2][1][2] + 0.5))
						end
						if (x - minp.x) >= div_sz_x and (x - minp.x) < 45 and z - minp.z < div_sz_z then
							height = math.max(height, math.floor((ramp_data[2][2][2] - ramp_data[2][2][1]) * (((z - minp.z) % div_sz_z) / div_sz_z) + ramp_data[2][2][1] + 0.5))
						end
						if (x - minp.x) >= div_sz_x and (x - minp.x) < 45 and z - minp.z >= div_sz_z then
							height = math.max(height, math.floor((ramp_data[2][2][3] - ramp_data[2][2][2]) * (((z - minp.z) % div_sz_z) / div_sz_z) + ramp_data[2][2][2] + 0.5))
						end
						if z - minp.z < 5 and x - minp.x < div_sz_x then
							height = math.max(height, math.floor((ramp_data[1][1][2] - ramp_data[1][1][1]) * (((x - minp.x) % div_sz_x) / div_sz_x) + ramp_data[1][1][1] + 0.5))
						end
						if z - minp.z < 5 and x - minp.x >= div_sz_x then
							height = math.max(height, math.floor((ramp_data[1][1][3] - ramp_data[1][1][2]) * (((x - minp.x) % div_sz_x) / div_sz_x) + ramp_data[1][1][2] + 0.5))
						end
						if (z - minp.z) >= div_sz_z and (z - minp.z) < 45 and x - minp.x < div_sz_x then
							height = math.max(height, math.floor((ramp_data[1][2][2] - ramp_data[1][2][1]) * (((x - minp.x) % div_sz_x) / div_sz_x) + ramp_data[1][2][1] + 0.5))
						end
						if (z - minp.z) >= div_sz_z and (z - minp.z) < 45 and x - minp.x >= div_sz_x then
							height = math.max(height, math.floor((ramp_data[1][2][3] - ramp_data[1][2][2]) * (((x - minp.x) % div_sz_x) / div_sz_x) + ramp_data[1][2][2] + 0.5))
						end

						if height > 1 and height <= maxp.y and height >= minp.y then
							local ivm = a:index(x, height, z)
							data[ivm] = node("cityscape:road")
							for y = height + 1, math.min(height + 20, maxp.y) do
								ivm = ivm + a.ystride
								if data[ivm] ~= node("cityscape:road") then
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
			if q_data[qx][qz] then
				height, range = q_data[qx][qz].alt, q_data[qx][qz].range
			end

			if height and range > 19 then
				--print("("..minp.x..","..minp.z.."): range is too great")
			end

			if height and height <= 1 then
				--print("("..minp.x..","..minp.z.."): height <= 1")
			end

			if height and (height <= minp.y or height > maxp.y - 20) then
				--print("("..minp.x..","..minp.z.."): height out of range")
			end


			if height and range and range < 20 and height > 1 and height > minp.y and height <= maxp.y - 20 then
				for dz = 5, div_sz_z - 1 do
					for dx = 5, div_sz_x - 1 do
						local floor = math.max(minp.y, height - 20)
						local ivm = a:index(((qx - 1) * div_sz_x) + dx + minp.x, floor, ((qz - 1) * div_sz_z) + dz + minp.z)
						for y = floor, maxp.y do
							if y == height then
								data[ivm] = node("cityscape:sidewalk")
							elseif y < height then
								data[ivm] = node("default:stone")
							else
								data[ivm] = node("air")
							end
							ivm = ivm + a.ystride
						end
					end
				end
			else
				q_data[qx][qz] = nil
			end

			local alt
			if q_data[qx][qz] then
				alt = q_data[qx][qz].alt
			end

			-- checking is done above
			if alt then
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
