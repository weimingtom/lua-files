
local function to_bezier3(x1, y1, x2, y2, x3, y3, x4, y4)
    -- Catmull-Rom to Cubic Bezier conversion matrix
    --    0       1       0       0
    --  -1/6      1      1/6      0
    --    0      1/6      1     -1/6
    --    0       0       1       0
    --[[
	 bp.push( { x: p[1].x,  y: p[1].y } );
    bp.push( { x: ((-p[0].x + 6*p[1].x + p[2].x) / 6), y: ((-p[0].y + 6*p[1].y + p[2].y) / 6)} );
    bp.push( { x: ((p[1].x + 6*p[2].x - p[3].x) / 6),  y: ((p[1].y + 6*p[2].y - p[3].y) / 6) } );
    bp.push( { x: p[2].x,  y: p[2].y } );

    d += "C" + bp[1].x + "," + bp[1].y + " " + bp[2].x + "," + bp[2].y + " " + bp[3].x + "," + bp[3].y + " ";
  }
  ]]
  return d
end

local function catmull_point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	return
		0.5 * ((2 * x2) + (-x1 + x3) * t + (2*x1 - 5*x2 + 4*x3 - x4) * t^2 + (-x1 + 3*x2 - 3*x3 + x4) * t^3),
		0.5 * ((2 * y2) + (-y1 + y3) * t + (2*y1 - 5*y2 + 4*y3 - y4) * t^2 + (-y1 + 3*y2 - 3*y3 + y4) * t^3)
end

local player = require'cairopanel_player'

function player:on_render(cr)
	cr:set_source_rgb(0,0,0)
	cr:paint()
	for i=0,1,0.01 do
		local x1,y1 = 300,300
		local x2,y2 = 600,200
		local x,y = catmull_point(i, 0, 100, x1,y1, x2,y2, 1000, 100)
		cr:circle(x,y,1)
		cr:circle(x1,y1,3)
		cr:circle(x2,y2,3)
		cr:set_source_rgb(1,1,1)
		cr:stroke()
	end
end

player:play()

return {
	to_bezier3 = to_bezier3,
	--hit & split API
	point = catmull_point,
}

