local player = require'cairo_player'
local glue = require'glue'
local path_state = require'path'
local path_cairo = require'path_cairo'

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local distance = require'path_point'.distance
local point_angle = require'path_point'.point_angle
local point_around = require'path_point'.point_around

local path = {
	'move', 900, 110,
	--lines and control commands
	'rel_line', 20, 100,
	'rel_hline', 100,
	'rel_vline', -100,
	'close',
	'rel_line', 50, 50,
	--quad curves
	'move', 100, 160,
	'rel_quad_curve', 20, -100, 40, 0,
	'rel_symm_quad_curve', 40, 0,
	'rel_move', 50, 0,
	'rel_smooth_quad_curve', 100, 20, 0, --smooth without a tangent
	'rel_move', 50, 0,
	'rel_quad_curve', 20, -100, 20, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a quad curve
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a quad curve
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a quad curve
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a quad curve
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_curve', 0, -100, 40, -100, 40, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a cubic curve
	--[[
	'rel_move', 50, 0,
	'rel_arc_3p', 0, -40, 50, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth an arc
	'rel_move', 50, -50,
	'rel_line', 0, 50,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a line
	'rel_move', 50, 0,
	'rel_quad_curve_3p', 20, -50, 40, 0,  --3p
	--cubic curves
	'move', 100, 300,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_symm_curve', 40, 50, 40, 0,
	'rel_move', 50, 0,
	'rel_smooth_curve', 100, 20, 50, 20, 0, --smooth without a tangent
	'rel_move', 50, 0,
	'rel_quad_curve', 20, -100, 20, 0,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a quad curve
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a cubic curve
	'rel_move', 50, 0,
	'rel_arc_3p', 0, -40, 50, 0,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth an arc
	'rel_move', 50, -50,
	'rel_line', 0, 50,
	'rel_smooth_curve', 50, 40, 50, 40, 0, --smooth a line
	--arcs
	'move', 100, 450,
	'rel_line_arc', 0, 0, 50, -90, 180,
	'rel_move', 100, -50,
	'rel_arc', 0, 0, 50, -90, 180,
	'rel_move', 100, -100,
	'rel_svgarc', -50, -20, -30, 0, 1, 30, 40,
	'rel_svgarc', -50, -20, -30, 1, 0, 30, 40,
	'rel_svgarc', 10, 0, 0, 0, 0, 50, 0, --invalid parametrization (zero radius)
	'rel_svgarc', 10, 10, 10, 10, 0, 0, 0, --invalid parametrization (endpoints coincide)
	'rel_move', 50, -50,
	'rel_arc_3p', 40, -40, 80, 0,
	'rel_arc_3p', 40, 0, 40, 0, --invalid parametrization (endpoints are collinear)
	'rel_arc_3p', 0, 0, 0, 0, --invalid parametrization (endpoints coincide)
	'rel_move', 70, 0,
	'rel_line_elliptic_arc', 0, 0, 70, 30, 0, -270, -30,
	'close',
	--closed shapes
	'rect', 100+60, 650, -50, -100,
	'round_rect', 100+120, 650, -50, -100, -10,
	'elliptic_rect', 100+180, 650, -50, -100, -100, -10,
	'elliptic_rect', 100+240, 650, -50, -100, -10, -100,
	'circle', 100+300, 600, -50,
	'ellipse', 100+390, 600, -30, -50, 30,
	'move', 100+480, 600,
	'rel_circle_3p', 50, 0, 0, 50, -50, 0,
	'superformula', 100+580, 600, 50, 300, 1, 1, 3, 1, 1, 1,
	'move', 100+700, 600,
	'rel_star', 0, 0, 0, -50, 30, 8,
	'move', 100+800, 600,
	'rel_star_2p', 0, 0, 0, -50, 20, 15, 5,
	'move', 100+900, 600,
	'rel_rpoly', 0, 0, 20, -30, 5,
	'move', 700, 350,
	'rel_text', 0, 0, {size=70}, 'mittens',
	]]
}

