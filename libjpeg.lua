--libjpeg binding
local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue' --fcall, index, pass
local stdio = require'stdio' --fopen
local jit = require'jit' --off
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

--all conversions that libjpeg implements, in order of preference. {source = {dest1, ...}}.
local conversions = {
	ycc = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr', 'g'},
	g = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr'},
	ycck = {'cmyk'},
}

--easiest conversions that libjpeg implements to a format that bmpconv can use as input.
local fallback_conversions = {
	ycc = 'rgb',
	g = 'g',
	ycck = 'cmyk',
}

local function best_pixel_format(pixel, accept)
	if not accept or accept[pixel] then return pixel end --no preference or source format accepted
	if conversions[pixel] then
		for _,pixel in ipairs(conversions[pixel]) do
			if accept[pixel] then return pixel end --convertible to the best accepted format
		end
		return fallback_conversions[pixel] --easiest supported conversion to a format that bmpconv can use as input
	end
	return pixel --not convertible
end

--create a callback manager object and its destructor.
local function callback_manager(mgr_ctype, callbacks)
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
		ffi.gc(mgr, nil)
		for k,cb in pairs(cbt) do
			mgr[k] = nil
			cb:free()
		end
	end
	ffi.gc(mgr, free_mgr)
	return mgr, free_mgr
end

--end-of-image marker, inserted on EOF for partial display of broken images.
local JPEG_EOI = string.char(0xff, 0xD9):rep(32)

local function set_source(cinfo, finally, partial_loading, img, read)
	partial_loading = partial_loading == nil or partial_loading

	local cb = {}
	cb.init_source = glue.pass
	cb.term_source = glue.pass
	cb.resync_to_restart = C.jpeg_resync_to_restart

	local s, buf, sz --these must be upvalues so they don't get collected between calls
	function cb.fill_input_buffer(cinfo)
		buf, sz = read(); s = buf
		if not buf then
			if partial_loading then
				buf = JPEG_EOI
				s = JPEG_EOI
				img.partial = true
			else
				assert(buf, 'eof')
			end
		end
		if type(buf) == 'string' then
			buf, sz = ffi.cast('const uint8_t*', s), #s --const prevents string copy
		end
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

	--create a source manager and set it up
	local mgr, free_mgr = callback_manager('jpeg_source_mgr', cb)
	cinfo.src = mgr
	finally(function() --the finalizer needs to pin mgr or it gets collected
		cinfo.src = nil
		free_mgr()
	end)

	cinfo.src.bytes_in_buffer = 0
	cinfo.src.next_input_byte = nil
end

local function one_shot_reader(data, size)
	local done
	return function()
		if done then return end
		done = true
		return data, size
	end
end

local dct_methods = {
	accurate = C.JDCT_ISLOW,
	fast = C.JDCT_IFAST,
	float = C.JDCT_FLOAT,
}

