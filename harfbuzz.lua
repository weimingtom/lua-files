local ffi = require'ffi'
require'harfbuzz_h'
local C = ffi.load'harfbuzz'
local ft = require'freetype'

local M = setmetatable({C = C}, {__index = C})

function M.version()
	local v = ffi.new'uint32_t[3]'
	C.hb_version(v, v+1, v+2)
	return v[0], v[1], v[2]
end

function M.version_string()
	return ffi.string(C.hb_version_string())
end

local function get_xy_func(func)
	return function(self)
		local x = ffi.new'int32_t[2]'
		func(self, x, x+1)
		return x[0], x[1]
	end
end

local function get_pos_func(func)
	return function(self, glyph)
		local x = ffi.new'hb_position_t[2]'
		func(self, glyph, x, x+1)
		return x[0], x[1]
	end
end

local function get_pos2_func(func)
	return function(self, glyph, index)
		local x = ffi.new'hb_position_t[2]'
		func(self, glyph, index, x, x+1)
		return x[0], x[1]
	end
end

function M.hb_blob_create(data, size, mode, user_data, destroy_func)
	return ffi.gc(C.hb_blob_create(data, size, mode, user_data, destroy_func), C.hb_blob_destroy)
end

ffi.metatype('hb_blob_t', {__index = {
	create_sub_blob = C.hb_blob_create_sub_blob, -- offset, length -> hb_blob_t

	get_empty = C.hb_blob_get_empty, -- () -> hb_blob_t
	reference = C.hb_blob_reference, -- ()
	destroy = C.hb_blob_destroy, --()
	set_user_data = C.hb_blob_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_blob_get_user_data, --key -> data
	make_immutable = C.hb_blob_make_immutable,
	is_immutable = C.hb_blob_is_immutable,

	get_length = C.hb_blob_get_length,
	get_data = C.hb_blob_get_data, --length -> data
	get_data_writable = C.hb_blob_get_data_writable --length -> data,
}})

function M.hb_face_create(blob, index)
	return ffi.gc(C.hb_face_create(blob, index), C.hb_face_destroy)
end

--hb_bool_t hb_feature_from_string (const char *str, int len, hb_feature_t *feature);
--void      hb_feature_to_string (hb_feature_t *feature, char *buf, unsigned int size);

local function hb_shape_plan_create(face, props, user_features, num_user_features, shaper_list)
	return C.hb_shape_plan_create(face, props, user_features, num_user_features, shaper_list)
end

ffi.metatype('hb_face_t', {__index = {

	get_empty = C.hb_face_get_empty, -- () -> hb_face_t
	reference = C.hb_face_reference, -- ()
	destroy = C.hb_face_destroy, --()
	set_user_data = C.hb_face_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_face_get_user_data, --key -> data
	make_immutable = C.hb_face_make_immutable,
	is_immutable = C.hb_face_is_immutable,

	reference_table = C.hb_face_reference_table, --tag -> hb_blob_t
	refernce_blob = C.hb_face_reference_blob, --() -> hb_blob_t
	set_index = C.hb_face_set_index,
	get_index = C.hb_face_get_index,
	set_upem  = C.hb_face_set_upem,
	get_upem  = C.hb_face_get_upem,
	set_glyph_count = C.hb_face_set_glyph_count,
	get_glyph_count = C.hb_face_get_glyph_count,

	create_shape_plan = hb_shape_plan_create,
}})

local function hb_shape(font, buffer, features, num_features)
	C.hb_shape(font, buffer, features, num_features or 0)
end

local function hb_shape_full(font, buffer, features, num_features, shaper_list)
	return C.hb_shape_full(font, buffer, features, num_features or 0, shaper_list)
end

function M.hb_font_create(face)
	return ffi.gc(C.hb_font_create(face), C.hb_font_destroy)
end

