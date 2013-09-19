--codedit measurements in the unclipped space, assuming a monospace font and fixed line height
local editor = require'codedit_editor'

editor.linesize = 1
editor.charsize = 1
editor.charvsize = 1

--width in pixels of all margins, or all left or right margins
function editor:margins_width(side)
	local w = 0
	for i,m in ipairs(self.margins) do
		w  = w + ((not side or m.side == side) and m:get_width() or 0)
	end
	return w
end

function editor:margin_coords(target_m, line)
	line = line or 1
	local y = (line - 1) * self.linesize
	if target_m.side == 'left' then
		local w = 0
		for i,m in ipairs(self.margins) do
			if m.side == 'left' then
				if m == target_m then
					return w, y
				end
				w = w + m:get_width()
			end
		end
	elseif target_m.side == 'right' then
		local w = 0
		for i = #self.margins, 1, -1 do
			local m = self.margins[i]
			if m.side == 'right' then
				if m == target_m then
					return self.clip_w - w - m:get_width(), y
				end
				w = w + m:get_width()
			end
		end
	end
	error('invalid margin')
end

function editor:buffer_coords()
	return self:margins_width'left', 0
end

--number of columns needed to fit the entire text (for computing the client area for horizontal scrolling)
local function max_visual_col(self) --self = editor
	local vcol = 0
	for line = 1, self:last_line() do
		local vcol1 = self:visual_col(line, self:last_col(line))
		if vcol1 > vcol then
			vcol = vcol1
		end
	end
	return vcol
end

function editor:buffer_dimensions()
	local maxvcol = max_visual_col(self)
	local maxline = self:last_line()

	--unrestricted cursors can enlarge the view area
	for cur in pairs(self.cursors) do
		if not cur.restrict_eol then
			maxvcol = math.max(maxvcol, cur:visual_col())
		end
		if not cur.restrict_eof then
			maxline = math.max(maxline, cur.line)
		end
	end

	local w = self.charsize * maxvcol
	local h = self.linesize * maxline

	return w, h
end

--cursor space -> view space
function editor:cell_coords(line, vcol)
	local cell_x = self.charsize * (vcol - 1)
	local cell_y = self.linesize * (line - 1)
	return cell_x, cell_y
end

function editor:cell_baseline(cell_y)
	return cell_y + self.linesize - math.floor((self.linesize - self.charvsize) / 2)
end

--view space -> cursor space
function editor:cell_at(x, y)
	local line = math.floor(y / self.linesize) + 1
	local vcol = math.floor((x + self.charsize / 2) / self.charsize) + 1
	return line, vcol
end

--text space -> view space
function editor:text_coords(line, vcol) --y is at the baseline
	local cell_x, cell_y = self:cell_coords(line, vcol)
	local baseline = self:cell_baseline(cell_y)
	return cell_x, baseline
end

function editor:caret_rect_insert_mode(cursor)
	local vcol = self:visual_col(cursor.line, cursor.col)
	local x, y = self:cell_coords(cursor.line, vcol)
	local w = cursor.caret_thickness
	local h = self.linesize
	x = x - math.floor(w / 2) --between columns
	x = x + (vcol == 1 and 1 or 0) --on col1, shift it a bit to the right to make it visible
	return x, y, w, h
end

function editor:caret_rect_over_mode(cursor)
	local vcol = self:visual_col(cursor.line, cursor.col)
	local x, y = self:text_coords(cursor.line, vcol)
	local w = 1
	local s = cursor:getline()
	local i = str.byte_index(cursor.col)
	if cursor:getline() and str.istab(s, i) then --make cursor as wide as the tabspace
		w = self:tabstop_distance(vcol - 1)
	end
	w = w * self.charsize
	local h = cursor.caret_thickness
	y = y + 1 --1 pixel under the baseline
	return x, y, w, h
end

function editor:caret_rect(cursor)
	if cursor.insert_mode then
		return self:caret_rect_insert_mode(cursor)
	else
		return self:caret_rect_over_mode(cursor)
	end
end

--selection rectangle for one selection line
function editor:selection_rect(sel, line)
	local col1, col2 = sel:cols(line)
	local vcol1 = self:visual_col(line, col1)
	local vcol2 = self:visual_col(line, col2)
	local x1 = (vcol1 - 1) * self.charsize
	local x2 = (vcol2 - 1) * self.charsize
	if line < sel.line2 then
		x2 = x2 + 0.5 --show eol as half space
	end
	local y1 = (line - 1) * self.linesize
	local y2 = line * self.linesize
	return x1, y1, x2 - x1, y2 - y1
end