local function recursion_safe(f)
	local setting = false
	return function(...)
		if setting then return end
		setting = true
		f(...)
		setting = false
	end
end

local function new_mutex()
	local setting = false
	return function(f)
		return function(...)
			if setting then return end
			setting = true
			f(...)
			setting = false
		end
	end
end

local function control_points(path)
	local points = {}
	local setters = {}
	local dx, dy = 0, 0 --point delta, for shifting points

	local function pt(x, y)
		local xi, yi = #points+1, #points+2
		points[xi] = x
		points[yi] = y
		local function set_px(v) points[xi] = v end
		local function set_py(v) points[yi] = v end
		setters[xi] = set_px
		setters[yi] = set_py
		return xi, yi
	end

	local function chain(pi, setter)
		local old_setter = setters[pi]
		setters[pi] = function(v)
			old_setter(v)
			setter(v)
		end
	end

	local cpx, cpy, spx, spy, tkind, tx, ty, tclen

	for i,s in path_state.commands(path) do
		if s == 'move' or s == 'line' then
			local c2x, c2y = i+1, i+2
			local p2x, p2y = pt(path[c2x], path[c2y])
			chain(p2x, function(v) path[c2x] = points[p2x] end)
			chain(p2y, function(v) path[c2y] = points[p2y] end)

			cpx, cpy = p2x, p2y
			spx, spy = cpx, cpy
			tkind = nil
		elseif s == 'rel_move' or s == 'rel_line' then
			local c2x, c2y = i+1, i+2
			local p1x, p1y = cpx, cpy
			local p2x, p2y = pt(points[p1x] + path[c2x], points[p1y] + path[c2y])
			chain(p2x, function(v) path[c2x] = points[p2x] - points[p1x] end)
			chain(p2y, function(v) path[c2y] = points[p2y] - points[p1y] end)
			chain(p1x, function(v) path[c2x] = points[p2x] - points[p1x] end)
			chain(p1y, function(v) path[c2y] = points[p2y] - points[p1y] end)

			cpx, cpy = p2x, p2y
			tkind = nil
		elseif s == 'hline' then
			local p1y = cpy
			local c2x = i+1
			local p2x, p2y = pt(path[c2x], points[p1y])
			chain(p2x, function(v) path[c2x] = points[p2x] end)

			cpx, cpy = p2x, p2y
			tkind = nil
		elseif s == 'vline' then
			local p1x = cpx
			local c2y = i+1
			local p2x, p2y = pt(points[p1x], path[c2y])
			chain(p2y, function(v) path[c2y] = points[p2y] end)

			cpx, cpy = p2x, p2y
			tkind = nil
		elseif s == 'rel_hline' then
			local p1x, p1y = cpx, cpy
			local c2x = i+1
			local p2x, p2y = pt(points[p1x] + path[c2x], points[p1y])
			chain(p2x, function(v) path[c2x] = points[p2x] - points[p1x] end)
			chain(p1x, function(v) path[c2x] = points[p2x] - points[p1x] end)
			chain(p2y, function(v) setters[p1y](v) end)
			chain(p1y, recursion_safe(function(v) setters[p2y](v) end))

			cpx, cpy = p2x, p2y
			tkind = nil
		elseif s == 'rel_vline' then
			local p1x, p1y = cpx, cpy
			local c2y = i+1
			local p2x, p2y = pt(points[p1x], points[p1y] + path[c2y])
			chain(p2y, function(v) path[c2y] = points[p2y] - points[p1y] end)
			chain(p1y, function(v) path[c2y] = points[p2y] - points[p1y] end)
			chain(p2x, function(v) setters[p1x](v) end)
			chain(p1x, recursion_safe(function(v) setters[p2x](v) end))

			cpx, cpy = p2x, p2y
			tkind = nil
		elseif s == 'close' or s == 'rel_close' then
			cpx, cpy = spx, spy
			tkind = nil
		elseif s == 'quad_curve' then
			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y = pt(path[c2x], path[c2y])
			local p3x, p3y = pt(path[c3x], path[c3y])

			local set_c2x = function(v) path[c2x] = points[p2x] end
			local set_c2y = function(v) path[c2y] = points[p2y] end
			local set_c3x = function(v) path[c3x] = points[p3x] end
			local set_c3y = function(v) path[c3y] = points[p3y] end

			--points update themselves in path
			chain(p2x, set_c2x)
			chain(p2y, set_c2y)
			chain(p3x, set_c3x)
			chain(p3y, set_c3y)

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil
		elseif s == 'rel_quad_curve' then
			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y = pt(points[p1x] + path[c2x], points[p1y] + path[c2y])
			local p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])

			local set_c2x = function(v) path[c2x] = points[p2x] - points[p1x] end
			local set_c2y = function(v) path[c2y] = points[p2y] - points[p1y] end
			local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
			local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end

			--points update themselves in path
			chain(p2x, set_c2x)
			chain(p2y, set_c2y)
			chain(p3x, set_c3x)
			chain(p3y, set_c3y)

			--current point moves its relative points
			chain(p1x, set_c2x)
			chain(p1y, set_c2y)
			chain(p1x, set_c3x)
			chain(p1y, set_c3y)

			--end points carry control point
			local shift_p2x = function(v) setters[p2x](points[p2x] + dx) end
			local shift_p2y = function(v) setters[p2y](points[p2y] + dy) end
			chain(p1x, shift_p2x)
			chain(p1y, shift_p2y)
			chain(p3x, shift_p2x)
			chain(p3y, shift_p2y)

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil
		elseif s == 'symm_quad_curve' then

		elseif s == 'rel_symm_quad_curve' then
			local p1x, p1y = cpx, cpy
			local c3x, c3y = i+1, i+2
			local p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])

			local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
			local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end

			chain(p3x, set_c3x)
			chain(p3y, set_c3y)

			chain(p1x, set_c3x)
			chain(p1y, set_c3y)

			local p2x, p2y
			if tkind == 'quad' then
				p2x, p2y = pt(reflect_point(points[tx], points[ty], points[p1x], points[p1y]))
				local tx_, ty_ = tx, ty
				chain(p2x, recursion_safe(function(v)
					setters[tx_]((reflect_point(points[p2x], points[p2y], points[p1x], points[p1y])))
				end))
				chain(p2y, recursion_safe(function(v)
					setters[ty_](select(2, reflect_point(points[p2x], points[p2y], points[p1x], points[p1y])))
				end))
				chain(tx, function(v)
					setters[p2x]((reflect_point(points[tx_], points[ty_], points[p1x], points[p1y])))
				end)
				chain(ty, function(v)
					setters[p2y](select(2, reflect_point(points[tx_], points[ty_], points[p1x], points[p1y])))
				end)

				--end points carry control point
				local shift_p2x = function(v) setters[p2x](points[p2x] + dx) end
				local shift_p2y = function(v) setters[p2y](points[p2y] + dy) end
				chain(p3x, shift_p2x)
				chain(p3y, shift_p2y)
			else
				p2x, p2y = p1x, p1y
			end

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil
		elseif s == 'smooth_quad_curve' then

		elseif s == 'rel_smooth_quad_curve' then
			local p1x, p1y = cpx, cpy
			local clen, c3x, c3y = i+1, i+2, i+3
			local p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])

			local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
			local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end

			chain(p3x, set_c3x)
			chain(p3y, set_c3y)

			chain(p1x, set_c3x)
			chain(p1y, set_c3y)

			local p2x, p2y
			if tkind then
				p2x, p2y = pt(reflect_point_distance(points[tx], points[ty], points[p1x], points[p1y], path[clen]))
				local tx_, ty_ = tx, ty
				local mutex = new_mutex()
				chain(p2x, mutex(function(v)
					local tclen = tclen and points[tclen] or distance(points[tx_], points[ty_], points[p1x], points[p1y])
					setters[tx_]((reflect_point_distance(points[p2x], points[p2y], points[p1x], points[p1y], tclen)))
					path[clen] = distance(points[p2x], points[p2y], points[p1x], points[p1y])
				end))
				chain(p2y, mutex(function(v)
					local tclen = tclen and points[tclen] or distance(points[tx_], points[ty_], points[p1x], points[p1y])
					setters[ty_](select(2, reflect_point_distance(points[p2x], points[p2y], points[p1x], points[p1y], tclen)))
					path[clen] = distance(points[p2x], points[p2y], points[p1x], points[p1y])
				end))
				chain(tx, mutex(function(v)
					setters[p2x]((reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])))
				end))
				chain(ty, mutex(function(v)
					setters[p2y](select(2, reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])))
				end))

				--end points carry control point
				chain(p3x, function(v) setters[p2x](points[p2x] + dx) end)
				chain(p3y, function(v) setters[p2y](points[p2y] + dy) end)
			else
				p2x, p2y = p1x, p1y
			end

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, clen
		elseif s == 'curve' then
		elseif s == 'rel_curve' then
			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y, c4x, c4y = i+1, i+2, i+3, i+4, i+5, i+6
			local p2x, p2y = pt(points[p1x] + path[c2x], points[p1y] + path[c2y])
			local p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])
			local p4x, p4y = pt(points[p1x] + path[c4x], points[p1y] + path[c4y])

			local set_c2x = function(v) path[c2x] = points[p2x] - points[p1x] end
			local set_c2y = function(v) path[c2y] = points[p2y] - points[p1y] end
			local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
			local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end
			local set_c4x = function(v) path[c4x] = points[p4x] - points[p1x] end
			local set_c4y = function(v) path[c4y] = points[p4y] - points[p1y] end

			--points update themselves in path
			chain(p2x, set_c2x)
			chain(p2y, set_c2y)
			chain(p3x, set_c3x)
			chain(p3y, set_c3y)
			chain(p4x, set_c4x)
			chain(p4y, set_c4y)

			--current point moves its relative points
			chain(p1x, set_c2x)
			chain(p1y, set_c2y)
			chain(p1x, set_c3x)
			chain(p1y, set_c3y)
			chain(p1x, set_c4x)
			chain(p1y, set_c4y)

			--end points carry control point
			chain(p1x, function(v) setters[p2x](points[p2x] + dx) end)
			chain(p1y, function(v) setters[p2y](points[p2y] + dy) end)
			chain(p4x, function(v) setters[p3x](points[p3x] + dx) end)
			chain(p4y, function(v) setters[p3y](points[p3y] + dy) end)

			cpx, cpy = p4x, p4y
			tkind, tx, ty, tclen = 'cubic', p3x, p3y, nil
		end
	end

	local function update(i, px, py)
		dx, dy = px - points[i], py - points[i+1]
		setters[i](px)
		setters[i+1](py)
	end

	return points, update
end

local points, update = control_points(path)

local drag_i

function player:on_render(cr)
	local draw = path_cairo(cr)
	cr:set_source_rgb(0,0,0)
	cr:paint()

	draw(path)
	cr:set_source_rgb(1,1,0)
	cr:stroke()

	for i=1,#points,2 do
		local x,y = points[i], points[i+1]
		cr:rectangle(x-5,y-5,10,10)
		cr:set_source_rgb(1,1,0)
		cr:fill()
	end

	for i=1,#points,2 do
		local x,y = points[i], points[i+1]
		if not drag_i and self.mouse_buttons.lbutton then
			if self:dragging(x, y, 10) then
				drag_i = i
			end
		elseif not self.mouse_buttons.lbutton then
			drag_i = nil
		end
	end
	if drag_i then
		update(drag_i, self.mouse_x, self.mouse_y)
	end
end

player:play()
