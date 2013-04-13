local player = require'cairo_player'
local glue = require'glue'
local path_state = require'path'
local path_cairo = require'path_cairo'

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local distance = require'path_point'.distance
local point_angle = require'path_point'.point_angle
--local point_around = require'path_point'.point_around
local elliptic_arc_endpoints = require'path_elliptic_arc'.endpoints
local svgarc_to_elliptic_arc = require'path_svgarc'.to_elliptic_arc
local point_at = require'path_elliptic_arc'.point_at

local path = {
	'move', 1200, 110,
	--lines and control commands
	'rel_line', 20, 100,
	'rel_hline', 100,
	'rel_vline', -100,
	'close',
	'rel_line', 50, 50,
	--quad curves
	'move', 100, 160,
	'rel_quad_curve', 20, -50, 40, 0,
	'rel_symm_quad_curve', 40, 0, --symm a curve
	'rel_symm_quad_curve', 40, 0, --symm a symm curve
	'rel_symm_quad_curve', 40, 0, --symm a symm curve
	'rel_move', 50, 0,
	'rel_quad_curve', 20, -50, 40, 0,
	'rel_smooth_quad_curve', 40, 40, 0, --smooth a curve
	'rel_smooth_quad_curve', 40, 40, 0, --smooth a smooth curve
	'rel_smooth_quad_curve', 40, 40, 0, --smooth a smooth curve
	'rel_move', 50, 0,
	'rel_symm_quad_curve', 0, -50, --symm without a tangent
	'rel_symm_quad_curve', 50, 50, --symm a symm curve without a tangent
	'rel_move', 50, 0,
	'rel_smooth_quad_curve', 40, 0, -50, --smooth without a tangent
	'rel_smooth_quad_curve', 40, 50, 50, --smooth a smooth curve without a tangent
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a cubic curve
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
	'rel_symm_curve', 40,  50, 40, 0, --symm a curve
	'rel_symm_curve', 40, -50, 40, 0, --symm a symm curve
	'rel_symm_curve', 40,  50, 40, 0, --symm a symm curve
	'rel_move', 50, 0,
	'rel_curve', 0, -50, 40, -50, 40, 0,
	'rel_smooth_curve', 20, 40,  50, 40, 0, --smooth a curve
	'rel_smooth_curve', 20, 40, -50, 40, 0, --smooth a smooth curve
	'rel_smooth_curve', 20, 40,  50, 40, 0, --smooth a smooth curve
	'rel_move', 50, 0,
	'rel_symm_curve', 20,  50, 20, 0, --symm without a tangent
	'rel_symm_curve', 20, -50, 20, 0, --symm a symm curve without a tangent
	'rel_move', 50, 0,
	'rel_smooth_curve', 20, 20,  50, 20, 0, --smooth without a tangent
	'rel_smooth_curve', 20, 20, -50, 20, 0, --smooth a smooth curve without a tangent
	'rel_move', 50, 0,
	'rel_quad_curve', 40, -50, 40, 0,
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
		local old_setter = assert(setters[pi])
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

			--endpoint updates its representation in path
			chain(p2x, function(v) path[c2x] = points[p2x] end)
			chain(p2y, function(v) path[c2y] = points[p2y] end)

			--advance the state
			cpx, cpy = p2x, p2y
			spx, spy = cpx, cpy
			tkind = nil

		elseif s == 'rel_move' or s == 'rel_line' then

			local c2x, c2y = i+1, i+2
			local p1x, p1y = cpx, cpy
			local p2x, p2y = pt(points[p1x] + path[c2x], points[p1y] + path[c2y])

			--endpoint updates its representation in path
			chain(p2x, function(v) path[c2x] = points[p2x] - points[p1x] end)
			chain(p2y, function(v) path[c2y] = points[p2y] - points[p1y] end)

			--current point updates relative points in path so as to preserve their absolute position
			chain(p1x, function(v) path[c2x] = points[p2x] - points[p1x] end)
			chain(p1y, function(v) path[c2y] = points[p2y] - points[p1y] end)

			--advance the state
			cpx, cpy = p2x, p2y
			tkind = nil

		elseif s == 'close' or s == 'rel_close' then

			--advance the state
			cpx, cpy = spx, spy
			tkind = nil

		elseif s == 'hline' then

			local p1y = cpy
			local c2x = i+1
			local p2x, p2y = pt(path[c2x], points[p1y])

			--endpoint updates its representation in path
			chain(p2x, function(v) path[c2x] = points[p2x] end)

			--advance the state
			cpx, cpy = p2x, p2y
			tkind = nil

		elseif s == 'vline' then

			local p1x = cpx
			local c2y = i+1
			local p2x, p2y = pt(points[p1x], path[c2y])

			--endpoint updates its representation in path
			chain(p2y, function(v) path[c2y] = points[p2y] end)

			--advance the state
			cpx, cpy = p2x, p2y
			tkind = nil

		elseif s == 'rel_hline' then

			local p1x, p1y = cpx, cpy
			local c2x = i+1
			local p2x, p2y = pt(points[p1x] + path[c2x], points[p1y])

			--endpoint updates its representation in path
			chain(p2x, function(v) path[c2x] = points[p2x] - points[p1x] end)

			--current point updates relative points in path so as to preserve their absolute position
			chain(p1x, function(v) path[c2x] = points[p2x] - points[p1x] end)

			--endpoint updates current point on the constrained axis to preserve horizontality
			chain(p2y, function(v) setters[p1y](v) end)

			--current point updates endpoint on the constrained axis to preserve horizontality
			chain(p1y, recursion_safe(function(v) setters[p2y](v) end))

			--advance the state
			cpx, cpy = p2x, p2y
			tkind = nil
		elseif s == 'rel_vline' then

			local p1x, p1y = cpx, cpy
			local c2y = i+1
			local p2x, p2y = pt(points[p1x], points[p1y] + path[c2y])

			--endpoint updates its representation in path
			chain(p2y, function(v) path[c2y] = points[p2y] - points[p1y] end)

			--current point updates relative points in path so as to preserve their absolute position
			chain(p1y, function(v) path[c2y] = points[p2y] - points[p1y] end)

			--endpoint updates current point on the constrained axis to preserve verticality
			chain(p2x, function(v) setters[p1x](v) end)

			--current point updates endpoint on the constrained axis to preserve verticality
			chain(p1x, recursion_safe(function(v) setters[p2x](v) end))

			--advance the state
			cpx, cpy = p2x, p2y
			tkind = nil

		elseif s == 'quad_curve' or s == 'rel_quad_curve' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y, p3x, p3y
			if s == 'quad_curve' then
				p2x, p2y = pt(path[c2x], path[c2y])
				p3x, p3y = pt(path[c3x], path[c3y])

				--points update their representation in path
				chain(p2x, function(v) path[c2x] = points[p2x] end)
				chain(p2y, function(v) path[c2y] = points[p2y] end)
				chain(p3x, function(v) path[c3x] = points[p3x] end)
				chain(p3y, function(v) path[c3y] = points[p3y] end)
			else
				p2x, p2y = pt(points[p1x] + path[c2x], points[p1y] + path[c2y])
				p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])

				local set_c2x = function(v) path[c2x] = points[p2x] - points[p1x] end
				local set_c2y = function(v) path[c2y] = points[p2y] - points[p1y] end
				local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
				local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end

				--points update their representation in path
				chain(p2x, set_c2x)
				chain(p2y, set_c2y)
				chain(p3x, set_c3x)
				chain(p3y, set_c3y)

				--current point moves its relative points
				chain(p1x, set_c2x)
				chain(p1y, set_c2y)
				chain(p1x, set_c3x)
				chain(p1y, set_c3y)
			end

			--end points carry control point
			local shift_p2x = function(v) setters[p2x](points[p2x] + dx) end
			local shift_p2y = function(v) setters[p2y](points[p2y] + dy) end
			chain(p1x, shift_p2x)
			chain(p1y, shift_p2y)
			chain(p3x, shift_p2x)
			chain(p3y, shift_p2y)

			--advance the state
			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil

		elseif s == 'curve' or s == 'rel_curve' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y, c4x, c4y = i+1, i+2, i+3, i+4, i+5, i+6

			local p2x, p2y, p3x, p3y, p4x, p4y
			if s == 'curve' then
				p2x, p2y = pt(path[c2x], path[c2y])
				p3x, p3y = pt(path[c3x], path[c3y])
				p4x, p4y = pt(path[c4x], path[c4y])

				--points update their representation in path
				chain(p2x, function(v) path[c2x] = points[p2x] end)
				chain(p2y, function(v) path[c2y] = points[p2y] end)
				chain(p3x, function(v) path[c3x] = points[p3x] end)
				chain(p3y, function(v) path[c3y] = points[p3y] end)
				chain(p4x, function(v) path[c4x] = points[p4x] end)
				chain(p4y, function(v) path[c4y] = points[p4y] end)
			else
				p2x, p2y = pt(points[p1x] + path[c2x], points[p1y] + path[c2y])
				p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])
				p4x, p4y = pt(points[p1x] + path[c4x], points[p1y] + path[c4y])

				local set_c2x = function(v) path[c2x] = points[p2x] - points[p1x] end
				local set_c2y = function(v) path[c2y] = points[p2y] - points[p1y] end
				local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
				local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end
				local set_c4x = function(v) path[c4x] = points[p4x] - points[p1x] end
				local set_c4y = function(v) path[c4y] = points[p4y] - points[p1y] end

				--points update their representation in path
				chain(p2x, set_c2x)
				chain(p2y, set_c2y)
				chain(p3x, set_c3x)
				chain(p3y, set_c3y)
				chain(p4x, set_c4x)
				chain(p4y, set_c4y)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_c2x)
				chain(p1y, set_c2y)
				chain(p1x, set_c3x)
				chain(p1y, set_c3y)
				chain(p1x, set_c4x)
				chain(p1y, set_c4y)
			end

			--endpoints carry control points
			chain(p1x, function(v) setters[p2x](points[p2x] + dx) end)
			chain(p1y, function(v) setters[p2y](points[p2y] + dy) end)
			chain(p4x, function(v) setters[p3x](points[p3x] + dx) end)
			chain(p4y, function(v) setters[p3y](points[p3y] + dy) end)

			cpx, cpy = p4x, p4y
			tkind, tx, ty, tclen = 'cubic', p3x, p3y, nil

		elseif s == 'symm_quad_curve' or s == 'rel_symm_quad_curve' then

			local p1x, p1y = cpx, cpy
			local c3x, c3y = i+1, i+2

			local p3x, p3y
			if s == 'symm_quad_curve' then
				p3x, p3y = pt(path[c3x], path[c3y])

				--endpoint updates its representation in path
				chain(p3x, function(v) path[c3x] = points[p3x] end)
				chain(p3y, function(v) path[c3y] = points[p3y] end)
			else
				p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])

				local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
				local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end

				--endpoint updates its representation in path
				chain(p3x, set_c3x)
				chain(p3y, set_c3y)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_c3x)
				chain(p1y, set_c3y)
			end

			local p2x, p2y
			if tkind == 'quad' then
				p2x, p2y = pt(reflect_point(points[tx], points[ty], points[p1x], points[p1y]))
				local tx_, ty_ = tx, ty

				--moving the virtual control point moves the tangent tip
				chain(p2x, recursion_safe(function(v)
					setters[tx_]((reflect_point(points[p2x], points[p2y], points[p1x], points[p1y])))
				end))
				chain(p2y, recursion_safe(function(v)
					setters[ty_](select(2, reflect_point(points[p2x], points[p2y], points[p1x], points[p1y])))
				end))

				--moving the tangent tip moves the virtual control point
				chain(tx, function(v)
					setters[p2x]((reflect_point(points[tx_], points[ty_], points[p1x], points[p1y])))
				end)
				chain(ty, function(v)
					setters[p2y](select(2, reflect_point(points[tx_], points[ty_], points[p1x], points[p1y])))
				end)

				--endpoints carry control point
				chain(p3x, function(v) setters[p2x](points[p2x] + dx) end)
				chain(p3y, function(v) setters[p2y](points[p2y] + dy) end)
			else
				--if the tangent tip is missing or not of 'quad' type, the first endpoint serves as tangent tip.
				p2x, p2y = p1x, p1y
			end

			--advance the state
			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil

		elseif s == 'symm_curve' or s == 'rel_symm_curve' then

			local p1x, p1y = cpx, cpy
			local c3x, c3y, c4x, c4y = i+1, i+2, i+3, i+4

			local p3x, p3y, p4x, p4y
			if s == 'symm_curve' then
				p3x, p3y = pt(path[c3x], path[c3y])
				p4x, p4y = pt(path[c4x], path[c4y])

				--points update their representation in path
				chain(p3x, function(v) path[c3x] = points[p3x] end)
				chain(p3y, function(v) path[c3y] = points[p3y] end)
				chain(p4x, function(v) path[c4x] = points[p4x] end)
				chain(p4y, function(v) path[c4y] = points[p4y] end)
			else
				p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])
				p4x, p4y = pt(points[p1x] + path[c4x], points[p1y] + path[c4y])

				local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
				local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end
				local set_c4x = function(v) path[c4x] = points[p4x] - points[p1x] end
				local set_c4y = function(v) path[c4y] = points[p4y] - points[p1y] end

				--points update their representation in path
				chain(p3x, set_c3x)
				chain(p3y, set_c3y)
				chain(p4x, set_c4x)
				chain(p4y, set_c4y)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_c3x)
				chain(p1y, set_c3y)
				chain(p1x, set_c4x)
				chain(p1y, set_c4y)
			end

			local p2x, p2y
			if tkind == 'cubic' then
				p2x, p2y = pt(reflect_point(points[tx], points[ty], points[p1x], points[p1y]))
				local tx_, ty_ = tx, ty

				--moving the virtual control point moves the tangent tip
				chain(p2x, recursion_safe(function(v)
					setters[tx_]((reflect_point(points[p2x], points[p2y], points[p1x], points[p1y])))
				end))
				chain(p2y, recursion_safe(function(v)
					setters[ty_](select(2, reflect_point(points[p2x], points[p2y], points[p1x], points[p1y])))
				end))

				--moving the tangent tip moves the virtual control point
				chain(tx, function(v)
					setters[p2x]((reflect_point(points[tx_], points[ty_], points[p1x], points[p1y])))
				end)
				chain(ty, function(v)
					setters[p2y](select(2, reflect_point(points[tx_], points[ty_], points[p1x], points[p1y])))
				end)
			else
				--if the tangent tip is missing or not of 'quad' type, the first endpoint serves as tangent tip.
				p2x, p2y = p1x, p1y
			end

			--second endpoint carries second control point
			chain(p4x, function(v) setters[p3x](points[p3x] + dx) end)
			chain(p4y, function(v) setters[p3y](points[p3y] + dy) end)

			--advance the state
			cpx, cpy = p4x, p4y
			tkind, tx, ty, tclen = 'cubic', p3x, p3y, nil

		elseif s == 'smooth_quad_curve' or s == 'rel_smooth_quad_curve' then

			local p1x, p1y = cpx, cpy
			local clen, c3x, c3y = i+1, i+2, i+3

			local p3x, p3y
			if s == 'smooth_quad_curve' then
				p3x, p3y = pt(path[c3x], path[c3y])

				--endpoint updates its representation in path
				chain(p3x, function(v) path[c3x] = points[p3x] end)
				chain(p3y, function(v) path[c3y] = points[p3y] end)
			else
				p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])

				local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
				local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end

				--endpoint updates its representation in path
				chain(p3x, set_c3x)
				chain(p3y, set_c3y)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_c3x)
				chain(p1y, set_c3y)
			end

			local p2x, p2y
			if tkind then
				p2x, p2y = pt(reflect_point_distance(points[tx], points[ty], points[p1x], points[p1y], path[clen]))
				local tx_, ty_ = tx, ty
				local mutex = new_mutex()

				--moving the virtual control point moves the tangent tip
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

				--moving the tangent tip moves the virtual control point
				chain(tx, mutex(function(v)
					setters[p2x]((reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])))
				end))
				chain(ty, mutex(function(v)
					setters[p2y](select(2, reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])))
				end))

				--endpoint carries control point
				chain(p3x, function(v) setters[p2x](points[p2x] + dx) end)
				chain(p3y, function(v) setters[p2y](points[p2y] + dy) end)
			else
				--if the tangent tip is missing, the first endpoint serves as tangent tip.
				p2x, p2y = p1x, p1y
			end

			--advance the state
			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, clen

		elseif s == 'smooth_curve' or s == 'rel_smooth_curve' then

			local p1x, p1y = cpx, cpy
			local clen, c3x, c3y, c4x, c4y = i+1, i+2, i+3, i+4, i+5

			local p3x, p3y
			if s == 'smooth_curve' then
				p3x, p3y = pt(path[c3x], path[c3y])
				p4x, p4y = pt(path[c4x], path[c4y])

				--points update their representation in path
				chain(p3x, function(v) path[c3x] = points[p3x] end)
				chain(p3y, function(v) path[c3y] = points[p3y] end)
				chain(p4x, function(v) path[c4x] = points[p4x] end)
				chain(p4y, function(v) path[c4y] = points[p4y] end)
			else
				p3x, p3y = pt(points[p1x] + path[c3x], points[p1y] + path[c3y])
				p4x, p4y = pt(points[p1x] + path[c4x], points[p1y] + path[c4y])

				local set_c3x = function(v) path[c3x] = points[p3x] - points[p1x] end
				local set_c3y = function(v) path[c3y] = points[p3y] - points[p1y] end
				local set_c4x = function(v) path[c4x] = points[p4x] - points[p1x] end
				local set_c4y = function(v) path[c4y] = points[p4y] - points[p1y] end

				--points update their representation in path
				chain(p3x, set_c3x)
				chain(p3y, set_c3y)
				chain(p4x, set_c4x)
				chain(p4y, set_c4y)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_c3x)
				chain(p1y, set_c3y)
				chain(p1x, set_c4x)
				chain(p1y, set_c4y)
			end

			local p2x, p2y
			if tkind then
				p2x, p2y = pt(reflect_point_distance(points[tx], points[ty], points[p1x], points[p1y], path[clen]))
				local tx_, ty_ = tx, ty
				local mutex = new_mutex()

				--moving the virtual control point moves the tangent tip
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

				--moving the tangent tip moves the virtual control point
				chain(tx, mutex(function(v)
					setters[p2x]((reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])))
				end))
				chain(ty, mutex(function(v)
					setters[p2y](select(2, reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])))
				end))

				--second endpoint carries second control point
				chain(p4x, function(v) setters[p3x](points[p3x] + dx) end)
				chain(p4y, function(v) setters[p3y](points[p3y] + dy) end)
			else
				--if the tangent tip is missing, the first endpoint serves as tangent tip.
				p2x, p2y = p1x, p1y
			end

			--advance the state
			cpx, cpy = p4x, p4y
			tkind, tx, ty, tclen = 'cubic', p3x, p3y, clen

		elseif s == 'arc' or s == 'rel_arc' or s == 'line_arc' or s == 'rel_line_arc' then

			local rel = s:match'^rel_'
			local p1x, p1y = cpx, cpy
			local ccx, ccy, cr, cstart_angle, csweep_angle = i+1, i+2, i+3, i+4, i+5

			local cx, cy, r, start_angle, sweep_angle = path[ccx], path[ccy], path[cr], path[cstart_angle], path[csweep_angle]
			if rel then
				cx = points[p1x] + cx
				cy = points[p1y] + cy
			end
			local x1, y1, x2, y2 = elliptic_arc_endpoints(cx, cy, r, r, start_angle, sweep_angle)

			local pcx, pcy = pt(cx, cy)
			local px1, py1 = pt(x1, y1)
			local px2, py2 = pt(x2, y2)

			if not rel then
				--center point updates its representation in path
				chain(pcx, function(v) path[ccx] = points[pcx] end)
				chain(pcy, function(v) path[ccy] = points[pcy] end)
			else
				local function set_ccx(v) path[ccx] = points[pcx] - points[p1x] end
				local function set_ccy(v) path[ccy] = points[pcy] - points[p1y] end

				--center point updates its representation in path
				chain(pcx, set_ccx)
				chain(pcy, set_ccy)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_ccx)
				chain(p1y, set_ccy)
			end

			--center carries other points
			chain(pcx, function(v) setters[px1](points[px1] + dx) end)
			chain(pcy, function(v) setters[py1](points[py1] + dy) end)
			chain(pcx, function(v) setters[px2](points[px2] + dx) end)
			chain(pcy, function(v) setters[py2](points[py2] + dy) end)

			--advance the state
			spx, spy, cpx, cpy = px1, py1, px2, py2
			tkind = nil

		elseif s == 'elliptic_arc' or s == 'rel_elliptic_arc' or s == 'line_elliptic_arc' or s == 'rel_line_elliptic_arc' then

			local rel = s:match'^rel_'
			local p1x, p1y = cpx, cpy
			local ccx, ccy, crx, cry, cstart_angle, csweep_angle, crotation = i+1, i+2, i+3, i+4, i+5, i+6, i+7

			local cx, cy, rx, ry, start_angle, sweep_angle, rotation =
				path[ccx], path[ccy], path[crx], path[cry], path[cstart_angle], path[csweep_angle], path[crotation]
			if rel then
				cx = points[p1x] + cx
				cy = points[p1y] + cy
			end
			local x1, y1, x2, y2 = elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation)

			local pcx, pcy = pt(cx, cy)
			local px1, py1 = pt(x1, y1)
			local px2, py2 = pt(x2, y2)

			if not rel then
				--center point updates its representation in path
				chain(pcx, function(v) path[ccx] = points[pcx] end)
				chain(pcy, function(v) path[ccy] = points[pcy] end)
			else
				local function set_ccx(v) path[ccx] = points[pcx] - points[p1x] end
				local function set_ccy(v) path[ccy] = points[pcy] - points[p1y] end

				--center point updates its representation in path
				chain(pcx, set_ccx)
				chain(pcy, set_ccy)

				--current point updates relative points in path so as to preserve their absolute position
				chain(p1x, set_ccx)
				chain(p1y, set_ccy)
			end

			--center carries other points
			chain(pcx, function(v) setters[px1](points[px1] + dx) end)
			chain(pcy, function(v) setters[py1](points[py1] + dy) end)
			chain(pcx, function(v) setters[px2](points[px2] + dx) end)
			chain(pcy, function(v) setters[py2](points[py2] + dy) end)

			--advance the state
			spx, spy, cpx, cpy = px1, py1, px2, py2
			tkind = nil

		elseif s == 'svgarc' or s == 'rel_svgarc' then

			local rel = s:match'^rel_'
			local px1, py1 = cpx, cpy
			local crx, cry, crotation, clarge_arc_flag, csweep_flag, cx2, cy2 = i+1, i+2, i+3, i+4, i+5, i+6, i+7

			local px2, py2
			if not rel then
				px2, py2 = pt(path[cx2], path[cy2])

				--endpoint updates its representation in path
				chain(px2, function(v) path[cx2] = points[px2] end)
				chain(py2, function(v) path[cy2] = points[py2] end)
			else
				px2, py2 = pt(path[cx2] + points[px1], path[cy2] + points[py1])

				local function set_cx2(v) path[cx2] = points[px2] - points[px1] end
				local function set_cy2(v) path[cy2] = points[py2] - points[py1] end

				--endpoint updates its representation in path
				chain(px2, set_cx2)
				chain(py2, set_cy2)

				--current point updates relative points in path so as to preserve their absolute position
				chain(px1, set_cx2)
				chain(py1, set_cy2)
			end

			--convert to elliptic arc for getting the center and radii points
			local x1, y1 = points[px1], points[py1]
			local x2, y2 = points[px2], points[py2]
			local rx, ry, rotation, large_arc_flag, sweep_flag =
					path[crx], path[cry], path[crotation], path[clarge_arc_flag], path[csweep_flag]

			local cx, cy, rx, ry, start_angle, sweep_angle, rotation =
				svgarc_to_elliptic_arc(x1, y1, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2)

			if cx then
				local pcx, pcy = pt(cx, cy)
				local prxx, prxy = pt(point_at( 0, cx, cy, rx, ry, rotation))
				local pryx, pryy = pt(point_at(90, cx, cy, rx, ry, rotation))

				--end points update center and radii points
				local function set_pts()
					local cx, cy, rx, ry, start_angle, sweep_angle, rotation =
						svgarc_to_elliptic_arc(points[px1], points[py1], path[crx], path[cry], path[crotation],
														path[clarge_arc_flag], path[csweep_flag], points[px2], points[py2])

					local a1 = 0  --start_angle < 90 and  0 or 180
					local a2 = 90 --start_angle < 90 and 90 or 270
					points[prxx], points[prxy] = point_at(a1, cx, cy, rx, ry, rotation)
					points[pryx], points[pryy] = point_at(a2, cx, cy, rx, ry, rotation)
					points[pcx], points[pcy] = cx, cy
				end
				chain(px2, set_pts)
				chain(py2, set_pts)
				chain(px1, set_pts)
				chain(py1, set_pts)

				--center carries endpoints
				chain(pcx, function(v) setters[px1](points[px1] + dx) end)
				chain(pcy, function(v) setters[py1](points[py1] + dy) end)
				chain(pcx, function(v) setters[px2](points[px2] + dx) end)
				chain(pcy, function(v) setters[py2](points[py2] + dy) end)

				--radii points update radii
				chain(prxx, function(v) ; set_pts() end)
				chain(prxy, function(v) ; set_pts() end)
			end

			--advance the state
			cpx, cpy = px2, py2
			tkind = nil

		elseif s == 'arc_3p' or s == 'rel_arc_3p' then

			local px1, py1 = cpx, cpy
			local cxp, cyp, cx2, cy2 = i+1, i+2, i+3, i+4

			local pxp, pyp, px2, py2
			if s == 'arc_3p' then
				pxp, pyp = pt(path[cxp], path[cyp])
				px2, py2 = pt(path[cx2], path[cy2])
			else
				pxp, pyp = pt(path[cxp] + points[px1], path[cyp] + points[px1])
				px2, py2 = pt(path[cx2] + points[px1], path[cy2] + points[py1])
			end

			--advance the state
			cpx, cpy = px2, py2
			tkind = nil

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
	cr:set_source_rgb(1,1,1)
	cr:stroke()

	for i=1,#points,2 do
		local x,y = points[i], points[i+1]
		cr:rectangle(x-3,y-3,6,6)
		cr:set_source_rgb(1,1,0)
		cr:fill()
	end

	for i=1,#points,2 do
		local x,y = points[i], points[i+1]
		if not drag_i and self.mouse_buttons.lbutton then
			if self:dragging(x, y, 3) then
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
