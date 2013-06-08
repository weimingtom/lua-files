--cairo freetype extension
local M = require'cairo'
local ffi = require'ffi'
local C = M.C
require'cairo_ft_h'

function M.cairo_ft_font_face_create_for_ft_face(...)
	return ffi.gc(C.cairo_ft_font_face_create_for_ft_face(...), M.cairo_font_face_destroy)
end
