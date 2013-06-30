local player = require'cairo_player'
local libpng = require'libpng'
local glue = require'glue'
local ffi = require'ffi'
local stdio = require'stdio'
local bmpconv = require'bmpconv'
require'unit' --dir

local good_files = dir'media/png/good/*.png'
local bad_files = dir'media/png/bad/*.png'

local source_type = 'path'
local files = good_files
local bottom_up = false
local max_cut_size = 1024 * 6
local cut_size = max_cut_size
local pixel_format = 'rgb'

function player:on_render(cr)

	--self.theme = self.themes.light

	files = self:mbutton{id = 'files', x = 10, y = 10, w = 180, h = 24,
						values = {good_files, bad_files}, texts = {[good_files] = 'good files', [bad_files] = 'bad files'},
						multiselect = false,
						selected = files}

	source_type = self:mbutton{id = 'source_type', x = 200, y = 10, w = 590, h = 24,
						values = {'path',  'stream', 'cdata', 'string', 'read cdata', 'read string'},
						selected = source_type}

	bottom_up = self:togglebutton{id = 'bottom_up', x = 800, y = 10, w = 90, h = 24, text = 'bottom_up', selected = bottom_up}

	if source_type ~= 'path' and source_type ~= 'stream' then
		cut_size = self:slider{id = 'cut_size', x = 900, y = 10, w = self.w - 900 - 10, h = 24,
										i0 = 0, i1 = max_cut_size, step = 1, i = cut_size, text = 'file cut'}
	end

	pixel_format = self:mbutton{id = 'pixel', x = 10, y = 40, w = 380, h = 24,
						values = {'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'ga', 'ag'}, selected = pixel_format}

	local cy = 80
	local cx = 10

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
			local cdata = ffi.new('uint8_t[?]', #s+1, s)
			if source_type == 'cdata' then
				t.cdata = cdata
				t.size = #s
			elseif source_type == 'string' then
				t.string = s
			elseif source_type:match'^read' then
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

		local w, h = 32, 32

		t.accept = {[pixel_format] = true, padded = true, bottom_up = bottom_up and true or nil}
		t.header_only = false

		local ok, image = pcall(libpng.load, t)

		if ok then
			image = bmpconv.convert_best(image, {bgra = true, padded = true})
		end

		if not ok then w = (w + 10) * 8 - 10 end
		--if not ok then print(image) end

		if cx + w + 10 > self.w then
			cx = 10
			cy = cy + h + 10 + 18
		end

		if ok then
			if not t.header_only then
				self:image{x = cx, y = cy, image = image}
			end

			self:text(image.file.pixel .. tostring(image.file.bit_depth),
						14, 'normal_fg', 'left', 'top', cx, cy - 18, w, h)
			self:text(image.file.paletted and 'P' or '',
						14, 'normal_fg', 'left', 'bottom', cx, cy, w, h)
		else
			local err = image
			self:rect(cx, cy, w, h, 'error_bg')
			self:text(string.format('%s', err:match('^(.-)\n'):match(': ([^:]-)$')), 14,
												'normal_fg', 'center', 'middle',
												cx, cy, w, h)
		end

		cx = cx + w + 10

		if t.stream then
			t.stream:close()
		end
	end
end

player:play()

