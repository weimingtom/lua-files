local glue = require'glue'
local line_hit = require'path_line'.hit
local arc_hit = require'path_arc'.hit
local bezier2_hit = require'path_bezier2'.hit
local bezier3_hit = require'path_bezier3'.hit

local except = glue.index{'', 'arc'}

local function path_hit(x0, y0, path)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in path_commands(path) do
		if s == 'move' or s == 'rel_move' then

		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(path, i, cpx, cpy, spx, spy, bx, by, qx, qy)
	end
end

return {
	hit = path_hit,
}

