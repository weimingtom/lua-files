--[[ lightweight oop interface over freetype's ffi API:
		- wraps constructors, assigns destructors, error checking
]]

local glue = require'glue'
local ffi = require'ffi'
require'freetype_h'
local C = ffi.load'libfreetype-6'
local M = glue.inherit({C = C}, C)

--utilities

local Error_Names = glue.index{
	FT_Err_Ok = 0x00,
	FT_Err_Cannot_Open_Resource = 0x01,
	FT_Err_Unknown_File_Format = 0x02,
	FT_Err_Invalid_File_Format = 0x03,
	FT_Err_Invalid_Version = 0x04,
	FT_Err_Lower_Module_Version = 0x05,
	FT_Err_Invalid_Argument = 0x06,
	FT_Err_Unimplemented_Feature = 0x07,
	FT_Err_Invalid_Table = 0x08,
	FT_Err_Invalid_Offset = 0x09,
	FT_Err_Array_Too_Large = 0x0A,
	FT_Err_Invalid_Glyph_Index = 0x10,
	FT_Err_Invalid_Character_Code = 0x11,
	FT_Err_Invalid_Glyph_Format = 0x12,
	FT_Err_Cannot_Render_Glyph = 0x13,
	FT_Err_Invalid_Outline = 0x14,
	FT_Err_Invalid_Composite = 0x15,
	FT_Err_Too_Many_Hints = 0x16,
	FT_Err_Invalid_Pixel_Size = 0x17,
	FT_Err_Invalid_Handle = 0x20,
	FT_Err_Invalid_Library_Handle = 0x21,
	FT_Err_Invalid_Driver_Handle = 0x22,
	FT_Err_Invalid_Face_Handle = 0x23,
	FT_Err_Invalid_Size_Handle = 0x24,
	FT_Err_Invalid_Slot_Handle = 0x25,
	FT_Err_Invalid_CharMap_Handle = 0x26,
	FT_Err_Invalid_Cache_Handle = 0x27,
	FT_Err_Invalid_Stream_Handle = 0x28,
	FT_Err_Too_Many_Drivers = 0x30,
	FT_Err_Too_Many_Extensions = 0x31,
	FT_Err_Out_Of_Memory = 0x40,
	FT_Err_Unlisted_Object = 0x41,
	FT_Err_Cannot_Open_Stream = 0x51,
	FT_Err_Invalid_Stream_Seek = 0x52,
	FT_Err_Invalid_Stream_Skip = 0x53,
	FT_Err_Invalid_Stream_Read = 0x54,
	FT_Err_Invalid_Stream_Operation = 0x55,
	FT_Err_Invalid_Frame_Operation = 0x56,
	FT_Err_Nested_Frame_Access = 0x57,
	FT_Err_Invalid_Frame_Read = 0x58,
	FT_Err_Raster_Uninitialized = 0x60,
	FT_Err_Raster_Corrupted = 0x61,
	FT_Err_Raster_Overflow = 0x62,
	FT_Err_Raster_Negative_Height = 0x63,
	FT_Err_Too_Many_Caches = 0x70,
	FT_Err_Invalid_Opcode = 0x80,
	FT_Err_Too_Few_Arguments = 0x81,
	FT_Err_Stack_Overflow = 0x82,
	FT_Err_Code_Overflow = 0x83,
	FT_Err_Bad_Argument = 0x84,
	FT_Err_Divide_By_Zero = 0x85,
	FT_Err_Invalid_Reference = 0x86,
	FT_Err_Debug_OpCode = 0x87,
	FT_Err_ENDF_In_Exec_Stream = 0x88,
	FT_Err_Nested_DEFS = 0x89,
	FT_Err_Invalid_CodeRange = 0x8A,
	FT_Err_Execution_Too_Long = 0x8B,
	FT_Err_Too_Many_Function_Defs = 0x8C,
	FT_Err_Too_Many_Instruction_Defs = 0x8D,
	FT_Err_Table_Missing = 0x8E,
	FT_Err_Horiz_Header_Missing = 0x8F,
	FT_Err_Locations_Missing = 0x90,
	FT_Err_Name_Table_Missing = 0x91,
	FT_Err_CMap_Table_Missing = 0x92,
	FT_Err_Hmtx_Table_Missing = 0x93,
	FT_Err_Post_Table_Missing = 0x94,
	FT_Err_Invalid_Horiz_Metrics = 0x95,
	FT_Err_Invalid_CharMap_Format = 0x96,
	FT_Err_Invalid_PPem = 0x97,
	FT_Err_Invalid_Vert_Metrics = 0x98,
	FT_Err_Could_Not_Find_Context = 0x99,
	FT_Err_Invalid_Post_Table_Format = 0x9A,
	FT_Err_Invalid_Post_Table = 0x9B,
	FT_Err_Syntax_Error = 0xA0,
	FT_Err_Stack_Underflow = 0xA1,
	FT_Err_Ignore = 0xA2,
	FT_Err_No_Unicode_Glyph_Name = 0xA3,
	FT_Err_Missing_Startfont_Field = 0xB0,
	FT_Err_Missing_Font_Field = 0xB1,
	FT_Err_Missing_Size_Field = 0xB2,
	FT_Err_Missing_Fontboundingbox_Field = 0xB3,
	FT_Err_Missing_Chars_Field = 0xB4,
	FT_Err_Missing_Startchar_Field = 0xB5,
	FT_Err_Missing_Encoding_Field = 0xB6,
	FT_Err_Missing_Bbx_Field = 0xB7,
	FT_Err_Bbx_Too_Big = 0xB8,
	FT_Err_Corrupted_Font_Header = 0xB9,
	FT_Err_Corrupted_Font_Glyphs = 0xBA,
}

