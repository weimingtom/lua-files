setfenv(1, require'windesigner.namespace')

ControlList = class(Window)

local control_classes = {
	Window = Window,
	Button = Button,
	CheckBox = CheckBox,
	RadioButton = RadioButton,
	GroupBox = GroupBox,
	Edit = Edit,
	ComboBox = ComboBox,
	TabControl = TabControl,
	ListBox = ListBox,
	ListView = ListView,
	Panel = Panel,
	Toolbar = Toolbar,
}

function ControlList:__init(designer)

	ControlList.__index.__init(self, {
		owner = designer.window, x = 10, y = 150, w = 100, h = 400, visible = false,
		tool_window = true,
		title = 'Controls',
		noclose = true,
	})

	self.designer = designer

	self.list = ListBox{
		parent = self, x = 0, y = 0, w = 100, h = 400,
		anchors = {left = true, top = true, right = true, bottom = true},
		free_height = true,
		sort = true,
	}

	for k in pairs(control_classes) do
		self.list.items:add(k)
	end

	function self.list:on_compare_items(i1, i2)
		print(i1, i2)
	end

	function self.list:on_double_click()
		local class = control_classes[self.items.selected]
		if class == Window then
			designer:new_window()
		else
			designer:new_control(class)
		end
	end
	--print(bit.band(GetWindowStyle(self.list.hwnd), LBS_NOTIFY))
	self.visible = true
end

