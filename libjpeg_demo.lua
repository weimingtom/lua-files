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
local pixel_format = 'rgb'
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
local padded = false

function player:on_render(cr)

	source_type = self:mbutton{id = 'source_type', x = 10, y = 10, w = 480, h = 24,
						values = {'path', 'stream', 'cdata', 'string', 'read cdata', 'read string'},
						selected = source_type}
	if source_type ~= 'path' and source_type ~= 'stream' then
		partial = self:togglebutton{id = 'partial', x = 500, y = 10, w = 140, h = 24, text = 'partial loading',
												selected = partial}
		cut_size = self:slider{id = 'cut_size', x = 650, y = 10, w = self.w - 650 - 10, h = 24,
										i0 = 0, i1 = 1024 * 64, step = 1, i = cut_size, text = 'file cut'}
	end

	dct_method = self:mbutton{id = 'dct', x = 10, y = 40, w = 180, h = 24, values = {'accurate', 'fast', 'float'}, selected = dct_method}
	fancy_upsampling = self:togglebutton{id = 'fancy_upsampling', x = 200, y = 40, w = 140, h = 24, text = 'fancy upsampling', selected = fancy_upsampling}
	block_smoothing = self:togglebutton{id = 'block_smoothing', x = 350, y = 40, w = 140, h = 24, text = 'block smoothing', selected = block_smoothing}

	pixel_format = self:mbutton{id = 'pixel', x = 500, y = 40, w = 390, h = 24,
						values = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'ga', 'ag', 'ycc', 'ycck', 'cmyk'},
						selected = pixel_format}
	bottom_up = self:togglebutton{id = 'bottom_up', x = 900, y = 40, w = 90, h = 24, text = 'bottom_up', selected = bottom_up}
	padded = self:togglebutton{id = 'padded', x = 1000, y = 40, w = 90, h = 24, text = 'padded', selected = padded}


	local cy = 80
	local cx = 0

	scroll = scroll - self.wheel_delta * 100
	scroll = self:vscrollbar{id = 'vscroll', x = self.w - 16 - cx, y = cy, w = 16, h = self.h - cy,
										i = scroll, size = total_h}
	total_h = 0

	self.cr:rectangle(cx, cy, self.w - 16 - cx, self.h - cy)
	self.cr:clip()

	cy = cy - scroll

	local last_image, maxh
	for i,filename in ipairs(files) do

		local t = {}
		if source_type == 'path' then
			t.path = filename
		elseif source_type == 'stream' then
			local stream = stdio.fopen(filename)
			t.stream = stream
		else
			local s = glue.readfile(filename)
			s = s:sub(1, cut_size)
			local cdata = ffi.new('unsigned char[?]', #s+1, s)
			if source_type == 'cdata' then
				t.cdata = cdata
				t.size = #s
			elseif source_type == 'string' then
				t.string = s
			elseif source_type:find'^read' then
				local function one_shot_reader(buf, sz)
					local done
					return function()
						if done then return end
						done = true
						return buf, sz
					end
				end
				if source_type:find'string' then
					t.read = one_shot_reader(s)
				else
					t.read = one_shot_reader(cdata, #s)
				end
			end
		end

		last_image = nil
		local function render_scan(image, scan_number)

			if not last_image and cx + image.w + 10 + 16 > self.w then
				cx = 0
				local h = (maxh or image.h) + 10
				cy = cy + h
				total_h = total_h + h
				maxh = nil
			end
			last_image = image

			self:image{x = cx, y = cy, image = image}

			self:text(string.format('scan %d', scan_number), 14, 'normal_fg', 'left', 'top',
												cx, cy, image.w, image.h)

			if image.partial then
				self:text('partial', 14, 'normal_fg', 'right', 'top', cx, cy, image.w, image.h)
			end
		end

		local ok, err = pcall(function()

			libjpeg.load(glue.update(t, {
					accept = {
						[pixel_format] = true,
						padded = padded,
						bottom_up = bottom_up,
						top_down = not bottom_up
					},
					dct_method = dct_method,
					fancy_upsampling = fancy_upsampling,
					block_smoothing = block_smoothing,
					partial_loading = partial,
					render_scan = render_scan,
				}))

		end)

		if ok then
			self:text(last_image.file.pixel .. ' -> ' .. last_image.pixel,
							14, 'normal_fg', 'center', 'middle', cx, cy, last_image.w, last_image.h)
		end

		if not ok and not last_image then

			local image = {w = 300, h = 100}

			if cx + image.w + 10 + 16 > self.w then
				cx = 0
				local h = (maxh or image.h) + 10
				cy = cy + h
				total_h = total_h + h
				maxh = nil
			end
			last_image = image

			self:rect(cx, cy, image.w, image.h, 'error_bg')
			self:text(string.format('%s', err:match('^(.-)\n'):match(': ([^:]-)$')), 14,
												'normal_fg', 'center', 'middle',
												cx, cy, image.w, image.h)
		end

		cx = cx + last_image.w + 10
		maxh = math.max(maxh or 0, last_image.h)

		if t.stream then
			t.stream:close()
		end
	end

	total_h = total_h + math.max(maxh or 0, last_image and last_image.h or 0)
end

player:play()

