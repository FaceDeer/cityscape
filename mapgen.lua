local function touch(pmin1, pmax1, pmin2, pmax2)
	if not ((pmin1.x <= pmin2.x and pmin2.x <= pmax1.x) or (pmin2.x <= pmin1.x and pmin1.x <= pmax2.x)) then
		return false
	end

	if not ((pmin1.y <= pmin2.y and pmin2.y <= pmax1.y) or (pmin2.y <= pmin1.y and pmin1.y <= pmax2.y)) then
		return false
	end

	if not ((pmin1.z <= pmin2.z and pmin2.z <= pmax1.z) or (pmin2.z <= pmin1.z and pmin1.z <= pmax2.z)) then
		return false
	end

	return true
end

local node = {}
local nodes = {
	-- Ground nodes
	{"stone", "default:stone"},
	{"glass", "default:glass"},
	{"obsidian", "default:obsidian"},
	{"dirt", "default:dirt"},
	{"dirt_with_grass", "default:dirt_with_grass"},
	{"dirt_with_dry_grass", "default:dirt_with_dry_grass"},
	{"dirt_with_snow", "default:dirt_with_snow"},
	{"sand", "default:sand"},
	{"sandstone", "default:sandstone"},
	{"desert_sand", "default:desert_sand"},
	{"gravel", "default:gravel"},
	{"desertstone", "default:desert_stone"},
	{"river_water_source", "default:river_water_source"},
	{"water_source", "default:water_source"},
	{"lava", "default:lava_source"},

	{"air", "air"},
	{"ignore", "ignore"},
}

for _, i in pairs(nodes) do
	node[i[1]] = minetest.get_content_id(i[2])
end


local function place(y, t, data, ivm)
	if y > t then
		data[ivm] = node["air"]
	else
		data[ivm] = node["stone"]
	end
end


