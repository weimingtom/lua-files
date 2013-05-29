local glue = require'glue'
local ffi = require'ffi'
local pp = require'pp'
local ft = require'freetype'
local player = require'cairo_player'
local cairo = require'cairo'

local function inspect_face(face)
	local face_flag_names = {
		[ft.FT_FACE_FLAG_SCALABLE]            = 'SCALABLE',
		[ft.FT_FACE_FLAG_FIXED_SIZES]         = 'FIXED_SIZES',
		[ft.FT_FACE_FLAG_FIXED_WIDTH]         = 'FIXED_WIDTH',
		[ft.FT_FACE_FLAG_SFNT]                = 'SFNT',
		[ft.FT_FACE_FLAG_HORIZONTAL]          = 'HORIZONTAL',
		[ft.FT_FACE_FLAG_VERTICAL]            = 'VERTICAL',
		[ft.FT_FACE_FLAG_KERNING]             = 'KERNING',
		[ft.FT_FACE_FLAG_FAST_GLYPHS]         = 'FAST_GLYPHS',
		[ft.FT_FACE_FLAG_MULTIPLE_MASTERS]    = 'MULTIPLE_MASTERS',
		[ft.FT_FACE_FLAG_GLYPH_NAMES]         = 'GLYPH_NAMES',
		[ft.FT_FACE_FLAG_EXTERNAL_STREAM]     = 'EXTERNAL_STREAM',
		[ft.FT_FACE_FLAG_HINTER]              = 'HINTER',
		[ft.FT_FACE_FLAG_CID_KEYED]           = 'CID_KEYED',
		[ft.FT_FACE_FLAG_TRICKY]              = 'TRICKY',
	}

	local style_flag_names = {
		[ft.FT_STYLE_FLAG_ITALIC]  = 'ITALIC',
		[ft.FT_STYLE_FLAG_BOLD]    = 'BOLD',
	}

	local function flags(flags, flag_names)
		local s
		for k,v in pairs(flag_names) do
			s = bit.band(flags, k) ~= 0 and ((s and s..', ' or '')..v) or s
		end
		return s or ''
	end

	local function s4(i)
		i = tonumber(i)
		return
			string.char(bit.band(bit.rshift(i, 24), 255)) ..
			string.char(bit.band(bit.rshift(i, 16), 255)) ..
			string.char(bit.band(bit.rshift(i,  8), 255)) ..
			string.char(bit.band(bit.rshift(i,  0), 255))
	end

	local function pad(s, n)
		return s..(' '):rep(n - #s)
	end

	local function struct(t,fields,decoders,indent)
		indent = indent or ''
		local s = ''
		for i,k in ipairs(fields) do
			s = s .. '\n   ' .. indent .. pad(k..':', 21 - #indent) .. (decoders and decoders[k] or glue.pass)(t[k])
		end
		return s
	end

	local function struct_array(t,n,fields,decoders,indent)
		indent = indent or ''
		local s = ''
		for i=0,n-1 do
			for j,k in ipairs(fields) do
				s = s .. '\n ' .. (j == 1 and '* ' or '  ') .. indent .. pad(k..':', 21 - #indent) ..
						(decoders and decoders[k] or glue.pass)(t[i][k])
			end
		end
		return s
	end

	local bitmap_size_fields = {'height','width','size','x_ppem','y_ppem'}
	local charmap_fields = {'encoding','platform_id','encoding_id'}
	local charmap_decoders = {encoding = s4}
	local bbox_fields = {'xMin','yMin','xMax','yMax'}
	local metrics_fields = {'x_ppem','y_ppem','x_scale','y_scale','ascender','descender','height','max_advance'}
	local size_fields = {'metrics'}
	local size_decoders = {metrics = function(m) return struct(m, metrics_fields, nil, '   ') end}
	print('num_faces:           ', face.num_faces)
	print('face_index:          ', face.face_index)
	print('face_flags:          ', flags(face.face_flags, face_flag_names))
	print('style_flags:         ', flags(face.style_flags, style_flag_names))
	print('num_glyphs:          ', face.num_glyphs)
	print('familiy_name:        ', ffi.string(face.family_name))
	print('style_name:          ', ffi.string(face.style_name))
	print('num_fixed_sizes:     ', face.num_fixed_sizes)
	print('available_sizes:     ', struct_array(face.available_sizes, face.num_fixed_sizes, bitmap_size_fields))
	print('num_charmaps:        ', face.num_charmaps)
	print('charmaps:            ', struct_array(face.charmaps, face.num_charmaps, charmap_fields, charmap_decoders))
	print('bbox:                ', struct(face.bbox, bbox_fields))
	print('units_per_EM:        ', face.units_per_EM)
	print('ascender:            ', face.ascender)
	print('descender:           ', face.descender)
	print('height:              ', face.height)
	print('max_advance_width:   ', face.max_advance_width)
	print('max_advance_height:  ', face.max_advance_height)
	print('underline_position:  ', face.underline_position)
	print('underline_thickness: ', face.underline_thickness)
	print('size:                ', struct(face.size, size_fields, size_decoders))
	print('charmap:             ', struct(face.charmap, charmap_fields, charmap_decoders))

	face:set_pixel_sizes(16)
	for i=0,face.num_charmaps-1 do
		face:select_charmap(face.charmaps[i].encoding)
		local n = 0
		for _ in face:chars() do
			n = n + 1
		end
		print(string.format('charmap %d:              %d\tentries', i, n))
	end
end

local function draw_charmap(cr,
	face, size, space,
	x0, y0, --charmap upper left coords
	bx1, by1, bx2, by2, --charmap screen bounding box
	i0, i1 --glyph index range
	)

	face:set_pixel_sizes(size)

	local i = 1
	local ii = 1
	for char, glyph in face:chars() do

		local x = x0 + (ii - 1) * (size + space)
		local y = y0

		if not i0 or i >= i0 and i <= i1 then

			if not bx1 or (x >= bx1 and x <= bx2 and y >= by1 and y <= by2) then

				face:load_glyph(glyph)

				face.glyph:render()
				assert(face.glyph.format == ft.FT_GLYPH_FORMAT_BITMAP)

				local bitmap = face.glyph.bitmap
				assert(bitmap.pixel_mode == ft.FT_PIXEL_MODE_GRAY)

				if bitmap.width > 0 and bitmap.rows > 0 then

					if bitmap.pitch % 4 ~= 0 then
						bitmap = face.glyph.library:new_bitmap()
						face.glyph.library:convert_bitmap(face.glyph.bitmap, bitmap, 4)
						assert(bitmap.pixel_mode == ft.FT_PIXEL_MODE_GRAY)
						assert(bitmap.pitch % 4 == 0)
					end

					local image = cairo.cairo_image_surface_create_for_data(
						bitmap.buffer,
						cairo.CAIRO_FORMAT_A8,
						face.glyph.bitmap.width,
						face.glyph.bitmap.rows,
						cairo.cairo_format_stride_for_width(cairo.CAIRO_FORMAT_A8, face.glyph.bitmap.width))

					x = x + face.glyph.bitmap_left
					y = y - face.glyph.bitmap_top
					cr:set_source_rgba(1, 1, 1, 1)
					cr:mask_surface(image, x, y)

					if face.glyph.bitmap ~= bitmap then
						face.glyph.library:free_bitmap(bitmap)
					end

					image:free()

				end

			end

			ii = ii + 1
		end

		i = i + 1
	end
end

local lib = ft:new()

--local face = lib:new_face'media/fonts/DejaVuSerif.ttf'
--local face = lib:new_face'media/fonts/amiri-regular.ttf'
local face = lib:new_face'media/fonts/fireflysung.ttf'
inspect_face(face)

local bi = 0
local msel = 1
function player:on_render(cr)
	cr:set_source_rgba(0,0,0,1)
	cr:paint()

	face:select_charmap(face.charmaps[msel-1].encoding)

	local n = 0; for _ in face:chars() do n = n + 1 end
	local charsize, charspace = 64, 24
	local linesize = 400
	local size = linesize * (charsize + charspace)
	local w = self.window.client_w
	local h = self.window.client_h

	bi = self:hscrollbar{x = 0, y = h - 40, w = w, h = 40, size = size, i = bi, autohide = true}
	local j = charsize + charspace
	for i=1,n,linesize do
		draw_charmap(cr, face, charsize, charspace, -bi, j, -charsize, 0, w, h, i, i + linesize - 1)
		j = j + charsize + charspace
	end

	local buttons = {}
	for i=1,face.num_charmaps do
		buttons[i] = 'Charmap '..i
	end
	msel = self:mbutton{id = 'charmap_btn', x = 10, y = 10, w = face.num_charmaps * 80, h = 22, buttons = buttons, selected = msel}
end

player:play()

face:free()

lib:free()
