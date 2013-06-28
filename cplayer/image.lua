--draw scaled RGBA8888 and G8 images
local player = require'cairo_player'
local cairo = require'cairo'

function player:image(t)
	local x = t.x or 0
	local y = t.y or 0
	local img = assert(t.image, 'image missing')

	--link image bits to a surface
	local surface
	if #img.pixel == 4 then
		surface =
			cairo.cairo_image_surface_create_for_data(img.data, cairo.CAIRO_FORMAT_ARGB32, img.w, img.h, img.stride)
	elseif #img.pixel == 1 then
		surface =
			cairo.cairo_image_surface_create_for_data(img.data, cairo.CAIRO_FORMAT_A8, img.w, img.h, img.stride)
	else
		error(string.format('unsupported format: %s', img.pixel))
	end

	local mt = self.cr:get_matrix()
	self.cr:translate(x, y)
	if t.scale then
		self.cr:scale(t.scale, t.scale)
	end
	if #img.pixel == 1 then
		self.cr:set_source_rgb(1,1,1)
		self.cr:mask_surface(surface, 0, 0)
		self.cr:fill()
	else
		self.cr:set_source_surface(surface, 0, 0)
		if t.filter then
			local pat = self.cr:get_source()
			pat:set_filter(t.filter)
		end
		self.cr:paint()
		self.cr:set_source_rgb(0,0,0)
	end
	self.cr:set_matrix(mt)

	surface:free()
end

if not ... then require'libjpeg_demo' end

