local ffi = require'ffi'
local glue = require'glue'
local bmpconv = require'bmpconv'
require'giflib_h'

local C = ffi.load'giflib5'

local function ptr(p) --convert NULL to nil
	return p ~= nil and p or nil
end

local function string_reader(data)
	local i = 1
	return function(_, buf, sz)
		if sz < 1 or #data < i then error'reading pass eof' end
		local s = data:sub(i, i+sz-1)
		ffi.copy(buf, s, #s)
		i = i + #s
		return #s
	end
end

local function cdata_reader(data, size)
	data = ffi.cast('unsigned char*', data)
	return function(_, buf, sz)
		if sz < 1 or size < 1 then error'reading pass eof' end
		sz = math.min(size, sz)
		ffi.copy(buf, data, sz)
		data = data + sz
		size = size - sz
		return sz
	end
end

local function reader_callback(reader)
	return ffi.cast('GifInputFunc', reader)
end

local function open_callback(cb, err)
	return C.DGifOpen(nil, cb, err)
end

local function open_fileno(fileno, err)
	return C.DGifOpenFileHandle(fileno, err)
end

local function open_file(filename, err)
	return C.DGifOpenFileName(filename, err)
end

local function open(opener, arg)
	local err = ffi.new'int[1]'
	local ft = ptr(opener(arg, err))
	if not ft then error(ffi.string(C.GifErrorString(err[0]))) end
	return ft
end

local function check(res, ft)
	if res == 0 then error(ffi.string(C.GifErrorString(ft.Error))) end
end

local function close(ft) --fugget about why it couldn't close, geez
	if C.DGifCloseFile(ft) == 0 then ffi.C.free(ft) end
end

local function parse(datatype, data, size, handle) --callback-based parser
	return glue.fcall(function(finally)
		local ft
		if datatype == 'string' then
			local cb = reader_callback(string_reader(data))
			finally(function() cb:free() end)
			ft = open(open_callback, cb)
		elseif datatype == 'cdata' then
			local cb = reader_callback(cdata_reader(data, size))
			finally(function() cb:free() end)
			ft = open(open_callback, cb)
		elseif datatype == 'path' then
			ft = open(open_file, data)
		elseif datatype == 'fileno' then
			ft = open(open_fileno, data)
		else
			error(string.format('Unknown data source type %s', tostring(datatype)))
		end
		finally(function() close(ft) end)
		check(C.DGifSlurp(ft), ft)
		return handle(ft)
	end)
end

local function decompress(datatype, data, size, opt)
	local mode = opt and opt.mode
	return parse(datatype, data, size, function(ft)
		local t = {frames = {}}
		t.w, t.h = ft.SWidth, ft.SHeight
		local c = ft.SColorMap.Colors[ft.SBackGroundColor]
		t.bg_color = {c.Red/255, c.Green/255, c.Blue/255}
		local gcb = ffi.new'GraphicsControlBlock'
		for i=0,ft.ImageCount-1 do
			local si = ft.SavedImages[i]

			--find delay and transparent color index, if any
			local delay, tcolor_idx
			if C.DGifSavedExtensionToGCB(ft, i, gcb) == 1 then
				delay = gcb.DelayTime * 10 --make it milliseconds
				tcolor_idx = gcb.TransparentColor
			end
			local w, h = si.ImageDesc.Width, si.ImageDesc.Height
			local colormap = si.ImageDesc.ColorMap ~= nil and si.ImageDesc.ColorMap or ft.SColorMap

			--convert image to RGBA8888
			local sz = w * h * 4
			local data = ffi.new('uint8_t[?]', sz)
			local di = 0
			for i=0, w * h-1 do
				local idx = si.RasterBits[i]
				assert(idx < colormap.ColorCount)
				if idx == tcolor_idx and mode ~= 'opaque' then
					data[di+0] = 0
					data[di+1] = 0
					data[di+2] = 0
					data[di+3] = 0
				else
					data[di+0] = colormap.Colors[idx].Red
					data[di+1] = colormap.Colors[idx].Green
					data[di+2] = colormap.Colors[idx].Blue
					data[di+3] = 0xff
				end
				di = di+4
			end

			local img = {
				data = data,
				size = sz,
				pixel = 'rgba',
				stride = w * 4,
				orientation = 'top_down',
				w = w,
				h = h,
				x = si.ImageDesc.Left,
				y = si.ImageDesc.Top,
				delay_ms = delay,
			}
			img = bmpconv.convert_best(img, opt and opt.accept)
			t.frames[#t.frames + 1] = img
		end
		return t
	end)
end

local function load(t, opt)
	if t.string then
		return decompress('string', t.string, nil, opt)
	elseif t.cdata then
		return decompress('cdata', t.cdata, t.size, opt)
	elseif t.path then
		return decompress('path', t.path, nil, opt)
	elseif t.fileno then
		return decompress('fileno', t.fileno, nil, opt)
	else
		error'unspecified data source: path, string, cdata or fileno expected'
	end
end

if not ... then require'giflib_test' end

return {
	load = load,
	C = C,
}
