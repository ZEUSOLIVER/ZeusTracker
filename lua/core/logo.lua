logo = {}

local screenWidth2 = love.graphics.getWidth()/2
local screenHeight2 = love.graphics.getHeight()/2

rectangle = {
	{x=1, y=-1, z=1},
	{x=-1, y=-1, z=1},
	{x=-1, y=1, z=1},
	{x=1, y=1, z=1},
	{x=1, y=-1, z=-1},
	{x=-1, y=-1, z=-1},
	{x=-1, y=1, z=-1},
	{x=1, y=1, z=-1}
}

stars = {}

function logo.update(dt)
    t = t + dt
    for i, star in ipairs(stars) do
        star.z = star.z - 50*dt
        if star.z <= 1 then
            star.x = math.random(-100,100)
            star.y = math.random(-100,100)
            star.z = math.random(100,200)
        end
    end
end


function logo.load(s1, s2)
	for i=1,400 do
    		stars[i] = {
        		x = math.random(-100,100),
        		y = math.random(-100,100),
        		z = math.random(10,200)
    		}
	end
end

function drawStars(scale, zoom)
    for i, star in ipairs(stars) do
        local z = star.z + zoom
        local sx = 200 + math.floor((star.x * scale) / z )
        local sy = 200 + math.floor((star.y * scale) / z )
        love.graphics.rectangle("fill", sx, sy, 1, 1)
    end
end

function logo.ASCIIZ(x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=4},
		{x=-1, y=-1, z=4},
		{x=-1, y=1, z=4},
		{x=1, y=1, z=4},
		{x=1, y=-1, z=-4},
		{x=-1, y=-1, z=-4},
		{x=-1, y=1, z=-4},
		{x=1, y=1, z=-4}
	}
	logo.draw("cube", x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=2},
		{x=-1, y=-1, z=2},
		{x=-1, y=-1, z=4},
		{x=1, y=-1, z=4},
		{x=1, y=7, z=-4},
		{x=-1, y=7, z=-4},
		{x=-1, y=7, z=-2},
		{x=1, y=7, z=-2}
	}
	logo.draw("cube", x, y+2, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=4},
		{x=-1, y=-1, z=4},
		{x=-1, y=1, z=4},
		{x=1, y=1, z=4},
		{x=1, y=-1, z=-4},
		{x=-1, y=-1, z=-4},
		{x=-1, y=1, z=-4},
		{x=1, y=1, z=-4}
	}
	logo.draw("cube", x, y+10, z, angle_x, angle_y, scale, zoom)
end

function logo.ASCIIE(x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=1},
		{x=-1, y=-1, z=1},
		{x=-1, y=11, z=1},
		{x=1, y=11, z=1},
		{x=1, y=-1, z=-1},
		{x=-1, y=-1, z=-1},
		{x=-1, y=11, z=-1},
		{x=1, y=11, z=-1}
	}
	logo.draw("cube", x, y, z+7, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=4},
		{x=-1, y=-1, z=4},
		{x=-1, y=1, z=4},
		{x=1, y=1, z=4},
		{x=1, y=-1, z=-4},
		{x=-1, y=-1, z=-4},
		{x=-1, y=1, z=-4},
		{x=1, y=1, z=-4}
	}
	logo.draw("cube", x, y, z+10, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=4},
		{x=-1, y=-1, z=4},
		{x=-1, y=1, z=4},
		{x=1, y=1, z=4},
		{x=1, y=-1, z=-4},
		{x=-1, y=-1, z=-4},
		{x=-1, y=1, z=-4},
		{x=1, y=1, z=-4}
	}
	logo.draw("cube", x, y+10, z+10, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=4},
		{x=-1, y=-1, z=4},
		{x=-1, y=1, z=4},
		{x=1, y=1, z=4},
		{x=1, y=-1, z=-4},
		{x=-1, y=-1, z=-4},
		{x=-1, y=1, z=-4},
		{x=1, y=1, z=-4}
	}
	logo.draw("cube", x, y+5, z+10, angle_x, angle_y, scale, zoom)
end

function logo.ASCIIU(x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=-1},
		{x=1, y=-1, z=1},
		{x=-1, y=-1, z=1},
		{x=-1, y=-1, z=-1},
		{x=1, y=11, z=-1},
		{x=1, y=11, z=1},
		{x=-1, y=11, z=1},
		{x=-1, y=11, z=-1}
	}
	logo.draw("cube", x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=9, z=4},
		{x=-1, y=9, z=4},
		{x=-1, y=11, z=4},
		{x=1, y=11, z=4},
		{x=1, y=9, z=-4},
		{x=-1, y=9, z=-4},
		{x=-1, y=11, z=-4},
		{x=1, y=11, z=-4}
	}
	logo.draw("cube", x, y, z+3, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=-1},
		{x=1, y=-1, z=1},
		{x=-1, y=-1, z=1},
		{x=-1, y=-1, z=-1},
		{x=1, y=11, z=-1},
		{x=1, y=11, z=1},
		{x=-1, y=11, z=1},
		{x=-1, y=11, z=-1}
	}
	logo.draw("cube", x, y, z+6, angle_x, angle_y, scale, zoom)
