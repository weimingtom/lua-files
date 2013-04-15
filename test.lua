local player = require'cairo_player'
local glue = require'glue'
local path_state = require'path'
local path_cairo = require'path_cairo'

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local distance = require'path_point'.distance
local point_angle = require'path_point'.point_angle
local point_around = require'path_point'.point_around
local rotate_point = require'path_point'.rotate_point
local elliptic_arc_endpoints = require'path_elliptic_arc'.endpoints
local svgarc_to_elliptic_arc = require'path_svgarc'.to_elliptic_arc
local point_at = require'path_elliptic_arc'.point_at
local circle_3p_to_circle = require'path_circle_3p'.to_circle
local star_to_star_2p = require'path_shapes'.star_to_star_2p
local affine2d = require'affine2d'

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
	'rel_elliptic_arc', 0, 0, 40, 30, 0, -270, 30,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth an elliptic arc
	'rel_move', 50, 0,
	'rel_svgarc', -50, -20, -30, 1, 0, 30, -40,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth a svgarc
	'rel_move', 50, 0,
	'rel_arc_3p', 0, -40, 50, 0,
	'rel_smooth_quad_curve', 50, 40, 0, --smooth an arc-3p
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
	--'move', 500, 300,
	--'rel_svgarc', 200, 100, 30, 0, 1, -100, 100,
	'rel_svgarc', -50, -20, -30, 1, 1, 30, 40,
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
	'superformula', 100+580, 600, 50, 300, 30, 1, 1, 3, 1, 1, 1,
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
	local points = {} --{x1, y1, x2, y2, ...}
	local setters = {} --{set_x1, set_y1, ...}

	--override the value setter at index px so that it chain-calls another setter
	local function chain(px, setter)
		local old_setter = assert(setters[px])
		setters[px] = function(v)
			old_setter(v)
			setter(v)
		end
	end

	--create a point with an update handler that updates its coordinates
	local function pt(x, y)
		local px, py = #points+1, #points+2
		points[px] = x
		points[py] = y
		--point updates its own coordinates
		setters[px] = function(v) points[px] = v end
		setters[py] = function(v) points[py] = v end
		return px, py
	end

	--create a point that directly represents an abs. point in path at index cx, cy
	local function path_abs_pt(cx, cy)
		local px, py = pt(path[cx], path[cy])
		--point updates its representation in path
		chain(px, function(v) path[cx] = points[px] end)
		chain(py, function(v) path[cy] = points[py] end)
		return px, py
	end

	--create a point that directly represents a rel. point in path at index cx, cy
	local function path_rel_pt(cx, cy, cpx, cpy)
		local px, py = pt(points[cpx] + path[cx], points[cpy] + path[cy])
		local function set_cx(v) path[cx] = points[px] - points[cpx] end
		local function set_cy(v) path[cy] = points[py] - points[cpy] end
		--point updates its representation in path
		chain(px, set_cx)
		chain(py, set_cy)
		--current point updates the relative point in path so as to preserve its absolute position
		chain(cpx, set_cx)
		chain(cpy, set_cy)
		return px, py
	end

	--create a point that directly represents a rel. or an abs. point in path at index cx, cy
	local function path_pt(cx, cy, rel, cpx, cpy)
		return (rel and path_rel_pt or path_abs_pt)(cx, cy, cpx, cpy)
	end

	--move px,py with delta when cx,cy is updated (i.e. cx,cy carries or drags px,py with it)
	local dx, dy = 0, 0
	local function move_delta(cx, cy, px, py, mutex)
		local move_px = function() setters[px](points[px] + dx) end
		local move_py = function() setters[py](points[py] + dy) end
		if mutex then
			move_px = mutex(move_px)
			move_py = mutex(move_py)
		end
		chain(cx, move_px)
		chain(cy, move_py)
	end

	local cpx, cpy, spx, spy, tkind, tx, ty, tclen

	for i,s in path_state.commands(path) do

		local s, rel = path_state.abs_name(s), path_state.is_rel(s)
		local tkind1 = tkind; tkind = nil

		if s == 'move' then

			local c2x, c2y = i+1, i+2
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			cpx, cpy = p2x, p2y
			spx, spy = cpx, cpy

		elseif s == 'line' then

			local c2x, c2y = i+1, i+2
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			cpx, cpy = p2x, p2y

		elseif s == 'close' then

			cpx, cpy = spx, spy

		elseif s == 'hline' and not rel then

			local p1y = cpy
			local c2x = i+1
			local p2x, p2y = pt(path[c2x], points[p1y])

			--endpoint updates its representation in path
			chain(p2x, function(v) path[c2x] = points[p2x] end)

			cpx, cpy = p2x, p2y

		elseif s == 'vline' and not rel then

			local p1x = cpx
			local c2y = i+1
			local p2x, p2y = pt(points[p1x], path[c2y])

			--endpoint updates its representation in path
			chain(p2y, function(v) path[c2y] = points[p2y] end)

			cpx, cpy = p2x, p2y

		elseif s == 'hline' and rel then

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

			cpx, cpy = p2x, p2y

		elseif s == 'vline' and rel then

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

			cpx, cpy = p2x, p2y

		elseif s == 'quad_curve' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)

			--end points carry control point
			move_delta(p1x, p1y, p2x, p2y)
			move_delta(p3x, p3y, p2x, p2y)

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'quad', p2x, p2y, nil

		elseif s == 'quad_curve_3p' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y = i+1, i+2, i+3, i+4
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)

			cpx, cpy = p3x, p3y
			tkind, tx, ty, tclen = 'tangent', p2x, p2y, nil

		elseif s == 'curve' then

			local p1x, p1y = cpx, cpy
			local c2x, c2y, c3x, c3y, c4x, c4y = i+1, i+2, i+3, i+4, i+5, i+6
			local p2x, p2y = path_pt(c2x, c2y, rel, cpx, cpy)
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)
			local p4x, p4y = path_pt(c4x, c4y, rel, cpx, cpy)

			--endpoints carry control points
			move_delta(p1x, p1y, p2x, p2y)
			move_delta(p4x, p4y, p3x, p3y)

			cpx, cpy = p4x, p4y
			tkind, tx, ty, tclen = 'cubic', p3x, p3y, nil

		elseif s == 'symm_quad_curve' or s == 'symm_curve' then

			local kind = s:match'quad' and 'quad' or 'cubic'
			local p1x, p1y = cpx, cpy
			local c3x, c3y = i+1, i+2
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)
			local p4x, p4y
			if kind == 'cubic' then
				local c4x, c4y = i+3, i+4
				p4x, p4y = path_pt(c4x, c4y, rel, cpx, cpy)
			end

			local psx, psy
			if tkind1 == kind then
				psx, psy = pt(reflect_point(points[tx], points[ty], points[p1x], points[p1y]))
				local tx_, ty_ = tx, ty

				--virtual control point moves the tangent tip
				chain(psx, recursion_safe(function(v) setters[tx_](2 * points[p1x] - v) end))
				chain(psy, recursion_safe(function(v) setters[ty_](2 * points[p1y] - v) end))

				--tangent tip moves the virtual control point
				chain(tx, function(v) setters[psx](2 * points[p1x] - v) end)
				chain(ty, function(v) setters[psy](2 * points[p1y] - v) end)

				--endpoints carry second control points
				if kind == 'quad' then
					move_delta(p3x, p3y, psx, psy)
				else
					move_delta(p1x, p1y, psx, psy)
				end
			else
				--if the tangent tip is missing or not of the right type, the first endpoint serves as tangent tip
				psx, psy = p1x, p1y
			end

			--second endpoint carries second control point
			if kind == 'cubic' then
				--TODO: move_delta(p4x, p4y, p3x, p3y)
			end

			--advance the state
			if kind == 'quad' then
				cpx, cpy = p3x, p3y
				tkind, tx, ty, tclen = kind, psx, psy, nil
			else
				cpx, cpy = p4x, p4y
				tkind, tx, ty, tclen = kind, p3x, p3y, nil
			end

		elseif s == 'smooth_quad_curve' or s == 'smooth_curve' then

			local kind = s:match'quad' and 'quad' or 'cubic'
			local p1x, p1y = cpx, cpy
			local clen, c3x, c3y = i+1, i+2, i+3
			local p3x, p3y = path_pt(c3x, c3y, rel, cpx, cpy)
			local p4x, p4y
			if kind == 'cubic' then
				local c4x, c4y = i+4, i+5
				p4x, p4y = path_pt(c4x, c4y, rel, cpx, cpy)
			end

			local psx, psy
			if tkind1 then
				psx, psy = pt(reflect_point_distance(points[tx], points[ty], points[p1x], points[p1y], path[clen]))
				local tx_, ty_, tclen_ = tx, ty, tclen

				--moving the virtual control point updates clen
				local function set_clen()
					path[clen] = distance(points[psx], points[psy], points[p1x], points[p1y])
				end
				chain(psx, set_clen)
				chain(psy, set_clen)

				local mutex = new_mutex()

				--virtual control point moves tangent tip
				local move_tip = mutex(function()
					if tclen_ then
						local tlen = path[tclen_]
						local x, y = reflect_point_distance(points[psx], points[psy], points[p1x], points[p1y], tlen)
						setters[tx_](x)
						setters[ty_](y)
					else
						local tlen = distance(points[tx_], points[ty_], points[p1x], points[p1y])
						local x, y = reflect_point_distance(points[psx], points[psy], points[p1x], points[p1y], tlen)
						setters[tx_](x)
						setters[ty_](y)
					end
				end)
				chain(psx, move_tip)
				chain(psy, move_tip)

				--tangent tip moves virtual control point
				local move_vpoint = mutex(function()
					local x, y = reflect_point_distance(points[tx_], points[ty_], points[p1x], points[p1y], path[clen])
					setters[psx](x)
					setters[psy](y)
				end)
				chain(tx, move_vpoint)
				chain(ty, move_vpoint)

				--second endpoint carries control point
				if kind == 'quad' then
					move_delta(p3x, p3y, psx, psy)
				end
			else
				--if the tangent tip is missing, the first endpoint serves as tangent tip
				psx, psy = p1x, p1y
			end

			--second endpoint carries second control point
			if kind == 'cubic' then
				move_delta(p4x, p4y, p3x, p3y)
			end

			--advance the state
			if kind == 'quad' then
				cpx, cpy = p3x, p3y
				tkind, tx, ty, tclen = kind, psx, psy--, clen
			else
				cpx, cpy = p4x, p4y
				tkind, tx, ty, tclen = kind, p3x, p3y--, clen
			end

		elseif s == 'arc' or s == 'line_arc' or s == 'elliptic_arc' or s == 'line_elliptic_arc' then

			local p1x, p1y = cpx, cpy
			local ccx, ccy, crx, cry, cstart_angle, csweep_angle, crotation
			if s:match'elliptic' then
				ccx, ccy, crx, cry, cstart_angle, csweep_angle, crotation = i+1, i+2, i+3, i+4, i+5, i+6, i+7
			else
				ccx, ccy, crx, cry, cstart_angle, csweep_angle = i+1, i+2, i+3, i+3, i+4, i+5
			end
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)

			--arc endpoints
			local px1, py1 = pt(0, 0)
			local px2, py2 = pt(0, 0)
			local function set_endpoints()
				local cx, cy = points[pcx], points[pcy]
				local rx, ry, start_angle, sweep_angle = path[crx], path[cry], path[cstart_angle], path[csweep_angle]
				local rotation = crotation and path[crotation]
				local x1, y1, x2, y2 = elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation)
				points[px1] = x1
				points[py1] = y1
				--TODO
				--setters[px2](x2)
				--setters[py2](y2)
				points[px2] = x2
				points[py2] = y2
			end
			set_endpoints()

			--center carries endpoints
			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)

			--endpoints change angles
			local function move_angles()
				local a1 = point_angle(points[px1], points[py1], points[pcx], points[pcy])
				local a2 = point_angle(points[px2], points[py2], points[pcx], points[pcy])
				path[cstart_angle] = a1
				--path[csweep_angle] = a2 - a1
				set_endpoints()
			end
			chain(px1, move_angles)
			chain(py1, move_angles)
			chain(px2, move_angles)
			chain(py2, move_angles)

			if s:match'^line_' then
				cpx, cpy = px2, py2
			else
				spx, spy, cpx, cpy = px1, py1, px2, py2
			end

		elseif s == 'svgarc' then

			local px1, py1 = cpx, cpy
			local crx, cry, crotation, clarge_arc_flag, csweep_flag, cx2, cy2 = i+1, i+2, i+3, i+4, i+5, i+6, i+7
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)

			local pcx, pcy = pt(0, 0)
			local prxx, prxy = pt(0, 0)
			local pryx, pryy = pt(0, 0)
			local prxx1, prxy1 = pt(0, 0)
			local pryx1, pryy1 = pt(0, 0)

			--endpoints update ellipse points
			local function set_pts()
				local cx, cy, rx, ry, start_angle, sweep_angle, rotation =
					svgarc_to_elliptic_arc(points[px1], points[py1], path[crx], path[cry], path[crotation],
													path[clarge_arc_flag], path[csweep_flag], points[px2], points[py2])
				if cx then
					points[pcx] = cx
					points[pcy] = cy
					points[prxx], points[prxy] = point_at(0, cx, cy, rx, ry, rotation)
					points[pryx], points[pryy] = point_at(90, cx, cy, rx, ry, rotation)
					points[prxx1], points[prxy1] = point_at(180, cx, cy, path[crx], path[cry], rotation)
					points[pryx1], points[pryy1] = point_at(270, cx, cy, path[crx], path[cry], rotation)
				else
					--TODO: find better spots for these
					points[pcx], points[pcy] = points[px1], points[py1]
					points[prxx], points[prxy] = points[px1], points[py1]
					points[pryx], points[pryy] = points[px1], points[py1]
					points[prxx1], points[prxy1] = points[px1], points[py1]
					points[pryx1], points[pryy1] = points[px1], points[py1]
				end
			end
			set_pts()

			chain(px2, set_pts)
			chain(py2, set_pts)
			chain(px1, set_pts)
			chain(py1, set_pts)

			--center carries endpoints
			chain(pcx, function(v) setters[px1](points[px1] + dx) end)
			chain(pcy, function(v) setters[py1](points[py1] + dy) end)
			chain(pcx, function(v) setters[px2](points[px2] + dx) end)
			chain(pcy, function(v) setters[py2](points[py2] + dy) end)

			--rotation points update rotation and ellipse points
			local function rotate_around_rx()
				path[crotation] = point_angle(points[prxx], points[prxy], points[pcx], points[pcy])
				set_pts()
			end
			local function rotate_around_ry()
				path[crotation] = point_angle(points[pryx], points[pryy], points[pcx], points[pcy]) - 90
				set_pts()
			end
			chain(prxx, rotate_around_rx)
			chain(prxy, rotate_around_rx)
			chain(pryx, rotate_around_ry)
			chain(pryy, rotate_around_ry)

			--radii points update radii and ellipse points
			local function set_radii()
				path[crx] = distance(points[prxx1], points[prxy1], points[pcx], points[pcy])
				path[cry] = distance(points[pryx1], points[pryy1], points[pcx], points[pcy])
				set_pts()
			end
			chain(prxx1, set_radii)
			chain(prxy1, set_radii)
			chain(pryx1, set_radii)
			chain(pryy1, set_radii)

			cpx, cpy = px2, py2

		elseif s == 'arc_3p' then

			local px1, py1 = cpx, cpy
			local cxp, cyp, cx2, cy2 = i+1, i+2, i+3, i+4

			local pxp, pyp = path_pt(cxp, cyp, rel, cpx, cpy)
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)

			cpx, cpy = px2, py2

		elseif s == 'circle_3p' then

			local cx1, cy1, cx2, cy2, cx3, cy3 = i+1, i+2, i+3, i+4, i+5, i+6
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)
			local px3, py3 = path_pt(cx3, cy3, rel, cpx, cpy)

			--center point
			local pcx, pcy = pt(0, 0)
			local function set_center()
				local cx, cy, r = circle_3p_to_circle(points[px1], points[py1], points[px2], points[py2],
																	points[px3], points[py3])
				if not cx then return end
				points[pcx], points[pcy] = cx, cy
			end
			set_center()

			--tangent points move center point
			chain(px1, set_center)
			chain(py1, set_center)
			chain(px2, set_center)
			chain(py2, set_center)
			chain(px3, set_center)
			chain(py3, set_center)

			--center point carries tangent points
			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)
			move_delta(pcx, pcy, px3, py3)

			cpx, cpy, spx, spy = nil

		elseif s == 'circle' then

			local ccx, ccy, cr = i+1, i+2, i+3
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)

			--arbitrary point on circle representing its radius
			local px, py = pt(points[pcx] - path[cr], points[pcy])
			local function set_r()
				path[cr] = distance(points[px], points[py], points[pcx], points[pcy])
			end
			--radius point changes radius
			chain(px, set_r)
			chain(py, set_r)

			--center point carries radius point
			move_delta(pcx, pcy, px, py)

			cpx, cpy, spx, spy = nil

		elseif s == 'ellipse' then

			local ccx, ccy, crx, cry, crotation = i+1, i+2, i+3, i+4, i+5
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)

			local elliptic_arc_tangent_vector = require'path_elliptic_arc'.tangent_vector
			local ptx1, pty1 = pt(0, 0)
			local ptx, pty = pt(0, 0)
			local ii = .5
			local function set_pt()
				local x1, y1, x, y = elliptic_arc_tangent_vector(ii,
					path[ccx], path[ccy], path[crx], path[cry], 0, 360, path[crotation])
				points[ptx1], points[pty1] = x1, y1
				points[ptx], points[pty] = x, y
			end
			set_pt()
			chain(pcx, set_pt)
			chain(pcy, set_pt)

			local mutex = new_mutex()

			--radii points change radii
			local prxx, prxy = pt(0, 0)
			local pryx, pryy = pt(0, 0)
			local function set_pts()
				local cx, cy, rx, ry, rotation = points[pcx], points[pcy], path[crx], path[cry], path[crotation]
				points[prxx], points[prxy] = point_at(0, cx, cy, rx, ry, rotation)
				points[pryx], points[pryy] = point_at(90, cx, cy, rx, ry, rotation)
			end
			set_pts()
			local set_rx = mutex(function()
				path[crotation] = point_angle(points[prxx], points[prxy], points[pcx], points[pcy])
				path[crx] = distance(points[prxx], points[prxy], points[pcx], points[pcy])
				set_pts()
				set_pt()
			end)
			chain(prxx, set_rx)
			chain(prxy, set_rx)

			local set_ry = mutex(function()
				path[crotation] = point_angle(points[pryx], points[pryy], points[pcx], points[pcy]) - 90
				path[cry] = distance(points[pryx], points[pryy], points[pcx], points[pcy])
				set_pts()
				set_pt()
			end)
			chain(pryx, set_ry)
			chain(pryy, set_ry)

			--center point carries radii points exclusive of their own updating
			move_delta(pcx, pcy, prxx, prxy, mutex)
			move_delta(pcx, pcy, pryx, pryy, mutex)

			cpx, cpy, spx, spy = nil

		elseif s == 'rect' or s == 'round_rect' or s == 'elliptic_rect' then

			local cx, cy, cw, ch = i+1, i+2, i+3, i+4
			local px1, py1 = path_pt(cx, cy, rel, cpx, cpy)
			local px2, py2 = pt(points[px1] + path[cw], points[py1] + path[ch])
			local function set_size()
				path[cw] = points[px2] - points[px1]
				path[ch] = points[py2] - points[py1]
			end
			chain(px1, set_size)
			chain(py1, set_size)
			chain(px2, set_size)
			chain(py2, set_size)

			if s == 'round_rect' or s == 'elliptic_rect' then
				local crx, cry = i+5, s == 'round_rect' and i+5 or i+6

				local w, h, rx, ry = path[cw], path[ch], path[crx], path[cry]
				local min, max, abs = math.min, math.max, math.abs
				if crx == cry then
					rx = min(abs(rx), abs(w/2), abs(h/2))
					ry = rx
				else
					rx = min(abs(rx), abs(w/2))
					ry = min(abs(ry), abs(h/2))
				end

				local prxx, prxy = pt(points[px1] - rx, points[py1])
				local pryx, pryy = pt(points[px1], points[py1] - ry)

				local function set_rx()
					points[prxx] = math.max((points[px2] + points[px1]) / 2, math.min(points[px1], points[prxx]))
					path[crx] = points[px1] - points[prxx]
				end
				chain(prxx, set_rx)
				setters[prxy] = function(v) points[prxy] = points[py1] end

				local function set_ry()
					points[pryy] = math.max((points[py2] + points[py1]) / 2, math.min(points[py1], points[pryy]))
					path[cry] = points[py1] - points[pryy]
				end
				chain(pryy, set_ry)
				setters[pryx] = function(v) points[pryx] = points[px1] end

				move_delta(px1, py1, prxx, prxy)
				move_delta(px1, py1, pryx, pryy)
			end

			cpx, cpy, spx, spy = nil

		elseif s == 'star' then

			local ccx, ccy, cx1, cy1, cr2, cn = i+1, i+2, i+3, i+4, i+5, i+6
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)

			local px2, py2 = pt(0, 0)
			local function set_p2()
				local cx, cy, x1, y1, x2, y2, n =
					star_to_star_2p(points[pcx], points[pcy], points[px1], points[py1], path[cr2], path[cn])
				points[px2], points[py2] = x2, y2
			end
			set_p2()

			chain(px1, set_p2)
			chain(py1, set_p2)

			local function set_r2()
				path[cr2] = distance(points[px2], points[py2], points[pcx], points[pcy])
				set_p2()
			end
			chain(px2, set_r2)
			chain(py2, set_r2)

			move_delta(pcx, pcy, px1, py1)

			cpx, cpy, spx, spy = nil

		elseif s == 'star_2p' then

			local ccx, ccy, cx1, cy1, cx2, cy2, cn = i+1, i+2, i+3, i+4, i+5, i+6, i+7
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)
			local px2, py2 = path_pt(cx2, cy2, rel, cpx, cpy)

			move_delta(pcx, pcy, px1, py1)
			move_delta(pcx, pcy, px2, py2)

			cpx, cpy, spx, spy = nil

		elseif s == 'rpoly' then

			local ccx, ccy, cx1, cy1, cn = i+1, i+2, i+3, i+4, i+5
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local px1, py1 = path_pt(cx1, cy1, rel, cpx, cpy)

			move_delta(pcx, pcy, px1, py1)

			cpx, cpy, spx, spy = nil

		elseif s == 'superformula' then

			local ccx, ccy, csize, csteps, crotation = i+1, i+2, i+3, i+4, i+5
			local pcx, pcy = path_pt(ccx, ccy, rel, cpx, cpy)
			local mutex = new_mutex()

			local prx, pry = pt(point_around(points[pcx], points[pcy], path[csize], path[crotation]))
			local set_size = mutex(function()
				path[crotation] = point_angle(points[prx], points[pry], points[pcx], points[pcy])
				path[csize] = distance(points[prx], points[pry], points[pcx], points[pcy])
			end)
			chain(prx, set_size)
			chain(pry, set_size)

			move_delta(pcx, pcy, prx, pry, mutex)

			cpx, cpy, spx, spy = nil

		end
	end

	local function update(i, px, py, co)
		dx, dy = px - points[i], py - points[i+1]
		setters[i](px)
		setters[i+1](py)
	end

	return points, update
end

local function tangent_tips(p)
	--for i,s in
end

local mt = affine2d()--:translate(100, 0):rotate(10):scale(1, .7)
local invmt = mt:inverse()
local points, update = control_points(path, mt)

local drag_i
local i = 0
function player:on_render(cr)
	local draw = path_cairo(cr)
	cr:set_source_rgb(0,0,0)
	cr:paint()

	draw(path, mt)
	cr:set_source_rgb(1,1,1)
	cr:stroke()

	for i=1,#points,2 do
		local x,y = points[i], points[i+1]
		x,y = mt(x,y)
		cr:rectangle(x-3,y-3,6,6)
		cr:set_source_rgb(1,1,0)
		cr:fill()
	end

	for i=1,#points,2 do
		local x, y = points[i], points[i+1]
		x,y = mt(x,y)
		if not drag_i and self.mouse_buttons.lbutton then
			if self:dragging(x, y, 3) then
				drag_i = i
			end
		elseif not self.mouse_buttons.lbutton then
			drag_i = nil
		end
	end
	if drag_i then
		local mx, my = self.mouse_x, self.mouse_y
		mx, my = invmt(mx, my)
		update(drag_i, mx, my)
	end

	local ttips = tangent_tips(p)

end

player:play()
