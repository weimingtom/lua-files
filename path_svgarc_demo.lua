local player = require'cairopanel_player'
local svgarc = require'path_svgarc'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local cpx, cpy
	local function write(_, x2, y2, x3, y3, x4, y4)
		cpx, cpy = cr:get_current_point()
		cr:circle(cpx,cpy, 2)
		cr:circle(x4, y4, 2)
		cr:move_to(cpx, cpy)
		cr:curve_to(x2, y2, x3, y3, x4, y4)
	end

	local x0, y0 = self.mouse_x or 0, self.mouse_y or 0
	local mind, minx, miny, mint

	--svg elliptical arc from http://www.w3.org/TR/SVG/images/paths/arcs02.svg
	local function ellipses(tx, ty, large, sweep)
		local rotation = i/5
		local x1, y1, rx, ry, x2, y2 = tx+125, ty+75, 100, 50, tx+125+100, ty+75+50
		local cx, cy, crx, cry = svgarc.to_elliptic_arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2)

		local mt = cr:get_matrix()
		cr:translate(cx, cy)
		cr:rotate(math.rad(rotation))
		cr:translate(-125, -125)
		cr:ellipse(125, 125, crx, cry)
		cr:set_matrix(mt)
		cr:set_line_width(2)
		cr:set_source_rgba(0,1,0,0.3)
		cr:stroke()

		local d, x, y, t = svgarc.hit(x0, y0, x1, y1, rx, ry, rotation, large, sweep, x2, y2)
		if not mind or d < mind then
			mind, minx, miny, mint = d, x, y, t
		end

		local
			x11, y11, rx1, ry1, rotation1, large1, sweep1, x12, y12,
			x21, y21, rx2, ry2, rotation2, large2, sweep2, x22, y22 =
				svgarc.split(t, x1, y1, rx, ry, rotation, large, sweep, x2, y2)

		cr:move_to(x11, y11)
		svgarc.to_bezier3(write, x11, y11, rx1, ry1, rotation1, large1, sweep1, x12, y12)
		cr:set_source_rgba(1,0,0,1)
		cr:stroke()

		cr:move_to(x21, y21)
		svgarc.to_bezier3(write, x21, y21, rx2, ry2, rotation2, large2, sweep2, x22, y22)
		cr:set_source_rgba(0.3,0.3,1,1)
		cr:stroke()

	end
	ellipses(0, 100, 0, 0)
	ellipses(400, 100, 0, 1)
	ellipses(400, 400, 1, 0)
	ellipses(0, 400, 1, 1)

	cr:set_source_rgb(1,1,1)
	cr:circle(minx, miny, 5)
	cr:fill()

end

player:play()

