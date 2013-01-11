local ffi = require'ffi'
local glue = require'glue'
local bmpconv = require'bmpconv'
require'libpng_h'

local C = ffi.load'png'

local PNG_LIBPNG_VER_STRING = '1.5.10'

local function string_reader(data)
	local i = 1
	return function(_, buf, sz)
		if sz < 1 or #data < i then error'Reading past EOF' end
		local s = data:sub(i, i+sz-1)
		ffi.copy(buf, s, #s)
		i = i + #s
	end
end

local function cdata_reader(data, size)
	data = ffi.cast('unsigned char*', data)
	return function(_, buf, sz)
		if sz < 1 or size < 1 then error'Reading past EOF' end
		sz = math.min(size, sz)
		ffi.copy(buf, data, sz)
		data = data + sz
		size = size - sz
		return sz
	end
end

local function load_(datatype, data, size, accept)
	return glue.fcall(function(finally)

		--create the state objects
		local png_ptr = assert(C.png_create_read_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil))
		local info_ptr = assert(C.png_create_info_struct(png_ptr))
		finally(function()
			local png_ptr = ffi.new('png_structp[1]', png_ptr)
			local info_ptr = ffi.new('png_infop[1]', info_ptr)
			C.png_destroy_read_struct(png_ptr, info_ptr, nil)
		end)

		--setup error handling
		local error_cb = ffi.cast('png_error_ptr', function(png_ptr, err)
			error(string.format('libpng error %s', ffi.string(err[0])))
		end)
		finally(function() error_cb:free() end)
		C.png_set_error_fn(png_ptr, nil, error_cb, nil)

		--setup input source
		if datatype == 'string' or datatype == 'cdata' then
			local reader = datatype == 'string' and string_reader(data) or cdata_reader(data, size)
			local read_cb = ffi.cast('png_rw_ptr', reader)
			finally(function() read_cb:free() end)
			C.png_set_read_fn(png_ptr, nil, read_cb)
		elseif datatype == 'path' then
			require'stdio' --because using Lua file handles crashes libpng
			local f = ffi.C.fopen(data, 'rb')
			assert(f ~= nil, string.format('Could not open file %s', data))
			finally(function() ffi.C.fclose(f) end)
			C.png_init_io(png_ptr, f)
		else
			assert(false, 'missing data source')
		end

		--read header and get dimensions
		C.png_read_info(png_ptr, info_ptr)
		local w = C.png_get_image_width(png_ptr, info_ptr)
		local h = C.png_get_image_height(png_ptr, info_ptr)

		--setup conversion options to give us RGBA8888 every time
		C.png_set_gray_to_rgb(png_ptr) --grayscale to rgb
		C.png_set_expand(png_ptr) --upscale to 8bpp
		C.png_set_scale_16(png_ptr) --downscale to 8bpp; since 1.5.4+
		C.png_set_tRNS_to_alpha(png_ptr) --transparency -> alpha
		C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER) --RGB -> RGBA where A = 0xff
		C.png_set_alpha_mode(png_ptr, C.PNG_ALPHA_OPTIMIZED, 2.2) --> premultiply alpha (TODO: test this)
		C.png_set_interlace_handling(png_ptr) --deinterlace
		C.png_read_update_info(png_ptr, info_ptr)

		--check if conversion options had the desired effect
		assert(C.png_get_color_type(png_ptr, info_ptr) == C.PNG_COLOR_TYPE_RGB_ALPHA)
		assert(C.png_get_bit_depth(png_ptr, info_ptr) == 8)
		assert(C.png_get_channels(png_ptr, info_ptr) == 4)
		assert(C.png_get_rowbytes(png_ptr, info_ptr) == w * 4)

		--get the data bits
		local size = w * 4 * h
		local data = ffi.new('uint8_t[?]', size)
		local rows_ptr = ffi.new('uint8_t*[?]', h)
		for i=0,h-1 do rows_ptr[i] = data + (w * 4 * i) end
		C.png_read_image(png_ptr, rows_ptr)
		C.png_read_end(png_ptr, info_ptr)

		--perform additional conversions that libpng couldn't do itself
		local format = {pixel = 'rgba', rows = 'top_down', rowsize = w * 4}
		local data, size, format = bmpconv.convert_best(data, size, format, accept, false)

		return {
			w = w, h = h,
			data = data,
			size = size,
			format = format,
		}
	end)
end

local function load(t, opt)
	local accept = opt and opt.accept
	if t.string then
		return load_('string', t.string, nil, accept)
	elseif t.cdata then
		return load_('cdata', t.cdata, t.size, accept)
	elseif t.path then
		return load_('path', t.path, nil, accept)
	else
		error'unspecified data source: path, string or cdata expected'
	end
end

if not ... then require'libpng_test' end

return {
	load = load,
	C = C,
}
