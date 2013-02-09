local player = require'cairopanel_player'
local arc = require'path_arc'.arc
local svgarc = require'path_svgarc'
local shapes = require'path_shapes'
local glue = require'glue'

local i = 0
function player:on_render(cr)
	i=i+1

	--markers
	local function dot(x,y)
		cr:new_path()
		cr:arc(x,y,5,0,2*math.pi)
		cr:set_source_rgb(1,1,1)
		cr:fill_preserve()
		cr:set_source_rgb(1,0,0)
		cr:stroke()
	end

	local function line(x1,y1,x2,y2)
		cr:new_path()
		cr:set_source_rgba(0,1,0,0.3)
		cr:move_to(x1,y1)
		cr:line_to(x2,y2)
		cr:stroke()
	end

	local function dots(t)
		for i=1,#t,2 do dot(t[i], t[i+1]) end
	end

	local function lines(t)
		for i=1,#t,4 do line(unpack(t, i, i + 3)) end
	end

	--path writer
	local function write(cmd, ...)
		if cmd == 'move' then
			cr:move_to(...)
		elseif cmd == 'line' then
			cr:line_to(...)
		elseif cmd == 'curve' then
			cr:curve_to(...)
		elseif cmd == 'close' then
			cr:close_path()
		end
	end

	--init
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local a = math.rad(i)

	local function arcs_beziers()
		cr:save()
		cr:set_line_width(1)
		cr:set_source_rgba(1,1,1,.2)

		arc(write, 200, 200, 100, 200, 0, 2*math.pi)
		cr:stroke()

		cr:set_source_rgb(1,1,1)
		cr:move_to(200, 200)
		arc(write, 200, 200, 100, 200, a + 5, 1, true)
		cr:line_to(200, 200)
		cr:stroke()

		arc(write, 200, 200, 100, 200, a, 4)
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
			arc(write, x, y, 100, 100, start_angle, sweep_angle)
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
			arc(write, 125, 125, 100, 50, 0, math.pi * 2)
			cr:stroke()
			arc(write, 225, 75, 100, 50, 0, math.pi * 2)
			cr:stroke()
			cr:set_source_rgba(1,0,0,1)
			cr:move_to(125, 75)
			svgarc(write, 125, 75, 100, 50, 0, large, sweep, 125+100, 75+50)
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

