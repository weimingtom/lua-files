--go@ luajit.exe -e "io.stdout:setvbuf'no'" -jv *
local ffi = require'ffi'
stackblur = require'im_stackblur'
boxblur = require'im_boxblur'
require'unit'

local function benchmark(blurname, w, h, n)
	local size = w * h * 4
	local img = ffi.new('uint8_t[?]', size)
	local imgcopy = ffi.new('uint8_t[?]', size)
	timediff()
	for i=1,n do
		ffi.copy(img, imgcopy, size)
		_G[blurname]({
			data = img,
			size = size,
			stride = w * 4,
			w = w,
			h = h,
		}, i % 50)
	end
	print(string.format('%s  \tfps @ %dx%d:  ', blurname, w, h), fps(n))
end

benchmark('stackblur', 1920, 1080, 5)
benchmark('stackblur', 800, 450, 20)
benchmark('stackblur', 320, 200, 80)
benchmark('boxblur', 1920, 1080, 10)
benchmark('boxblur', 800, 450, 60)
benchmark('boxblur', 320, 200, 400)
