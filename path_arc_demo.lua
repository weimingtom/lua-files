local player = require'cairo_player'
local arc = require'path_arc'
local affine = require'affine2d'
local glue = require'glue'

local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 400, 300, 200, 0, 300, 30
local zoom = 1
local tangent_t = 1

function player:on_render(cr)

	self:label{x = 10, y = 10, text = 'testing best_segment_max_sweep() at different scales', font_size = 16}
	zoom = self:slider{id = 'scale', x = 10, y = 40, w = 490, h = 24, text = 'zoom', i0 = 1, i1 = 1000, i = zoom}
	start_angle = self:slider{id = 'start_angle', x = 10, y = 70, w = 190, h = 24, text = 'start angle', i0 = 0, i1 = 360, i = start_angle}
	sweep_angle = self:slider{id = 'sweep_angle', x = 10, y = 100, w = 190, h = 24, text = 'sweep angle', i0 = -360, i1 = 360, i = sweep_angle}
	tangent_t = self:slider{id = 'tangent_t', x = 10, y = 130, w = 190, h = 24, text = 'tangent t', i0 = 0, i1 = 1, step = 0.01, i = tangent_t}

	local function draw(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, color)
		local x1, y1 = arc.endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		cr:move_to(x1, y1)
		local function write(s, ...)
			cr:curve_to(...)
			x1, y1 = select(5, ...)
			cr:circle(x1, y1, 4)
			cr:move_to(x1, y1)
		end
		arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		self:stroke(color, 6)
	end

	local scale = zoom^2

	local mt = affine():translate(400, 170.922):scale(scale):translate(-400, -170.922)

	--draw
	draw(cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt, 'normal_fg')

	--draw tangent vector
	local x1, y1, x2, y2 = arc.tangent_vector(tangent_t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt)
	self:line(x1, y1, x2, y2, '#22466A', 2)
	self:dot(x2, y2, 4, '#22466A')

	--hit -> point & time
	local d,x,y,t = arc.hit(self.mousex, self.mousey, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt)

	--split -> draw #1, draw #2
	local
		cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1,
		cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2 =
			arc.split(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	draw(cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1, nil, nil, mt, '#9C6EA4')
	draw(cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2, nil, nil, mt, '#22466A')

	--exact hit/split point
	self:circle(x, y, 2, '#00ff00')

	--split time
	self:label{x = x, y = y+30, text = string.format('t: %4.2f (scale: %d)', t, scale), font_size = 16}
end

player:play()

