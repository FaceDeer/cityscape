cityscape.node = {}
local node = cityscape.node
local good_nodes = {}
do
	local nodes = {
		-- Ground nodes
		{"stone", "default:stone"},
		{"concrete", "cityscape:concrete", true},
		{"concrete2", "cityscape:concrete2", true},
		{"concrete3", "cityscape:concrete3", true},
		{"concrete4", "cityscape:concrete4", true},
		{"concrete5", "cityscape:concrete5", true},
		{"sidewalk", "cityscape:sidewalk", true},
		{"floor_ceiling", "cityscape:floor_ceiling", true},
		{"roof", "cityscape:roof", true},
		{"brick", "default:brick", true},
		{"sandstone_brick", "default:sandstonebrick", true},
		{"stone_brick", "default:stonebrick", true},
		{"desert_stone_brick", "default:desert_stonebrick", true},
		{"plaster", "cityscape:plaster"},
		{"glass", "default:glass"},
		{"ladder", "default:ladder"},
		{"manhole_cover", "doors:trapdoor_steel"},
		{"light_panel", "cityscape:light_panel"},
		{"streetlight", "cityscape:streetlight"},
		{"gargoyle", "cityscape:gargoyle"},
		{"fence", "cityscape:fence_steel"},
		{"road", "cityscape:road", true},
		{"road_yellow_line", "cityscape:road_yellow_line", true},
		{"plate_glass", "cityscape:silver_glass", true},
		{"stair_road", "stairs:stair_road", true},
		{"stair_stone", "stairs:stair_stone"},
		{"stair_pine", "stairs:stair_pine_wood"},
		{"stair_wood", "stairs:stair_wood"},
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
		if i[3] then
			good_nodes[node[i[1]]] = true
		end
	end
end


local data = {}
local p2data = {}
local bd = {}
local pd = {}


function cityscape.generate(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local ivm = 0
	vm:get_data(data)
	p2data = vm:get_param2_data()
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)
	local heightmap = minetest.get_mapgen_object("heightmap")

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 500 then
		print("Cityscape is manually collecting garbage as memory use has exceeded 500K.")
		collectgarbage("collect")
	end

	local streetw = 5    -- street width
	local sidewalk = 2   -- sidewalk width
	-- divide the block into this many buildings
	local mx, mz = cityscape.divisions_x, cityscape.divisions_z

	local rx = math.floor(csize.x / mx)
	local rz = math.floor(csize.z / mz)
	local lx = math.floor((csize.x % rx) / 2)
	local lz = math.floor((csize.z % rz) / 2)
	local dx = (rx - streetw - sidewalk * 2)
	local dz = (rz - streetw - sidewalk * 2)


	local index = 0
	local avg = 0
	local count = 0
	local min = 31000
	local max = -31000
	local border = 6
	local city_block = true

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			-- One off values are likely to be errors.
			if heightmap[index] ~= minp.y - 1 and heightmap ~= maxp.y + 1 then
				-- Terrain going through minp.y or maxp.y causes problems,
				-- since there's no practical way to tell if you're above
				-- or below a city block.
				if heightmap[index] > maxp.y or heightmap[index] < minp.y then
					city_block = false
				end

				if x == minp.x + (border + 1) or z == minp.z + (border + 1) or x == maxp.x - (border + 1) or z == maxp.z - (border + 1) then
					if heightmap[index] < min then
						min = heightmap[index]
					end
					if heightmap[index] > max then
						max = heightmap[index]
					end

					avg = avg + heightmap[index]
					count = count + 1
				end
			end
		end
	end

	-- Avoid steep terrain.
	if max - min > 20 then
		city_block = false
	end

	-- If the average ground level is too high, there won't
	-- be enough room for any buildings.
	avg = math.floor((avg / count) + 0.5)
	if avg > minp.y + 67 or avg < 1 then
		city_block = false
	end

	if city_block then
		for i = 1,mx do
			if not bd[i] then
				bd[i] = {}
			end
			if not pd[i] then
				pd[i] = {}
			end
			for j = 1,mz do
				if not bd[i][j] then
					bd[i][j] = {}
				end
				pd[i][j] = {}
				for k = 0,dx+1 do
					if not bd[i][j][k] then
						bd[i][j][k] = {}
					end
					for l = 0,(maxp.y - avg + 2) do
						if not bd[i][j][k][l] then
							bd[i][j][k][l] = {}
						end
						for m = 0,dz+1 do
							bd[i][j][k][l][m] = nil
						end
					end
				end
			end
		end

		local px, pz, qx, qz, street_avg, dir, diro
		local avg_xn, avg_xp, avg_zn, avg_zp = avg, avg, avg, avg
		local ivm_xn, ivm_xp, ivm_zn, ivm_zp, sewer, manhole
		local street, ramp, street_center_x, street_center_z, streetlight
		local off_xn, off_xp, off_zn, off_zp = border, border, border, border

		sewer = avg - minp.y > 5

		-- calculating connection altitude
		-- Border data is frequently incorrect. However, there's not
		-- really any other way to deal with these issues.
		ivm_xn = a:index(minp.x - 1, minp.y, math.floor(minp.z + rx))
		ivm_xp = a:index(maxp.x + 1, minp.y, math.floor(minp.z + rx))
		ivm_zn = a:index(math.floor(minp.x + rz), minp.y, minp.z - 1)
		ivm_zp = a:index(math.floor(minp.x + rz), minp.y, maxp.z + 1)
		for y = minp.y, maxp.y do
			if good_nodes[data[ivm_xn]] then
				avg_xn = y
				off_xn = 0
			elseif off_xn == border and data[ivm_xn] == node["ignore"] then
				off_xn = border / 2
			end
			if good_nodes[data[ivm_xp]] then
				avg_xp = y
				off_xp = 0
			end
			if good_nodes[data[ivm_zn]] then
				avg_zn = y
				off_zn = 0
			elseif off_zn == border and data[ivm_zn] == node["ignore"] then
				off_zn = border / 2
			end
			if good_nodes[data[ivm_zp]] then
				avg_zp = y
				off_zp = 0
			end

			ivm_xn = ivm_xn + a.ystride
			ivm_xp = ivm_xp + a.ystride
			ivm_zn = ivm_zn + a.ystride
			ivm_zp = ivm_zp + a.ystride
		end

		-- This causes problems, but at least it clears out
		-- most of the overlapping schematics.
		for z = minp.z - off_zn, maxp.z + off_zp do
			for x = minp.x - off_xn, maxp.x + off_xp do
				if x < minp.x or x > maxp.x or z < minp.z or z > maxp.z then
					ivm = a:index(x, minp.y, z)
					for y = minp.y, maxp.y do
						if y <= avg and y > min - 5 then
							data[ivm] = node["concrete"]
						elseif y > min - 5 then
							data[ivm] = node["air"]
						end
						ivm = ivm + a.ystride
					end
				end
			end
		end

		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ivm = a:index(x, minp.y, z)
				px = math.floor((x - minp.x - lx) % rx)
				pz = math.floor((z - minp.z - lz) % rz)
				qx = math.floor((x - minp.x) / rx) + 1
				qz = math.floor((z - minp.z) / rz) + 1

				street = px < streetw or pz < streetw
				street_center_x = (px == math.floor(streetw / 2) and pz / 2 == math.floor(pz / 2)) and not (px < streetw and pz < streetw)
				street_center_z = (pz == math.floor(streetw / 2) and px / 2 == math.floor(px / 2)) and not (px < streetw and pz < streetw)
				ramp = (px < streetw and ((qx > 1 or mx == 1) and qx <= mx)) or (pz < streetw and ((qz > 1 or mz == 1) and qz <= mz))
				streetlight = px == streetw and pz == streetw
				manhole = (px == math.floor(streetw / 2)) and (pz == math.floor(streetw / 2))

				-- calculating ramps
				street_avg = avg
				dir = 0
				if math.abs(avg - avg_xn) > math.abs(x - minp.x) then
					street_avg = avg_xn + ((avg - avg_xn) / math.abs(avg - avg_xn)) * math.abs(x - minp.x)
					dir = 3
					diro = 1
				end
				if math.abs(avg - avg_zn) > math.abs(z - minp.z) then
					street_avg = avg_zn + ((avg - avg_zn) / math.abs(avg - avg_zn)) * math.abs(z - minp.z)
					dir = 4
					diro = 0
				end
				if math.abs(avg - avg_xp) > math.abs(maxp.x - x) then
					street_avg = avg_xp + ((avg - avg_xp) / math.abs(avg - avg_xp)) * math.abs(maxp.x - x)
					dir = 1
					diro = 3
				end
				if math.abs(avg - avg_zp) > math.abs(maxp.z - z) then
					street_avg = avg_zp + ((avg - avg_zp) / math.abs(avg - avg_zp)) * math.abs(maxp.z - z)
					dir = 0
					diro = 4
				end

				for y = minp.y, maxp.y + 15 do
					if y == street_avg + 1 and ramp and street_avg < avg then
						-- ramp down
						data[ivm] = node["stair_road"]
						p2data[ivm] = diro
					elseif y == street_avg and ramp and street_avg > avg then
						-- ramp up
						data[ivm] = node["stair_road"]
						p2data[ivm] = dir
					elseif sewer and street and street_avg == avg and y == avg + 1 and manhole then
						data[ivm] = node["manhole_cover"]
						p2data[ivm] = 0
					elseif sewer and street and street_avg == avg and y <= avg and manhole then
						data[ivm] = node["ladder"]
						p2data[ivm] = 4
					elseif sewer and street and y < minp.y + 1 then
						data[ivm] = node["water_source"]
					elseif sewer and street and y < minp.y + 3 then
						data[ivm] = node["air"]
					elseif y == avg and (not ramp or street_avg == avg) and street_center_x then
						data[ivm] = node["road_yellow_line"]
					elseif y == avg and (not ramp or street_avg == avg) and street_center_z then
						data[ivm] = node["road_yellow_line"]
						p2data[ivm] = 21
					elseif y == street_avg and ramp then
						-- ramp normal
						data[ivm] = node["road"]
					elseif y < street_avg and y > min - 5 and ramp then
						-- ramp support
						data[ivm] = node["stone"]
					elseif y == avg + 1 and streetlight then
						data[ivm] = node["streetlight"]
					elseif y == avg and street and not ramp then
						data[ivm] = node["road"]
					elseif y < avg and y > min - 5 and street and not ramp then
						data[ivm] = node["stone"]
					elseif y == avg and not street then
						data[ivm] = node["sidewalk"]
					elseif y < avg and y > min - 5 and not street then
						data[ivm] = node["stone"]
						-- safety barriers
					elseif not ramp and x == minp.x and z ~= minp.z and z ~= maxp.z and y == avg + 1 and street_avg < avg then
						data[ivm] = node["fence"]
					elseif not ramp and x == minp.x and z ~= minp.z and z ~= maxp.z and y == avg + 1 and street_avg > avg and street_avg - avg < 16 then
						data[ivm + a.ystride * (street_avg - avg) - 1] = node["fence"]
					elseif not ramp and x == maxp.x and z ~= minp.z and z ~= maxp.z and y == avg + 1 and street_avg < avg then
						data[ivm] = node["fence"]
					elseif not ramp and x == maxp.x and z ~= minp.z and z ~= maxp.z and y == avg + 1 and street_avg > avg and street_avg - avg < 16 then
						data[ivm + a.ystride * (street_avg - avg) + 1] = node["fence"]
					elseif not ramp and z == minp.z and x ~= minp.x and x ~= maxp.x and y == avg + 1 and street_avg < avg then
						data[ivm] = node["fence"]
					elseif not ramp and z == minp.z and x ~= minp.x and x ~= maxp.x and y == avg + 1 and street_avg > avg and street_avg - avg < 16 then
						data[ivm + a.ystride * (street_avg - avg) - a.zstride] = node["fence"]
					elseif not ramp and z == maxp.z and x ~= minp.x and x ~= maxp.x and y == avg + 1 and street_avg < avg then
						data[ivm] = node["fence"]
					elseif not ramp and z == maxp.z and x ~= minp.x and x ~= maxp.x and y == avg + 1 and street_avg > avg and street_avg - avg < 16 then
						data[ivm + a.ystride * (street_avg - avg) + a.zstride] = node["fence"]
					elseif y > min - 5 then
						data[ivm] = node["air"]
					end

					ivm = ivm + a.ystride
				end
			end
		end

		for qz = 1,mz do
			for qx = 1,mx do
				cityscape.build(bd[qx][qz], pd[qx][qz], dx, maxp.y - avg, dz)
			end
		end

		for qz = 1,mz do
			for qx = 1,mx do
				for iz = 0,dz+1 do
					for ix = 0,dx+1 do
						ivm = a:index(minp.x + (qx - 1) * rx + streetw + sidewalk + lx + ix - 1, avg, minp.z + (qz - 1) * rz + streetw + sidewalk + lz + iz - 1)
						for y = 0,(maxp.y - avg) do
							if bd[qx][qz][ix][y][iz] then
								data[ivm] = bd[qx][qz][ix][y][iz]
							elseif y > 0 then
								data[ivm] = node["air"]
							end
							ivm = ivm + a.ystride
						end
					end
				end

				for _, p in pairs(pd[qx][qz]) do
					ivm = a:index(minp.x + (qx - 1) * rx + streetw + sidewalk + lx + p[1] - 1, avg + p[2], minp.z + (qz - 1) * rz + streetw + sidewalk + lz + p[3] - 1)
					p2data[ivm] = p[4]
				end
			end
		end
	end

	vm:set_data(data)
	vm:set_param2_data(p2data)
	--vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()
end
