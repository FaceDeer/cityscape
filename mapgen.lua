local node = cityscape.node
local breaker = cityscape.breaker
local good_nodes = {}
local grassy = {}

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


local function clear_bd(plot_buf, plot_sz_x, dy, plot_sz_z)
	for k = 0,plot_sz_x+1 do
		if not plot_buf[k] then
			plot_buf[k] = {}
		end
		for l = 0,dy do
			if not plot_buf[k][l] then
				plot_buf[k][l] = {}
			end
			for m = 0,plot_sz_z+1 do
				plot_buf[k][l][m] = nil
			end
		end
	end
end


local data = {}  -- vm data buffer
local p2data = {}  -- vm rotation data buffer
local plot_buf = {}  -- passed to functions to build houses/buildings in
local p2_buf = {}  -- passed to functions to store rotation data
local sw = {}  -- sewer water height


function cityscape.generate(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local ivm = 0  -- vm data index
	local a = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local csize = vector.add(vector.subtract(maxp, minp), 1)
	local heightmap = minetest.get_mapgen_object("heightmap")

	-- Deal with memory issues. This, of course, is supposed to be automatic.
	local mem = math.floor(collectgarbage("count")/1024)
	if mem > 500 then
		print("Cityscape is manually collecting garbage as memory use has exceeded 500K.")
		collectgarbage("collect")
	end

	local index = 0
	local alt = 0
	local count = 0
	local min = 31000
	local max = -31000
	local border = 6

	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			index = index + 1
			-- One off values are likely to be errors.
			if heightmap[index] ~= minp.y - 1 and heightmap ~= maxp.y + 1 then
				-- Terrain going through minp.y or maxp.y causes problems,
				-- since there's no practical way to tell if you're above
				-- or below a city block.
				if heightmap[index] > maxp.y or heightmap[index] < minp.y then
					return
				end

				if x == minp.x + (border + 1) or z == minp.z + (border + 1) or x == maxp.x - (border + 1) or z == maxp.z - (border + 1) then
					if heightmap[index] < min then
						min = heightmap[index]
					end
					if heightmap[index] > max then
						max = heightmap[index]
					end

					alt = alt + heightmap[index]
					count = count + 1
				end
			end
		end
	end

	-- Avoid steep terrain.
	if max - min > 20 then
		return
	end

	-- If the average ground level is too high, there won't
	-- be enough room for any buildings.
	alt = math.floor((alt / count) + 0.5)
	if alt > minp.y + 67 or alt < 1 then
		return
	end

	local streetw = 5    -- street width
	local sidewalk = 2   -- sidewalk width
	-- divide the block into this many buildings
	local mx, mz = cityscape.divisions_x, cityscape.divisions_z

	local div_sz_x = math.floor(csize.x / mx)  -- size of each division with streets
	local div_sz_z = math.floor(csize.z / mz)
	local rem_x = math.floor((csize.x % div_sz_x) / 2)  -- left-over blocks when the divisions don't divide evenly
	local rem_z = math.floor((csize.z % div_sz_z) / 2)
	local plot_sz_x = (div_sz_x - streetw - sidewalk * 2)  -- size we can actually build on
	local plot_sz_z = (div_sz_z - streetw - sidewalk * 2)
	local div_off_x, div_off_z  -- nodes into the current division
	local sec_x, sec_z  -- which division we're in
	local alt_next  -- altitude of the next block
	local dir, diro  -- direction of ramp blocks
	-- altitude of block to the -X (xn), +X (xp), -Z (zn), +Z (zp)
	local alt_xn, alt_xp, alt_zn, alt_zp = alt, alt, alt, alt
	local ivm_xn, ivm_xp, ivm_zn, ivm_zp  -- vm data indexes
	local sewer, manhole  -- whether this square has a sewer/manhole
	-- these are similar -- whether the square has the feature
	local street, ramp, street_center_x, street_center_z, streetlight
	local xlimit, zlimit  -- whether we're at the max or min
	local suburb = false  -- is this a suburb
	-- amount of border to clear, to avoid schematic bleed-over
	local bord_xn, bord_xp, bord_zn, bord_zp = border, border, border, border

	sewer = alt - minp.y > 5
	vm:get_data(data)
	p2data = vm:get_param2_data()

	-- calculating connection altitude
	-- Border data is frequently incorrect. However, there's not
	-- really any other way to deal with these issues.
	ivm_xn = a:index(minp.x - 1, minp.y, math.floor(minp.z + div_sz_x))
	ivm_xp = a:index(maxp.x + 1, minp.y, math.floor(minp.z + div_sz_x))
	ivm_zn = a:index(math.floor(minp.x + div_sz_z), minp.y, minp.z - 1)
	ivm_zp = a:index(math.floor(minp.x + div_sz_z), minp.y, maxp.z + 1)
	for y = minp.y, maxp.y do
		if good_nodes[data[ivm_xn]] then
			alt_xn = y
			bord_xn = 0
		elseif bord_xn == border and data[ivm_xn] == node("ignore") then
			bord_xn = border / 2
		end
		if good_nodes[data[ivm_xp]] then
			alt_xp = y
			bord_xp = 0
		end
		if good_nodes[data[ivm_zn]] then
			alt_zn = y
			bord_zn = 0
		elseif bord_zn == border and data[ivm_zn] == node("ignore") then
			bord_zn = border / 2
		end
		if good_nodes[data[ivm_zp]] then
			alt_zp = y
			bord_zp = 0
		end

		ivm_xn = ivm_xn + a.ystride
		ivm_xp = ivm_xp + a.ystride
		ivm_zn = ivm_zn + a.ystride
		ivm_zp = ivm_zp + a.ystride
	end

	-- If the ramps would be too long, don't bother.
	if math.abs(alt_xn - alt) >= div_sz_x or math.abs(alt_xp - alt) >= div_sz_x
		or math.abs(alt_zn - alt) >= div_sz_z or math.abs(alt_zp - alt) >= div_sz_z then
		return
	end

	-- If there are no ramps, we might be able to fit a suburb block in.
	if math.abs(alt_xn - alt) <= streetw and  math.abs(alt_zn - alt) <= streetw
		and math.abs(alt_xp - alt) <= 1 and math.abs(alt_zp - alt) <= 1
		and math.random(10) <= cityscape.suburbs then
		suburb = true
	end

	for ivm = 1,csize.x*csize.y*csize.z+1 do
		p2data[ivm] = 0
	end

	-- This causes problems, but at least it clears out
	-- most of the overlapping schematics.
	for z = minp.z - bord_zn, maxp.z + bord_zp do
		for x = minp.x - bord_xn, maxp.x + bord_xp do
			if x < minp.x or x > maxp.x or z < minp.z or z > maxp.z then
				if not ((x < minp.x - (sidewalk + 1) or x > maxp.x + (sidewalk + 1))
					and (z < minp.z - (sidewalk + 1) or z > maxp.z + (sidewalk + 1))) then
					ivm = a:index(x, minp.y, z)
					for y = minp.y, maxp.y do
						if y <= alt and y > min - 5 then
							data[ivm] = node(breaker("cityscape:concrete"))
						elseif y > min - 5 then
							data[ivm] = node("air")
						end
						ivm = ivm + a.ystride
					end
				end
			end
		end
	end

	-- This may fix problems with the generate function getting
	-- called twice and producing split buildings.
	-- The same buildings should be generated each time if we
	-- use the same seed (based on perlin noise).
	local seed_noise = minetest.get_perlin({offset = 0, scale = 32768,
	seed = 5202, spread = {x = 80, y = 80, z = 80}, octaves = 2,
	persist = 0.4, lacunarity = 2})
	math.randomseed(seed_noise:get2d({x=minp.x, y=minp.z}))

	-- Generate the sewer water levels.
	for i = 1,mx do
		if not sw[i] then
			sw[i] = {}
		end
		for j = 1,mz do
			sw[i][j] = math.random(0,2)
		end
	end

	-- Suburbs will have to have fixed characteristics. They're too
	-- complicated to fool around with.
	if suburb then
		streetw = 3
		sidewalk = 1
		div_sz_x = math.floor((csize.x - 3) / 2)
		div_sz_z = csize.z - 3
		rem_x = math.floor((csize.x % (div_sz_x + 1.5)) / 2)
		rem_z = 0
		plot_sz_x = math.floor((div_sz_x - streetw - sidewalk * 2) / 2)
		plot_sz_z = math.floor((div_sz_z - streetw - sidewalk * 2) / 4)
	end

	local dx, dz
	for z = minp.z, maxp.z do
		for x = minp.x, maxp.x do
			ivm = a:index(x, minp.y, z)
			div_off_x = math.floor((x - minp.x - rem_x) % div_sz_x)
			div_off_z = math.floor((z - minp.z - rem_z) % div_sz_z)
			sec_x = math.floor((x - minp.x) / div_sz_x) + 1
			sec_z = math.floor((z - minp.z) / div_sz_z) + 1

			street = div_off_x < streetw or div_off_z < streetw
			street_center_x = (div_off_x == math.floor(streetw / 2) and div_off_z / 2 == math.floor(div_off_z / 2)) and not (div_off_x < streetw and div_off_z < streetw)
			street_center_z = (div_off_z == math.floor(streetw / 2) and div_off_x / 2 == math.floor(div_off_x / 2)) and not (div_off_x < streetw and div_off_z < streetw)
			ramp = (div_off_x < streetw and ((sec_x > 1 or mx == 1) and sec_x <= mx)) or (div_off_z < streetw and ((sec_z > 1 or mz == 1) and sec_z <= mz))
			streetlight = div_off_x == streetw and div_off_z == streetw
			manhole = (div_off_x == math.floor(streetw / 2)) and (div_off_z == math.floor(streetw / 2))
			xlimit = x == minp.x or x == maxp.x
			zlimit = z == minp.z or z == maxp.z
			dx = x - minp.x
			dz = z - minp.z

			-- calculating ramps
			alt_next = alt
			dir = 0
			if dx <= dz and dx + dz <= csize.x and math.abs(alt - alt_xn) > math.abs(x - minp.x) then
				if alt > alt_xn then
					alt_next = alt_xn + (x - minp.x)
				else
					alt_next = alt_xn - (x - minp.x)
				end
				dir = 3
				diro = 1
			elseif dx >= dz and dx + dz <= csize.x and math.abs(alt - alt_zn) > math.abs(z - minp.z) then
				if alt > alt_zn then
					alt_next = alt_zn + (z - minp.z)
				else
					alt_next = alt_zn - (z - minp.z)
				end
				dir = 4
				diro = 0
			elseif dx >= dz and dx + dz >= csize.x and math.abs(alt - alt_xp) > math.abs(maxp.x - x) then
				if alt > alt_xp then
					alt_next = alt_xp + (maxp.x - x)
				else
					alt_next = alt_xp - (maxp.x - x)
				end
				dir = 1
				diro = 3
			elseif dx <= dz and dx + dz >= csize.z and math.abs(alt - alt_zp) > math.abs(maxp.z - z) then
				if alt > alt_zp then
					alt_next = alt_zp + (maxp.z - z)
				else
					alt_next = alt_zp - (maxp.z - z)
				end
				dir = 0
				diro = 4
			end

			for y = minp.y, maxp.y + 15 do
				if y == alt_next + 1 and ramp and alt_next < alt then
					-- ramp down
					data[ivm] = node("stairs:stair_road")
					p2data[ivm] = diro
				elseif y == alt_next and ramp and alt_next > alt then
					-- ramp up
					data[ivm] = node("stairs:stair_road")
					p2data[ivm] = dir
				elseif sewer and street and alt_next == alt and y == alt + 1 and manhole then
					if cityscape.desolation > 0 and math.random(6) <= cityscape.desolation then
						data[ivm] = node("air")
					else
						data[ivm] = node("cityscape:manhole_cover")
						p2data[ivm] = 0
					end
				elseif sewer and street and alt_next == alt and y <= alt and manhole then
					if cityscape.desolation > 0 then
						data[ivm] = node("air")
					else
						data[ivm] = node("default:ladder")
						p2data[ivm] = 4
					end
				elseif sewer and street and (y - minp.y) < sw[math.min(sec_x,3)][math.min(sec_z,3)] then
					data[ivm] = node("default:water_source")
				elseif sewer and street and y < minp.y + 3 then
					data[ivm] = node("air")
				elseif not suburb and y == alt and (not ramp or alt_next == alt) and street_center_x then
					data[ivm] = node("cityscape:road_yellow_line")
				elseif not suburb and y == alt and (not ramp or alt_next == alt) and street_center_z then
					data[ivm] = node("cityscape:road_yellow_line")
					p2data[ivm] = 21
				elseif y == alt_next and ramp then
					-- ramp normal
					data[ivm] = node(breaker("cityscape:road"))
				elseif y < alt_next and y > min - 5 and ramp then
					-- ramp support
					data[ivm] = node("default:stone")
				elseif y == alt + 1 and streetlight then
					if cityscape.desolation > 0 then
						data[ivm] = node("cityscape:streetlight_broken")
					else
						data[ivm] = node("cityscape:streetlight")
					end
				elseif y == alt and street and not ramp then
					data[ivm] = node(breaker("cityscape:road"))
				elseif y < alt and y > min - 5 and street and not ramp then
					data[ivm] = node("default:stone")
					street = div_off_x < streetw or div_off_z < streetw
				elseif suburb and y == alt and not street and (div_off_x == streetw or div_off_x == div_sz_x - 1 or div_off_z == streetw or div_off_z == div_sz_z - 1) then
					data[ivm] = node(breaker("cityscape:sidewalk"))
				elseif suburb and y == alt and not street then
					data[ivm] = node("default:dirt_with_grass")
				elseif y == alt and not street then
					data[ivm] = node(breaker("cityscape:sidewalk"))
				elseif y < alt and y > min - 5 and not street then
					data[ivm] = node("default:stone")
					-- safety barriers
				elseif not ramp and xlimit ~= zlimit and y == alt + 1 and alt_next < alt then
					data[ivm] = node("cityscape:fence_steel")
				elseif not ramp and x == minp.x and not zlimit and y == alt_xn + 1 and alt_next > alt then
					data[ivm - 1] = node("cityscape:fence_steel")
				elseif not ramp and x == maxp.x and not zlimit and y == alt_xp + 1 and alt_next > alt then
					data[ivm + 1] = node("cityscape:fence_steel")
				elseif not ramp and z == minp.z and not xlimit and y == alt_zn + 1 and alt_next > alt then
					data[ivm - a.zstride] = node("cityscape:fence_steel")
				elseif not ramp and z == maxp.z and not xlimit and y == alt_zp + 1 and alt_next > alt then
					data[ivm + a.zstride] = node("cityscape:fence_steel")
				elseif y > min - 5 then
					data[ivm] = node("air")
				end

				ivm = ivm + a.ystride
			end
		end
	end

	local p2, p2_ct  -- param2 (rotation) value and count
	if suburb then
		local mm  -- which direction to build houses so they face the street
		for sec_z = 1,4 do
			for sec_x = 1,2 do
				for mir = 1,2 do
					clear_bd(plot_buf, plot_sz_x, (maxp.y - alt + 2), plot_sz_z)
					p2_ct = cityscape.house(plot_buf, p2_buf, plot_sz_x, maxp.y - alt, plot_sz_z, mir)
					for iz = 0,plot_sz_z+1 do
						for ix = 0,plot_sz_x+1 do
							mm = 1
							if mir == 2 then
								mm = -1
							end
							ivm = a:index(minp.x + (sec_x + mir - 2) * div_sz_x + (2 - mir) * (streetw + sidewalk) + rem_x + (mm * ix) - 1, alt, minp.z + (sec_z - 1) * plot_sz_z + streetw + sidewalk + rem_z + iz - 1)
							for y = 0,(maxp.y - alt + 1) do
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
						for i = 1,p2_ct do
							p2 = p2_buf[i]
							ivm = a:index(minp.x + (sec_x + mir - 2) * div_sz_x + (2 - mir) * (streetw + sidewalk) + rem_x + (mm * p2[1]) - 1, alt + p2[2], minp.z + (sec_z - 1) * plot_sz_z + streetw + sidewalk + rem_z + p2[3] - 1)
							p2data[ivm] = p2[4]
						end
					end
				end
			end
		end

		for iz = minp.z + streetw + sidewalk + rem_z, maxp.z - streetw - sidewalk - rem_z do
			for sec_x = 1,2 do
				ivm = a:index(minp.x + (sec_x - 1) * div_sz_x + plot_sz_x + streetw + sidewalk + rem_x, alt + 1, iz)
				data[ivm] = node("default:fence_wood")
			end
		end
	else
		for sec_z = 1,mz do
			for sec_x = 1,mx do
				clear_bd(plot_buf, plot_sz_x, (maxp.y - alt + 2), plot_sz_z)
				p2_ct = cityscape.build(plot_buf, p2_buf, plot_sz_x, maxp.y - alt, plot_sz_z)
				for iz = 0,plot_sz_z+1 do
					for ix = 0,plot_sz_x+1 do
						ivm = a:index(minp.x + (sec_x - 1) * div_sz_x + streetw + sidewalk + rem_x + ix - 1, alt, minp.z + (sec_z - 1) * div_sz_z + streetw + sidewalk + rem_z + iz - 1)
						for y = 0,(maxp.y - alt + 1) do
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
					for i = 1,p2_ct do
						p2 = p2_buf[i]
						ivm = a:index(minp.x + (sec_x - 1) * div_sz_x + streetw + sidewalk + rem_x + p2[1] - 1, alt + p2[2], minp.z + (sec_z - 1) * div_sz_z + streetw + sidewalk + rem_z + p2[3] - 1)
						p2data[ivm] = p2[4]
					end
				end
			end
		end
	end

	if cityscape.desolation > 0 then
		for z = minp.z - bord_zn, maxp.z + bord_zp do
			for x = minp.x - bord_xn, maxp.x + bord_xp do
				ivm = a:index(x, minp.y, z)
				for y = minp.y, maxp.y do
					if grassy[data[ivm]] and data[ivm+a.ystride] == node("air") and math.random(5) == 1 then
						data[ivm+a.ystride] = node("default:grass_"..math.random(3))
					elseif good_nodes[data[ivm]] and data[ivm] ~= node("cityscape:road_broken") and data[ivm+a.ystride] == node("air") and math.random(20) == 1 then
						data[ivm+a.ystride] = node("cityscape:small_rocks"..math.random(6))
						p2data[ivm+a.ystride] = math.random(4) - 1
					end
					ivm = ivm + a.ystride
				end
			end
		end
	end


	local x, z
	for i = 1,4 do
		if math.random(2) == 1 then
			x = minp.x + (math.random(mx) - 1) * div_sz_x + (math.random(2) - 1) * math.floor(streetw / 2) + rem_x + 1
			z = math.random(math.floor(csize.z / 2)) + math.floor(csize.z / 4) + minp.z
			ivm = a:index(x, alt + 1, z)
			p2data[ivm] = math.random(2) * 2 - 2
		else
			z = minp.z + (math.random(mz) - 1) * div_sz_z + (math.random(2) - 1) * math.floor(streetw / 2) + rem_z + 1
			x = math.random(math.floor(csize.x / 2)) + math.floor(csize.x / 4) + minp.x
			ivm = a:index(x, alt + 1, z)
			p2data[ivm] = math.random(2) * 2 - 1
		end

		if cityscape.desolation > 0 then
			data[ivm] = node("cityscape:car_broken")
		else
			data[ivm] = node("cityscape:car")
		end
	end

	vm:set_data(data)
	vm:set_param2_data(p2data)
	vm:set_lighting({day = 0, night = 0})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()
end
