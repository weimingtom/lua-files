local player = require'cairopanel_player'
local arc = require'path_arc'
local svgarc = require'path_svgarc'
local glue = require'glue'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function arc_function(arc)
		return function(...)
			local segments = arc(...)
			cr:move_to(segments[1], segments[2])
			if #segments == 4 then
				cr:line_to(segments[3], segments[4])
			else
				for i=3,#segments,8 do
					cr:curve_to(unpack(segments, i, i + 6 - 1))
				end
			end
		end
	end
	local arc = arc_function(arc)
	local svgarc = arc_function(svgarc)

	local a = math.rad(i)

	local function arcs_beziers()
		cr:save()
		cr:set_line_width(1)
		cr:set_source_rgba(1,1,1,.2)

		arc(200, 200, 100, 200, 0, 2*math.pi)
		cr:stroke()

		cr:set_source_rgb(1,1,1)
		cr:move_to(200, 200)
		arc(200, 200, 100, 200, a + 5, 1)
		cr:line_to(200, 200)
		cr:stroke()

		arc(200, 200, 100, 200, a, 4)
		cr:stroke()
		cr:restore()
	end

	local function arcs_angles() --study the difference between cairo and agg semantics
		local function draw(x, y, cairo_arc, a1, a2, start_angle, sweep_angle)
			cr:set_source_rgba(0,1,0,0.3)
			cr:set_line_width(5)
			cairo_arc(cr, x, y, 100, a1, a2)
			cr:stroke()
			cr:new_path()
			cr:set_line_width(20)
			arc(x, y, 100, 100, start_angle, sweep_angle)
			cr:stroke()
		end
		cr:save()
		local pi2 = 2*math.pi
		draw(300, 300, cr.arc, a, 2*a, a, a)
		draw(600, 300, cr.arc, 2*a, a, 2*a, pi2 - a % pi2)
		draw(300, 600, cr.arc_negative, -a, -2*a, -a, -a)
		draw(600, 600, cr.arc_negative, -2*a, -a, -2*a, -pi2 + a % pi2)
		cr:restore()
	end

	local function svgarcs()
		--svg elliptical arc from http://www.w3.org/TR/SVG/images/paths/arcs02.svg
		local function ellipses(large, sweep)
			cr:set_line_width(5)
			cr:set_source_rgba(0,1,0,0.3)
			arc(125, 125, 100, 50, 0, math.pi * 2)
			cr:stroke()
			arc(225, 75, 100, 50, 0, math.pi * 2)
			cr:stroke()
			cr:set_source_rgba(1,0,0,1)
			cr:move_to(125, 75)
			svgarc(125, 75, 100, 50, 0, large, sweep, 125+100, 75+50)
			cr:stroke()
		end
		cr:save()
		ellipses(0, 0)
		cr:translate(400, 0)
		ellipses(0, 1)
		cr:translate(0, 200)
		ellipses(1, 0)
		cr:translate(-400, 0)
		ellipses(1, 1)
		cr:restore()
	end

	cr:save(); cr:translate(-50, 50)
	arcs_beziers()
	cr:restore(); cr:save(); cr:translate(200, -50); cr:scale(0.5, 0.5)
	arcs_angles()
	cr:restore(); cr:save(); cr:translate(600, 50); cr:scale(0.5, 0.5)
	svgarcs()
end

player:play()

