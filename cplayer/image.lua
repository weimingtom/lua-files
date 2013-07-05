--draw scaled RGBA8888 and G8 images
local player = require'cairo_player'
local cairo = require'cairo'
local bmpconv = require'bmpconv'

function player:image(t)
	local x = t.x or 0
	local y = t.y or 0
	local img = assert(t.image, 'image missing')

	--link image bits to a surface
	img = bmpconv.convert_best(img, {bgra = true, top_down = true})
	local surface = cairo.cairo_image_surface_create_for_data(img.data, cairo.CAIRO_FORMAT_ARGB32,
																					img.w, img.h, img.stride)

	local mt = self.cr:get_matrix()
	self.cr:translate(x, y)
	if t.scale then
		self.cr:scale(t.scale, t.scale)
	end
	self.cr:set_source_surface(surface, 0, 0)
	self.cr:paint()
	self.cr:set_source_rgb(0,0,0)
	self.cr:set_matrix(mt)

	surface:free()
end

if not ... then require'libjpeg_demo' end

