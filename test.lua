local glue = require'glue'
local path_state = require'path_state'
local arc = require'path_arc'
local path_math = require'path_math'

--a varlinker links variables together with custom expressions so that when one variable is updated,
--other dependent variables are updated as well. variables are declared with var(t,i) -> var, which
--makes val[var] return the value at t[i] and setting val[var] = v results in setting t[i] = v.
--variables can then be linked with link(source_var, dest_var, f, var1, ...) which means whenever
--val[source_var] is set, val[dest_var] is also set with the result of calling f(var1, ...).
--an indirect link to the source table is kept so a variable can be retrieved with find(t,i) -> var.
local function varlinker()
	local refs = {}
	local vars = {}
	local function var(t,i)
		local k = #refs+1
		refs[k] = {t,i}
		vars[t] = vars[t] or {}
		vars[t][i] = k
		return k
	end
	local function find(t,i)
		return vars[t][i]
	end
	local function get(k)
		local t,i = unpack(refs[k])
		return t[i]
	end
	local function set(k,v)
		local t,i = unpack(refs[k])
		t[i] = v
	end
	local deps = {}
	local function link(k1, k2, f, ...)
		deps[k1] = deps[k1] or {}
		deps[k1][k2] = f and {f, ...} or {get, k1}
	end
	local function update(k, v, touched)
		touched = touched or {}
		if touched[k] then return end
		set(k,v)
		touched[k] = true
		local dt = deps[k]
		if not dt then return end
		for k2,dep in pairs(dt) do
			update(k2, dep[1](unpack(dep, 2)), touched)
		end
	end
	local val = setmetatable({}, {
		__index = function(t,k) return get(k) end,
		__newindex = function(t,k,v) update(k,v) end,
	})
	return {
		var = var,
		val = val,
		link = link,
		find = find,
	}
end

