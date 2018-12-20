function love.load()
	--[[
	9 x 9 = 10
	16 x 16 = 40
	16 x 30 = 99
	]]
	state = 0 -- 0: idle, 1: lose, 2: win, 3: playing
	difficulty = 2 -- 1: beginner, 2: intermediate, 3: advanced
	options = {
		{9, 9, 10},
		{16, 16, 40},
		{30, 16, 99}
	}
	cell = {}
	cell.margin = 1
	cell.size = 32
	
	do
		local width = cell.margin * (options[difficulty][1] + 1) + cell.size * options[difficulty][1]
		local height = cell.margin * (options[difficulty][2] + 1) + cell.size * options[difficulty][2]
		
		love.window.setMode(width, height)
		love.graphics.setLineWidth(cell.margin)
	end
	
	function reset()
		local width = options[difficulty][1]
		local height = options[difficulty][2]
		local totalmines = options[difficulty][3]
		cell.width, cell.height = width, height
		cell.map = {}
		cell.totalmines = totalmines
		cell.totalopened = width * height
		cell.opened = {}
		cell.tagged = {}
		
		do
			for x = 1, width do
				cell.map[x] = {}
				cell.opened[x] = {}
				cell.tagged[x] = {}
				
				for y = 1, height do
					cell.map[x][y] = ' '
					cell.opened[x][y] = false
					cell.tagged[x][y] = false
				end
			end
			
			local mines = 0
			
			repeat
				local x = love.math.random(1, width)
				local y = love.math.random(1, height)
				
				if cell.map[x][y] ~= 'm' then
					cell.map[x][y] = 'm'
					mines = mines + 1
				end
			until mines == totalmines
		end
		
		for x = 1, width do
			for y = 1, height do
				if cell.map[x][y] ~= 'm' then
					local mines = 0
					
					for a = -1, 1 do
						for b = -1, 1 do
							if cell.map[x + a] and cell.map[x + a][y + b] == 'm' then
								mines = mines + 1
							end
						end
					end
					
					if mines > 0 then
						cell.map[x][y] = tostring(mines)
					end
				end
			end
		end
	end
	
	reset()
	
	state = 3
end

function love.mousepressed(x, y, button)
	if button == 1 or button == 2 then
		if state == 3 then
			x, y = (x + 1 - cell.margin) / (cell.size + cell.margin), (y + 1 - cell.margin) / (cell.size + cell.margin)
			
			if x - math.floor(x) > 0 and y - math.floor(y) > 0 then
				x, y = math.ceil(x), math.ceil(y)
				
				if button == 1 then 
					if cell.tagged[x][y] then
						return
					end
				else
					if not cell.opened[x][y] then
						cell.tagged[x][y] = not cell.tagged[x][y]
					end
					
					return
				end
						
				if cell.map[x][y] == 'm' then
					cell.opened[x][y] = true
					state = 1
					return
				end
				
				local cells = {}
				
				do
					local traversed = {}
					
					local function traverse(x, y)
						if x < 1 or y < 1 or x > cell.width or y > cell.height then
							return   
						end
						
						-- index = (y - 1) * x + x
						-- y = math.ceil(index / height)
						-- x = index - math.floor((index - 1) / height) * height
						traversed[(y - 1) * cell.width + x] = true
						cells[#cells + 1] = {x, y}
						
						if cell.map[x][y] ~= ' ' then
							return
						end
						
						for _, n in ipairs({{1, 0}, {1, -1}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}, {0, 1}, {1, 1}}) do
							local nx, ny = x + n[1], y + n[2]
							
							if not traversed[(ny - 1) * cell.width + nx] then
								if type(tonumber(cell.map[nx] and cell.map[nx][ny] or nil)) == 'number' then
									if cell.map[x][y] == ' ' then
										traverse(nx, ny)
									end
								else
									traverse(nx, ny)
								end
							end
						end
					end
					
					traverse(x, y)
				end
				
				for _, c in ipairs(cells) do
					cell.opened[c[1]][c[2]] = true
					cell.totalopened = cell.totalopened - 1
				end
				
				if cell.totalopened == cell.totalmines then
					state = 2
					return
				end
			end
		else
			reset()
			
			state = 3
		end
	end
end

function love.draw()
	for x = 1, cell.width do
		for y = 1, cell.height do
			love.graphics.setColor(.5, .5, .5)
			love.graphics.rectangle('fill',
				(x - 1) * (cell.size + cell.margin) + cell.margin,
				(y - 1) * (cell.size + cell.margin) + cell.margin,
				cell.size, cell.size)
			love.graphics.setColor(0, 0, 0)
			love.graphics.print(cell.map[x][y],
				(x - 1) * (cell.size + cell.margin) + cell.margin / 2 + (cell.size + cell.margin) / 2,
				(y - 1) * (cell.size + cell.margin) + cell.margin / 2 + (cell.size + cell.margin) / 2)
			
			if not cell.opened[x][y] then
				if cell.tagged[x][y] then
					love.graphics.setColor(1, 0, 0)
				else
					love.graphics.setColor(1, 1, 1)
				end
				
				love.graphics.rectangle('fill',
					(x - 1) * (cell.size + cell.margin) + cell.margin,
					(y - 1) * (cell.size + cell.margin) + cell.margin,
					cell.size, cell.size)
			end
		end
	end
	
	if state == 1 or state == 2 then
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(({'LOST', 'WON'})[state], 10, 10)
	end
end