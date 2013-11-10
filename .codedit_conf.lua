--codedit_app local config file
return {
	view = {
		--codeedit_view.lua
		font_file = 'x:/work/lua-files/media/fonts/FSEX300.ttf',
		--cplayer/code_editor.lua
		eol_markers = false,
		minimap = false,
	},
	cursor = {
		--codedit_cursor.lua
		restrict_eol = true,
		restrict_eof = true,
		land_bof     = false,
		land_eof     = false,
	},
	--codeedit_editor.lua
	line_numbers = true,
	blame = false,

	filetypes = {
		lua = {
			view = {lang = 'lua'},
			cursor = {
				restrict_eol = false,
			},
		},
	}

}
