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

