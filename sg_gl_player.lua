local glue = require'glue'
local winapi = require'winapi'
require'winapi.windowclass'
require'winapi.messageloop'
require'winapi.wglpanel'

local GLSG = require'sg_gl'
require'sg_gl_mesh'
require'sg_gl_obj'

local imagefile = require'imagefile'

local main = winapi.Window{
	autoquit = true,
	visible = false,
}

local panel = winapi.WGLPanel{
	anchors = {left = true, top = true, right = true, bottom = true},
	visible = false,
}

function main:init()
	panel.w = self.client_w
	panel.h = self.client_h
	panel.parent = self
	panel:init(self)
	panel.visible = true
	self.visible = true
	panel:settimer(1/60, panel.invalidate)
end

function panel:init()
	self.sg = GLSG:new()
end

function panel:on_destroy()
	self.sg:free()
end

local viewport = {
	type = 'viewport',
	x = 0, y = 0, w = 1000, h = 1000,
	scene = {
		type = 'group', z = -2,
	}
}


local function open(path)
	local node
	local filetype = imagefile.detect_type(path)
	if filetype then
		node = {type = ''},
		{type = 'obj_model', scale = 0.01, file = {path = 'media/obj/greek_vase1/greek_vase.obj'}}
	end
	return node
end

local r = 1
function panel:on_render()
	r = r + 1
	viewport.w = self.client_w
	viewport.h = self.client_h

	--viewport.camera = {eye = {0,0,0}, center = {0,0,-1}, up = {0,1,0}, rz = -2,
	--							ax = r + self.cursor_pos.y, ay = r, az = 0 + self.cursor_pos.x}
	self.sg:render(viewport)
end

main:init()

os.exit(winapi.MessageLoop())
