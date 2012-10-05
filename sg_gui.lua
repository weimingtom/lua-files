local glue = require'glue'
local SG = require'sg_cairo'
local cairo = require'cairo'

local Button = {}

function Button:measure(scene_graph)
	local x1,y1,x2,y2 = scene_graph:path_extents(self.text_path)
	self.text_path[3] = (self.button_path[4] - (x2-x1))/2
	self.text_path.invalid = true
end

function Button:new(x, y, w, h, text)
	local font = {size = 12}
	local button_path = {'round_rect', 0, 0, w, h, 5}
	local text_path = {'text', font, 0, 5 + 12, text}
	return glue.inherit({
		button_path = button_path,
		text_path = text_path,
		object = {
			type = 'group',
			x = x, y = y,
			{type = 'shape',
				path = button_path,
				fill = {
					type = 'group',
					{type = 'color', 1, 1, 1},
					{type = 'shape',
						path = text_path,
						fill = {type = 'color', 0, 0, 0, 1},
					},
				},
			},
		}
	}, self)
end

if not ... then
local player = require'sg_cairo_player'

local button = Button:new(200, 200, 100, 24, 'Cancel')
local scene = {
	type = 'group',
	{type = 'color',0,0,0,1},
	{type = 'color',1,1,1,.1},
	button.object,
}

local stroke_extents_stroke = {type = 'color', 0, 0, 1, 0.5}
local fill_extents_stroke = {type = 'color', 1, 0, 0, 0.5}
function player:on_render()
	self.scene_graph.stroke_extents_stroke = stroke_extents_stroke
	self.scene_graph.fill_extents_stroke = fill_extents_stroke
	button:measure(self.scene_graph)
	self:render(scene)
end
player:play()
end
