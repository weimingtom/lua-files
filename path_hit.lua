local glue = require'glue'
local line_hit = require'path_line'.hit
local arc_hit = require'path_arc'.hit
local bezier2_hit = require'path_bezier2_hit'
local bezier3_hit = require'path_bezier3_hit'

local function path_hit(x0, y0, path)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in path_commands(path) do
		if s == 'move' or s == 'rel_move' then
		else
		end
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(path, i, cpx, cpy, spx, spy, bx, by, qx, qy)
	end
end

if not ... then require'path_hit_demo' end

return {
	hit = path_hit,
}

