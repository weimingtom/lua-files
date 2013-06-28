local player = require'cairo_player'
local giflib = require'giflib'
local cairo = require'cairo'
local glue = require'glue'
local ffi = require'ffi'
local stdio = require'stdio'

require'unit'

local files = dir'media/gif/*'

local white_bg = false
local source_type = 'path'
local bottom_up = false
local mode = 'transparent'
local frame_state = {} --{[filename] = {frame = <current_frame_no>, time = <next_frame_time>}

function player:on_render(cr)

	white_bg = self:mbutton{id = 'white_bg', x = 10, y = 10, w = 130, h = 24,
						texts = {[true] = 'white bg', [false] = 'dark bg'}, values = {true, false}, selected = white_bg}
	self.theme = self.themes[white_bg and 'light' or 'dark']

	source_type = self:mbutton{id = 'source_type', x = 150, y = 10, w = 290, h = 24,
						values = {'path', 'cdata', 'string', 'fileno'},
						selected = source_type}

	mode = self:mbutton{id = 'mode', x = 450, y = 10, w = 190, h = 24,
						values = {'transparent', 'opaque'},
						selected = mode}

	bottom_up = self:togglebutton{id = 'bottom_up', x = 650, y = 10, w = 90, h = 24, text = 'bottom_up', selected = bottom_up}

	local cx, cy = 0, 40
	local maxh = 0

	for i,filename in ipairs(files) do

		local source, file
		if source_type == 'path' then
			source = {path = filename}
		elseif source_type == 'fileno' then
			file = assert(io.open(filename, 'rb'))
			source = {fileno = ffi.C._fileno(file)}
		elseif source_type == 'cdata' then
			local s = glue.readfile(filename)
			local cdata = ffi.new('unsigned char[?]', #s+1, s)
			source = {cdata = cdata, size = #s}
		elseif source_type == 'string' then
			local s = glue.readfile(filename)
			source = {string = s}
		end

		local gif = giflib.load(source, {
			accept = {bgra = true, g = true, padded = true, bottom_up = bottom_up, top_down = not bottom_up},
			mode = mode,
		})

		local state = frame_state[filename]
		if not state then
			state = {frame = 0, time = 0}
			frame_state[filename] = state
		end

		local image
		if self.clock >= state.time then
			state.frame = state.frame + 1
			if state.frame > #gif.frames then
				state.frame = 1
			end
			image = gif.frames[state.frame]
			state.time = self.clock + (image.delay_ms or 0)
		else
			image = gif.frames[state.frame]
		end

		if cx + image.w > self.w then
			cx = 0
			cy = cy + maxh + 10
			maxh = 0
		end

		self:image{x = cx, y = cy, image = image}

		cx = cx + gif.w + 10
		maxh = math.max(maxh, image.h)

		if file then
			file:close()
		end
	end
end

player:play()

