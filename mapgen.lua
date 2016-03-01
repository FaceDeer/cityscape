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
	{"plate_glass", "cityscape:silver_glass"},
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
	local count = 0
	local min = 31000
	local max = -31000
	local outs_up = 0
	local outs_down = 0
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			if heightmap[index] > maxp.y then
				outs_up = outs_up + 1
			elseif heightmap[index] < minp.y then
				outs_down = outs_down + 1
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

			avg = avg + heightmap[index]
			count = count + 1
		end
	end

	avg = math.floor(avg / count + 0.5)
	if avg > minp.y + 67 then
		return
	end

	local airy = outs_down > 0 and outs_up + outs_down < csize.x * csize.z
	local earthy = outs_up > 0 and outs_up + outs_down < csize.x * csize.z
	local urban = outs_up + outs_down < csize.x * csize.z / 2
	local centered = avg >= minp.y and avg <= maxp.y
	local streetw = 5
	local sidewalk = 2

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

	if true then
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				local ivm = a:index(x, minp.y, z)
				for y = minp.y, maxp.y do
					if airy and urban and not centered then
						data[ivm] = node["air"]
					elseif earthy and urban and not centered then
						data[ivm] = node["stone"]
					elseif centered then
						local px = x - minp.x + 1
						local pz = z - minp.z + 1

						if y < avg then
							data[ivm] = node["stone"]
						elseif y == avg and ((px % rx) <= streetw or (pz % rz) <= streetw) then
							data[ivm] = node["obsidian"]
						elseif y == avg then
							data[ivm] = node["stone"]
						elseif ((px % rx) > streetw + sidewalk and (pz % rz) > streetw + sidewalk and (px % rx) < rx - sidewalk and (pz % rz) < rz - sidewalk) and y <= bh[math.ceil(px / rx)][math.ceil(pz / rz)] then
							if (y - avg) % 4 == 0 then
								data[ivm] = node["stone"]
							else
								if px % rx <= streetw + sidewalk + 1 or px % rx >= rx - (sidewalk + 1) then
									if pz % math.floor(rz / 3) == 2 then
										data[ivm] = node["stone"]
									elseif pz % math.floor(rz / 3) == 5 and y <= avg + 2 then
										data[ivm] = node["air"]
									else
										data[ivm] = node["plate_glass"]
									end
								elseif pz % rz <= streetw + sidewalk + 1 or pz % rz >= rz - (sidewalk + 1) then
									if px % math.floor(rx / 3) == 2 then
										data[ivm] = node["stone"]
									elseif px % math.floor(rx / 3) == 5 and y <= avg + 2 then
										data[ivm] = node["air"]
									else
										data[ivm] = node["plate_glass"]
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

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 500 then
		print("Cityscape is manually collecting garbage as memory use has exceeded 500K.")
		collectgarbage("collect")
	end
end
