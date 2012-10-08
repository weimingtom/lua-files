local winapi = require'winapi'
require'winapi.messageloop'
local SGPanel = require'winapi.cairosgpanel'

local main = winapi.Window{autoquit = true, visible = false}
local panel = SGPanel{
	parent = main, w = main.client_w, h = main.client_h,
	anchors = {left=true,right=true,top=true,bottom=true}
}
local scene = {type = 'group', scale = 1}

function main:on_mouse_wheel(x, y, buttons, delta)
	scene.scale = scene.scale + delta/120/10
	panel:invalidate()
end

local player = {}

function panel:on_render()
	player.scene_graph = self.scene_graph
	player:on_render()
end

panel:settimer(1/60, panel.invalidate)

function player:play()
	main:show()
	os.exit(winapi.MessageLoop())
end

function player:render(user_scene)
	scene[1] = user_scene
	panel.scene_graph:render(scene)
end

function player:measure(e)
	return panel.scene_graph:measure(e)
end

return player
