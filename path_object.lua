--2d path editing

local glue = require'glue'

local path = {}
local path_mt = {__index = path}

function path:new(t)
	return setmetatable(t or {}, path_mt)
end

function path:copy()
	return path:new(glue.update({}, self))
end

function path:append(...)
	return glue.append(self, ...)
end

function path:extend(...)
	return glue.extend(self, ...)
end

path.argc = {
	move = 2,
	rel_move = 2,
	close = 0,
	['break'] = 0,
	line = 2,
	rel_line = 2,
	hline = 1,
	rel_hline = 1,
	vline = 1,
	rel_vline = 1,
	curve = 6,
	rel_curve = 6,
	smooth_curve = 4,
	rel_smooth_curve = 4,
	quad_curve = 4,
	rel_quad_curve = 4,
	smooth_quad_curve = 2,
	rel_smooth_quad_curve = 2,
	arc = 5,
	rel_arc = 5,
	elliptical_arc = 7,
	rel_elliptical_arc = 7,
	text = 2,
	--shapes
	ellipse = 4,
	circle = 3,
	rect = 4,
	round_rect = 5,
	star = 7,
	rpoly = 4,
}

local function path_iter(self, i)
	if i > #self then return end
	if type(self[i]) == 'string'
end

function path:elements()
	local i = 1
	local s
	while i <= #self do
		if type(self[i]) == 'string' then --see if command changed
			s = self[i]; i = i + 1
		end
	end
end

function path:points() --iterate over (path-point) excluding control points
end

function path:control_points() --iterate over (control-point, anchor-point) pairs
end

function path:elements() --iterate over path elements (command, args, ...)
end

function path:hit_test(x, y) --return what's found: segment, point, ctrl point etc.
end

function path:move_point(pi, x, y)
end

function path:split_curve(ei, x, y)
end

function path:remove_point(pi)
end

function path:quad_to_cubic(ei)
end

function path:cubic_to_quad(ei)
end

function path:smooth_curve(ei)
end

function path:unsmooth_curve(ei)
end

function path:curve_to_line(ei)
end

function path:line_to_curve(ei)
end

function path:break_at_point(pi)
end

--pi1 must end a subpath and pi2 must start a sub-path; re-arrange path if points are not consecutive.
function path:join_points(pi1, pi2)
end

function path:simplify(ei)
end

function path:remove_point(pi) --merge beziers, merge lines, merge bezier with line
end

function path:transform(mt, ei) --transform an element or the whole path
end

