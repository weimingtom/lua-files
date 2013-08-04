local codedit = require'codedit'
local player = require'cairo_player'
local glue = require'glue'

local view = codedit.view:new{x = 0, y = 0, w = 0, h = 0}
local buffer = codedit.buffer:new()
local editor = codedit.editor:new{id = 'view', buffer = buffer, view = view}

function player:on_render(cr)

	if not self.loaded then
		buffer:load(glue.readfile('codedit.lua'))
		self.loaded = true
	end

	view.eol_markers = false
	view.w = self.w
	view.h = self.h

	editor:render(self)

end

player:play()

