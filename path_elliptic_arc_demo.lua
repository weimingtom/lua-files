local player = require'cairo_player'
local arc = require'path_elliptic_arc'
local affine = require'affine2d'
local glue = require'glue'

local i = 0
function player:on_render(cr)
	i = i + 1
	local function draw_arc(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		local x1, y1 = arc.endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		cr:move_to(x1, y1)
		local function write(s, ...)
			cr:curve_to(...)
			x1, y1 = select(5, ...)
			cr:circle(x1, y1, 5)
			cr:move_to(x1, y1)
		end
		arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	end

	local function fill(r,g,b)
		cr:identity_matrix()
		cr:set_source_rgb(r,g,b)
		cr:fill()
	end
	local function stroke(r,g,b,w)
		cr:identity_matrix()
		cr:set_source_rgb(r,g,b)
		cr:set_line_width(w)
		cr:stroke()
	end

	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:set_font_size(16)
	cr:paint()

	local x0, y0 = self.mouse_x or 0, self.mouse_y or 0
	local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 400, 300, 200, 0, 300, 30
	local scale = i/10
	local mt = affine():translate(500,300):translate(-cx*scale,-cy/2*scale):scale(scale,scale)
	mt:translate(cx,cy):rotate(-27):translate(-cx,-cy)
	draw_arc(cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt); stroke(1,1,1,10)
	local d,x,y,t = arc.hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt)

	local
		cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1,
		cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2 =
			arc.split(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	draw_arc(cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1, nil, nil, mt); stroke(1,0,0,10)
	draw_arc(cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2, nil, nil, mt); stroke(0,0,1,10)

	cr:identity_matrix()
	cr:circle(x,y,2)
	fill(0,1,0)

	cr:identity_matrix()
	cr:move_to(x,y+30)
	cr:text_path(string.format('t: %4.2f (scale: %d)', t, scale))
	fill(1,1,1)
end

player:play()