local function editor(path)
	local linker = varlinker()
	local var, val, link, find = linker.var, linker.val, linker.link, linker.find

	local function add(var1, var2) return val[var1] + val[var2] end
	local function sub(var1, var2) return val[var1] - val[var2] end
	local function reflect(varx, varc) return 2 * val[varc] - val[varx] end
	local function point_distance(p1x, p1y, p2x, p2y)
		return path_math.point_distance(val[p1x], val[p1y], val[p2x], val[p2y])
	end
	local function point_angle(p1x, p1y, p2x, p2y)
		return math.deg(path_math.point_angle(val[p1x], val[p1y], val[p2x], val[p2y]))
	end

	local points = {}
	local function point(x,y,nolink)
		glue.append(points, x, y)
		return var(points, #points-1), var(points, #points)
	end

	local delta = var({},1)
	local function update(t,i,v)
		local var = find(t,i)
		val[delta] = v - val[var]
		val[var] = v
	end

	local cplines = {}
	local function cpline(p1x, p1y, p2x, p2y)
		glue.append(cplines, val[p1x], val[p1y])
		link(p1x, var(cplines, #cplines-1))
		link(p1y, var(cplines, #cplines-0))
		glue.append(cplines, val[p2x], val[p2y])
		link(p2x, var(cplines, #cplines-1))
		link(p2y, var(cplines, #cplines-0))
	end

	local cparcs = {}

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

			--point updates path
			link(p2x, c2x)
			link(p2y, c2y)

			pcpx, pcpy = p2x, p2y
			if s == 'move' then pspx, pspy = pcpx, pcpy end
		elseif s == 'close' then
			pcpx, pcpy = pspx, pspy
		elseif s == 'rel_move' or s == 'rel_line' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local p2x, p2y = point(ox + val[c2x], oy + val[c2y])

			--point updates path
			link(p2x, c2x, sub, p2x, p1x)
			link(p2y, c2y, sub, p2y, p1y)
			--first point updates last point
			link(p1x, c2x, sub, p2x, p1x)
			link(p1y, c2y, sub, p2y, p1y)

			pcpx, pcpy = p2x, p2y
			if s == 'rel_move' then pspx, pspy = pcpx, pcpy end
		elseif s == 'hline' then
			local c2x = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(val[c2x], val[p1y])

			--point updates path
			link(p2x, c2x)
			--last point updates first point
			link(p2y, p1y)
			--first point updates last point
			link(p1y, p2y)

			pcpx, pcpy = p2x, p2y
		elseif s == 'vline' then
			local c2y = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(val[p1x], val[c2y])

			--point updates path
			link(p2y, c2y)
			--last point updates first point
			link(p2x, p1x)
			--first point updates last point
			link(p1x, p2x)

			pcpx, pcpy = p2x, p2y
		elseif s == 'rel_hline' then
			local c2x = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(ox + val[c2x], oy)

			--point updates path
			link(p2x, c2x, sub, p2x, p1x)
			--last point updates first point
			link(p2y, p1y)
			--first point updates last point
			link(p1y, p2y)
			link(p1x, c2x, sub, p2x, p1x)

			pcpx, pcpy = p2x, p2y
		elseif s == 'rel_vline' then
			local c2y = var(path, i+1)
			local p2x, p2y, h2x, h2y = point(ox, oy + val[c2y])

			--point updates path
			link(p2y, c2y, sub, p2y, p1y)
			--last point updates first point
			link(p2x, p1x)
			--first point updates last point
			link(p1x, p2x)
			link(p1y, c2y, sub, p2y, p1y)

			pcpx, pcpy = p2x, p2y
		elseif s == 'curve' or s == 'rel_curve' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local c3x, c3y = var(path, i+3), var(path, i+4)
			local c4x, c4y = var(path, i+5), var(path, i+6)
			--create end point first so it has lower z-order than control points
			local p4x, p4y = point(ox + val[c4x], oy + val[c4y])
			local p2x, p2y = point(ox + val[c2x], oy + val[c2y])
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y])

			if rel then
				--points update themselves in path
				link(p2x, c2x, sub, p2x, p1x)
				link(p2y, c2y, sub, p2y, p1y)
				link(p3x, c3x, sub, p3x, p1x)
				link(p3y, c3y, sub, p3y, p1y)
				link(p4x, c4x, sub, p4x, p1x)
				link(p4y, c4y, sub, p4y, p1y)
				--first point updates last point
				link(p1x, c4x, sub, p4x, p1x)
				link(p1y, c4y, sub, p4y, p1y)
			else
				--points update themselves in path
				link(p2x, c2x); link(p2y, c2y)
				link(p3x, c3x); link(p3y, c3y)
				link(p4x, c4x); link(p4y, c4y)
				--first and last point move their control points
				link(p1x, p2x, add, p2x, delta)
				link(p1y, p2y, add, p2y, delta)
				link(p4x, p3x, add, p3x, delta)
				link(p4y, p3y, add, p3y, delta)
			end

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
					reflect(pbx1, p1x),
					reflect(pby1, p1y))
			end
			--create end point first so it has lower z-order than control points
			local p4x, p4y = point(ox + val[c4x], oy + val[c4y])
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y])

			if rel then
				--points update themselves in path
				link(p3x, c3x, sub, p3x, p1x)
				link(p3y, c3y, sub, p3y, p1y)
				link(p4x, c4x, sub, p4x, p1x)
				link(p4y, c4y, sub, p4y, p1y)
				--first point updates last point
				link(p1x, c4x, sub, p4x, p1x)
				link(p1y, c4y, sub, p4y, p1y)
			else
				--points update themselves in path
				link(p3x, c3x); link(p3y, c3y)
				link(p4x, c4x); link(p4y, c4y)
			end
			if p2x then
				--first and last point move their control point
				link(p1x, p2x, add, p2x, delta)
				link(p1y, p2y, add, p2y, delta)
				link(p4x, p3x, add, p3x, delta)
				link(p4y, p3y, add, p3y, delta)
				--reflective control points move each other around first point
				link(p2x, pbx1, reflect, p2x, p1x)
				link(p2y, pby1, reflect, p2y, p1y)
				link(pbx1, p2x, reflect, pbx1, p1x)
				link(pby1, p2y, reflect, pby1, p1y)

				cpline(p1x, p1y, p2x, p2y)
			end
			cpline(p3x, p3y, p4x, p4y)

			pbx, pby = p3x, p3y
			pcpx, pcpy = p4x, p4y
		elseif s == 'quad_curve' or s == 'rel_quad_curve' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local c3x, c3y = var(path, i+3), var(path, i+4)
			--create end point first so it has lower z-order than control points
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y])
			local p2x, p2y = point(ox + val[c2x], oy + val[c2y])

			if rel then
				--points update themselves in path
				link(p2x, c2x, sub, p2x, p1x)
				link(p2y, c2y, sub, p2y, p1y)
				link(p3x, c3x, sub, p3x, p1x)
				link(p3y, c3y, sub, p3y, p1y)
				--first point updates last point
				link(p1x, c3x, sub, p3x, p1x)
				link(p1y, c3y, sub, p3y, p1y)
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

			cpline(p1x, p1y, p2x, p2y)
			cpline(p2x, p2y, p3x, p3y)

			pqx, pqy = p2x, p2y
			pcpx, pcpy = p3x, p3y
		elseif s == 'smooth_quad_curve' or s == 'rel_smooth_quad_curve' then
			local c3x, c3y = var(path, i+1), var(path, i+2)
			local p2x, p2y
			if pqx1 then
				p2x, p2y = point(
					reflect(pqx1, p1x),
					reflect(pqy1, p1y))
			end
			local p3x, p3y = point(ox + val[c3x], oy + val[c3y])

			if rel then
				--points update themselves in path
				link(p3x, c3x, sub, p3x, p1x)
				link(p3y, c3y, sub, p3y, p1y)
				--first point updates last point
				link(p1x, c3x, sub, p3x, p1x)
				link(p1y, c3y, sub, p3y, p1y)
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
			local cx, cy, r, start_angle, sweep_angle = unpack(path, i + 1, i + 5)
			local ccx, ccy, cr, cstart_angle, csweep_angle =
				var(path, i+1), var(path, i+2), var(path, i+3), var(path, i+4), var(path, i+5)
			if rel then cx, cy = ox + cx, oy + cy end
			local pcx, pcy = point(cx, cy)
			if rel then
				link(pcx, ccx, sub, pcx, p1x)
				link(pcy, ccy, sub, pcy, p1y)
				--first point updates center
				link(p1x, ccx, sub, pcx, p1x)
				link(p1y, ccy, sub, pcy, p1y)
			else
				link(pcx, ccx)
				link(pcy, ccy)
			end
			local segments = arc(cx, cy, r, r, math.rad(start_angle), math.rad(sweep_angle))
			local p2x, p2y = point(segments[1], segments[2])
			local p3x, p3y = point(segments[#segments-1], segments[#segments])

			--arc's control points update radius
			link(p2x, cr, point_distance, p2x, p2y, pcx, pcy)
			link(p2y, cr, point_distance, p2x, p2y, pcx, pcy)
			link(p3x, cr, point_distance, p3x, p3y, pcx, pcy)
			link(p3y, cr, point_distance, p3x, p3y, pcx, pcy)
			--arc's start control point update start angle
			link(p2x, cstart_angle, point_angle, pcx, pcy, p2x, p2y)
			link(p2y, cstart_angle, point_angle, pcx, pcy, p2x, p2y)
			--arc's start control point update second control point
			link(p2x, p3x, point_angle, pcx, pcy, p2x, p2y)
			link(p2x, p3y, point_angle, pcx, pcy, p2x, p2y)
			link(p2y, p3x, point_angle, pcx, pcy, p2x, p2y)
			link(p2y, p3y, point_angle, pcx, pcy, p2x, p2y)

			cpline(pcx, pcy, p2x, p2y)
			cpline(pcx, pcy, p3x, p3y)

			pcpx, pcpy = p3x, p3y
		elseif s == 'text' then
			--TODO:
		else
			--TODO:
		end
	end

	return {
		points = points,
		handles = points,
		cplines = cplines,
		cparcs = cparcs,
		update = update,
	}
end

local path = {
	'move', 100, 100,
	'line', 200, 200,
	'line', 300, 50,
	'close',
	'rel_move', 0, 100,
	'rel_line', 100, -100,
	'hline', 500,
	'vline', 200,
	'hline', 600,
	'vline', 300,
	'rel_hline', 100,
	'rel_vline', -100,
	'rel_hline', 100,
	'rel_vline', 100,
	'rel_hline', 100,
	'rel_quad_curve', 50, -100, 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'move', 100, 400,
	'quad_curve', 200, 300, 300, 400,
	'smooth_quad_curve', 500, 400,
	'rel_line', 50, 100,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 0, -100,
	'rel_smooth_quad_curve', 100, 0,
	'move', 100, 600,
	'curve', 50, 500, 250, 500, 200, 600,
	'rel_curve', 150, 100, -50, 100, 100, 0,
	'smooth_curve', 350, 500, 500, 600,
	'rel_smooth_curve', -50, 100, 100, 0,
	'rel_line', 100, 0,
	'rel_smooth_curve', 50, 100, 100, 0,
	'rel_arc', 100, 0, 50, 30, 60,
}

local e = editor(path)

local player = require'cairopanel_player'
local path_simplify = require'path_simplify'
local ffi = require'ffi'
local i = 0
function player:on_render(cr)
	i = i + 1
	cr:set_source_rgb(0,0,0)
	cr:paint()
	cr:identity_matrix()

	for i=#e.handles-1,1,-2 do
		local x, y = e.handles[i], e.handles[i+1]
		if self.is_dragging then
			if not self.dragging_handle and self:dragging(x, y) then
				self.dragging_handle = i
				self.old_path = glue.update({}, path)
			end
		else
			self.dragging_handle = nil
			self.old_path = nil
		end
		if self.dragging_handle == i then
			e.update(e.handles, i+0, self.mouse_x)
			e.update(e.handles, i+1, self.mouse_y)
		end
	end

	local function write(s,...)
		if s == 'move' then
			cr:move_to(...)
		elseif s == 'line' then
			cr:line_to(...)
		elseif s == 'curve' then
			cr:curve_to(...)
		elseif s == 'close' then
			cr:close_path()
		end
	end

	cr:set_line_width(1)

	cr:set_dash(ffi.new('double[?]', 2, {1,2}), 2, 0)
	cr:set_source_rgb(0.5,1,0.5)
	cr:new_path()
	for i=1,#e.cplines,4 do
		cr:move_to(e.cplines[i+0], e.cplines[i+1])
		cr:line_to(e.cplines[i+2], e.cplines[i+3])
		cr:stroke()
	end

	if self.old_path then
		cr:set_dash(nil, 0, 0)
		cr:set_source_rgb(1,1,1)
		cr:new_path()
		path_simplify(write, self.old_path)
		cr:stroke()

		cr:set_dash(ffi.new('double[?]', 2, {1,2}), 2, 0)
		cr:set_source_rgb(0.5,0.5,1)
		cr:new_path()
		path_simplify(write, path)
		cr:stroke()
	else
		cr:set_dash(nil, 0, 0)
		cr:set_source_rgb(1,1,1)
		cr:new_path()
		path_simplify(write, path)
		cr:stroke()
	end

	for i=1,#e.points,2 do
		local x, y = e.points[i], e.points[i+1]
		cr:circle(x, y, 2)
		cr:set_source_rgb(1,1,1)
		cr:fill()
	end
end
player:play()
