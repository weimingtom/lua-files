
local path = {
	'move', 200, 200,
	'rel_quad_curve', 50, -100, 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
}

local fn = {
	copy = function(t, i) return t[i] end,
	add = function(t, i, j) return t[i] + t[j] end,
	sub = function(t, i, j) return t[i] - t[j] end,
	reflect = function(t, xi, ci) return 2 * t[ci] - t[xi] end,
}

local n = 0
local function var(f, ...)
	n = n - 1
	path[n] = assert(f(path, ...))
	return n
end

local dv = 0

local deps = {}
local function link(k, k2, f, ...)
	deps[k] = deps[k] or {}
	deps[k][k2] = {f, ...}
end

local function update(k, v, touched)
	if not touched then path[dv] = v - path[k] end
	touched = touched or {}
	if touched[k] then return end
	path[k] = v
	touched[k] = true
	local t = deps[k]
	if not t then return end
	for k2,with in pairs(t) do
		update(k2, with[1](path, unpack(with, 2)), touched)
	end
end

local path2 = {
	'move', 200, 200,
	'quad_curve', 50, -100, 100, 0,
	'smooth_quad_curve', 100, 0,
	'smooth_quad_curve', 100, 0,
}

local c1x, c1y = 2, 3
local c2x, c2y = 5, 6
local c3x, c3y = 7, 8
local c5x, c5y = 10, 11
local c7x, c7y = 13, 14
local consts = {
	c1x, c1y,
	c2x, c2y,
	c3x, c3y,
	c5x, c5y,
	c7x, c7y,
}

local p1x, p1y = var(fn.copy, c1x), var(fn.copy, c1y)
local p2x, p2y = var(fn.add, c1x, c2x), var(fn.add, c1y, c2y)
local p3x, p3y = var(fn.add, p1x, c3x), var(fn.add, p1y, c3y)
local p4x, p4y = var(fn.reflect, p2x, p3x), var(fn.reflect, p2y, p3y)
local p5x, p5y = var(fn.add, p3x, c5x), var(fn.add, p3y, c5y)
local p6x, p6y = var(fn.reflect, p4x, p5x), var(fn.reflect, p4y, p5y)
local p7x, p7y = var(fn.add, p5x, c7x), var(fn.add, p5y, c7y)
local points = {
	p1x, p1y,
	p2x, p2y,
	p3x, p3y,
	p4x, p4y,
	p5x, p5y,
	p6x, p6y,
	p7x, p7y,
}

-- points update path
link(p1x, c1x, fn.copy, p1x)
link(p1y, c1y, fn.copy, p1y)

link(p2x, c2x, fn.sub, p2x, p1x)
link(p2y, c2y, fn.sub, p2y, p1y)

link(p3x, c3x, fn.sub, p3x, p1x)
link(p3y, c3y, fn.sub, p3y, p1y)

link(p5x, c5x, fn.sub, p5x, p3x)
link(p5y, c5y, fn.sub, p5y, p3y)

link(p7x, c7x, fn.sub, p7x, p5x)
link(p7y, c7y, fn.sub, p7y, p5y)

-- first point moves last point
link(p1x, c3x, fn.sub, p3x, p1x)
link(p1y, c3y, fn.sub, p3y, p1y)

link(p3x, c5x, fn.sub, p5x, p3x)
link(p3y, c5y, fn.sub, p5y, p3y)

link(p5x, c7x, fn.sub, p7x, p5x)
link(p5y, c7y, fn.sub, p7y, p5y)

-- quad control point moves nearby smooth quad control points
link(p2x, p4x, fn.reflect, p2x, p3x)
link(p2y, p4y, fn.reflect, p2y, p3y)

link(p4x, p2x, fn.reflect, p4x, p3x)
link(p4y, p2y, fn.reflect, p4y, p3y)

link(p4x, p6x, fn.reflect, p4x, p5x)
link(p4y, p6y, fn.reflect, p4y, p5y)

link(p6x, p4x, fn.reflect, p6x, p5x)
link(p6y, p4y, fn.reflect, p6y, p5y)

-- first and last points move their control point
link(p1x, p2x, fn.add, p2x, dv)
link(p1y, p2y, fn.add, p2y, dv)

link(p3x, p2x, fn.add, p2x, dv)
link(p3y, p2y, fn.add, p2y, dv)

link(p3x, p4x, fn.add, p4x, dv)
link(p3y, p4y, fn.add, p4y, dv)

link(p5x, p4x, fn.add, p4x, dv)
link(p5y, p4y, fn.add, p4y, dv)

link(p5x, p6x, fn.add, p6x, dv)
link(p5y, p6y, fn.add, p6y, dv)

link(p7x, p6x, fn.add, p6x, dv)
link(p7y, p6y, fn.add, p6y, dv)

pp(path)
--pp(deps)

local player = require'cairopanel_player'
local path_simplify = require'path_simplify'
local i = 0
function player:on_render(cr)
	i = i + 1
	cr:set_source_rgb(0,0,0)
	cr:paint()
	cr:identity_matrix()
	cr:set_line_width(1)
	cr:set_source_rgb(1,1,1)

	for i=1,#points,2 do
		local x, y = path[points[i]], path[points[i+1]]
		if self.is_dragging then
			if not self.dragging_point and self:dragging(x, y) then
				self.dragging_point = i
			end
		else
			self.dragging_point = nil
		end
		if self.dragging_point == i then
			update(points[i], self.mouse_x)
			update(points[i+1], self.mouse_y)
		end
	end
	for i=1,#points,2 do
		local x, y = path[points[i]], path[points[i+1]]
		cr:circle(x, y, 5)
		cr:stroke()
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
	cr:new_path()
	path_simplify(write, path)
	cr:stroke()

end
player:play()
