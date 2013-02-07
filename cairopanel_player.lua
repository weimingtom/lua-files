local CPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
local cairo = require'cairo'
local fps = require'fps_function'(2)

local main = winapi.Window{
	autoquit = true,
	visible = false,
	--state = 'maximized',
	title = 'CairoPanel Player',
}

local panel = CPanel{
	parent = main, w = main.client_w, h = main.client_h,
	anchors = {left=true,right=true,top=true,bottom=true}
}

local player = {}

function player:on_render(cr) end
function player:on_init(cr) end

function panel:__create_surface(surface)
	self.cr = surface:create_context()
	player:on_init(self.cr)
end

function panel:__destroy_surface(surface)
	self.cr:free()
end

function panel:on_render(surface)
	main.title = string.format('Cairo %s - %6.2f fps', cairo.cairo_version_string(), fps())
	player:on_render(self.cr)
end

function player:play()
	main:show()
	panel:settimer(1, panel.invalidate)
	winapi.MessageLoop()
end

if not ... then require'cairopanel_player_test' end

return player

