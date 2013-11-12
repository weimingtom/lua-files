local scene = {
	type = 'group',
	{type = 'color', 1, 1, 1},
	{type = 'image', file =
		{path = 'media/jpeg/progressive.jpg'}
		--{path = 'media/jpeg/autumn-wallpaper.jpg'}
	},
}

local boxblur = require'im_boxblur'.blur_8888
local boxblur_lua = require'im_boxblur_lua'.blur_8888
local stackblur = require'im_stackblur'.blur_8888
local ffi = require'ffi'

--TODO: make this demo based on cplayer and load the image using imagefile.
--eventually, extend cairo to support loading images through the imagefile API.
local player = require'sg_cplayer'
local unit = require'unit'

local imgcopy

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
		--stackblur(img.data, img.w, img.h, radius)
		boxblur(img.data, img.w, img.h, radius)
		--boxblur_lua(img.data, img.w, img.h, radius)
	end
end

player:play()
