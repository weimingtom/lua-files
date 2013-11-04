local codedit = require'codedit'
local player = require'cairo_player'
local glue = require'glue'

--player.continuous_rendering = false
player.show_magnifier = false

--config
player.key_bindings = {
	['ctrl+N'] = 'new_tab',
	['ctrl+W'] = 'close_tab',
	['ctrl+tab'] = 'next_tab',
	['ctrl+shift+tab'] = 'prev_tab',
}

--state
player.tabs = {}
player.active_tab = nil
player.editors = {}
player.config = {}

function player:getconf(var)
	return self.config[var]
end

function player:load_config(filename)
	if glue.fileexists(filename) then
		local conf = assert(loadfile(filename))()
		glue.update(player.config, conf)
	end
end

function player:load_config_files()
	--local
	self:load_config('.codedit_conf.lua')
	--user
	self:load_config(os.getenv('HOMEPATH') .. '/.codedit_conf.lua')
	--global
	--TODO: winapi.registry
end

function player:perform_shortcut(shortcut, ...)
	local command = self.key_bindings[shortcut]
	if command and self[command] then
		self[command](self)
	end
end

function player:new_tab(filename, i)
	i = i or #self.tabs + 1
	local tabname = filename or 'Untitled'

	local editor = self:code_editor{
		id = 'editor_' .. i,
		filename = filename,
		view = {
			x = 0, y = 26,
			w = self.w,
			h = self.h,
			font_file     = self:getconf'font_file',
			eol_markers   = self:getconf'eol_markers',
			minimap       = self:getconf'minimap',
		},
	}

	glue.update(self.key_bindings, self:getconf'key_bindings')

	--override shortcut handling with local methods
	local parent = self
	function editor:perform_shortcut(shortcut, ...)
		parent:perform_shortcut(shortcut, ...)
		codedit.perform_shortcut(self, shortcut, ...)
	end

	table.insert(self.tabs, tabname)
	self.active_tab = #self.tabs

	table.insert(self.editors, editor)
end

function player:close_tab()
	if #self.tabs == 0 then return end
	local editor = self.editors[self.active_tab]
	table.remove(self.editors, self.active_tab)
	table.remove(self.tabs, self.active_tab)
	self.active_tab = math.min(self.active_tab, #self.tabs)
end

function player:next_tab()
	self.active_tab = (((self.active_tab + 1) - 1) % #self.tabs) + 1
end

function player:prev_tab()
	self.active_tab = (((self.active_tab - 1) - 1) % #self.tabs) + 1
end

function player:on_render(cr)

	if #self.tabs == 0 then
		self:load_config_files()
		self:new_tab()
	end

	self.active_tab = self:tablist{id = 'tabs', x = 0, y = 0, w = self.w, h = 26,
											values = self.tabs, selected = self.active_tab}

	local editor = self.editors[self.active_tab]
	editor.view.x = 0
	editor.view.y = 26
	editor.view.w = self.w
	editor.view.h = self.h

	self:code_editor(editor)

end

player:play()

