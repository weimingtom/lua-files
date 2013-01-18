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
	[C.JCS_GRAYSCALE]= 'g',
	[C.JCS_YCbCr]    = 'ycc',
	[C.JCS_CMYK]     = 'cmyk',
	[C.JCS_YCCK]     = 'ycck',
	[C.JCS_RGB]      = 'rgb',
	[C.JCS_EXT_RGB]  = 'rgb',
	[C.JCS_EXT_BGR]  = 'bgr',
	[C.JCS_EXT_RGBX] = 'rgbx',
	[C.JCS_EXT_BGRX] = 'bgrx',
	[C.JCS_EXT_XRGB] = 'xrgb',
	[C.JCS_EXT_XBGR] = 'xbgr',
	[C.JCS_EXT_RGBA] = 'rgba',
	[C.JCS_EXT_BGRA] = 'bgra',
	[C.JCS_EXT_ARGB] = 'argb',
	[C.JCS_EXT_ABGR] = 'abgr',
}

local color_spaces = glue.index(pixel_formats)

local conversions = { --all conversions that libjpeg implements (source = {dest1, ...}}
	ycc = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr', 'g'},
	g = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr'},
	ycck = {'cmyk'},
}

local function best_pixel_format(pixel, accept)
	if not accept or accept[pixel] then return pixel end --no preference or source accepted
	if conversions[pixel] then
		for _,pixel in ipairs(conversions[pixel]) do
			if accept[pixel] then return pixel end --convertible to the best accepted format
		end
		return conversions[pixel][1] --convertible to a format that bmpconv can use as input
	end
	return pixel --not convertible
end

local dct_methods = {
	accurate = C.JDCT_ISLOW,
	fast = C.JDCT_IFAST,
	float = C.JDCT_FLOAT,
}
local upsample_methods = {fast = 0, smooth = 1}
local smoothing_methods = {fuzzy = 1, blocky = 0}

local function callback_manager(mgr_ctype, callbacks) --create a callback manager and its destructor
	local mgr = ffi.new(mgr_ctype)
	local cbt = {}
	for k,f in pairs(callbacks) do
		if type(f) == 'function' then
			cbt[k] = ffi.cast(string.format('jpeg_%s_callback', k), f)
			mgr[k] = cbt[k]
		else
			mgr[k] = f
		end
	end
	local function free_mgr()
		for k,cb in pairs(cbt) do
			mgr[k] = nil
			cb:free()
		end
	end
	ffi.gc(mgr, free_mgr)
	return mgr, free_mgr
end

local function set_source(cinfo, finally, callbacks) --create a source manager and set it up
	local mgr, free_mgr = callback_manager('jpeg_source_mgr', callbacks)
	cinfo.src = mgr
	finally(function() --the finalizer needs to pin mgr or it gets collected
		cinfo.src = nil
		ffi.gc(mgr, nil)
		free_mgr()
	end)
end

local function set_cdata_source(cinfo, finally, data, size)
	local cb = {}
	cb.init_source = glue.pass
	cb.term_source = glue.pass
	cb.resync_to_restart = C.jpeg_resync_to_restart
	function cb.fill_input_buffer(cinfo) error'eof' end
	function cb.skip_input_data(cinfo, sz)
		cinfo.src.next_input_byte = cinfo.src.next_input_byte + sz
		cinfo.src.bytes_in_buffer = cinfo.src.bytes_in_buffer - sz
	end
	set_source(cinfo, finally, cb)
	cinfo.src.bytes_in_buffer = size
	cinfo.src.next_input_byte = data
end

