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


local node = {}
local nodes = {
	-- Ground nodes
	{"stone", "default:stone"},
	{"glass", "default:glass"},
	{"plate_glass", "cityscape:silver_glass"},
	{"road", "cityscape:road"},
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

	local streetw = 5    -- street width
	local sidewalk = 2   -- sidewalk width

	local bh = {}
	for i = 1,3 do
		bh[i] = {}
		for j = 1,3 do
			bh[i][j] = math.random() * (maxp.y - avg - 8) + 8
			bh[i][j] = bh[i][j] - math.floor(bh[i][j] % 4) + avg
		end
	end

	local rx = csize.x / 3
	local rz = csize.z / 3

	if true then
		local px, pz, qx, qz, ivm, street_avg
		local avg_xn, avg_xp, avg_zn, avg_zp = avg, avg, avg, avg
		local ivm_xn, ivm_xp, ivm_zn, ivm_zp

		ivm_xn = a:index(minp.x - 1, minp.y, math.floor(minp.z + rz + 1))
		ivm_xp = a:index(maxp.x + 1, minp.y, math.floor(minp.z + rz + 1))
		ivm_zn = a:index(math.floor(minp.x + rx + 1), minp.y, minp.z - 1)
		ivm_zp = a:index(math.floor(minp.x + rx + 1), minp.y, maxp.z + 1)
		for y = minp.y, maxp.y do
			if data[ivm_xn] == node["road"] then
				avg_xn = y
			end

			if data[ivm_xp] == node["road"] then
				avg_xp = y
			end

			if data[ivm_zn] == node["road"] then
				avg_zn = y
			end

			if data[ivm_zp] == node["road"] then
				avg_zp = y
			end

			ivm_xn = ivm_xn + a.ystride
			ivm_xp = ivm_xp + a.ystride
			ivm_zn = ivm_zn + a.ystride
			ivm_zp = ivm_zp + a.ystride
		end
		--print("avg (xn,xp,zn,xp): "..dump(avg_xn)..","..dump(avg_xp)..","..dump(avg_zn)..","..dump(avg_zp)..", at ("..minp.x..","..minp.z..")")
		
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ivm = a:index(x, minp.y, z)
				px = math.floor((x - minp.x) % rx)
				pz = math.floor((z - minp.z) % rz)
				qx = math.ceil((x - minp.x + 1) / rx)
				qz = math.ceil((z - minp.z + 1) / rz)
				local street = px < streetw or pz < streetw
				local ramp = (px < streetw and (qx == 2 or qx == 3)) or (pz < streetw and (qz == 2 or qz == 3))
				local develop = px >= streetw + sidewalk and pz >= streetw + sidewalk and px < math.floor(rx) - sidewalk and pz < math.floor(rz) - sidewalk
				local wall_x = px == streetw + sidewalk or px == math.floor(rx) - (sidewalk + 1)
				local wall_z = pz == streetw + sidewalk or pz == math.floor(rz) - (sidewalk + 1)

				street_avg = avg
				if math.abs(avg - avg_xn) > math.abs(x - minp.x) then
					street_avg = avg_xn + ((avg - avg_xn) / math.abs(avg - avg_xn)) * math.abs(x - minp.x)
				end
				if math.abs(avg - avg_zn) > math.abs(z - minp.z) then
					street_avg = avg_zn + ((avg - avg_zn) / math.abs(avg - avg_zn)) * math.abs(z - minp.z)
				end
				if math.abs(avg - avg_xp) > math.abs(maxp.x - x) then
					street_avg = avg_xp + ((avg - avg_xp) / math.abs(avg - avg_xp)) * math.abs(maxp.x - x)
				end
				if math.abs(avg - avg_zp) > math.abs(maxp.z - z) then
					street_avg = avg_zp + ((avg - avg_zp) / math.abs(avg - avg_zp)) * math.abs(maxp.z - z)
				end
				--if math.abs(street_avg - avg) > 10 then
				--	print("*** street_avg = "..street_avg.." at ("..x..","..z..")")
				--	print("*** avg: "..avg..", avg_(xn,xp,zn,zp): "..avg_xn..", "..avg_xp..", "..avg_zn..", "..avg_zp)
				--end

				for y = minp.y, maxp.y do
					if y == street_avg and ramp then
						data[ivm] = node["road"]
					elseif y < street_avg and ramp then
						data[ivm] = node["stone"]
					elseif y == avg and street and not ramp then
						data[ivm] = node["road"]
					elseif y < avg and street and not ramp then
						data[ivm] = node["stone"]
					elseif y <= avg and not street then
						data[ivm] = node["stone"]
					elseif develop and y <= bh[qx][qz] then
						if (y - avg) % 4 == 0 then
							data[ivm] = node["stone"]
						else
							if wall_x then
								if pz % math.floor(rz / 3) == 2 then
									data[ivm] = node["stone"]
								elseif pz % math.floor(rz / 3) == 5 and y <= avg + 2 then
									data[ivm] = node["air"]
								else
									data[ivm] = node["plate_glass"]
								end
							elseif wall_z then
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
