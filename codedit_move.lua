--codedit: moving the caret.
local lines = require'codedit_lines'
local move = {}

function move.left(s, lnum, cnum)
	if cnum <= 1 then
		if lnum <= 1 then
			return 1, 1
		else
			local i, j, lnum = lines.pos(s, lnum - 1)
			return lnum, j - i + 2
		end
	else
		return lnum, cnum - 1
	end
end

function move.right(s, lnum, cnum, restrict_right, restrict_down)
	local i, j, lnum1 = lines.pos(s, lnum)
	if restrict_right and lnum1 == lnum and cnum > j - i + 1 then
		if restrict_down then
			local i, j, lnum1 = lines.pos(s, lnum + 1)
			return lnum1, 1
		else
			return lnum + 1, 1
		end
	else
		return lnum, cnum + 1
	end
end

function move.up(s, lnum, cnum, vcnum, tabsize, restrict_right)
	if lnum == 1 then return lnum, cnum end
	if not vcnum then
		local i, j = lines.pos(s, lnum)
		vcnum = lines.view_cnum(s, i, j, cnum, tabsize)
	end
	lnum = lnum - 1
	local i, j = lines.pos(s, lnum)
	cnum = lines.file_cnum(s, i, j, vcnum, tabsize)
	if restrict_right and cnum > j - i + 2 then
		cnum = j - i + 2
	end
	return lnum, cnum
end

function move.down(s, lnum, cnum, vcnum, tabsize, restrict_down, restrict_right)
	if not vcnum then
		local i, j = lines.pos(s, lnum)
		vcnum = lines.view_cnum(s, i, j, cnum, tabsize)
	end
	lnum = lnum + 1
	if restrict_down then
		local i, j, lnum1 = lines.pos(s, lnum)
		lnum = lnum1
	end

	return lnum + 1, vnum
end

if not ... then require'codedit_demo' end

return move
