--[[
CAVEATS:
- the algorithm for choosing between negative and positive arc is prone to histeresis.
  that's not a problem for mouse handling (in fact it's a feature), but may become a problem
  for programatic update.
- linking in terms of delta is not idempotent. this only becomes a problem if you link the
- same variable to delta in more than one linkset, which you shouldn't have reason to do anyway.

FEATURES:
- separate endpoints from control points
- independent-point move:
	- independent move of bezier points from control points and viceversa
		* to avoid recreating the editor everytime, set a variable and make conditional_link(cond_var, ...)
	- independent move of arc start point from end point
	- independent move of rect x1,y1 from x2,y2
- constrained change:
	- fix arc radius, only change the angle
	- rect w = h => square
	- rect resize from center
	- rect resize only on x or y axis
	- ellipse w = h => circle
- constrained move:
	- rect move only on x or y axis

NEW SHAPES:
- 3-point arc: cpx, cpy, x2, y2, radius, start_angle, sweep_angle
- html5 3-point arc: cpx, cpy, x2, y2, x3, y3, radius
- elliptic_arc: cx, cy, rx, ry, rot
- svgarc: rx, ry, angle, f1, f2, x2, y2
- angle_ellipse: cx, cy, rx, ry, angle
- angle_arc: cx, cy, rx, ry, angle, start_angle, sweep_angle
- angle_rect: x1, y1, x2, y2, length_flag, length

]]

local glue = require'glue'
local path_state = require'path_state'
local point_angle = require'path_point'.angle
local point_distance = require'path_point'.distance
local arc_endpoints = require'path_arc'.endpoints
local svgarc_to_elliptic_arc = require'path_svgarc'.to_elliptic_arc
local varlinker = require'varlinker'

local function sign(x) return x > 0 and 1 or -1 end

--varlinker expressions
local function copy(t, var) return t[var] end
local function add(t, var1, var2) return t[var1] + t[var2] end
local function sub(t, var1, var2) return t[var1] - t[var2] end
local function reflect(t, varx, varc) return 2 * t[varc] - t[varx] end
local function middle(t, var1, var2) return t[var1] + (t[var2] - t[var1])/2 end
local point_distance = function(t, p1x, p1y, p2x, p2y)
	return point_distance(t[p1x], t[p1y], t[p2x], t[p2y])
end
local point_angle = function(t, p2x, p2y, p1x, p1y)
	return math.deg(point_angle(t[p2x], t[p2y], t[p1x], t[p1y]))
end