local function checknz(result)
	if result == 0 then return end
	error(string.format('freetype error %d: %s', result, Error_Names[result] or '<unknown error>'), 2)
end

local function nonzero(ret)
	return ret ~= 0 and ret or nil
end

--wrappers

function M.FT_Init_FreeType()
	local library = ffi.new'FT_Library[1]'
	checknz(C.FT_Init_FreeType(library))
	library = library[0]
	return ffi.gc(library, M.FT_Done_FreeType)
end

function M.FT_Done_FreeType(library)
	checknz(C.FT_Done_FreeType(library))
	ffi.gc(library, nil)
end

function M.FT_New_Face(library, filename, i)
	local face = ffi.new'FT_Face[1]'
	checknz(C.FT_New_Face(library, filename, i or 0, face))
	face = face[0]
	return ffi.gc(face, M.FT_Done_Face)
end

function M.FT_New_Memory_Face(library, file_base, file_size, face_index)
	local face = ffi.new'FT_Face[1]'
	checknz(C.FT_New_Memory_Face(library, file_base, file_size, face_index or 0, face))
	face = face[0]
	return ffi.gc(face, M.FT_Done_Face)
end

--TODO: construct FT_Args
function M.FT_Open_Face(library, args, face_index)
	local face = ffi.new'FT_Face[1]'
	checknz(C.FT_Open_Face(library, args, face_index or 0, face))
	face = face[0]
	return ffi.gc(face, M.FT_Done_Face)
end

function M.FT_Reference_Face(face)
	checknz(C.FT_Reference_Face(face))
end

function M.FT_Attach_File(face, filepathname)
	checknz(C.FT_Attach_File(face, filepathname))
end

--TODO: construct FT_Args
function M.FT_Attach_Stream(face, parameters)
	checknz(C.FT_Attach_Stream(face, parameters))
end

function M.FT_Done_Face(face)
	checknz(C.FT_Done_Face(face))
	ffi.gc(face, nil)
end

function M.FT_Select_Size(face, strike_index)
	checknz(C.FT_Select_Size(face, strike_index))
end

function M.FT_Request_Size(face, req)
	req = req or ffi.new'FT_Size_Request'
	checknz(C.FT_Request_Size(face, req))
	return req
end

function M.FT_Set_Char_Size(face, char_width, char_height, horz_resolution, vert_resolution)
	checknz(C.FT_Set_Char_Size(face, char_width, char_height or 0, horz_resolution or 0, vert_resolution or 0))
end

function M.FT_Set_Pixel_Sizes(face, pixel_width, pixel_height)
	checknz(C.FT_Set_Pixel_Sizes(face, pixel_width, pixel_height or 0))
end

function M.FT_Load_Glyph(face, glyph_index, load_flags) --FT_LOAD_*
	checknz(C.FT_Load_Glyph(face, glyph_index, load_flags or 0))
end

function M.FT_Load_Char(face, char_code, load_flags) --FT_LOAD_*
	checknz(C.FT_Load_Char(face, char_code, load_flags))
end

function M.FT_Set_Transform(face, xx, xy, yx, yy, x0, y0)
	local matrix = ffi.new('FT_Matrix', xx or 1, xy or 0, yx or 0, yy or 1)
	local delta = ffi.new('FT_Vector', x0 or 0, y0 or 0)
	C.FT_Set_Transform(face, matrix, delta)
end

function M.FT_Render_Glyph(slot, render_mode) --FT_RENDER_*
	checknz(C.FT_Render_Glyph(slot, render_mode or 0))
end

