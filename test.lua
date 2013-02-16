require'glue'

local path = {
	'move', 1, 1,
	'rel_curve', 2, 2, 3, 3, 4, 4,
	'rel_smooth_curve', 6, 6, 7, 7,
	'rel_quad_curve', 8, 8, 9, 9,
	'rel_smooth_quad_curve', 11, 11,
	'rel_smooth_quad_curve', 13, 13,
}

local function find(vv) for i,v in ipairs(path) do if v == vv then return i end end end
local c1x, c1y = find(1),find(1)+1
local c2x, c2y = find(2),find(2)+1
local c3x, c3y = find(3),find(3)+1
local c4x, c4y = find(4),find(4)+1
local c6x, c6y = find(6),find(6)+1
local c7x, c7y = find(7),find(7)+1
local c8x, c8y = find(8),find(8)+1
local c9x, c9y = find(9),find(9)+1
local c11x, c11y = find(11),find(11)+1
local c13x, c13y = find(13),find(13)+1

local funcs = {
	copy = function(t, i) return t[i] end,
	add = function(t, i, j) return t[i] + t[j] end,
	sub = function(t, i, j) return t[i] - t[j] end,
	reflect = function(t, xi, ci) return 2 * t[ci] - t[xi] end,
}

path.n = 0
local function new(v)
	path.n = path.n + 1
	path[-path.n] = v
	return -path.n
end

local p1x, p1y = new(path[c1x]), new(path[c1y])
local p2x, p2y = new(path[c1x] + path[c2x]), new(path[c1y] + path[c2y])

local deps = {}
local function link(k, k2, f, ...)
	deps[k] = deps[k] or {}
	deps[k][k2] = {f, ...}
end

link(p1x, c1x, funcs.copy, p1x)
link(p2x, c2x, funcs.sub, p2x, p1x)
pp(deps)
pp(path)

--new_link(p1x, p2x, function(t) t[p1x] + t[c2x] end)

local function update(k, v, touched)
	touched = touched or {}
	if touched[k] then return end
	data[k] = v
	touched[k] = true
	local t = reverse_deps[k]
	if not t then return end
	for i,k in ipairs(t) do
		update(k, setters[k](data), touched)
	end
end

