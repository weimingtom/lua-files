local player = require'cairopanel_player'
local arc_to_bezier3 = require'path_arc'.arc_to_bezier3
local svgarc_to_bezier3 = require'path_svgarc'.svgarc_to_bezier3
local ellipse = require'path_shapes'.ellipse
local glue = require'glue'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function arc_function(arc_to_bezier3)
		return function(...)
			local segments = arc_to_bezier3(...)
			cr:move_to(segments[1], segments[2])
			if #segments == 4 then
				cr:line_to(segments[3], segments[4])
			else
				for i=3,#segments,8 do
					cr:curve_to(unpack(segments, i, i + 6 - 1))
				end
			end
			cr:circle(segments[1], segments[2], 2)
			cr:circle(segments[#segments-1], segments[#segments], 6)
		end
	end
	local arc = arc_function(arc_to_bezier3)
	local svgarc = arc_function(svgarc_to_bezier3)

	local a = math.rad(i)

	local function arcs_beziers()
		cr:save()
		cr:set_line_width(1)
		cr:set_source_rgba(1,1,1,.2)

		arc(200, 200, 100, 0, 2*math.pi)
		cr:stroke()

		cr:set_source_rgb(1,1,1)
		cr:move_to(200, 200)
		arc(200, 200, 100, a + 5, 1)
		cr:line_to(200, 200)
		cr:stroke()

		arc(200, 200, 100, a, 4)
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
			arc(x, y, 100, start_angle, sweep_angle)
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

	local ellipse_ = ellipse
	local function write(s, ...)
		if s == 'move' then cr:move_to(...)
		elseif s == 'curve' then cr:curve_to(...)
		elseif s == 'close' then cr:close_path(...)
		end
	end
	local function ellipse(...)
		ellipse_(write, ...)
	end

	local function svgarcs()
		--svg elliptical arc from http://www.w3.org/TR/SVG/images/paths/arcs02.svg
		local function ellipses(large, sweep)
			cr:set_line_width(5)
			cr:set_source_rgba(0,1,0,0.3)
			ellipse(125, 125, 100, 50)
			cr:stroke()
			ellipse(225, 75, 100, 50)
			cr:stroke()
			cr:set_source_rgba(1,0,0,1)
			cr:move_to(125, 75)
			svgarc(125, 75, 100, 50, i/100, large, sweep, 125+100, 75+50)
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

