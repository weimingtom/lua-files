--codedit: a composable code editor with many features.
local glue = require'glue'
local lines = require'codedit_lines'
local move = require'codedit_move'
local edit = require'codedit_edit'

local editor = {}

function editor:new(s)
	return glue.inherit({
		s = s,
	}, editor)
end

local caret = {}

function caret:new(editor, gettime)
	return glue.inherit({
		editor = editor,
		lnum = 1,
		cnum = 1,
		wanted_cnum = 1,
		tabsize = 3,
		insert_mode = true,
		restrict_right = true,
		restrict_down = false,
		gettime = gettime,
	}, caret)
end

function caret:move_right()
	self.start_clock = self.gettime()
	self.lnum, self.cnum, self.vcnum = move.right(self.editor.s, self.lnum, self.cnum, self.restrict_right, self.restrict_down)
	self.wanted_cnum = self.cnum
end

function caret:move_left()
	self.start_clock = self.gettime()
	self.lnum, self.cnum, self.vcnum = move.left(self.editor.s, self.lnum, self.cnum)
	self.wanted_cnum = self.cnum
end

function caret:move_up(vcnum)
	self.start_clock = self.gettime()
	self.lnum, self.cnum, self.vcnum = move.up(self.editor.s, self.lnum, self.cnum, vcnum or self.vcnum, self.tabsize)
end

function caret:move_down(vcnum)
	self.start_clock = self.gettime()
	self.lnum, self.cnum, self.vcnum = move.down(self.editor.s, self.lnum, self.cnum,
													vcnum or self.vcnum, self.tabsize, self.restrict_down, self.restrict_right)
end

function caret:page_up()

end

function caret:page_down()

end

function caret:move_home()

end

function caret:move_end()

end

function caret:scroll_up()

end

function caret:scroll_down()

end


function tokens(s, lexer)
	local lxsh = require'lxsh'
	lexer = lxsh.lexers[lexer]
	local match = lexer.gmatch((s:gsub('\t', '   ')))
	return function()
		local kind, s, lnum, cnum = match()
		return lnum, cnum, s, kind
	end
end


if not ... then require'codedit_demo' end

return {
	line_pos = line_pos,

	editor = editor,
	viewer = require'codedit_view',
	caret = caret,
}