local function set_string_source(cinfo, finally, s)
	set_cdata_source(cinfo, finally, ffi.cast('const uint8_t*', s), #s) --const prevents copying
end

local function set_cdata_reader_source(cinfo, finally, read)
	local cb = {}
	cb.init_source = glue.pass
	cb.term_source = glue.pass
	cb.resync_to_restart = C.jpeg_resync_to_restart
	local buf, sz --pin it so it doesn't get collected till next read
	function cb.fill_input_buffer(cinfo)
		buf, sz = read()
		assert(buf, 'eof')
		cinfo.src.bytes_in_buffer = sz
		cinfo.src.next_input_byte = buf
		return true
	end
	function cb.skip_input_data(cinfo, sz)
		if sz <= 0 then return end
		while sz > cinfo.src.bytes_in_buffer do
			sz = sz - cinfo.src.bytes_in_buffer
			cb.fill_input_buffer(cinfo)
		end
		cinfo.src.next_input_byte = cinfo.src.next_input_byte + sz
		cinfo.src.bytes_in_buffer = cinfo.src.bytes_in_buffer - sz
	end
	set_source(cinfo, finally, cb)
	cinfo.src.bytes_in_buffer = 0
	cinfo.src.next_input_byte = nil
end

local function set_string_reader_source(cinfo, finally, read)
	local s --pin it so it doesn't get collected till next read
	local function read_wrapper()
		s = read()
		return ffi.cast('const uint8_t*', s), #s --const prevents string copy
	end
	return set_cdata_reader_source(cinfo, finally, read_wrapper)
end

local function load(src, opt)
	return glue.fcall(function(finally)
		opt = opt or {}
		local cinfo = ffi.new'jpeg_decompress_struct'

		--setup error handling
		local jerr = ffi.new'jpeg_error_mgr'
		local err_cb = ffi.cast('jpeg_error_exit_callback', function(cinfo)
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

		--init state
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
			C.jpeg_stdio_src(cinfo, f)
		elseif src.string then
			set_string_source(cinfo, finally, src.string)
		elseif src.cdata then
			set_cdata_source(cinfo, finally, src.cdata, src.size)
		elseif src.cdata_source then
			set_cdata_reader_source(cinfo, finally, src.cdata_source)
		elseif src.string_source then
			set_string_reader_source(cinfo, finally, src.string_source)
		else
			error'invalid source: stream, path, string, cdata/size, cdata_source, string_source accepted'
		end

		--read header and get info
		C.jpeg_read_header(cinfo, 1)
		local img = {}
		img.image_w = cinfo.image_width
		img.image_h = cinfo.image_height
		img.image_pixel = assert(pixel_formats[tonumber(cinfo.jpeg_color_space)])
		assert(cinfo.num_components == #img.image_pixel)
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
		img.pixel = best_pixel_format(img.image_pixel, opt.accept)
		cinfo.out_color_space = assert(color_spaces[img.pixel])
		cinfo.output_components = #img.pixel
		cinfo.scale_num = opt.scale_num or 1
		cinfo.scale_denom = opt.scale_denom or 1
		local function setopt(k, dk, enum)
			if opt[k] then cinfo[dk] = glue.assert(enum[opt[k]], 'invalid %s %s', k, opt[k]) end
		end
		setopt('dct', 'dct_method', dct_methods)
		setopt('upsampling', 'do_fancy_upsampling', upsample_methods)
		setopt('smoothing', 'do_block_smoothing', smoothing_methods)
		cinfo.buffered_image = C.jpeg_has_multiple_scans(cinfo) and opt.render_scan and 1 or 0
		C.jpeg_start_decompress(cinfo)

		--get info about the output image
		img.w = cinfo.output_width
		img.h = cinfo.output_height
		img.stride = cinfo.output_width * cinfo.output_components
		if opt.accept and opt.accept.padded then
			img.stride = bmpconv.pad_stride(img.stride)
		end

		--allocate image and rows buffers
		img.size = img.h * img.stride
		img.data = ffi.new('uint8_t[?]', img.size)
		local rows = ffi.new('uint8_t*[?]', img.h)

		--arrange row pointers according to accepted orientation
		local bottom_up = opt.accept and opt.accept.bottom_up and not opt.accept.top_down
		if bottom_up then
			for i=0,img.h-1 do
				rows[img.h-1-i] = img.data + (i * img.stride)
			end
			img.orientation = 'bottom_up'
		else
			for i=0,img.h-1 do
				rows[i] = img.data + (i * img.stride)
			end
			img.orientation = 'top_down'
		end

		local function read_scanlines()
			img.scan = cinfo.output_scan_number
			while cinfo.output_scanline < img.h do
				local i = cinfo.output_scanline
				local n = math.min(img.h - i, cinfo.rec_outbuf_height)
				local actual = C.jpeg_read_scanlines(cinfo, rows + i, n)
				assert(actual == n)
				assert(cinfo.output_scanline == i + actual)
				if opt.update_lines then opt.update_lines(img) end
			end
		end

		if cinfo.buffered_image == 1 then --multiscan reading
			while C.jpeg_input_complete(cinfo) == 0 do
				if opt.have_data then
					while opt.have_data() do
						local ret = C.jpeg_consume_input(cinfo)
						assert(ret ~= C.JPEG_SUSPENDED)
						if ret == C.JPEG_REACHED_EOI then break end
					end
				end
				C.jpeg_start_output(cinfo, cinfo.input_scan_number)
				read_scanlines()
				img = bmpconv.convert_best(img, opt.accept)
				opt.render_scan(img)
				C.jpeg_finish_output(cinfo)
			end
		else
			read_scanlines()
			img = bmpconv.convert_best(img, opt.accept)
		end

		C.jpeg_finish_decompress(cinfo)
		return img --last scan
	end)
end

if not ... then require'libjpeg_test' end

return {
	load = load,
	C = C,
}

