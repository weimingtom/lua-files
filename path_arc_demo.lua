local player = require'cairo_player'
local arc = require'path_arc'
local affine = require'affine2d'
local glue = require'glue'

local scale = 1

function player:on_render(cr)

	scale = self:slider{id = 'scale',
		x = 10, y = 10, w = 400, h = 24, text = 'scale',
		i0 = 0.1, i1 = 1500, step = 0.1, i = scale,
	}

	scale = math.max(0.1, scale + scale * self.wheel_delta)

	local function draw(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, color)
		local x1, y1 = arc.endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		cr:move_to(x1, y1)
		local function write(s, ...)
			cr:curve_to(...)
			x1, y1 = select(5, ...)
			cr:circle(x1, y1, 5)
			cr:move_to(x1, y1)
		end
		arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		self:stroke(color, 10)
	end

	local x0, y0 = self.mousex or 0, self.mousey or 0
	local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 400, 300, 200, 0, 300, 30
	local mt = affine():translate(500,300):translate(-cx*scale,-cy/2*scale):scale(scale,scale)
	mt:translate(cx,cy):rotate(-27):translate(-cx,-cy)
	draw(cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt, 'normal_fg')
	local d,x,y,t = arc.hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt)

	local
		cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1,
		cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2 =
			arc.split(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	draw(cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1, nil, nil, mt, '#ff0000')
	draw(cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2, nil, nil, mt, '#0000ff')

	cr:circle(x,y,2)
	self:fill('#00ff00')

	cr:move_to(x,y+30)
	cr:text_path(string.format('t: %4.2f (scale: %d)', t, scale))
	cr:set_font_size(16)
	self:fill('normal_fg')
end

player:play()

