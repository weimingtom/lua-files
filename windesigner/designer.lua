io.stdout:setvbuf'no'
setfenv(1, require'windesigner.namespace')
require'winapi.windowclass'
require'winapi.buttonclass'
require'winapi.checkboxclass'
require'winapi.radiobuttonclass'
require'winapi.groupboxclass'
require'winapi.editclass'
require'winapi.comboboxclass'
require'winapi.tabcontrolclass'
require'winapi.listboxclass'
require'winapi.listviewclass'
require'winapi.menuclass'
require'winapi.panelclass'
require'winapi.toolbarclass'
require'winapi.imagelistclass'

require'winapi.messageloop'
require'winapi.resource'
require'winapi.module'
require'winapi.icon'

require'windesigner.controllist'
require'windesigner.selectionpanel'
require'windesigner.inspector'

Designer = class(Window)

function Designer:__init()
	local icon = LoadIconFromFile'designer.ico'
	Designer.__index.__init(self, {
		title = 'Designer',
		icon = icon,
		autoquit = true,
		state = 'maximized',
		visible = false,
		background = COLOR_GRAYTEXT,
	})

	--main menu
	self.window_menu = Menu{
		items = {
			{text = 'New...', on_click = function() self:new_window() end},
			{text = 'Save...', on_click = function() self:save_window() end},
			{text = 'Load...', on_click = function() self:load_window() end},
		},
	}
	self.file_menu = Menu{
		items = {
			{text = 'E&xit', on_click = function() self:close() end},
		},
	}
	local mainm = MenuBar{
		items = {
			{text = '&File', submenu = self.file_menu},
			{text = '&Window', submenu = self.window_menu},
		},
	}
	self.menu = mainm

	local h = self.h - self.client_h
	self.min_h = h
	self.max_h = h

	--settings
	self.config = {}

	--state
	self.windows = {}

	function self.on_close(_self) --as if self.window was their owner
		for w in pairs(self.windows) do
			w:close()
		end
	end

	--components
	--self.control_toolbar = ControlToolbar(self)
	self.control_list = ControlList(self)
	self.inspector = Inspector(self)

	self.visible = true
end

function Designer:on_activate_app()
	if not self.inspector then return end
	self.inspector:bring_to_front()
	self.control_list:bring_to_front()
	for win in pairs(self.windows) do
		win:bring_to_front()
	end
	if Windows.active_window then
		Windows.active_window:bring_to_front()
	end
end

DesignWindow = class(Window)

function DesignWindow:__init(designer)
	DesignWindow.__index.__init(self, {
		visible = false,
	})
	self.designer = designer
	self.selection_panel = SelectionPanel(self, designer)

	self.accelerators:add_items{
		{hotkey = 'ctrl+X', handler = self.cut_controls},
		{hotkey = 'ctrl+C', handler = self.copy_controls},
		{hotkey = 'ctrl+V', handler = self.paste_controls},
		{hotkey = 'delete', handler = self.delete_controls},
	}
end

function DesignWindow:cut_controls() self.designer:cut_controls() end
function DesignWindow:copy_controls() self.designer:copy_controls() end
function DesignWindow:paste_controls() self.designer:paste_controls() end
function DesignWindow:delete_controls() self.designer:delete_controls() end
function DesignWindow:on_destroy() self.designer:remove_window(self) end
function DesignWindow:on_activate() self.designer:select_window(self) end

function Designer:new_window()
	local window = DesignWindow(self)
	self.windows[window] = true
	window.visible = true
end

function Designer:remove_window(window)
	self.windows[window] = nil
	if not next(self.windows) then
		self:disable_tools()
		self.active_window = nil
	end
end

function Designer:load_window()
	--
end

function Designer:save_window()
	local ok, info = GetSaveFileName{
		filter = {'All Files','*.*','Lua Files','*.lua'},
	}
	if ok then
		local f = assert(io.open(info.filepath, 'w'))
		local s = self.active_window
		f:write(s)
		f:close()
	end
end

function Designer:selection_changed(controls)
	if next(controls) then
		self.inspector:inspect(controls)
	else
		self.inspector:inspect{[self.active_window] = true}
	end
end

function Designer:select_window(window)
	self.active_window = window
	self:enable_tools()
	self:selection_changed(self.active_window.selection_panel.selected_controls)
end

function Designer:enable_tools(q)
	if q == nil then q = true end
	self.inspector.enabled = q
	self.control_list.enabled = q
	--TODO: sort this out!
	--local mi = self.window_menu.items:get(2); mi.state.enabled = q
	--print(mi)
	--self.window_menu.items:set(2, mi)
	--local mi = self.window_menu.items:get(2); mi.state.enabled = q
	--self.window_menu.items:set(3, mi)
end

function Designer:disable_tools()
	self:enable_tools(false)
	self.inspector.list.items:clear()
	self:activate()
end

function Designer:copy_controls()
	self.clipboard = self.active_window.selection_panel:copy_controls()
end

function Designer:cut_controls()
	self.clipboard = self.active_window.selection_panel:cut_controls()
end

function Designer:paste_controls()
	if not self.clipboard then return end
	self.active_window.selection_panel:paste_controls(self.clipboard)
	self.clipboard = nil
end

function Designer:delete_controls()
	self.active_window.selection_panel:delete_controls()
end

function Designer:new_control(class)
	return class{parent = self.active_window}
end

local designer = Designer()


designer:new_window()
designer.active_window.rect = {200, 200, 600, 600}
designer:new_window()
designer.active_window.rect = {400, 400, 800, 800}
designer:new_control(Button):move(10, 10)
designer:new_control(Button):move(10, 40)
designer:new_control(ListView):move(100, 10)

jit.off()
os.exit(MessageLoop())

