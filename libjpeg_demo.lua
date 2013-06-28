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
local dct = 'accurate'
local upsampling = 'smooth'
local smoothing = 'fuzzy'
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
						values = {'path', 'cdata', 'string', 'cdata_source', 'string_source', 'stream', 'progressive'},
						selected = source_type}
	if source_type == 'progressive' then
		cut_size = self:slider{id = 'cut_size', x = 800, y = 10, w = 180, h = 24,
										i0 = 1, i1 = 1024 * 64, step = 1, i = cut_size, text = 'file cut'}
	end

	bottom_up = self:togglebutton{id = 'bottom_up', x = 700, y = 10, w = 90, h = 24, text = 'bottom_up', selected = bottom_up}

	dct = self:mbutton{id = 'dct', x = 300, y = 10, w = 190, h = 24, values = {'accurate', 'fast', 'float'}, selected = dct}
	upsampling = self:mbutton{id = 'upsampling', x = 500, y = 10, w = 90, h = 24, values = {'fast', 'smooth'}, selected = upsampling}
	smoothing = self:mbutton{id = 'smoothing', x = 600, y = 10, w = 90, h = 24, values = {'fuzzy', 'blocky'}, selected = smoothing}

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
			elseif source_type == 'cdata_source' then
				local function read_cdata() return cdata, #s end
				source = {cdata_source = read_cdata}
			elseif source_type == 'string_source' then
				local function read_string() return s end
				source = {string_source = read_string}
			elseif source_type == 'progressive' then
				require'jit'.off(libjpeg.load, true)
				local pos = 1
				local function read_string()
					local newpos = math.min(cut_size, pos + 4096 - 1)
					local rs = s:sub(pos, newpos)
					pos = newpos + 1
					if #rs == 0 then return end
					return rs
				end
				source = {string_source = read_string}
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
		end

		local ok, err = pcall(function()

			libjpeg.load(source, {
					accept = {bgra = true, g = true, padded = true, bottom_up = bottom_up},
					dct = dct, upsampling = upsampling, smoothing = smoothing,
					render_scan = render_scan,
				})

		end)

		if not ok and not last_image then
			local image = {w = 50, h = 50}

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

