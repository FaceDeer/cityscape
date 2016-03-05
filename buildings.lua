local node = cityscape.node


local function lights(data, param, pos1, pos2)
	local y = math.max(pos2.y, pos1.y)
	for z = pos1.z,pos2.z do
		for x = pos1.x,pos2.x do
			if (data[x][y][z] == node['air'] or data[x][y][z] == nil) and data[x][y+1][z] == node['concrete'] and math.random(20) == 1 then
				data[x][y][z] = node['light_panel']
				param[#param+1] = {x, y, z, 20} -- 20-23
			end
		end
	end
end


local function stairwell(data, param, pos1, pos2, left)
	local dz, px, py, pz
	if left then
		dz = 0
	else
		dz = 2
	end

	px = math.floor((pos2.x - pos1.x - 4) / 2)
	py = math.min(pos2.y, pos1.y)
	pz = math.floor((pos2.z - pos1.z - 6) / 2)
	local walls = px > 1 or pz > 1

	if walls then
		for z = 1+dz,6+dz do
			for x = 1,4 do
				for y = 1,3 do
					if z == 1+dz or z == 6+dz or x == 1 or x == 4 then
						if left and x == 2 and z == 1 and y < 3 then
							data[x + px][y + py][z + pz] = node['air']
						elseif not left and x == 3 and z == 6+dz and y < 3 then
							data[x + px][y + py][z + pz] = node['air']
						else
							data[x + px][y + py][z + pz] = node['plaster']
						end
					end
				end
			end
		end
	end

	if left then
		for i = 1,4 do
			data[2 + px][i + py][2 + i + pz] = node['stair_stone']
		end
		for i = 1,3 do
			data[2 + px][4 + py][2 + i + pz] = node['air']
		end
	else
		for i = 1,4 do
			data[3 + px][i + py][7 - i + pz] = node['stair_stone']
			param[#param+1] = {3+px, i+py, 7-i+pz, 4}
		end
		for i = 1,3 do
			data[3 + px][4 + py][7 - i + pz] = node['air']
		end
	end
end


local function hospital(data, param, dx, dy, dz)
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

	for f = 1,floors do
		stairwell(data, param, {x=1,y=((f-1)*4),z=1}, {x=dx,y=(f*4-1),z=dz}, (f / 2 == math.floor(f / 2)))
		lights(data, param, {x=3,y=((f-1)*4),z=3}, {x=dx-2,y=(f*4-1),z=dz-2})
	end
end


local function standard(data, param, dx, dy, dz)
	local develop, wall_x, wall_z, floors
	floors = math.random(math.floor(dy / 4))

	for z = 1,dz do
		for x = 1,dx do
			wall_x = x == 1 or x == dx
			wall_z = z == 1 or z == dz
			for y = 1,(floors * 4) do
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

	for f = 1,floors do
		stairwell(data, param, {x=1,y=((f-1)*4),z=1}, {x=dx,y=(f*4-1),z=dz}, (f / 2 == math.floor(f / 2)))
		lights(data, param, {x=1,y=((f-1)*4),z=1}, {x=dx,y=(f*4-1),z=dz})
	end
end


function cityscape.build(data, param, dx, dy, dz)
	local sr = math.random(2)

	if math.random(10) < cityscape.vacancies then
		return
	end

	if sr == 1 then
		hospital(data, param, dx, dy, dz)
	elseif sr == 2 then
		standard(data, param, dx, dy, dz)
	end
end
