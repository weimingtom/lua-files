local scene = {
	type = 'group', x = 100, y = 100,
	{type = 'color', 0,0,0,1},
	{type = 'group', x = 200, cx = 300, cy = 300, angle = -15, scale = .5, skew_x = 0,
		{type = 'shape', path = {'rect', 0, 0, 100, 100}, fill = {type = 'color', 1,1,1,1}},
		{type = 'shape', y = 210, path = {'rect', 0, 0, 100, 100}, line_width = 50, stroke = {type = 'color', 1,1,1,1}},
		{type = 'image', angle = -30, y = 360, x = 100, file = {path = 'media/jpeg/testorig.jpg'}},
	},
}

local function box2rect(x1,y1,x2,y2)
	return x1,y1,x2-x1,y2-y1
end

local player = require'sg_cairo_player'
local ffi = require'ffi'
local cairo = require'cairo'
local r = 0
function player:on_render()
	r = r + .2
	scene[2].angle = r
	player:render(scene)
	player:render{type = 'shape', path = {'rect', box2rect(self.scene_graph:measure(scene))},
						stroke = {type='color',1,1,1,.2}, line_width = 10}
	--[=[
	local cr = self.scene_graph.cr
	cr:identity_matrix()
	cr:translate(100,100)
	cr:rotate(math.pi/4)
	cr:new_path()
	--cr:arc(0, 0, 50, 0, math.pi*2)
	cr:rectangle(0,0,100,100)
	local path = cr:copy_path_flat()
	local i = 0
	while true do
		local len = path.data[i].header.length
		print(path.data[i].header.type)
		for j=1,len-1 do
 			print(path.data[i+j].point.x, path.data[i+j].point.y)
		end
		i = i + len
		if i >= path.num_data then break end
	end
	local dx1,dy1,dx2,dy2 = ffi.new'double[1]',ffi.new'double[1]',ffi.new'double[1]',ffi.new'double[1]'
	cr:set_source_rgba(1,1,1,1)
	print(cr:get_matrix())
	local x1,y1 = cr:user_to_device(0,0)
	local x2,y2 = cr:user_to_device(100,0)
	local x3,y3 = cr:user_to_device(100,100)
	local x4,y4 = cr:user_to_device(0,100)
	cr:stroke_preserve()
	--cr:identity_matrix()
	cairo.lib.cairo_path_extents(cr,dx1,dy1,dx2,dy2)
	print(cairo.cairo_version_string(),dx1[0],dy1[0],dx2[0],dy2[0])

	--cr:identity_matrix()
	cr:rotate(-math.pi/4)
	cr:new_path()
	cr:rectangle(dx1[0],dy1[0],dx2[0]-dx1[0],dy2[0]-dy1[0])
	--[[
	cr:new_path()
	cr:move_to(x1,y1)
	cr:line_to(x2,y2)
	cr:line_to(x3,y3)
	cr:line_to(x4,y4)
	cr:close_path()
	]]
	cr:stroke()
	]=]
end
player:play()

