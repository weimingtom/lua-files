local glue = require'glue'
local path_state = require'path_state'

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

	local function add(var1,var2) return val[var1] + val[var2] end
	local function sub(var1,var2) return val[var1] - val[var2] end
	local function reflect(varx, varc) return 2 * val[varc] - val[varx] end

	local points = {}
	local handles = {}

	local function point(x,y,nolink)
		glue.append(points, x, y)
		local px, py = var(points, #points-1), var(points, #points)
		glue.append(handles, x, y)
		local hx, hy = var(handles, #handles-1), var(handles, #handles)
		if not nolink then --handles directly update points, with some exceptions
			link(hx, px)
			link(hy, py)
		end
		return px, py, hx, hy
	end

	local delta = var({},1)
	local function update(t,i,v)
		local var = find(t,i)
		val[delta] = v - val[var]
		val[var] = v
	end

	local cp_path = {}
	local function add_cp(p1x, p1y, p2x, p2y)
		glue.append(cp_path, 'move', val[p1x], val[p1y])
		link(p1x, var(cp_path, #cp_path-1))
		link(p1y, var(cp_path, #cp_path-0))
		glue.append(cp_path, 'line', val[p2x], val[p2y])
		link(p2x, var(cp_path, #cp_path-1))
		link(p2y, var(cp_path, #cp_path-0))
	end

	local pcpx, pcpy, pspx, pspy, pbx, pby, pqx, pqy
	for i,s in path_state.commands(path) do
		local is_quad, is_cubic
		if s == 'move' or s == 'line' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local p2x, p2y = point(val[c2x], val[c2y])

			--point updates path
			link(p2x, c2x)
			link(p2y, c2y)

			pcpx, pcpy = p2x, p2y
			if s == 'move' then pspx, pspy = pcpx, pcpy end
		elseif s == 'rel_move' or s == 'rel_line' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local p1x, p1y = pcpx, pcpy
			local p2x, p2y = point(add(p1x, c2x), add(p1y, c2y))

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
			local p1x, p1y = pcpx, pcpy
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
			local p1x, p1y = pcpx, pcpy
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
			local p1x, p1y = pcpx, pcpy
			local p2x, p2y, h2x, h2y = point(val[p1x] + val[c2x], val[p1y])

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
			local p1x, p1y = pcpx, pcpy
			local p2x, p2y, h2x, h2y = point(val[p1x], val[p1y] + val[c2y])

			--point updates path
			link(p2y, c2y, sub, p2y, p1y)
			--last point updates first point
			link(p2x, p1x)
			--first point updates last point
			link(p1x, p2x)
			link(p1y, c2y, sub, p2y, p1y)

			pcpx, pcpy = p2x, p2y
		elseif s == 'quad_curve' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local c3x, c3y = var(path, i+3), var(path, i+4)
			local p1x, p1y = pcpx, pcpy
			local p2x, p2y = point(val[c2x], val[c2y])
			local p3x, p3y = point(val[c3x], val[c3y])

			--points update themselves in path
			link(p2x, c2x)
			link(p2y, c2y)
			link(p3x, c3x)
			link(p3y, c3y)
			--first and last point move their control points
			link(p1x, p2x, add, p2x, delta)
			link(p1y, p2y, add, p2y, delta)
			link(p3x, p2x, add, p2x, delta)
			link(p3y, p2y, add, p2y, delta)

			add_cp(p1x, p1y, p2x, p2y)
			add_cp(p2x, p2y, p3x, p3y)

			pqx, pqy, is_quad = p2x, p2y, true
			pcpx, pcpy = p3x, p3y
		elseif s == 'rel_quad_curve' then
			local c2x, c2y = var(path, i+1), var(path, i+2)
			local c3x, c3y = var(path, i+3), var(path, i+4)
			local p1x, p1y = pcpx, pcpy
			local p2x, p2y = point(add(p1x, c2x), add(p1y, c2y))
			local p3x, p3y = point(add(p1x, c3x), add(p1y, c3y))

			--points update themselves in path
			link(p2x, c2x, sub, p2x, p1x)
			link(p2y, c2y, sub, p2y, p1y)
			link(p3x, c3x, sub, p3x, p1x)
			link(p3y, c3y, sub, p3y, p1y)
			--first point updates last point
			link(p1x, c3x, sub, p3x, p1x)
			link(p1y, c3y, sub, p3y, p1y)
			--first and last point move their control points
			link(p1x, p2x, add, p2x, delta)
			link(p1y, p2y, add, p2y, delta)
			link(p3x, p2x, add, p2x, delta)
			link(p3y, p2y, add, p2y, delta)

			add_cp(p1x, p1y, p2x, p2y)
			add_cp(p2x, p2y, p3x, p3y)

			pqx, pqy, is_quad = p2x, p2y, true
			pcpx, pcpy = p3x, p3y
		elseif s == 'rel_smooth_quad_curve' then
			local c3x, c3y = var(path, i+1), var(path, i+2)
			local p1x, p1y = pcpx, pcpy
			local p2x, p2y = point(
				reflect(pqx or p1x, p1x),
				reflect(pqy or p1y, p1y))
			local p3x, p3y = point(add(p1x, c3x), add(p1y, c3y))

			--points update themselves in path
			link(p3x, c3x, sub, p3x, p1x)
			link(p3y, c3y, sub, p3y, p1y)
			--first point updates last point
			link(p1x, c3x, sub, p3x, p1x)
			link(p1y, c3y, sub, p3y, p1y)
			--first and last point move their control points
			link(p1x, p2x, add, p2x, delta)
			link(p1y, p2y, add, p2y, delta)
			link(p3x, p2x, add, p2x, delta)
			link(p3y, p2y, add, p2y, delta)
			--reflective control points move each other around first point
			if pqx then
				link(p2x, pqx, reflect, p2x, p1x)
				link(p2y, pqy, reflect, p2y, p1y)
				link(pqx, p2x, reflect, pqx, p1x)
				link(pqy, p2y, reflect, pqy, p1y)
			end

			add_cp(p1x, p1y, p2x, p2y)
			add_cp(p2x, p2y, p3x, p3y)

			pqx, pqy, is_quad = p2x, p2y, true
			pcpx, pcpy = p3x, p3y
		end
	end

	return {
		points = points,
		handles = handles,
		cp_path = cp_path,
		update = update,
	}
end

local path = {
	'move', 100, 100,
	'line', 200, 200,
	'rel_move', 100, -50,
	'rel_line', 100, -100,
	'hline', 500,
	'vline', 200,
	'hline', 600,
	'vline', 300,
	'rel_hline', 100,
	'rel_vline', -100,
	'rel_quad_curve', 50, -100, 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'move', 100, 700,
	'quad_curve', 200, 500, 300, 600,
	'quad_curve', 400, 500, 600, 600,
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

	for i=1,#e.points,2 do
		local x, y = e.points[i], e.points[i+1]
		if self.is_dragging then
			if not self.dragging_point and self:dragging(x, y) then
				self.dragging_point = i
				self.old_path = glue.update({}, path)
			end
		else
			self.dragging_point = nil
			self.old_path = nil
		end
		if self.dragging_point == i then
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
	--pp(e.cp_path)
	path_simplify(write, e.cp_path)
	cr:stroke()

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
		cr:circle(x, y, 3)
		cr:set_source_rgb(1,1,1)
		cr:fill()
	end

end
player:play()
