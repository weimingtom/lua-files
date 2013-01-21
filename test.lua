--xgo@ x:\work\lua-files\bin\luajit.exe -e package.path='x:/work/lua-files/?.lua;x:/work/lua-files/?/init.lua';io.stdout:setvbuf'no';pp=require'pp'.pp -jannotate  "test.lua"
local scene = {
	type = 'group',
	{type = 'color', 1, 1, 1},
	{type = 'image', file = {path = 'media/jpeg/progressive.jpg'}},
}

local blur = require'im_boxblur'
local ffi = require'ffi'

local player = require'sg_cairo_player'
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
	timediff()
	ffi.copy(img.data, imgcopy, size)
	for i=1,3 do
		blur({
			data = img.data,
			size = size,
			stride = img.w * 4,
			w = img.w,
			h = img.h,--math.floor(img.h / 4),
		}, math.floor((self.scene_graph.mouse_x or 1) / 10)+1)
	end
	print(timediff())
end

player:play()