end

function logo.ASCIIS(x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=-1, z=-1},
		{x=1, y=-1, z=1},
		{x=-1, y=-1, z=1},
		{x=-1, y=-1, z=-1},
		{x=1, y=6, z=-1},
		{x=1, y=6, z=1},
		{x=-1, y=6, z=1},
		{x=-1, y=6, z=-1}
	}
	logo.draw("cube", x, y, z, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=4, z=4},
		{x=-1, y=4, z=4},
		{x=-1, y=6, z=4},
		{x=1, y=6, z=4},
		{x=1, y=4, z=-4},
		{x=-1, y=4, z=-4},
		{x=-1, y=6, z=-4},
		{x=1, y=6, z=-4}
	}
	logo.draw("cube", x, y, z+3, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=6, z=-1},
		{x=1, y=6, z=1},
		{x=-1, y=6, z=1},
		{x=-1, y=6, z=-1},
		{x=1, y=11, z=-1},
		{x=1, y=11, z=1},
		{x=-1, y=11, z=1},
		{x=-1, y=11, z=-1}
	}
	logo.draw("cube", x, y, z+6, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=4, z=4},
		{x=-1, y=4, z=4},
		{x=-1, y=6, z=4},
		{x=1, y=6, z=4},
		{x=1, y=4, z=-4},
		{x=-1, y=4, z=-4},
		{x=-1, y=6, z=-4},
		{x=1, y=6, z=-4}
	}
	logo.draw("cube", x, y+5, z+3, angle_x, angle_y, scale, zoom)
	rectangle = {
		{x=1, y=4, z=4},
		{x=-1, y=4, z=4},
		{x=-1, y=6, z=4},
		{x=1, y=6, z=4},
		{x=1, y=4, z=-4},
		{x=-1, y=4, z=-4},
		{x=-1, y=6, z=-4},
		{x=1, y=6, z=-4}
	}
	logo.draw("cube", x, y-5, z+3, angle_x, angle_y, scale, zoom)
end

function logo.draw(type, xp, yp, zp, x, y, scale, zoom, ret)
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	local TempCube = {}
	if type == "cube" then
		for i, point in ipairs(rectangle) do
			TempCube[i] = {
				x=point.x+xp,
				y=point.y+yp,
				z=point.z+zp
			}
		end
	else
		for i, point in ipairs(stars) do
			TempCube[i] = {
				x=point.x+xp,
				y=point.y+yp,
				z=point.z+zp
			}
		end
	end
	local sin = math.sin(x)
	local cos = math.cos(x)
	for i, point in ipairs(TempCube) do
		TempCube[i] = {
			x=point.x*sin + point.z*cos,
			y=point.y,
			z=point.x*cos - point.z*sin
		}
	end
	local sin = math.sin(y)
	local cos = math.cos(y)
	for i, point in ipairs(TempCube) do
		TempCube[i] = {
			x=point.x,
			y=point.y*sin + point.z*cos,
			z=point.y*cos - point.z*sin
		}
	end
	for i, point in ipairs(TempCube) do
		local z = point.z + zoom
		if z <= 1 then
			TempCube[i] = {
				x=screenWidth2+point.x,
				y=screenHeight2+point.y
			}

		else
			TempCube[i] = {
				x=screenWidth2+math.floor((point.x*scale)/z/2)*2,
				y=screenHeight2+math.floor((point.y*scale)/z/2)*2
			}
		end
	end
	if type == "cube" then
		love.graphics.line(TempCube[1].x, TempCube[1].y, TempCube[2].x, TempCube[2].y)
		love.graphics.line(TempCube[2].x, TempCube[2].y, TempCube[3].x, TempCube[3].y)
		love.graphics.line(TempCube[3].x, TempCube[3].y, TempCube[4].x, TempCube[4].y)
		love.graphics.line(TempCube[4].x, TempCube[4].y, TempCube[1].x, TempCube[1].y)
		love.graphics.line(TempCube[5].x, TempCube[5].y, TempCube[6].x, TempCube[6].y)
		love.graphics.line(TempCube[6].x, TempCube[6].y, TempCube[7].x, TempCube[7].y)
		love.graphics.line(TempCube[7].x, TempCube[7].y, TempCube[8].x, TempCube[8].y)
		love.graphics.line(TempCube[8].x, TempCube[8].y, TempCube[5].x, TempCube[5].y)
		love.graphics.line(TempCube[1].x, TempCube[1].y, TempCube[5].x, TempCube[5].y)
		love.graphics.line(TempCube[2].x, TempCube[2].y, TempCube[6].x, TempCube[6].y)
		love.graphics.line(TempCube[3].x, TempCube[3].y, TempCube[7].x, TempCube[7].y)
		love.graphics.line(TempCube[4].x, TempCube[4].y, TempCube[8].x, TempCube[8].y)
	else
		drawStars(scale, zoom)
	end
end

return logo