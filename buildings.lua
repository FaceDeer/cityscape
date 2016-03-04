local node = cityscape.node


local function hospital(data, dx, dy, dz)
	local develop, wall_x, wall_x_2, wall_z, wall_z_2, floors
	floors = math.random(math.floor(dy / 4))

						--if y % 4 == 0 and x % 5 == 2 then
							--data[x][y][z] = node["gargoyle"]

	for z = 1,dz do
		for x = 1,dx do
			develop = x > 1 and x < dx and z > 1 and z < dz
			wall_x = x == 1 or x == dx
			wall_z = z == 1 or z == dz
			wall_x_2 = x == 2 or x == dx - 1
			wall_z_2 = z == 2 or z == dz - 1
			for y = 1,(floors * 4) do
				if y % 4 == 0 and develop then
					data[x][y][z] = node['concrete']
				elseif wall_x then
					if z % 5 == 4 then
						data[x][y][z] = node["concrete"]
					else
						data[x][y][z] = node["air"]
					end
				elseif wall_x_2 and develop then
					if z % 12 == 3 and y <= 2 then
						data[x][y][z] = node["air"]
					elseif y % 4 ~= 2 or z % 5 == 4 then
						data[x][y][z] = node["concrete"]
					else
						data[x][y][z] = node["plate_glass"]
					end
				elseif wall_z then
					if x % 5 == 4 then
						data[x][y][z] = node["concrete"]
					else
						data[x][y][z] = node["air"]
					end
				elseif wall_z_2 and develop then
					if x % 12 == 3 and y <= 2 then
						data[x][y][z] = node["air"]
					elseif y % 4 ~= 2 or x % 5 == 4 then
						data[x][y][z] = node["concrete"]
					else
						data[x][y][z] = node["plate_glass"]
					end
				else
					data[x][y][z] = node["air"]
				end
			end
		end
	end
end


local function standard(data, dx, dy, dz)
	local develop, wall_x, wall_z, floors
	floors = math.random(math.floor(dy / 4))

	for z = 1,dz do
		for x = 1,dx do
			wall_x = x == 1 or x == dx
			wall_z = z == 1 or z == dz
			for y = 1,dy do
				if y % 4 == 0 then
					data[x][y][z] = node['concrete']
				elseif wall_x then
					if (z - 2) % 5 == 2 then
						data[x][y][z] = node['concrete']
					elseif z == 6 and y <= 2 then
						data[x][y][z] = node['air']
					else
						data[x][y][z] = node['plate_glass']
					end
				elseif wall_z then
					if (x - 2) % 5 == 2 then
						data[x][y][z] = node['concrete']
					elseif x == 6 and y <= 2 then
						data[x][y][z] = node['air']
					else
						data[x][y][z] = node['plate_glass']
					end
				end
			end
		end
	end
end


function cityscape.build(data, dx, dy, dz)
	--hospital(data, dx, dy, dz)
	standard(data, dx, dy, dz)
end
