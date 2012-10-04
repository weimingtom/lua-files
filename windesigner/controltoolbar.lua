setfenv(1, require'designer')

ControlToolbar = class(winapi.Toolbar)

function ControlToolbar:__init(parent)
	local iml = winapi.ImageList{32,32, colors = '256bit'}
	local img = winapi.LoadBitmapFromFile('designer/icons/all.bmp')
	iml:add{bitmap = img}

	ControlToolbar.__index.__init(self, {
		parent = parent,
		image_list = iml,
		align = 'left',
		customizable = true,
		alt_drag = true,
		no_divider = true,
		custom_erase_background = true,
		--multiline = true,
	})
	--self.items:add{i = i}
	for i=1,20 do
		self.items:add{i = i, state = 'TBSTATE_WRAP|TBSTATE_ENABLED'}
	end
end

--[[
function classlb:on_double_click()
	local class = classes[classlb.items.selected]
	if not class then return end
	local ctl = class{parent = designer, x = 340, y = math.random(10, 300)}
	ctl.__designer = designer
	--designer.selection_panel:send_to_back()
end

for name, class in pairs(classes) do
	classlb.items:add(name)
end
]]
