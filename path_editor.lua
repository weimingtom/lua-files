--2d path editing
local glue = require'glue'
local arc = require'path_arc'.arc
local path_state = require'path_state'
local path_math = require'path_math'

local editor = {}
local editor_mt = {__index = editor}

function editor:new(path)
	return setmetatable({path = path}, editor_mt)
end

function editor:insert(i, ...)
	error'NYI'
end

function editor:commands()
	return path_state.commands(self.path)
end

function editor:next_state(...)
	return path_state.next_state(self.path, ...)
end

function editor:command_indices()
	local t = {}
	for k in self.path:commands() do
		if k == i then break end
		t[#t+1] = k
	end
	return t
end

function editor:control_points(at, px, py)
	local path = self.path

	--remember path indices of compatible curve commands that precede smooth curve commands
	local prev = {}
	local cpx, cpy, spx, spy
	for i,s in self:commands() do
		local nexti, nexts = path_state.next_command(path, i)
		if nexts and nexts:match'smooth_(.-)curve$' and path[i]:match'curve$'
			and path[i]:match'quad_' == nexts:match'quad_' --quads smooth quads, cubics smooth cubics
		then
			prev[nexti] = {i, cpx, cpy}
		end
		cpx, cpy, spx, spy = self:next_state(i, cpx, cpy, spx, spy)
	end

	local points = {}
	local cpx, cpy, spx, spy

	local function setpoint(i,ofs,style)
		local x1, y1 = path[i+ofs+1], path[i+ofs+2]
		if at == #points + 1 then path[i+ofs+1], path[i+ofs+2] = px, py end
		local x2, y2 = path[i+ofs+1], path[i+ofs+2]
		glue.append(points, x2, y2, style or '')
		return x2 - x1, y2 - y1
	end

	local function setrelpoint(i,ofs,style)
		if at == #points + 1 then path[i+ofs+1], path[i+ofs+2] = px - cpx, py - cpy end
		glue.append(points, cpx + path[i+ofs+1], cpy + path[i+ofs+2], style or '')
	end

	local deltax, deltay = 0, 0

	local nexti, nexts
	local function checknextrel()
		if nexts == 'rel_hline' then
			path[nexti+1] = path[nexti+1] - deltax
		elseif nexts == 'rel_vline' then
			path[nexti+1] = path[nexti+1] - deltay
		elseif nexts:match'^rel_' then
			path[nexti+1], path[nexti+2] = path[nexti+1] - deltax, path[nexti+2] - deltay
		end
	end

	for i,s in self:commands() do

		nexti, nexts = path_state.next_command(path, i)

		if s == 'move' or s == 'line' then
			deltax, deltay = setpoint(i,0)
			checknextrel()
		elseif s == 'close' then
			checknextrel()
		elseif s == 'rel_move' or s == 'rel_line' then
			setrelpoint(i,0)
			checknextrel()
		elseif s == 'hline' then
			if at == #points + 1 then path[i+1] = px end
			glue.append(points, path[i+1], cpy, '')
		elseif s == 'rel_hline' then
			if at == #points + 1 then path[i+1] = px - cpx end
			glue.append(points, cpx + path[i+1], cpy, '')
		elseif s == 'vline' then
			if at == #points + 1 then path[i+1] = py end
			glue.append(points, cpx, path[i+1], '')
		elseif s == 'rel_vline' then
			if at == #points + 1 then path[i+1] = py - cpy end
			glue.append(points, cpx, cpy + path[i+1], '')
		elseif s == 'curve' then
			setpoint(i,0,'cp')
			path[i+1], path[i+2] = deltax + path[i+1], deltay + path[i+2]
			local x1, y1 = path[i+5], path[i+6]
			setpoint(i,4)
			local x2, y2 = path[i+5], path[i+6]
			setpoint(i,2,'cp')
			path[i+3], path[i+4] = path[i+3] + x2 - x1, path[i+4] + y2 - y1
		elseif s == 'rel_curve' then
			setrelpoint(i,0,'cp')
			setrelpoint(i,2,'cp')
			setrelpoint(i,4)
		elseif s == 'quad_curve' then
			setpoint(i,0,'cp')
			setpoint(i,2)
		elseif s == 'rel_quad_curve' then
			setrelpoint(i,0,'cp')
			setrelpoint(i,2)
		elseif s == 'smooth_curve' or s == 'rel_smooth_curve' then
			--our first control point is virtual: it actually adjusts the second control point of the previous curve
			if prev[i] then
				local pi, pcpx, pcpy = unpack(prev[i])
				local ps = path[pi]
				if at == #points + 1 then
					local x, y = path_math.reflect_point(px, py, cpx, cpy)
					--adjust the control point that we created for the last cp of the prev. curve
					points[#points-5], points[#points-4] = x, y
					--set the last cp of the prev. curve
					if ps:match'^rel_' then x, y = x - pcpx, y - pcpy end
					path[i-4], path[i-3] = x, y
				end
				local x, y = path[i-4], path[i-3]
				if ps:match'^rel_' then x, y = x + pcpx, y + pcpy end
				x, y = path_math.reflect_point(x, y, cpx, cpy)
				glue.append(points, x, y, '')
			end

			if s == 'smooth_curve' then
				setpoint(i,0,'cp')
				setpoint(i,2)
			else
				setrelpoint(i,0,'cp')
				setrelpoint(i,2)
			end
		elseif s == 'smooth_quad_curve' or s == 'rel_smooth_quad_curve' then
			--our first control point is virtual: it actually adjusts the control point of the last non-smooth curve
			--[[
			if prev[i] then
				if at == #points + 1 then
					local j = i
					local pti = #points
					local x, y = path_math.reflect_point(px, py, cpx, cpy)
					while prev[j] do
						local pi, pcpx, pcpy = unpack(prev[j])
						--adjust the control point that we created for the last cp of the prev. curve
						points[pti-5], points[pti-4] = x, y
						--set the last cp of the prev. non-smooth curve
						if not ps:match'smooth_' then
							if ps:match'^rel_' then x, y = x - pcpx, y - pcpy end
							path[j-4], path[j-3] = x, y
							break
						end
						pti = pti - 3
						px, py = path_math.reflect_point(x, y, pcpx, pcpy)
					end
				end
			end
			local x, y = path[i-4], path[i-3]
			if ps:match'^rel_' then x, y = x + pcpx, y + pcpy end
			x, y = path_math.reflect_point(x, y, cpx, cpy)
			glue.append(points, x, y, '')
			]]
			if s == 'smooth_quad_curve' then
				setpoint(i,0)
			else
				setrelpoint(i,0)
			end
		elseif s == 'arc' or s == 'rel_arc' then
			if s == 'arc' then
				setpoint(i,0)
			else
				setrelpoint(i,0)
			end
			local cx, cy = path[i+1], path[i+2]
			if s == 'rel_arc' then cx, cy = cpx + cx, cpy + cy end
			if at == #points + 1 then
				path[i+4] = math.deg(path_math.point_angle(cx, cy, px, py))
			elseif at == #points + 4 then
				path[i+5] = math.deg(path_math.point_angle(cx, cy, px, py)) - path[i+4]
			end
			local r, start_angle, sweep_angle = path[i+3], path[i+4], path[i+5]
			local segments = arc(cx, cy, r, r, math.rad(start_angle), math.rad(sweep_angle))
			local x0, y0 = segments[1], segments[2]
			local x1, y1 = segments[#segments-1], segments[#segments]
			glue.append(points, x0, y0, '')
			glue.append(points, x1, y1, '')
		elseif s == 'elliptical_arc' then
			setpoint(i,5)
		elseif s == 'rel_elliptical_arc' then
			setrelpoint(i,5)
		elseif s == 'text' then
			--TODO
		end
		cpx, cpy, spx, spy = self:next_state(i, cpx, cpy, spx, spy)
	end
	return points
end

function editor:hit_test(x, y) --return what's found: segment, point, ctrl point etc.
end

function editor:split_curve(ei, x, y)
end

function editor:remove_point(pi)
end

function editor:quad_to_cubic(ei)
end

function editor:cubic_to_quad(ei)
end

function editor:smooth_curve(ei)
end

function editor:cusp_curve(ei)
end

function editor:curve_to_line(ei)
end

function editor:line_to_curve(ei)
end

function editor:break_at_point(pi)
end

--pi1 must end a subpath and pi2 must start a sub-path; re-arrange path if points are not consecutive.
function editor:join_points(pi1, pi2)
end

function editor:simplify(ei)
end

function editor:remove_point(pi) --merge beziers, merge lines, merge bezier with line
end

function editor:transform(mt, ei) --transform an element or the whole path
end


if not ... then require'path_editor_demo' end

return editor
