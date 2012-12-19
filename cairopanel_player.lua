local CPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
local cairo = require'cairo'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	state = 'maximized',
}

local panel = CPanel{
	parent = main, w = main.client_w, h = main.client_h,
	anchors = {left=true,right=true,top=true,bottom=true}
}

local player = {}

function player:on_render(cr) end --stub

function panel:on_render(surface)
	local cr = surface:create_context()
	player:on_render(cr)
	cr:free()
end

function player:play()
	main:show()
	winapi.MessageLoop()
end

if not ... then
	function player:on_render(cr)
		cr:set_source_rgba(1,1,1,.5)
		cr:rotate(.2)
		cr:new_path()
		cr:rectangle(0,0,100,100)
		cr:stroke_preserve()
		local path = cr:copy_path_flat()
		cr:identity_matrix()
		cr:translate(500,500)
		--cr:new_path(); cr:append_path(path)
		cr:stroke_preserve()
		cr:rectangle(0,0,100,100)
		cr:stroke_preserve()
	end
	player:play()
end

return player
