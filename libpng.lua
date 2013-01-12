local ffi = require'ffi'
local glue = require'glue'
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

local pixel_formats = {
	[C.PNG_COLOR_TYPE_GRAY] = 'g',
	[C.PNG_COLOR_TYPE_RGB] = 'rgb',
	[C.PNG_COLOR_TYPE_RGB_ALPHA] = 'rgba',
	[C.PNG_COLOR_TYPE_GRAY_ALPHA] = 'ga',
}

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
		local warnings = {}
		local warning_cb = ffi.cast('png_error_ptr', function(png_ptr, err)
			warnings[#warnings+1] = ffi.string(err)
		end)
		local error_cb = ffi.cast('png_error_ptr', function(png_ptr, err)
			error(string.format('libpng error: %s', ffi.string(err)))
		end)
		finally(function()
			C.png_set_error_fn(png_ptr, nil, nil, nil)
			error_cb:free()
			warning_cb:free()
		end)
		C.png_set_error_fn(png_ptr, nil, error_cb, warning_cb)

		--setup input source
		if datatype == 'string' or datatype == 'cdata' then
			local reader = datatype == 'string' and string_reader(data) or cdata_reader(data, size)
			local read_cb = ffi.cast('png_rw_ptr', reader)
			finally(function()
				C.png_set_read_fn(png_ptr, nil, nil)
				read_cb:free()
			end)
			C.png_set_read_fn(png_ptr, nil, read_cb)
		elseif datatype == 'path' then
			require'stdio' --because using Lua file handles crashes libpng
			local f = ffi.C.fopen(data, 'rb')
			assert(f ~= nil, string.format('Could not open file %s', data))
			finally(function()
				C.png_init_io(png_ptr, nil)
				ffi.C.fclose(f)
			end)
			C.png_init_io(png_ptr, f)
		else
			error'missing data source'
		end

		--read header
		C.png_read_info(png_ptr, info_ptr)

		--setup mandatory conversion options
		C.png_set_expand(png_ptr) --1,2,4bpp -> 8bpp, palette -> 8bpp, tRNS -> alpha
		C.png_set_scale_16(png_ptr) --16bpp -> 8bpp; since 1.5.4+
		C.png_set_interlace_handling(png_ptr) --deinterlace
		C.png_read_update_info(png_ptr, info_ptr)

		--get dimensions and pixel format information
		local w = C.png_get_image_width(png_ptr, info_ptr)
		local h = C.png_get_image_height(png_ptr, info_ptr)
		local color_type = C.png_get_color_type(png_ptr, info_ptr)
		color_type = bit.band(color_type, bit.bnot(C.PNG_COLOR_MASK_PALETTE))
		local paletted = bit.band(color_type, C.PNG_COLOR_MASK_PALETTE) == C.PNG_COLOR_MASK_PALETTE
		local pixel_format = assert(pixel_formats[color_type])
		local dest_pixel_format = pixel_format

		--request more conversions depending on pixel_format and the accept table
		if accept then
			local function strip_alpha(png_ptr)
				local my_background = ffi.new('png_color_16', 0, 0xff, 0xff, 0xff, 0xff)
				local image_background = ffi.new'png_color_16'
				local image_background_p = ffi.new('png_color_16p[1]', image_background)
				if C.png_get_bKGD(png_ptr, info_ptr, image_background_p) then
					C.png_set_background(png_ptr, image_background, C.PNG_BACKGROUND_GAMMA_FILE, 1, 1.0)
				else
					C.png_set_background(png_ptr, my_background, PNG_BACKGROUND_GAMMA_SCREEN, 0, 1.0)
				end
			end
			local function set_alpha(png_ptr)
				C.png_set_alpha_mode(png_ptr, C.PNG_ALPHA_OPTIMIZED, 2.2) --> premultiply alpha
			end
			if pixel_format == 'g' then
				if accept.g then
					--we're good
				elseif accept.ga then
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
					set_alpha(png_ptr)
					dest_pixel_format = 'ga'
				elseif accept.ag then
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_BEFORE)
					set_alpha(png_ptr)
					dest_pixel_format = 'ag'
				elseif accept.rgb then
					C.png_set_gray_to_rgb(png_ptr)
					dest_pixel_format = 'rgb'
				elseif accept.bgr then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_bgr(png_ptr)
					dest_pixel_format = 'bgr'
				elseif accept.rgba then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
					set_alpha(png_ptr)
					dest_pixel_format = 'rgba'
				elseif accept.argb then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_BEFORE)
					set_alpha(png_ptr)
					dest_pixel_format = 'argb'
				elseif accept.bgra then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_bgr(png_ptr)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
					set_alpha(png_ptr)
					dest_pixel_format = 'bgra'
				elseif accept.abgr then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_bgr(png_ptr)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_BEFORE)
					set_alpha(png_ptr)
					dest_pixel_format = 'abgr'
				end
			elseif pixel_format == 'ga' then
				if accept.ga then
					set_alpha(png_ptr)
				elseif accept.ag then
					C.png_set_swap_alpha(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'ag'
				elseif accept.rgba then
					C.png_set_gray_to_rgb(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'rgba'
				elseif accept.argb then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_swap_alpha(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'argb'
				elseif accept.bgra then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_bgr(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'bgra'
				elseif accept.abgr then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_bgr(png_ptr)
					C.png_set_swap_alpha(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'abgr'
				elseif accept.g then
					strip_alpha(png_ptr)
					dest_pixel_format = 'g'
				elseif accept.rgb then
					C.png_set_gray_to_rgb(png_ptr)
					strip_alpha(png_ptr)
					dest_pixel_format = 'rgb'
				elseif accept.bgr then
					C.png_set_gray_to_rgb(png_ptr)
					C.png_set_bgr(png_ptr)
					strip_alpha(png_ptr)
					dest_pixel_format = 'bgr'
				end
			elseif pixel_format == 'rgb' then
				if accept.rgb then
					--we're good
				elseif accept.bgr then
					C.png_set_bgr(png_ptr)
					dest_pixel_format = 'bgr'
				elseif accept.rgba then
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
					set_alpha(png_ptr)
					dest_pixel_format = 'rgba'
				elseif accept.argb then
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_BEFORE)
					set_alpha(png_ptr)
					dest_pixel_format = 'argb'
				elseif accept.bgra then
					C.png_set_bgr(png_ptr)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
					set_alpha(png_ptr)
					dest_pixel_format = 'bgra'
				elseif accept.abgr then
					C.png_set_bgr(png_ptr)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_BEFORE)
					set_alpha(png_ptr)
					dest_pixel_format = 'abgr'
				elseif accept.g then
					C.png_set_rgb_to_gray_fixed(png_ptr, 1, -1, -1)
					dest_pixel_format = 'g'
				elseif accept.ga then
					C.png_set_rgb_to_gray_fixed(png_ptr, 1, -1, -1)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_AFTER)
					dest_pixel_format = 'ga'
				elseif accept.ag then
					C.png_set_rgb_to_gray_fixed(png_ptr, 1, -1, -1)
					C.png_set_add_alpha(png_ptr, 0xff, C.PNG_FILLER_BEFORE)
					dest_pixel_format = 'ag'
				end
			elseif pixel_format == 'rgba' then
				if accept.rgba then
					set_alpha(png_ptr)
				elseif accept.argb then
					C.png_set_swap_alpha(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'argb'
				elseif accept.bgra then
					C.png_set_bgr(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'bgra'
				elseif accept.abgr then
					C.png_set_bgr(png_ptr)
					C.png_set_swap_alpha(png_ptr)
					set_alpha(png_ptr)
					dest_pixel_format = 'abgr'
				elseif accept.rgb then
					strip_alpha(png_ptr)
					dest_pixel_format = 'rgb'
				elseif accept.bgr then
					C.png_set_bgr(png_ptr)
					strip_alpha(png_ptr)
					dest_pixel_format = 'bgr'
				elseif accept.ga then
					C.png_set_rgb_to_gray_fixed(png_ptr, 1, -1, -1)
					dest_pixel_format = 'ga'
				elseif accept.ag then
					C.png_set_rgb_to_gray_fixed(png_ptr, 1, -1, -1)
					C.png_set_swap_alpha(png_ptr)
					dest_pixel_format = 'ag'
				elseif accept.g then
					C.png_set_rgb_to_gray_fixed(png_ptr, 1, -1, -1)
					strip_alpha(png_ptr)
					dest_pixel_format = 'g'
				end
			else
				assert(false)
			end
			C.png_read_update_info(png_ptr, info_ptr) --calling this twice is libpng 1.5.6+
		end

		--check if conversion options had the desired effect
		assert(C.png_get_bit_depth(png_ptr, info_ptr) == 8)

		local color_type = C.png_get_color_type(png_ptr, info_ptr)
		local actual_pixel_format = assert(pixel_formats[color_type])
		assert(#actual_pixel_format == #dest_pixel_format) --same number of channels

		local channels = C.png_get_channels(png_ptr, info_ptr)
		assert(channels == #actual_pixel_format) --each letter a channel

		local rowsize = w * channels
		assert(C.png_get_rowbytes(png_ptr, info_ptr) == rowsize)
		if accept and accept.padded then
			rowsize = bit.band(rowsize + 3, bit.bnot(3))
		end

		local row_format = 'top_down'
		if accept and accept.bottom_up and not accept.top_down then
			row_format = 'bottom_up'
		end

		--get the data bits
		local size = rowsize * h
		local data = ffi.new('uint8_t[?]', size)
		local rows_ptr = ffi.new('uint8_t*[?]', h)
		if row_format == 'bottom_up' then
			for i=0,h-1 do
				rows_ptr[h-1-i] = data + (rowsize * i)
			end
		else
			for i=0,h-1 do
				rows_ptr[i] = data + (rowsize * i)
			end
		end
		C.png_read_image(png_ptr, rows_ptr)
		C.png_read_end(png_ptr, info_ptr)

		return {
			w = w, h = h,
			data = data,
			size = size,
			format = {
				pixel = dest_pixel_format,
				rows = row_format,
				rowsize = rowsize,
			},
			warnings = warnings,
			file_format = pixel_format,
			paletted = paletted,
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
