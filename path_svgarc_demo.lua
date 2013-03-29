local player = require'cairo_player'
local svgarc = require'path_svgarc'
local matrix = require'affine2d'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local cpx, cpy
	local function write(_, x2, y2, x3, y3, x4, y4)
		cpx, cpy = cr:get_current_point()
		cr:circle(cpx, cpy, 2)
		cr:circle(x4, y4, 2)
		cr:move_to(cpx, cpy)
		cr:curve_to(x2, y2, x3, y3, x4, y4)
	end

	local world_center_x, world_center_y = 500, 400
	local world_angle = i / 10
	local mt = matrix():rotate_around(world_center_x, world_center_y, world_angle)

	local function arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2, r, g, b, a)
		cr:move_to(mt(x1, y1))
		svgarc.to_bezier3(write, x1, y1, rx, ry, rotation, large, sweep, x2, y2, mt)
		cr:set_source_rgba(r, g, b, a)
		cr:stroke()
	end

	cr:set_line_width(2)

	local x0, y0 = self.mouse_x or 0, self.mouse_y or 0
	local mind, minx, miny, mint
	local function hit(x1, y1, rx, ry, rotation, large, sweep, x2, y2)

		--arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2, 1, 1, 1, 1)

		local d, x, y, t = svgarc.hit(x0, y0, x1, y1, rx, ry, rotation, large, sweep, x2, y2, mt)
		if not mind or d < mind then
			mind, minx, miny, mint = d, x, y, t
		end

		local
			x11, y11, rx1, ry1, rotation1, large1, sweep1, x12, y12,
			x21, y21, rx2, ry2, rotation2, large2, sweep2, x22, y22 =
				svgarc.split(t, x1, y1, rx, ry, rotation, large, sweep, x2, y2)

		arc(x11, y11, rx1, ry1, rotation1, large1, sweep1, x12, y12, 1, 0, 0, 1)
		arc(x21, y21, rx2, ry2, rotation2, large2, sweep2, x22, y22, 0.3, 0.3, 1, 1)
	end

	--the four svg elliptical arcs from http://www.w3.org/TR/SVG/images/paths/arcs02.svg
	local function ellipses(tx, ty, large, sweep)
		local rotation = i/5
		local x1, y1, rx, ry, x2, y2 = tx+125, ty+75, 100, 50, tx+125+100, ty+75+50
		local cx, cy, crx, cry = svgarc.to_elliptic_arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2, mt)

		local cmt = cr:get_matrix()
		cr:rotate_around(world_center_x, world_center_y, math.rad(world_angle))
		cr:translate(cx, cy)
		cr:rotate(math.rad(rotation))
		cr:translate(-125, -125)
		cr:ellipse(125, 125, crx, cry)
		cr:set_matrix(cmt)
		cr:set_source_rgba(0,1,0,0.3)
		cr:stroke()

		hit(x1, y1, rx, ry, rotation, large, sweep, x2, y2)
	end
	ellipses(0, 200, 0, 0)
	ellipses(400, 200, 0, 1)
	ellipses(400, 500, 1, 0)
	ellipses(0, 500, 1, 1)

	--degenerate arcs
	hit(700, 100, 100, 0, 0, 0, 0, 800, 200) --zero radius
	hit(800, 100, 100, 100, 0, 0, 0, 800, 100) --conincident endpoints

	--final hit point
	cr:set_line_width(1)
	cr:set_source_rgb(1,1,1)
	cr:circle(minx, miny, 5)
	cr:stroke()

end

player:play()

