local player = require'cairo_player'
local libjpeg = require'libjpeg'
local cairo = require'cairo'
local glue = require'glue'
local ffi = require'ffi'
local stdio = require'stdio'

require'unit'

local files = dir'media/jpeg/test*'
table.insert(files, 'media/jpeg/progressive.jpg')
--table.insert(files, 'media/jpeg/autumn-wallpaper.jpg')

--gui options
local filter = cairo.CAIRO_FILTER_NEAREST
local zoom = 1
local cut_size = 1024 * 64 --truncate input file to size to test progressive mode
local scroll = 0
local total_h = 0

--jpeg options
local source_type = 'path'
local dct_method = 'accurate'
local fancy_upsampling = false
local block_smoothing = false
local partial = true
local bottom_up = false

function player:on_render(cr)

	zoom = self:slider{id = 'zoom', x = 10, y = 10, w = 80, h = 24, i0 = 0.1, i1 = 10, step = 0.1, i = zoom, text = 'zoom'}

	filter = self:mbutton{id = 'filter',
		x = 100, y = 10, w = 190, h = 24,
		values = {
			cairo.CAIRO_FILTER_NEAREST,
			cairo.CAIRO_FILTER_BILINEAR,
			cairo.CAIRO_FILTER_GAUSSIAN
		},
		texts = {
			[cairo.CAIRO_FILTER_NEAREST] = 'nearest',
			[cairo.CAIRO_FILTER_BILINEAR] = 'bilinear',
			[cairo.CAIRO_FILTER_GAUSSIAN] = 'gaussian',
		},
		selected = filter}

	source_type = self:mbutton{id = 'source_type', x = 10, y = 40, w = 600, h = 24,
						values = {'path', 'cdata', 'string', 'read_cdata', 'read_string', 'stream', 'progressive'},
						selected = source_type}
	if source_type == 'progressive' then
		cut_size = self:slider{id = 'cut_size', x = 900, y = 10, w = 180, h = 24,
										i0 = 1, i1 = 1024 * 64, step = 1, i = cut_size, text = 'file cut'}
		partial = self:togglebutton{id = 'partial', x = 900, y = 40, w = 140, h = 24, text = 'partial loading',
												selected = partial}
	end

	bottom_up = self:togglebutton{id = 'bottom_up', x = 800, y = 10, w = 90, h = 24, text = 'bottom_up', selected = bottom_up}

	dct_method = self:mbutton{id = 'dct', x = 300, y = 10, w = 190, h = 24, values = {'accurate', 'fast', 'float'}, selected = dct_method}
	fancy_upsampling = self:togglebutton{id = 'fancy_upsampling', x = 500, y = 10, w = 140, h = 24, text = 'fancy upsampling', selected = fancy_upsampling}
	block_smoothing = self:togglebutton{id = 'block_smoothing', x = 650, y = 10, w = 140, h = 24, text = 'block smoothing', selected = block_smoothing}

	local cy = 80
	local cx = 0

	scroll = scroll - self.wheel_delta * zoom * 100
	scroll = self:vscrollbar{id = 'vscroll', x = self.w - 16 - cx, y = cy, w = 16, h = self.h - cy,
										i = scroll, size = total_h}

	self.cr:rectangle(cx, cy, self.w - 16 - cx, self.h - cy)
	self.cr:clip()

	local maxh
	for i,filename in ipairs(files) do

		local source
		if source_type == 'path' then
			source = {path = filename}
		elseif source_type == 'stream' then
			local stream = stdio.fopen(filename)
			source = {stream = stream}
		else
			local s = glue.readfile(filename)
			local cdata = ffi.new('unsigned char[?]', #s+1, s)
			if source_type == 'cdata' then
				source = {cdata = cdata, size = #s}
			elseif source_type == 'string' then
				source = {string = s}
			elseif source_type == 'read_cdata' then
				local function read_cdata() return cdata, #s end
				source = {read = read_cdata}
			elseif source_type == 'read_string' then
				local function read_string() return s end
				source = {read = read_string}
			elseif source_type == 'progressive' then
				local pos = 1
				local function read_string()
					local newpos = math.min(cut_size, pos + 4096 - 1)
					local rs = s:sub(pos, newpos)
					pos = newpos + 1
					if #rs == 0 then return end
					return rs
				end
				source = {read = read_string}
			end
		end

		local last_image
		local function render_scan(image)

			if not last_image and cx + image.w * zoom + 10 + 16 > self.w then
				cx = 0
				cy = cy + (maxh or image.h) * zoom + 10
				maxh = nil
			end
			last_image = image

			self:image{x = cx, y = cy - scroll, image = image, filter = filter, scale = zoom}

			self:text(string.format('scan %d', image.scan), 14, 'normal_fg', 'left', 'top',
												cx, cy - scroll, image.w * zoom, image.h * zoom)

			if image.partial then
				self:text('partial', 14, 'normal_fg', 'right', 'top', cx, cy - scroll, image.w * zoom, image.h * zoom)
			end
		end

		local ok, err = pcall(function()

			libjpeg.load(glue.update({
					accept = {bgra = true, g = true, padded = true, bottom_up = bottom_up and true or nil},
					dct_method = dct_method,
					fancy_upsampling = fancy_upsampling,
					block_smoothing = block_smoothing,
					partial_loading = partial,
					render_scan = render_scan,
				}, source))

		end)

		if not ok and not last_image then
			local image = {w = 200, h = 100}

			if cx + image.w * zoom + 10 + 16 > self.w then
				cx = 0
				cy = cy + (maxh or image.h) * zoom + 10
				maxh = nil
			end
			last_image = image

			self:rect(cx, cy - scroll, image.w * zoom, image.h * zoom, 'error_bg')
			self:text(string.format('%s', err:match('^(.-)\n'):match(': ([^:]-)$')), 14,
												'normal_fg', 'center', 'middle',
												cx, cy - scroll, image.w * zoom, image.h * zoom)
		end

		cx = cx + last_image.w * zoom + 10
		maxh = math.max(maxh or 0, last_image.h)

		if source.stream then
			source.stream:close()
		end
	end

	total_h = cy + (maxh or 0)
end

player:play()