ffi.metatype('hb_font_t', {__index = {
	create_sub_font = C.hb_font_create_sub_font, --parent -> hb_font_t
	get_parent = C.hb_font_get_parent, -- () -> hb_font_t
	get_face = C.hb_font_get_face, -- () -> hb_face_t

	get_empty = C.hb_font_get_empty, -- () -> hb_font_t
	reference = C.hb_font_reference, -- ()
	destroy = C.hb_font_destroy, --()
	set_user_data = C.hb_font_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_font_get_user_data, --key -> data
	make_immutable = C.hb_font_make_immutable,
	is_immutable = C.hb_font_is_immutable,

	set_scale = C.hb_font_set_scale, --int x_scale, int y_scale
	get_scale = get_xy_func(C.hb_font_get_scale), --int *x_scale, int *y_scale
	set_ppem = C.hb_font_set_ppem, --x_ppem, y_ppem
	get_ppem = get_xy_func(C.hb_font_get_ppem), --uint *x_ppem, uint *y_ppem

	get_glyph = C.hb_font_get_glyph, --hb_codepoint_t unicode, hb_codepoint_t variation_selector, hb_codepoint_t *glyph -> hb_glyph_t
	get_glyph_h_advance = C.hb_font_get_glyph_h_advance, --glyph -> hb_position_t
	get_glyph_v_advance = C.hb_font_get_glyph_v_advance, --glyph -> hb_position_t
	get_glyph_h_origin = get_pos_func(C.hb_font_get_glyph_h_origin), --glyph -> x, y
	get_glyph_v_origin = get_pos_func(C.hb_font_get_glyph_v_origin), --glyph -> x, y
	get_glyph_h_kerning = C.hb_font_get_glyph_h_kerning, --left_glyph, right_glyph -> hb_position_t
	get_glyph_v_kerning = C.hb_font_get_glyph_v_kerning, --top_glyph, bottom_glyph -> hb_position_t
	get_glyph_extents = C.hb_font_get_glyph_extents, --glyph, hb_glyph_extents_t *extents
	get_glyph_contour_point = get_pos2_func(C.hb_font_get_glyph_contour_point), --glyph, point_index -> x, y
	get_glyph_name = C.hb_font_get_glyph_name, --glyph, name, size
	get_glyph_from_name = C.hb_font_get_glyph_from_name, --name, len, *glyph
	get_glyph_advance_for_direction = C.hb_font_get_glyph_advance_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	get_glyph_origin_for_direction = C.hb_font_get_glyph_origin_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	add_glyph_origin_for_direction = C.hb_font_add_glyph_origin_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	subtract_glyph_origin_for_direction = C.hb_font_subtract_glyph_origin_for_direction, --hb_codepoint_t glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	get_glyph_kerning_for_direction = C.hb_font_get_glyph_kerning_for_direction, --b_codepoint_t first_glyph, hb_codepoint_t second_glyph, hb_direction_t direction, hb_position_t *x, hb_position_t *y
	get_glyph_extents_for_origin = C.hb_font_get_glyph_extents_for_origin, --hb_codepoint_t glyph, hb_direction_t direction, hb_glyph_extents_t *extents -> hb_bool_t
	get_glyph_contour_point_for_origin = C.hb_font_get_glyph_contour_point_for_origin, --hb_codepoint_t glyph, point_index, hb_direction_t direction, hb_position_t *x, hb_position_t *y -> hb_bool_t
	glyph_to_string = C.hb_font_glyph_to_string, --hb_codepoint_t glyph, s, size
	glyph_from_string = C.hb_font_glyph_from_string, --s, len, hb_codepoint_t *glyph -> hb_bool_t

	shape = hb_shape,
	shape_full = hb_shape_full,
}})

function M.hb_buffer_create()
	local self = assert(ffi.gc(C.hb_buffer_create(), C.hb_buffer_destroy))
	C.hb_buffer_set_unicode_funcs(self, C.hb_ucdn_get_unicode_funcs())
	return self
end

local function hb_buffer_shape_full(buffer, font, features, num_features, shaper_list)
	return C.hb_shape_full(font, buffer, features, num_features or 0, shaper_list)
end

