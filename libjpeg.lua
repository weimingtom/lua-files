--libjpeg binding
local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
local stdio = require'stdio'
local bmpconv = require'bmpconv'
require'libjpeg_h'
local C = ffi.load'libjpeg'

local LIBJPEG_VERSION = 62

local pixel_formats = {
	[C.JCS_UNKNOWN]  = false,
	[C.JCS_GRAYSCALE]= 'g',
	[C.JCS_RGB]      = 'rgb',
	[C.JCS_YCbCr]    = 'ycbcr', --TODO: planar
	[C.JCS_CMYK]     = 'cmyk',
	[C.JCS_YCCK]     = 'ycck',
	[C.JCS_EXT_RGB]  = 'rgb',
	[C.JCS_EXT_RGBX] = 'rgbx',
	[C.JCS_EXT_BGR]  = 'bgr',
	[C.JCS_EXT_BGRX] = 'bgrx',
	[C.JCS_EXT_XBGR] = 'xbgr',
	[C.JCS_EXT_XRGB] = 'xrgb',
	[C.JCS_EXT_RGBA] = 'rgba',
	[C.JCS_EXT_BGRA] = 'bgra',
	[C.JCS_EXT_ABGR] = 'abgr',
	[C.JCS_EXT_ARGB] = 'argb',
}

local dct_methods = {
	accurate = C.JDCT_ISLOW,
	fast = C.JDCT_IFAST,
	float = C.JDCT_FLOAT,
}
local upsample_methods = {fast = 0, smooth = 1}
local smoothing_methods = {fuzzy = 1, blocky = 0}

local function load(src, opt)
	return glue.fcall(function(finally)
		opt = opt or {}
		local cinfo = ffi.new'jpeg_decompress_struct'

		--setup error handling
		local jerr = ffi.new'jpeg_error_mgr'
		local err_cb = ffi.cast('jpeg_error_exit', function(cinfo)
			local buf = ffi.new'uint8_t[512]'
			cinfo.err.format_message(cinfo, buf)
			error(string.format('libjpeg error: %s', ffi.string(buf)))
		end)
		finally(function()
			jerr.error_exit = nil
			C.jpeg_std_error(jerr)
			err_cb:free()
		end)
		jerr.error_exit = err_cb
		cinfo.err = C.jpeg_std_error(jerr)

		--init library
		C.jpeg_CreateDecompress(cinfo, LIBJPEG_VERSION, ffi.sizeof(cinfo))
		finally(function() C.jpeg_destroy_decompress(cinfo) end)

		--setup source
		if src.stream then
			C.jpeg_stdio_src(cinfo, src.stream)
		elseif src.path then
			local f = ffi.C.fopen(src.path, 'rb')
			glue.assert(f ~= nil, 'could not open file %s', src.path)
			finally(function()
				C.jpeg_stdio_src(cinfo, nil)
				ffi.C.fclose(f)
			end)
			C.jpeg_stdio_src(cinfo, src.stream)
		elseif src.string then
		elseif src.cdata then
		elseif src.cdata_source then
		elseif src.string_source then
		end

		--read header and get info
		C.jpeg_read_header(cinfo, 1)

		local img = {}
		img.image_w = cinfo.image_width
		img.image_h = cinfo.image_height

		local channels = cinfo.num_components
		img.image_pixel = assert(pixel_formats[tonumber(cinfo.jpeg_color_space)], 'unknown pixel format')

		img.jfif = cinfo.saw_JFIF_marker == 1 and {
			maj_ver = cinfo.JFIF_major_version,
			min_ver = cinfo.JFIF_minor_version,
			density_unit = cinfo.density_unit,
			x_density = cinfo.X_density,
			y_density = cinfo.Y_density,
		} or nil
		img.adobe = cinfo.saw_Adobe_marker == 1 and {
			transform = cinfo.Adobe_transform,
		} or nil

		--set decompression options
		--TODO: find out which conversions are supported by libjpeg
		cinfo.out_color_space = C.JCS_EXT_RGBA

		cinfo.scale_num = opt.scaling_numerator or 1
		cinfo.scale_denom = opt.scaling_denominator or 1

		local function setopt(k, dk, enum)
			if opt[k] then cinfo[dk] = glue.assert(enum[opt[k]], 'invalid %s %s', k, opt[k]) end
		end
		setopt('dct', 'dct_method', dct_methods)
		setopt('upsample', 'do_fancy_upsampling', upsample_methods)
		setopt('smoothing', 'do_block_smoothing', smoothing_methods)

		--set the options and get info about the output
		C.jpeg_start_decompress(cinfo)
		img.w = cinfo.output_width
		img.h = cinfo.output_height
		img.pixel = assert(pixel_formats[tonumber(cinfo.out_color_space)])
		img.stride = cinfo.output_width * cinfo.output_components
		if opt.accept and opt.accept.padded then
			img.stride = bmpconv.pad_stride(img.stride)
		end

		print(img.pixel, cinfo.output_components)

		--allocate a scanline buffer: if writeline is given, only allocate the recommended height
		local buf_h = opt.writeline and cinfo.rec_outbuf_height or img.h
		img.size = buf_h * img.stride
		img.data = ffi.new('uint8_t[?]', img.size)
		local rows_ptr = ffi.new('uint8_t*[?]', buf_h)
		local bottom_up = opt.accept and opt.accept.bottom_up and not opt.accept.top_down
		if bottom_up then
			assert(buf_h == img.h) --bottom_up only works with a full buffer
			for i=0,buf_h-1 do
				rows_ptr[h-1-i] = img.data + (img.stride * i)
			end
			img.orientation = 'bottom_up'
		else
			for i=0,buf_h-1 do
				rows_ptr[i] = img.data + (img.stride * i)
			end
			img.orientation = 'top_down'
		end

		--read the scanlines
		while cinfo.output_scanline < cinfo.output_height do
			C.jpeg_read_scanlines(cinfo, rows_ptr, buf_h)
			if opt.writeline then opt.writeline(buf, sz) end
		end

		C.jpeg_finish_decompress(cinfo)
		return bmpconv.convert_best(img, opt.accept)
	end)
end

if not ... then require'libjpeg_test' end

return {
	load = load,
	C = C,
}

