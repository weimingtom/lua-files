local scene = {
	type = 'group',
	{type = 'color', 1, 1, 1},
	{type = 'image', file = {path = 'media/jpeg/progressive.jpg'}},
}

local blur = require'boxblur'
local ffi = require'ffi'

local player = require'sg_cairo_player'
local blurred = 0
function player:on_render()
	self:render(scene)
	local img = self.scene_graph.cache:get(scene[2].file)
	--print(img.w, img.h, img.w * img.h * 4, ffi.sizeof(img.data))
	if blurred < 3 then
		blur({
			data = img.data,
			size = img.w * img.h * 4,
			stride = img.w * 4,
			w = img.w,
			h = img.h,
		}, 3)
		blurred = blurred + 1
	end
end
player:play()
