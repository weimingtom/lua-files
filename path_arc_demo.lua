local player = require'cairopanel_player'
local elliptic_arc_endpoints = require'path_elliptic_arc'.endpoints
local elliptic_arc_to_bezier3 = require'path_elliptic_arc'.to_bezier3
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_endpoints = require'path_arc'.endpoints
local svgarc_to_bezier3 = require'path_svgarc'.to_bezier3
local svgarc_to_elliptic_arc = require'path_svgarc'.to_elliptic_arc
local glue = require'glue'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function dot(cx,cy)
		cpx, cpy = cr:get_current_point()
		cr:circle(cx,cy,2)
		cr:move_to(cpx, cpy)
	end

	local function write(command, ...)
		local cpx, cpy
		if command == 'line' then
			cr:line_to(...)
			dot(...)
		elseif command == 'curve' then
			cr:curve_to(...)
			dot(select(5,...))
		end
	end

	local function elarc(...)
		local x1, y1 = elliptic_arc_endpoints(...)
		cr:move_to(x1, y1)
		elliptic_arc_to_bezier3(write, ...)
	end
	local function arc(...)
		local x1, y1 = arc_endpoints(...)
		cr:move_to(x1, y1)
		arc_to_bezier3(write, ...)
	end
	local function svgarc(x1, y1, ...)
		cr:move_to(x1, y1)
		svgarc_to_bezier3(write, x1, y1, ...)
	end

	local a = i

	local function arcs_beziers()
		cr:save()
		cr:set_line_width(1)
		cr:set_source_rgba(1,1,1,.2)

		elarc(200, 200, 100, 200, 0, 360, 30)
		cr:stroke()

		cr:set_source_rgb(1,1,1)
		cr:move_to(200, 200)
		elarc(200, 200, 100, 200, a + 270, 60, 30)
		cr:line_to(200, 200)
		cr:stroke()

		elarc(200, 200, 100, 200, a, 240, 30)
		cr:stroke()
		cr:restore()
	end

	local function arcs_angles() --study the difference between cairo and agg semantics
		local function draw(x, y, cairo_arc, a1, a2, start_angle, sweep_angle)
			cr:set_source_rgba(0,1,0,0.3)
			cr:set_line_width(5)
			cairo_arc(cr, x, y, 100, math.rad(a1), math.rad(a2))
			cr:stroke()
			cr:new_path()
			cr:set_line_width(20)
			arc(x, y, 100, start_angle, sweep_angle)
			cr:stroke()
		end
		cr:save()
		draw(300, 300, cr.arc, a, 2*a, a, a)
		draw(600, 300, cr.arc, 2*a, a, 2*a, 360 - a % 360)
		draw(300, 600, cr.arc_negative, -a, -2*a, -a, -a)
		draw(600, 600, cr.arc_negative, -2*a, -a, -2*a, -360 + a % 360)
		cr:restore()
	end

	local function svgarcs()
		--svg elliptical arc from http://www.w3.org/TR/SVG/images/paths/arcs02.svg
		local function ellipses(large, sweep)
			cr:set_line_width(5)
			cr:set_source_rgba(0,1,0,0.3)

			local rotation = -i/2

			local cx, cy, rx, ry = svgarc_to_elliptic_arc(125, 75, 100, 50, rotation, large, sweep, 125+100, 75+50)
			local mt = cr:get_matrix()
			cr:translate(cx, cy)
			cr:rotate(math.rad(rotation))
			cr:translate(-125, -125)
			cr:ellipse(125, 125, rx, ry)
			cr:set_matrix(mt)
			cr:stroke()

			cr:set_source_rgba(1,0,0,1)
			svgarc(125, 75, 100, 50, rotation, large, sweep, 125+100, 75+50)
			cr:stroke()
		end
		cr:save()
		ellipses(0, 0)
		cr:translate(400, 0)
		ellipses(0, 1)
		cr:translate(0, 300)
		ellipses(1, 0)
		cr:translate(-400, 0)
		ellipses(1, 1)
		cr:restore()
	end

	cr:save(); cr:translate(-50, 50)
	arcs_beziers()
	cr:restore(); cr:save(); cr:translate(200, -50); cr:scale(.5, .5)
	arcs_angles()
	cr:restore(); cr:save(); cr:translate(600, 50); cr:scale(.5, .5)
	svgarcs()
end

player:play()

