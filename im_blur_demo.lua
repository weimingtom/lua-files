local scene = {
	type = 'group',
	{type = 'color', 1, 1, 1},
	{type = 'image', file =
		{path = 'media/jpeg/progressive.jpg'}
		--{path = 'media/jpeg/autumn-wallpaper.jpg'}
	},
}

local boxblur = require'im_boxblur'
local stackblur = require'im_stackblur'
local ffi = require'ffi'

local player = require'sg_cairo_player'
local unit = require'unit'

local imgcopy

ffi.cdef[[
void box_blur_argb32(uint8_t* pix, int w, int h, int radius);
]]
local box_blur_argb32 = ffi.load'boxblur'.box_blur_argb32

function player:on_render()
	self:render(scene)
	local img = self.scene_graph.cache:get(scene[2].file)
	local size = img.w * img.h * 4
	if not imgcopy then
		imgcopy = ffi.new('uint8_t[?]', size)
		ffi.copy(imgcopy, img.data, size)
	end
	ffi.copy(img.data, imgcopy, size)
	local radius = math.floor((self.scene_graph.mouse_x or 1) / 10)+1
	for i=1,2 do
		--[[
		stackblur({
			data = img.data,
			size = size,
			stride = img.w * 4,
			w = img.w,
			h = img.h,--math.floor(img.h / 4),
		}, radius)
		]]
		box_blur_argb32(img.data, img.w, img.h, radius)
	end
end

player:play()
