local glue = require'glue'
local path_state = require'path_state'
local arc_to_bezier3 = require'path_arc'.arc_to_bezier3
local arc_endpoints = require'path_arc'.arc_endpoints
local svgarc_to_elliptic_arc = require'path_svgarc'.svgarc_to_elliptic_arc

--
local function snapper()
	local function add_segment(x1, y1, x2, y2)

	end

	--local function add_

	local function snap_point(x, y)
		return x, y
	end

	return {
		snap_point = snap_point,
	}
end

return snapper
