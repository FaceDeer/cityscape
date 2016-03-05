function math.round(x)
	return math.floor(x + 0.5)
end


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


cityscape.node = {}
local node = cityscape.node
do
	local nodes = {
		-- Ground nodes
		{"stone", "default:stone"},
		{"concrete", "cityscape:concrete"},
		{"plaster", "cityscape:plaster"},
		{"road", "cityscape:road"},
		{"glass", "default:glass"},
		{"light_panel", "cityscape:light_panel"},
		{"streetlight", "cityscape:streetlight"},
		{"gargoyle", "cityscape:gargoyle"},
		{"fence", "cityscape:fence_steel"},
		{"treebot_road", "cityscape:treebot_road"},
		{"treebot_concrete", "cityscape:treebot_concrete"},
		{"plate_glass", "cityscape:silver_glass"},
		{"stair_road", "stairs:stair_road"},
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
	end
end


local data = {}
local p2data = {}
local bd = {}
local pd = {}


function cityscape.generate(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
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
	local mx, mz = 3, 3  -- divide the block into this many buildings

	local rx = math.floor(csize.x / mx)
	local rz = math.floor(csize.z / mz)
	local lx = math.floor((csize.x % rx) / 2)
	local lz = math.floor((csize.z % rz) / 2)
	local dx, dz = (rx - streetw - sidewalk * 2), (rz - streetw - sidewalk * 2)


	local index = 0
	local avg = 0
	local count = 0
	local min = 31000
	local max = -31000
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			-- Terrain going through minp.y or maxp.y causes problems,
			-- since there's no practical way to tell if you're above
			-- or below a city block.
			if heightmap[index] > maxp.y or heightmap[index] < minp.y then
				return
			end

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

	-- Avoid steep terrain.
	if max - min > 20 or min < 1 then
		return
	end

	-- If the average ground level is too high, there won't
	-- be enough room for any buildings.
	avg = math.round(avg / count)
	if avg > minp.y + 67 then
		return
	end

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
			for k = 0,csize.x+1 do
				if not bd[i][j][k] then
					bd[i][j][k] = {}
				end
				for l = 0,(maxp.y - avg + 2) do
					if not bd[i][j][k][l] then
						bd[i][j][k][l] = {}
					end
					for m = 0,csize.z+1 do
						bd[i][j][k][l][m] = nil
					end
				end
			end
		end
	end

	local px, pz, qx, qz, ivm, street_avg, dir, diro
	local avg_xn, avg_xp, avg_zn, avg_zp = avg, avg, avg, avg
	local ivm_xn, ivm_xp, ivm_zn, ivm_zp
	local street, ramp, develop

	-- calculating connection altitude
	ivm_xn = a:index(minp.x - 1, minp.y, math.floor(minp.z + rz + 1))
	ivm_xp = a:index(maxp.x + 1, minp.y, math.floor(minp.z + rz + 1))
	ivm_zn = a:index(math.floor(minp.x + rx + 1), minp.y, minp.z - 1)
	ivm_zp = a:index(math.floor(minp.x + rx + 1), minp.y, maxp.z + 1)
	for y = minp.y, maxp.y do
		if data[ivm_xn] == node["road"] or data[ivm_xn] == node["treebot_road"] then
			avg_xn = y
		end
		if data[ivm_xp] == node["road"] or data[ivm_xp] == node["treebot_road"] then
			avg_xp = y
		end
		if data[ivm_zn] == node["road"] or data[ivm_zn] == node["treebot_road"] then
			avg_zn = y
		end
		if data[ivm_zp] == node["road"] or data[ivm_zp] == node["treebot_road"] then
			avg_zp = y
		end

		ivm_xn = ivm_xn + a.ystride
		ivm_xp = ivm_xp + a.ystride
		ivm_zn = ivm_zn + a.ystride
		ivm_zp = ivm_zp + a.ystride
	end

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			ivm = a:index(x, minp.y, z)
			px = math.floor((x - minp.x - lx) % rx)
			pz = math.floor((z - minp.z - lx) % rz)
			qx = math.ceil((x - minp.x + 1) / rx)
			qz = math.ceil((z - minp.z + 1) / rz)

			street = px < streetw or pz < streetw
			ramp = (px < streetw and (qx == 2 or qx == 3)) or (pz < streetw and (qz == 2 or qz == 3))
			develop = px >= streetw + sidewalk and pz >= streetw + sidewalk and px < rx - sidewalk and pz < rz - sidewalk
			streetlight = px == streetw and pz == streetw

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
				elseif y == street_avg and ramp then
					-- ramp normal
					data[ivm] = node["treebot_road"]
				elseif y < street_avg and ramp then
					-- ramp support
					data[ivm] = node["stone"]
				elseif y == avg + 1 and streetlight then
					data[ivm] = node["streetlight"]
				elseif y == avg and street and not ramp then
					data[ivm] = node["treebot_road"]
				elseif y < avg and street and not ramp then
					data[ivm] = node["stone"]
				elseif y == avg and not street and not develop then
					data[ivm] = node["treebot_concrete"]
				elseif y < avg and not street then
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
				else
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
			for iz = 0,dx+1 do
				for ix = 0,dz+1 do
					ivm = a:index(minp.x + (qx - 1) * rx + streetw + sidewalk + ix, avg, minp.z + (qz - 1) * rz + streetw + sidewalk + iz)
					for y = 0,(maxp.y - avg) do
						if bd[qx][qz][ix][y][iz] then
							data[ivm] = bd[qx][qz][ix][y][iz]
						else
							if y == 0 then
								data[ivm] = node['treebot_concrete']
							else
								data[ivm] = node['air']
							end
						end
						ivm = ivm + a.ystride
					end
				end
			end

			for _, p in pairs(pd[qx][qz]) do
				ivm = a:index(minp.x + (qx - 1) * rx + streetw + sidewalk + p[1], avg + p[2], minp.z + (qz - 1) * rz + streetw + sidewalk + p[3])
				p2data[ivm] = p[4]
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