local function load(t)
	assert(t, 'args missing')
	return glue.fcall(function(finally)
		local cinfo = ffi.new'jpeg_decompress_struct'
		local img = {}

		--setup error handling
		local jerr = ffi.new'jpeg_error_mgr'
		C.jpeg_std_error(jerr)
		local err_cb = ffi.cast('jpeg_error_exit_callback', function(cinfo)
			local buf = ffi.new'uint8_t[512]'
			cinfo.err.format_message(cinfo, buf)
			error(string.format('libjpeg error: %s', ffi.string(buf)))
		end)
		local warnbuf --cache this buffer because there are a ton of messages
		local emit_cb = ffi.cast('jpeg_emit_message_callback', function(cinfo, level)
			if t.warning then
				warnbuf = warnbuf or ffi.new'uint8_t[512]'
				cinfo.err.format_message(cinfo, warnbuf)
				t.warning(ffi.string(warnbuf), level)
			end
		end)
		finally(function()
			C.jpeg_std_error(jerr)
			err_cb:free()
			emit_cb:free()
		end)
		jerr.error_exit = err_cb
		jerr.emit_message = emit_cb
		cinfo.err = jerr

		--init state
		C.jpeg_CreateDecompress(cinfo, LIBJPEG_VERSION, ffi.sizeof(cinfo))
		finally(function() C.jpeg_destroy_decompress(cinfo) end)

		--setup source
		if t.stream then
			C.jpeg_stdio_src(cinfo, t.stream)
		elseif t.path then
			local f = stdio.fopen(t.path, 'rb')
			finally(function()
				C.jpeg_stdio_src(cinfo, nil)
				f:close()
			end)
			C.jpeg_stdio_src(cinfo, f)
		elseif t.string then
			set_source(cinfo, finally, t.partial_loading, img, one_shot_reader(t.string))
		elseif t.cdata then
			set_source(cinfo, finally, t.partial_loading, img, one_shot_reader(t.cdata, t.size))
		elseif t.read then
			set_source(cinfo, finally, t.partial_loading, img, t.read)
		else
			error'invalid source: stream, path, string, cdata/size, cdata_source, string_source expected'
		end

		--read header and get info
		assert(C.jpeg_read_header(cinfo, 1) ~= 0, 'eof')
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

		if not t.header_only then

			--find the best accepted output pixel format
			img.pixel = best_pixel_format(img.image_pixel, t.accept)

			--set decompression options
			cinfo.out_color_space = assert(color_spaces[img.pixel])
			cinfo.output_components = #img.pixel
			cinfo.scale_num = t.scale_num or 1
			cinfo.scale_denom = t.scale_denom or 1
			cinfo.dct_method = assert(dct_methods[t.dct_method or 'accurate'], 'invalid dct_method')
			cinfo.do_fancy_upsampling = t.fancy_upsampling or false
			cinfo.do_block_smoothing = t.block_smoothing or false
			cinfo.buffered_image = C.jpeg_has_multiple_scans(cinfo) and t.render_scan and 1 or 0

			--decompress image
			C.jpeg_start_decompress(cinfo)

			--get info about the output image
			img.w = cinfo.output_width
			img.h = cinfo.output_height
			img.stride = cinfo.output_width * cinfo.output_components
			if t.accept and t.accept.padded then
				img.stride = bit.band(img.stride + 3, bit.bnot(3)) --bmpconv.pad_stride()
			end

			--allocate image and rows buffers
			img.size = img.h * img.stride
			img.data = ffi.new('uint8_t[?]', img.size)
			local rows = ffi.new('uint8_t*[?]', img.h)

			--arrange row pointers according to accepted orientation
			local bottom_up = t.accept and t.accept.bottom_up and not t.accept.top_down
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

			local function read_scan()
				img.scan = cinfo.output_scan_number
				while cinfo.output_scanline < img.h do
					local i = cinfo.output_scanline
					local n = math.min(img.h - i, cinfo.rec_outbuf_height)
					local actual = C.jpeg_read_scanlines(cinfo, rows + i, n)
					assert(actual == n)
					assert(cinfo.output_scanline == i + actual)
					if t.update_lines then t.update_lines(img) end
				end
				if t.accept and not t.accept[img.pixel] then
					local bmpconv = require'bmpconv'
					img = bmpconv.convert_best(img, t.accept)
				end
				if t.render_scan then
					t.render_scan(img)
				end
			end

			if cinfo.buffered_image == 1 then --multiscan reading
				while C.jpeg_input_complete(cinfo) == 0 do
					repeat
						local ret = C.jpeg_consume_input(cinfo)
						assert(ret ~= C.JPEG_SUSPENDED)
					until ret == C.JPEG_REACHED_EOI or ret == C.JPEG_SCAN_COMPLETED
					C.jpeg_start_output(cinfo, cinfo.input_scan_number)
					read_scan()
					C.jpeg_finish_output(cinfo)
				end
			else
				read_scan()
			end

			C.jpeg_finish_decompress(cinfo)
		end

		return img
	end)
end

jit.off(load, true) --can't call error() from callbacks called from C

if not ... then require'libjpeg_demo' end

return {
	load = load,
	C = C,
}