function M.FT_Get_Kerning(face, left_glyph, right_glyph, kern_mode, akerning) --FT_KERNING_*
	akerning = akerning or ffi.new'FT_Vector'
	checknz(C.FT_Get_Kerning(face, left_glyph, right_glyph, kern_mode, akerning))
	return akerning.x, akerning.y
end

function M.FT_Get_Track_Kerning(face, point_size, degree, akerning)
	akerning = akerning or ffi.new'FT_Vector'
	checknz(C.FT_Get_Track_Kerning(face, point_size, degree, akerning))
	return akerning.x, akerning.y
end

function M.FT_Get_Glyph_Name(face, glyph_index, buffer, buffer_max)
	buffer = buffer or ffi.new('uint8_t[?]', buffer_max or 64)
	local ret = C.FT_Get_Glyph_Name(face, glyph_index, buffer, buffer_max)
	return ret ~= 0 and ffi.string(buffer) or nil
end

function M.FT_Get_Postscript_Name(face)
	local name = C.FT_Get_Postscript_Name(face)
	return name ~= nil and ffi.string(name) or nil
end

function M.FT_Select_Charmap(face, encoding)
	if type(encoding) == 'string' then
		encoding = (s:byte(1) or 32) * 2^24 + (s:byte(2) or 32) * 2^16 + (s:byte(3) or 32) * 256 + (s:byte(4) or 32)
	end
	checknz(C.FT_Select_Charmap(face, encoding))
end

function M.FT_Set_Charmap(face, charmap)
	checknz(C.FT_Set_Charmap(face, charmap))
end

function M.FT_Get_Charmap_Index(charmap)
	local ret = C.FT_Get_Charmap_Index(charmap)
	assert(ret ~= -1)
	return ret
end

function M.FT_Get_Char_Index(face, charcode)
	return C.FT_Get_Char_Index(face, charcode)
end

function M.FT_Get_First_Char(face, agindex)
	return C.FT_Get_First_Char(face, agindex)
end

function M.FT_Get_Next_Char(face, char_code, agindex)
	return C.FT_Get_Next_Char(face, char_code, agindex)
end

local function face_chars(face) --returns iterator<charcode, glyph_index>
	local gindex = ffi.new'FT_UInt[1]'
	return function(_, charcode)
		if not charcode then
			charcode = M.FT_Get_First_Char(face, gindex)
		else
			charcode = M.FT_Get_Next_Char(face, charcode, gindex)
		end
		if gindex[0] == 0 then return end
		return charcode, gindex[0]
	end
end

function M.FT_Get_Name_Index(face, glyph_name)
	return nonzero(C.FT_Get_Name_Index(face, glyph_name))
end

function M.FT_Get_SubGlyph_Info(glyph, sub_index, p_index, p_flags, p_arg1, p_arg2, p_transform)
	p_index = p_index or ffi.new'FT_Int[1]'
	p_flags = p_flags or ffi.new'FT_UInt[1]'
	p_arg1  = p_arg1  or ffi.new'FT_Int[1]'
	p_arg2  = p_arg2  or ffi.new'FT_Int[1]'
	p_transform = p_transform or ffi.new'FT_Matrix[1]'
	checknz(M.FT_Get_SubGlyph_Info(glyph, sub_index, p_index, p_flags, p_arg1, p_arg2, p_transform))
	return
		p_index[0], p_flags[0], p_arg1[0], p_arg2[0],
		p_transform.xx, p_transform.xy, p_transform.yx, p_transform.yy
end

M.FT_Get_FSType_Flags = C.FT_Get_FSType_Flags -- returns a FS_TYPE_* mask

function M.FT_Face_GetCharVariantIndex(face, charcode, variantSelector)
	return nonzero(C.FT_Face_GetCharVariantIndex(face, charcode, variantSelector))
end

function M.FT_Face_GetCharVariantIsDefault(face, charcode, variantSelector)
	local ret = C.FT_Face_GetCharVariantIsDefault(face, charcode, variantSelector)
	if ret == -1 then return nil end
	return ret == 1 --1 if found in the standard (Unicode) cmap, 0 if found in the variation selector cmap
end

local function uint_list(p)
	if p == nil then return nil end
	return p
	--[[ TODO: return list of indices in a table or iterator
	if ret == nil then return end
		local t = {}
		local i = 0
		while ret[i] ~= 0 do
			t[i+1] = ret[i]
			i = i + 1
		end
		return t
	]]
end

function M.FT_Face_GetVariantSelectors(face)
	return uint_list(C.FT_Face_GetVariantSelectors(face))
end

function M.FT_Face_GetVariantsOfChar(face, charcode)
	return uint_list(C.FT_Face_GetVariantsOfChar(face, charcode))