ffi.metatype('hb_buffer_t', {__index = {
	get_empty = C.hb_buffer_get_empty, -- () -> hb_buffer_t
	reference = C.hb_buffer_reference, -- ()
	destroy = C.hb_buffer_destroy, --()
	set_user_data = C.hb_buffer_set_user_data, --key, data, destroy, replace
	get_user_data = C.hb_buffer_get_user_data, --key -> data

	set_content_type = C.hb_buffer_set_content_type, --hb_buffer_content_type_t content_type
	get_content_type = C.hb_buffer_get_content_type, -- () -> hb_buffer_content_type_t
	--set_unicode_funcs = C.hb_buffer_set_unicode_funcs, --hb_unicode_funcs_t *unicode_funcs
	--get_unicode_funcs = C.hb_buffer_get_unicode_funcs,
	set_direction = function(self, direction)
		if type(direction) == 'string' then
			direction = C.hb_direction_from_string(direction, #direction)
		end
		C.hb_buffer_set_direction(self, direction)
	end,
	get_direction = C.hb_buffer_get_direction,
	set_script = C.hb_buffer_set_script, --hb_script_t script
	get_script = C.hb_buffer_get_script,
	set_language = function(self, lang)
		if type(lang) == 'string' then
			lang = C.hb_language_from_string(lang, #lang)
		end
		C.hb_buffer_set_language(self, lang)
	end,
	get_language = C.hb_buffer_get_language,
	set_segment_properties = C.hb_buffer_set_segment_properties, --hb_segment_properties_t *props
	get_segment_properties = C.hb_buffer_get_segment_properties,
	guess_segment_properties = C.hb_buffer_guess_segment_properties,

	set_flags = C.hb_buffer_set_flags, --hb_buffer_flags_t flags
	get_flags = C.hb_buffer_get_flags,
	reset = C.hb_buffer_reset,
	clear = C.hb_buffer_clear_contents,
	pre_allocate = C.hb_buffer_pre_allocate, --size
	allocation_successful = C.hb_buffer_allocation_successful,
	reverse = C.hb_buffer_reverse,
	reverse_clusters = C.hb_buffer_reverse_clusters,

	add = C.hb_buffer_add, --hb_codepoint_t codepoint, unsigned int cluster
	add_utf8  = function(self, buf, sz, iofs, isz) C.hb_buffer_add_utf8 (self, buf, sz or #buf, iofs or 0, isz or sz or #buf) end,
	add_utf16 = function(self, buf, sz, iofs, isz) C.hb_buffer_add_utf16(self, buf, sz or #buf, iofs or 0, isz or sz or #buf) end,
	add_utf32 = function(self, buf, sz, iofs, isz) C.hb_buffer_add_utf32(self, buf, sz or #buf, iofs or 0, isz or sz or #buf) end,

	set_length = C.hb_buffer_set_length, --length
	get_length = C.hb_buffer_get_length,
	get_glyph_infos     = function(self) return C.hb_buffer_get_glyph_infos(self, nil) end,
	get_glyph_positions = function(self) return C.hb_buffer_get_glyph_positions(self, nil) end,

	normalize_glyphs = C.hb_buffer_normalize_glyphs,
	serialize_glyphs = function(self, buf, sz, start, end_, buf_consumed, font, format, flags)
		start = start or 1
		end_ = end_ or self:get_length()
		format = format or C.HB_BUFFER_SERIALIZE_FORMAT_JSON
		flags = flags or C.HB_BUFFER_SERIALIZE_FLAGS_DEFAULT
		--returns number of items serialized
		return C.hb_buffer_serialize_glyphs(start-1, end_-1, buf, sz, buf_consumed, font, format, flags)
	end,
	deserialize_glyphs = function(self, buf, buf_len, end_ptr, font, format)
		format = format or C.HB_BUFFER_SERIALIZE_FORMAT_JSON
		return C.hb_buffer_deserialize_glyphs(buf, buf_len or -1, end_ptr, font, format)
	end,

	shape = function(buffer, font, features, num_features)
		C.hb_shape(font, buffer, features, num_features or 0)
	end,

	shape_full = hb_buffer_shape_full,
}})

function M.list_shapers()
	local t = {}
	local s = C.hb_shape_list_shapers()
	while s ~= nil do
		t[#t+1] = ffi.string(s[0])
		s = s + 1
	end
	return t
end

--[[

hb_shape_plan_t *
hb_shape_plan_create_cached (hb_face_t *face,
        const hb_segment_properties_t *props,
        const hb_feature_t *user_features,
        unsigned int num_user_features,
        const char * const *shaper_list);
hb_shape_plan_t * hb_shape_plan_get_empty (void);
hb_shape_plan_t * hb_shape_plan_reference (hb_shape_plan_t *shape_plan);
void         hb_shape_plan_destroy (hb_shape_plan_t *shape_plan);
hb_bool_t    hb_shape_plan_set_user_data (hb_shape_plan_t *shape_plan,
                        hb_user_data_key_t *key,
                        void * data,
                        hb_destroy_func_t destroy,
                        hb_bool_t replace);
void *       hb_shape_plan_get_user_data (hb_shape_plan_t *shape_plan, hb_user_data_key_t *key);
hb_bool_t    hb_shape_plan_execute (hb_shape_plan_t *shape_plan,
                        hb_font_t *font,
                        hb_buffer_t *buffer,
                        const hb_feature_t *features,
                        unsigned int num_features);
const char * hb_shape_plan_get_shaper (hb_shape_plan_t *shape_plan);


]]

if not ... then require'harfbuzz_test' end

return M