local function editor(path)
	local linker = varlinker()
	local var, val, linkon, expron, constrain =
		linker.var, linker.val, linker.link, linker.expr, linker.constrain
	local function link(...) linkon(1, ...) end
	local function expr(...) expron(1, ...) end

	local points = {}
	local point_vars = {}
	local function pointvar(x, setter, ...)
		glue.append(points, x)
		local px = var(points, #points, setter, ...)
		glue.append(point_vars, px)
		return px
	end
	local delta = var({},1)
	local function update(xi,x)
		local px = point_vars[xi]
		local d = x - val[px]
		if d == 0 then return end
		val[delta] = d
		val[px] = x
	end

	local point_styles = {}
	local function point(x, y, style)
		point_styles[#points+1] = style
		return pointvar(x), pointvar(y)
	end
	local function update_point(xi,x,y)
		update(xi,x)
		update(xi+1,y)
	end

	local control_path = {}
	local function cpline(p1x, p1y, p2x, p2y)
		glue.append(control_path, 'move', val[p1x], val[p1y])
		local cp1x = var(control_path, #control_path-1)
		local cp1y = var(control_path, #control_path-0)
		link(p1x, cp1x)
		link(p1y, cp1y)
		glue.append(control_path, 'line', val[p2x], val[p2y])
		local cp2x = var(control_path, #control_path-1)
		local cp2y = var(control_path, #control_path-0)
		link(p2x, cp2x)
		link(p2y, cp2y)
		return cp1x, cp1y, cp2x, cp2y
	end

	local pcpx, pcpy, pspx, pspy, pbx, pby, pqx, pqy

	for i,s in path_state.commands(path) do

		local rel = s:match'^rel_'

		local p1x, p1y = pcpx, pcpy
		local ox = rel and val[p1x] or 0
		local oy = rel and val[p1y] or 0

		local pbx1, pby1, pqx1, pqy1 = pbx, pby, pqx, pqy
		pbx, pby, pqx, pqy = nil

		if s == 'move' or s == 'line' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local p2x, p2y = point(val[c2x], val[c2y])

			--point updates point in path
			link(p2x, c2x)
			link(p2y, c2y)

			pcpx, pcpy = p2x, p2y
			if s == 'move' then pspx, pspy = pcpx, pcpy end
		elseif s == 'close' then
			pcpx, pcpy = pspx, pspy
		elseif s == 'rel_move' or s == 'rel_line' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local p2x, p2y = point(ox + val[c2x], oy + val[c2y])

			--both first and second points update point in path
			expr(c2x, sub, p2x, p1x)
			expr(c2y, sub, p2y, p1y)

			pcpx, pcpy = p2x, p2y
			if s == 'rel_move' then pspx, pspy = pcpx, pcpy end
		elseif s == 'hline' then
			local c2x = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(val[c2x], val[p1y])

			--point updates length in path
			link(p2x, c2x)
			--second point updates first point
			link(p2y, p1y)
			--first point updates second point
			link(p1y, p2y)

			pcpx, pcpy = p2x, p2y
		elseif s == 'vline' then
			local c2y = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(val[p1x], val[c2y])

			--point updates length in path
			link(p2y, c2y)
			--second point updates first point
			link(p2x, p1x)
			--first point updates second point
			link(p1x, p2x)

			pcpx, pcpy = p2x, p2y
		elseif s == 'rel_hline' then
			local c2x = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(ox + val[c2x], oy)

			--both first point and second point update length in path
			expr(c2x, sub, p2x, p1x)
			--second point updates first point
			link(p2y, p1y)
			--first point updates second point
			link(p1y, p2y)

			pcpx, pcpy = p2x, p2y
		elseif s == 'rel_vline' then
			local c2y = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(ox, oy + val[c2y])

			--both first point and second point update length in path
			expr(c2y, sub, p2y, p1y)
			--last point updates first point
			link(p2x, p1x)
			--first point updates last point
			link(p1x, p2x)

			pcpx, pcpy = p2x, p2y
		elseif s == 'curve' or s == 'rel_curve' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local c3x, c3y = var(path, i+3), var(path, i+4)
			local c4x, c4y = var(path, i+5), var(path, i+6)
			--create end point first so it has lower z-order than control points
			local p4x, p4y = point(ox + val[c4x], oy + val[c4y])
			local p2x, p2y = point(ox + val[c2x], oy + val[c2y], 'control')
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y], 'control')

			if rel then
				--points update themselves in path
				expr(c2x, sub, p2x, p1x)
				expr(c2y, sub, p2y, p1y)
				expr(c3x, sub, p3x, p1x)
				expr(c3y, sub, p3y, p1y)
				expr(c4x, sub, p4x, p1x)
				expr(c4y, sub, p4y, p1y)
			else
				--points update themselves in path
				link(p2x, c2x); link(p2y, c2y)
				link(p3x, c3x); link(p3y, c3y)
				link(p4x, c4x); link(p4y, c4y)
			end
			--first and last point move their control points
			link(p1x, p2x, add, p2x, delta)
			link(p1y, p2y, add, p2y, delta)
			link(p4x, p3x, add, p3x, delta)
			link(p4y, p3y, add, p3y, delta)

			cpline(p1x, p1y, p2x, p2y)
			cpline(p3x, p3y, p4x, p4y)

			pbx, pby = p3x, p3y
			pcpx, pcpy = p4x, p4y
		elseif s == 'smooth_curve' or s == 'rel_smooth_curve' then
			local c3x, c3y = var(path, i+1), var(path, i+2)
			local c4x, c4y = var(path, i+3), var(path, i+4)
			local p2x, p2y
			if pbx1 then
				p2x, p2y = point(
					reflect(val, pbx1, p1x),
					reflect(val, pby1, p1y), 'control')
			end
			--create end point first so it has lower z-order than control points
			local p4x, p4y = point(ox + val[c4x], oy + val[c4y])
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y], 'control')

			if rel then
				--points update themselves in path
				expr(c3x, sub, p3x, p1x)
				expr(c3y, sub, p3y, p1y)
				expr(c4x, sub, p4x, p1x)
				expr(c4y, sub, p4y, p1y)
			else
				--points update themselves in path
				link(p3x, c3x); link(p3y, c3y)
				link(p4x, c4x); link(p4y, c4y)
			end
			if p2x then
				--first point moves its control point
				link(p1x, p2x, add, p2x, delta)
				link(p1y, p2y, add, p2y, delta)
				--reflective control points move each other around first point
				link(p2x, pbx1, reflect, p2x, p1x)
				link(p2y, pby1, reflect, p2y, p1y)
				link(pbx1, p2x, reflect, pbx1, p1x)
				link(pby1, p2y, reflect, pby1, p1y)

				cpline(p1x, p1y, p2x, p2y)
			end
			--last point moves its control point
			link(p4x, p3x, add, p3x, delta)
			link(p4y, p3y, add, p3y, delta)

			cpline(p3x, p3y, p4x, p4y)

			pbx, pby = p3x, p3y
			pcpx, pcpy = p4x, p4y
		elseif s == 'quad_curve' or s == 'rel_quad_curve' or s == 'quad_curve_3p' or s == 'rel_quad_curve_3p' then
			local _3p = s:match'_3p$'
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local c3x, c3y = var(path, i+3), var(path, i+4)
			--create end point first so it has lower z-order than control points
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y])
			local p2x, p2y = point(ox + val[c2x], oy + val[c2y], 'control')

			if rel then
				--points update themselves in path
				expr(c2x, sub, p2x, p1x)
				expr(c2y, sub, p2y, p1y)
				expr(c3x, sub, p3x, p1x)
				expr(c3y, sub, p3y, p1y)
			else
				--points update themselves in path
				link(p2x, c2x); link(p2y, c2y)
				link(p3x, c3x); link(p3y, c3y)
			end
			--first and last point move their control points
			link(p1x, p2x, add, p2x, delta)
			link(p1y, p2y, add, p2y, delta)
			link(p3x, p2x, add, p2x, delta)
			link(p3y, p2y, add, p2y, delta)

			if not _3p then
				cpline(p1x, p1y, p2x, p2y)
				cpline(p2x, p2y, p3x, p3y)
				pqx, pqy = p2x, p2y
			end
			pcpx, pcpy = p3x, p3y
		elseif s == 'smooth_quad_curve' or s == 'rel_smooth_quad_curve' then
			local c3x, c3y = var(path, i+1), var(path, i+2)
			local p2x, p2y
			if pqx1 then
				p2x, p2y = point(
					reflect(val, pqx1, p1x),
					reflect(val, pqy1, p1y), 'control')
			end
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y])

			if rel then
				--points update themselves in path
				expr(c3x, sub, p3x, p1x)
				expr(c3y, sub, p3y, p1y)
			else
				--points update themselves in path
				link(p3x, c3x)
				link(p3y, c3y)
			end
			if p2x then
				--first and last point move their control point
				link(p1x, p2x, add, p2x, delta)
				link(p1y, p2y, add, p2y, delta)
				link(p3x, p2x, add, p2x, delta)
				link(p3y, p2y, add, p2y, delta)
				--reflective control points move each other around first point
				link(p2x, pqx1, reflect, p2x, p1x)
				link(p2y, pqy1, reflect, p2y, p1y)
				link(pqx1, p2x, reflect, pqx1, p1x)
				link(pqy1, p2y, reflect, pqy1, p1y)

				cpline(p1x, p1y, p2x, p2y)
				cpline(p2x, p2y, p3x, p3y)
			end

			pqx, pqy = p2x or p1x, p2y or p1y
			pcpx, pcpy = p3x, p3y
		elseif s == 'arc' or s == 'rel_arc' then
			--path variables
			local ccx, ccy, cr, cstart_angle, csweep_angle =
				var(path, i+1), var(path, i+2), var(path, i+3), var(path, i+4), var(path, i+5)

			--arc endpoint expressions
			local function endpoint_arg(i)
				return function()
					local t = val
					local cx, cy = t[ccx], t[ccy]
					if rel then cx, cy = t[p1x] + cx, t[p1y] + cy end
					return select(i,
						arc_endpoints(cx, cy, t[cr], math.rad(t[cstart_angle]), math.rad(t[csweep_angle])))
				end
			end
			local getp2x, getp2y, getp3x, getp3y =
				endpoint_arg(1), endpoint_arg(2), endpoint_arg(3), endpoint_arg(4)

			--arc sweep angle expression
			local function calc_sweep_angle(t, p1x, p1y, p2x, p2y, p3x, p3y, csweep_angle)
				local start_angle = point_angle(t, p2x, p2y, p1x, p1y)
				local sweep_angle1 = t[csweep_angle]
				local end_angle = point_angle(t, p3x, p3y, p1x, p1y)
				local sweep_angle_poz = (end_angle - start_angle) % 360
				local sweep_angle_neg = sweep_angle_poz - 360
				--choose the angle closest to the current sweep angle
				local sweep_angle =
					math.abs(sweep_angle_poz - sweep_angle1) <
					math.abs(sweep_angle_neg - sweep_angle1)
					and sweep_angle_poz or sweep_angle_neg
				return sweep_angle
			end

			--finally, the points
			local cx, cy = path[i+1], path[i+2]
			if rel then cx, cy = ox + cx, oy + cy end
			local pcx, pcy = point(cx, cy)
			local p2x, p2y = point(getp2x(), getp2y(), 'control')
			local p3x, p3y = point(getp3x(), getp3y(), 'control')

			--center point updates itself in path
			if rel then
				expr(ccx, sub, pcx, p1x)
				expr(ccy, sub, pcy, p1y)
			else
				link(pcx, ccx)
				link(pcy, ccy)
			end
			--arc's control points update the arc parameters in path
			link(p2x, cr, point_distance, p2x, p2y, pcx, pcy)
			link(p2y, cr, point_distance, p2x, p2y, pcx, pcy)
			link(p3x, cr, point_distance, p3x, p3y, pcx, pcy)
			link(p3y, cr, point_distance, p3x, p3y, pcx, pcy)
			link(p2x, cstart_angle, point_angle, p2x, p2y, pcx, pcy)
			link(p2y, cstart_angle, point_angle, p2x, p2y, pcx, pcy)
			link(p3x, csweep_angle, calc_sweep_angle, pcx, pcy, p2x, p2y, p3x, p3y, csweep_angle)
			link(p3y, csweep_angle, calc_sweep_angle, pcx, pcy, p2x, p2y, p3x, p3y, csweep_angle)
			--arc's start control point updates sweep control point in a separate link chain
			linkon(2, p2x, p3x, getp3x)
			linkon(2, p2x, p3y, getp3y)
			linkon(2, p2y, p3x, getp3x)
			linkon(2, p2y, p3y, getp3y)
			--arc's sweep control point updates start control point in a separate link chain
			linkon(3, p3x, p2x, getp2x)
			linkon(3, p3x, p2y, getp2y)
			linkon(3, p3y, p2x, getp2x)
			linkon(3, p3y, p2y, getp2y)
			--arc's center control point updates angle control points in a separate link chain
			linkon(4, pcx, p2x, add, p2x, delta)
			linkon(4, pcy, p2y, add, p2y, delta)
			linkon(4, pcx, p3x, add, p3x, delta)
			linkon(4, pcy, p3y, add, p3y, delta)

			local lcx, lcy, l2x, l2y = cpline(pcx, pcy, p2x, p2y)
			for i=2,4 do --update cpline in all link chains
				linkon(i, p2x, l2x)
				linkon(i, p2y, l2y)
			end
			local lcx, lcy, l3x, l3y = cpline(pcx, pcy, p3x, p3y)
			for i=2,4 do --update cpline in all link chains
				linkon(i, p3x, l3x)
				linkon(i, p3y, l3y)
			end

			pcpx, pcpy = p3x, p3y
		elseif s == 'arc_3p' or s == 'rel_arc_3p' then
			local c2x, c2y, c3x, c3y =
				var(path, i+1), var(path, i+2), var(path, i+3), var(path, i+4)
			local p2x, p2y = point(ox + path[i+1], oy + path[i+2])
			local p3x, p3y = point(ox + path[i+3], oy + path[i+4])

			--control points update circle in path
			if rel then
				expr(c2x, sub, p2x, p1x)
				expr(c2y, sub, p2y, p1y)
				expr(c3x, sub, p3x, p1x)
				expr(c3y, sub, p3y, p1y)
			else
				link(p2x, c2x); link(p2y, c2y)
				link(p3x, c3x); link(p3y, c3y)
			end

			pcpx, pcpy = p3x, p3y
		elseif s == 'svgarc' or s == 'rel_svgarc' then
			--path variables
			local crx, cry, crotate, cflag1, cflag2, c2x, c2y =
				var(path, i+1), var(path, i+2), var(path, i+3),
				var(path, i+4), var(path, i+5), var(path, i+6), var(path, i+7)

			--second endpoint
			local rx, ry, rotate, flag1, flag2, x2, y2 = unpack(path, i + 1, i + 7)
			if rel then x2, y2 = ox + x2, oy + y2 end
			local p2x, p2y = point(x2, y2)

			--arc arguments expressions
			local function arc_arg(i)
				local t = val
				return function()
					return select(i,
						svgarc_to_elliptic_arc(t[p1x], t[p1y], t[crx], t[cry], t[crotate],
															t[cflag1], t[cflag2], t[p2x], t[p2y]))
				end
			end
			local getcx, getcy = arc_arg(1), arc_arg(2)
			local getrx, getry = arc_arg(3), arc_arg(4)

			--arc's center point
			local pcx, pcy = point(getcx(), getcy())
			--arc's radius points
			local function getprxx() return getcx() + getrx() end
			local function getpryy() return getcy() + getry() end
			local prxx, prxy = point(getprxx(), val[pcy], 'control')
			local pryx, pryy = point(val[pcx], getpryy(), 'control')
			constrain(pryx, copy, pcx)
			constrain(prxy, copy, pcy)

			--arc second endpoint updates itself in path
			if rel then
				expr(c2x, sub, p2x, p1x)
				expr(c2y, sub, p2y, p1y)
			else
				link(p2x, c2x)
				link(p2y, c2y)
			end
			--arc's center point updates end points
			link(pcx, p1x, add, p1x, delta)
			link(pcy, p1y, add, p1y, delta)
			link(pcx, p2x, add, p2x, delta)
			link(pcy, p2y, add, p2y, delta)
			link(pcx, prxx, add, prxx, delta)
			link(pcy, pryy, add, pryy, delta)
			link(pcx, prxy, add, prxy, delta)
			link(pcy, pryx, add, pryx, delta)
			--arc's center point changes when end points change
			expron(2, pcx, getcx, p1x, p1y, p2x, p2y)
			expron(2, pcy, getcy, p1x, p1y, p2x, p2y)
			--arc's radius points change when end points change
			expron(2, prxx, getprxx, p1x, p1y, p2x, p2y)
			expron(2, pryy, getpryy, p1x, p1y, p2x, p2y)
			linkon(2, pcx, prxy)
			linkon(2, pcy, pryx)

			pcpx, pcpy = p2x, p2y
		elseif s == 'text' then
			--TODO:
		elseif s == 'rect' or s == 'round_rect' then
			local x, y, w, h = unpack(path, i + 1, i + 4)
			local cx, cy = var(path, i+1), var(path, i+2)
			local cw, ch = var(path, i+3), var(path, i+4)

			--corner control points
			local p11x, p11y = point(x, y)
			local p22x, p22y = point(x + w, y + h)
			local p21x, p21y = point(x + w, y)
			local p12x, p12y = point(x, y + h)
			--median control points
			local pc1x, pc1y = point(x + w/2, y)
			constrain(pc1x, middle, p22x, p11x)
			local pc2x, pc2y = point(x + w/2, y + h)
			constrain(pc2x, middle, p22x, p11x)
			local pc3x, pc3y = point(x, y + h/2)
			constrain(pc3y, middle, p22y, p11y)
			local pc4x, pc4y = point(x + w, y + h/2)
			constrain(pc4y, middle, p22y, p11y)

			--moving top,left and bottom,right (primary) corner control points updates the rect in path
			link(p11x, cx)
			link(p11y, cy)
			link(p11x, cw, sub, p22x, p11x)
			link(p11y, ch, sub, p22y, p11y)
			link(p22x, cw, sub, p22x, p11x)
			link(p22y, ch, sub, p22y, p11y)
			--moving primary corner control points moves top,right and bottom,left (secondary) corner control points
			link(p11x, p12x)
			link(p11y, p21y)
			link(p22x, p21x)
			link(p22y, p12y)
			--moving secondary corner control points moves primary corner control points
			link(p21x, p22x)
			link(p21y, p11y)
			link(p12x, p11x)
			link(p12y, p22y)
			--moving primary control points moves median control points
			link(p22x, pc1x, middle, p22x, p11x)
			link(p11x, pc1x, middle, p22x, p11x)
			link(p11y, pc1y)
			link(p22x, pc2x, middle, p22x, p11x)
			link(p11x, pc2x, middle, p22x, p11x)
			link(p22y, pc2y)
			link(p22y, pc3y, middle, p22y, p11y)
			link(p11y, pc3y, middle, p22y, p11y)
			link(p11x, pc3x)
			link(p22y, pc4y, middle, p22y, p11y)
			link(p11y, pc4y, middle, p22y, p11y)
			link(p22x, pc4x)
			--moving median control points moves primary corner control points
			link(pc1y, p11y)
			link(pc2y, p22y)
			link(pc3x, p11x)
			link(pc4x, p22x)

			if s == 'round_rect' then
				local r = math.abs(path[i+5])
				local cr = var(path, i+5)

				local rx = r * (w > 0 and 1 or -1)
				local ry = r * (h > 0 and 1 or -1)

				local function radius_points()
					local prx, pry = point(x + rx, y, 'control')
					constrain(pry, copy, p11y)
					constrain(prx, function(t)
						local absr = math.min(math.abs(t[prx] - t[p11x]), math.abs(t[cw]/2), math.abs(t[ch]/2))
						return t[p11x] + absr * (t[cw] > 0 and 1 or -1)
					end)

					link(prx, cr, sub, prx, p11x)
					link(p11x, prx, function(t) return t[p11x] + t[cr] * (t[cw] > 0 and 1 or -1) end)
					link(p11y, pry)
					--link(cr, prx, add, p11x, cr)
				end
				radius_points()
			end

			pcpx, pcpy, pspx, pspy = nil
		elseif s == 'circle' then
			local x, y, r = path[i+1], path[i+2], path[i+3]
			local cx, cy, cr = var(path, i+1), var(path, i+2), var(path, i+3)
			local pcx, pcy = point(x, y)
			local prx, pry = point(x + r, y, 'control')

			--control points update circle in path
			link(pcx, cx)
			link(pcy, cy)
			link(prx, cr, point_distance, prx, pry, pcx, pcy)
			link(pry, cr, point_distance, prx, pry, pcx, pcy)
			--center control point updates radius control point
			link(pcx, prx, add, prx, delta)
			link(pcy, pry, add, pry, delta)

			cpline(pcx, pcy, prx, pry)

			pcpx, pcpy, pspx, pspy = nil
		elseif s == 'circle_3p' then
			local cx1, cy1, cx2, cy2, cx3, cy3 =
				var(path, i+1), var(path, i+2), var(path, i+3), var(path, i+4), var(path, i+5), var(path, i+6)
			local px1, py1 = point(path[i+1], path[i+2])
			local px2, py2 = point(path[i+3], path[i+4])
			local px3, py3 = point(path[i+5], path[i+6])

			--control points update circle in path
			link(px1, cx1); link(py1, cy1)
			link(px2, cx2); link(py2, cy2)
			link(px3, cx3); link(py3, cy3)

			pcpx, pcpy, pspx, pspy = nil
		elseif s == 'ellipse' then
			local x, y, rx, ry = path[i+1], path[i+2], path[i+3], path[i+4]
			local cx, cy, crx, cry = var(path, i+1), var(path, i+2), var(path, i+3), var(path, i+4)
			local pcx, pcy = point(x, y)
			local prxx, prxy = point(x + rx, y, 'control')
			local pryx, pryy = point(x, y + ry, 'control')
			constrain(pryx, copy, pcx)
			constrain(prxy, copy, pcy)

			--control points update circle in path
			link(pcx, cx)
			link(pcy, cy)
			link(prxx, crx, sub, prxx, pcx)
			link(pryy, cry, sub, pryy, pcy)
			--center control point updates radius control points
			link(pcx, prxx, add, prxx, delta)
			link(pcy, prxy, add, prxy, delta)
			link(pcx, pryx, add, pryx, delta)
			link(pcy, pryy, add, pryy, delta)

			cpline(pcx, pcy, prxx, prxy)
			cpline(pcx, pcy, pryx, pryy)

			pcpx, pcpy, pspx, pspy = nil
		end
	end

	return {
		points = points,
		update_point = update_point,
		point_styles = point_styles,
		control_path = control_path,
	}
end

if not ... then require'path_editor_demo' end

return editor