function cityscape.generate(minp, maxp, seed)
	local leaf_radius = 3

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)

	local heightmap = minetest.get_mapgen_object("heightmap")

	local write = false

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 300 then
		print("Manually collecting garbage...")
		collectgarbage("collect")
	end

	local index = 0
	local avg = 0
	local avg_a = {{0,0,0}, {0,0,0}, {0,0,0}}
	local edge_y = {}
	local corner = {}
	local min = 31000
	local max = -31000
	local outs = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			if heightmap[index] > maxp.y or heightmap[index] < minp.y then
				outs = outs + 1
			end
			if heightmap[index] < min then
				min = heightmap[index]
			end
			if heightmap[index] > max then
				max = heightmap[index]
			end
			if max - min > 20 or min < 1 then
				return
			end

			--avg_a[2][2] = avg_a[2][2] + heightmap[index]
			--if x == minp.x then
			--	avg_a[1][2] = avg_a[1][2] + heightmap[index]
			--end
			--if x == maxp.x then
			--	avg_a[3][2] = avg_a[3][2] + heightmap[index]
			--end
			--if z == minp.z then
			--	avg_a[2][1] = avg_a[2][1] + heightmap[index]
			--end
			--if z == maxp.z then
			--	avg_a[2][3] = avg_a[2][3] + heightmap[index]
			--end
			--if max < heightmap[index] then
			--	max = heightmap[index]
			--end
			--if min > heightmap[index] then
			--	min = heightmap[index]
			--end
		end
	end
	--avg_a[2][2] = avg_a[2][2] / (csize.x * csize.z)
	--avg_a[1][2] = avg_a[1][2] / (csize.x + csize.z)
	--avg_a[3][2] = avg_a[3][2] / (csize.x + csize.z)
	--avg_a[2][1] = avg_a[2][1] / (csize.x + csize.z)
	--avg_a[2][3] = avg_a[2][3] / (csize.x + csize.z)

	--avg_a[1][1] = (avg_a[1][2] + avg_a[2][1]) / 2
	--avg_a[1][3] = (avg_a[1][2] + avg_a[2][3]) / 2
	--avg_a[3][1] = (avg_a[2][1] + avg_a[3][2]) / 2
	--avg_a[3][3] = (avg_a[2][3] + avg_a[3][2]) / 2

	--corner[1] = avg_a[1][1]
	--corner[2] = avg_a[3][1]
	--corner[3] = avg_a[1][3]
	--corner[4] = avg_a[3][3]
	--avg = avg_a[2][2]

	corner[1] = math.max(math.min(maxp.y, heightmap[1]), minp.y)  -- x0, z0
	corner[2] = math.max(math.min(maxp.y, heightmap[maxp.x - minp.x + 1]), minp.y)  -- x1, z0
	corner[3] = math.max(math.min(maxp.y, heightmap[(maxp.z - minp.z) * (maxp.x - minp.x + 1) + 1]), minp.y)  -- x0, z1
	corner[4] = math.max(math.min(maxp.y, heightmap[(maxp.z - minp.z + 1) * (maxp.x - minp.x + 1)]), minp.y)  -- x1, z1
	avg = math.floor((corner[1] + corner[2] + corner[3] + corner[4]) / 4 + 0.5)
	if avg > minp.y + 60 then
		--return
	end

	local airy = outs > csize.x * csize.z / 2
	local bh = {}
	for i = 1,3 do
		bh[i] = {}
		for j = 1,3 do
			bh[i][j] = math.random() * (maxp.y - avg - 8) + 8
			bh[i][j] = bh[i][j] - math.floor(bh[i][j] % 4) + avg
		end
	end

	local rx = csize.x / 3 + 0.01
	local rz = csize.z / 3 + 0.01

	--if max - min <= 20 then
	if true then
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				local ivm = a:index(x, minp.y, z)
				edge_y[1] = (corner[2] - corner[1]) * ((x - minp.x) / csize.x) + corner[1]
				edge_y[3] = (corner[3] - corner[1]) * ((z - minp.z) / csize.z) + corner[1]
				edge_y[2] = (corner[4] - corner[3]) * ((x - minp.x) / csize.x) + corner[3]
				edge_y[4] = (corner[4] - corner[2]) * ((z - minp.z) / csize.z) + corner[1]
				for y = minp.y, maxp.y do
					if airy then
						data[ivm] = node["air"]
					else
						local px = x - minp.x + 1
						local pz = z - minp.z + 1

						if y < avg then
							data[ivm] = node["stone"]
						elseif y == avg and ((px % rx) <= 5 or (pz % rz) <= 5) then
							data[ivm] = node["obsidian"]
						elseif ((px % rx) > 5 and (pz % rz) > 5) and y <= bh[math.ceil(px / rx)][math.ceil(pz / rz)] then
							if (y - avg) % 4 == 0 then
								data[ivm] = node["stone"]
							else
								if px % rx <= 6 or px % rx >= rx - 1 then
									if pz % math.floor(rz / 3) == 2 then
										data[ivm] = node["stone"]
									elseif pz % math.floor(rz / 3) == 5 and y <= avg + 2 then
										data[ivm] = node["air"]
									else
										data[ivm] = node["glass"]
									end
								elseif pz % rz <= 6 or pz % rz >= rz - 1 then
									if px % math.floor(rx / 3) == 2 then
										data[ivm] = node["stone"]
									elseif px % math.floor(rx / 3) == 5 and y <= avg + 2 then
										data[ivm] = node["air"]
									else
										data[ivm] = node["glass"]
									end
								else
									data[ivm] = node["air"]
								end
							end
						else
							data[ivm] = node["air"]
						end
					end
					ivm = ivm + a.ystride
				end
			end
		end
	end
	write = true

	if write then
		vm:set_data(data)
		--vm:set_lighting({day = 0, night = 0})
		vm:calc_lighting()
		vm:update_liquids()
		vm:write_to_map()
	end
end