end

function M.FT_Face_GetCharsOfVariant(face, variantSelector)
	return uint_list(C.FT_Face_GetCharsOfVariant(face, variantSelector))
end

function M.FT_Library_Version(library)
	local v = 'FT_Int[3]'
	C.FT_Library_Version(library, v, v+1, v+2)
	return v[0], v[1], v[2]
end

function M.FT_Face_CheckTrueTypePatents(face)
	return C.FT_Face_CheckTrueTypePatents(face) == 1
end

function M.FT_Face_SetUnpatentedHinting(face, value)
	return C.FT_Face_SetUnpatentedHinting(face, value) == 1
end

--ftbitmap.h

function M.FT_Bitmap_New(library)
	local bitmap = ffi.new'FT_Bitmap[1]'
	C.FT_Bitmap_New(bitmap)
	assert(bitmap[0] ~= nil)
	bitmap = bitmap[0]
	return ffi.gc(bitmap, function() checknz(C.FT_Bitmap_Done(library, bitmap)) end)
end

function M.FT_Bitmap_Copy(library, source, target)
	checknz(C.FT_Bitmap_Copy(library, source, target))
end

function M.FT_Bitmap_Embolden(library, bitmap, xStrength, yStrength)
	checknz(C.FT_Bitmap_Embolden(library, bitmap, xStrength, yStrength))
end

function M.FT_Bitmap_Convert(library, source, target, alignment)
	checknz(C.FT_Bitmap_Convert(library, source, target, alignment))
end

function M.FT_GlyphSlot_Own_Bitmap(slot)
	checknz(C.FT_GlyphSlot_Own_Bitmap(slot))
end

function M.FT_Bitmap_Done(library, bitmap)
	ffi.gc(bitmap, nil)
	checknz(C.FT_Bitmap_Done(library, bitmap))
end

--methods

M.new = M.FT_Init_FreeType

ffi.metatype('FT_LibraryRec', {__index = {
	free = M.FT_Done_FreeType,
	new_face = M.FT_New_Face,
	new_memory_face = M.FT_New_Memory_Face,
	open_face = M.FT_Open_Face,
	version = M.FT_Library_Version,
	--bitmaps
	bitmap_copy = M.FT_Bitmap_Copy,
	bitmap_embolden = M.FT_Bitmap_Embolden,
	bitmap_convert = M.FT_Bitmap_Convert,
	bitmap_done = M.FT_Bitmap_Done,
}})

ffi.metatype('FT_FaceRec', {__index = {
	free = M.FT_Done_Face,
	reference = M.FT_Reference_Face,
	attach_file = M.FT_Attach_File,
	atach_stream = M.FT_Attach_Stream,
	select_size = M.FT_Select_Size,
	request_size = M.FT_Request_Size,
	set_char_size = M.FT_Set_Char_Size,
	set_pixel_sizes = M.FT_Set_Pixel_Sizes,
	load_glyph = M.FT_Load_Glyph,
	load_char = M.FT_Load_Char,
	set_transform = M.FT_Set_Transform,
	kerning = M.FT_Get_Kerning,
	track_kerning = M.FT_Get_Track_Kerning,
	glyph_name = M.FT_Get_Glyph_Name,
	postscript_name = M.FT_Get_Postscript_Name,
	select_charmap = M.FT_Select_Charmap,
	set_charmap = M.FT_Set_Charmap,
	char_index = M.FT_Get_Char_Index,
	first_char = M.FT_Get_First_Char,
	next_char = M.FT_Get_Next_Char,
	chars = face_chars,
	name_index = M.FT_Get_Name_Index,
	fstype_flags = M.FT_Get_FSType_Flags,
	--glyph variants
	char_variant_index = M.FT_Face_GetCharVariantIndex,
	char_variant_is_default = M.FT_Face_GetCharVariantIsDefault,
	variant_selectors = M.FT_Face_GetVariantSelectors,
	variants_of_char = M.FT_Face_GetVariantsOfChar,
	chars_of_variant = M.FT_Face_GetCharsOfVariant,
	--hinting patents BS
	truetype_patents = M.FT_Face_CheckTrueTypePatents,
	set_unpatended_hinting = M.FT_Face_SetUnpatentedHinting,
}})

ffi.metatype('FT_GlyphSlotRec', {__index = {
	render = M.FT_Render_Glyph,
	subglyph_info = M.FT_Get_SubGlyph_Info,
	--bitmaps
	own_bitmap = M.FT_GlyphSlot_Own_Bitmap,
}})

ffi.metatype('FT_CharMapRec', {__index = {
	index = M.FT_Get_Charmap_Index,
}})

if not ... then require'freetype_test' end

return M
