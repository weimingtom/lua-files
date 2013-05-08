io.stdout:setvbuf'no'
local glue = require'glue'
local cairo = require'cairo'
local winapi = require'winapi'
local CairoSGPanel = require'winapi.cairosgpanel'
require'winapi.messageloop'

local Wheel = {}

function Wheel:new(n, size, radius)
	self = glue.inherit({}, self)
	self.radius = radius
	self.cds = {}
	self.cds_zorder = {type = 'group'}
	self.lights = {}
	local shadow_fill = {type = 'gradient', x1 = 0, y1 = 0, x2 = 0, y2 = size+4, 0, {0,0,0,0.9}, 1, {0,0,0,1}}
	for i=1,n do
		self.lights[i] = {type = 'color', 0,0,0}
		local cd_image = {type = 'shape',
			path = {'rect', 0, 0, size, size},
			fill = {type = 'group',
				{type = 'image', file = {path = string.format('../../media/demos/cdspin/cd%d.png', i)}},
				self.lights[i],
			},
			stroke = {type = 'color', 0,0,0},
			line_width = 10,
			in_fill = function(render, e, inside)
				--e.stroke[1] = inside and 1 or 0
			end,
		}
		local cd_shadow = {type = 'group',
			y = size + 20,
			{type = 'group',
				y = size,
				sy = -1,
				cd_image,
			},
			{type = 'shape',
				path = {'rect', -2, -2, size+4, size+4}, --TODO: find a better way, remove the margins
				fill = shadow_fill,
			},
		}
		self.cds_zorder[i] = {
			type = 'group',
			{type = 'group',
				x = -size/2,
				y = -size/2,
				cd_image,
				cd_shadow,
			}
		}
		self.cds[i] = self.cds_zorder[i]
	end
	self.left_button = {
		type = 'group',
		y = 700,
		sx = 12, sy = 12,
		{
			type = 'shape',
			path = {'move', 0, 0, 'line', 5, 0, 'arc', 5, 5, 5, 270, 90, 'line', 0, 10, 'close'},
			stroke = {type = 'color', 1, 1, 1, alpha = .05},
			fill = {
				type = 'group',
				{
					type = 'shape',
					x = 3, y = 2.5,
					sx = 0.4, sy = 0.5,
					path = {'move', 0, 0, 'line', 10, 5, 'line', 0, 10, 'close'},
					stroke = {type = 'color', 1, 1, 1, alpha = .05},
					fill = {type = 'color', 1, 1, 1, alpha = .5},
				},
				{
					type = 'shape',
					path = {'rect', 0, 0, 50, 50},
					fill = {type = 'gradient', x1 = 0, y1 = 30, r1 = 0, x2 = 0, y2 = 30, r2 = 26, 0, {1,1,1,0.2}, 1, {0,0,0,0.5}},
				},
			},
			in_fill = function(render, e, inside)
				e.fill[1].fill.alpha = inside and .7 or .5
				e.stroke.alpha = inside and .1 or .05
				if inside and render.mouse_buttons.lbutton then
					e.fill[1].fill.alpha = 1
					e.stroke.alpha = .2
				end
			end,
		},
	}
	self.right_button = {
		type = 'group',
		sx = -1,
		x = -20,
		self.left_button,
	}
	self.scene = {
		type = 'group',
		{type = 'color', 0, 0, 0},
		self.cds_zorder,
		self.left_button,
		self.right_button,
	}
	return self
end

function Wheel:spin(distance)
	local n,t = #self.cds,self.cds
	local angle = 2*math.pi/n
	for i=1,n do
		local a = (i-1+distance)*angle
		t[i].x = self.radius*math.sin(a)
		local z = math.cos(a)-1
		t[i].z = z --for sorting
		--fake a perspective projection by scaling the CDs
		local scale = (1+z)/1.5+0.8
		scale = math.max(0.1, scale)
		t[i].sx = scale
		t[i].sy = scale
		self.lights[i].alpha = -z
	end
	for i=1,n do self.cds_zorder[i] = t[i] end
	table.sort(self.cds_zorder, function(a, b) return a.z < b.z end)
end

--the cairo panel and main window

local panel = CairoSGPanel{
	visible = false,
}

function panel:on_mouse_move(x, y, buttons)
	--self.scene_graph.mouse_x = x
	--self.scene_graph.mouse_y = y
	--self.scene_graph.mouse_buttons = buttons
	self:invalidate()
end

panel.on_lbutton_down = panel.on_mouse_move
panel.on_lbutton_up = panel.on_mouse_move

function panel:on_render()
	local w,h = self.client_w, self.client_h
	self.wheel.scene.x = w/2
	self.wheel.scene.y = h/2 - 100
	self.wheel.scene.sx = 0.2 * w/h
	self.wheel.scene.sy = 0.2 * w/h
	self.scene_graph:render(self.wheel.scene)
end

function panel:spin_more()
	if self.popup then return end
	local inertia = 3
	local distance = math.abs(self.where - self.cd)
	local sign = self.where < self.cd and 1 or -1
	if distance < 0.001 then self.where = self.cd end
	if self.where == self.cd then return end
	self.where = self.where + sign * distance / inertia
	self.wheel:spin(self.where)
	self:invalidate()
end

function panel:on_key_up(vk, flags)
	local zoom = 1.5
	if vk == winapi.VK_RETURN and not self.popup then
		self.popup = true
		local cd = self.wheel.cds_zorder[#self.wheel.cds_zorder]
		cd.sx = cd.sx*zoom
		cd.sy = cd.sy*zoom
	else
		if self.popup then
			local cd = self.wheel.cds_zorder[#self.wheel.cds_zorder]
			cd.sx = cd.sx/zoom
			cd.sy = cd.sy/zoom
			self.popup = nil
		end
		self.cd = self.cd + ((vk == winapi.VK_LEFT and 1) or (vk == winapi.VK_RIGHT and -1) or 0)
	end
	self:invalidate()
end

function panel:init(parent)
	self.parent = parent
	self.w = parent.client_w
	self.h = parent.client_h
	self.anchors = {left = true, right = true, top = true, bottom = true}
	self.wheel = Wheel:new(10, 500, 500)
	math.randomseed(os.time())
	self.cd = math.random(1,10)
	self.where = 1
	self.wheel:spin(self.where)
	self.visible = true
	self:settimer(1/60, self.spin_more)
end

local main = winapi.Window{
	autoquit = true,
	title = string.format('Cairo %s', cairo.cairo_version_string()),
	visible = false,
}

function main:init()
	panel:init(self)
	self.visible = true
end

main:init()

os.exit(winapi.MessageLoop())

