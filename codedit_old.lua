
--block selection --------------------------------------------------------------------------------------------------------

local block_selection = glue.update({}, selection)

local function clamp_pos(editor, line, col)
	line = clamp(line, 1, editor:last_line())
	col = clamp(col, 1, 1/0)
	return line, col
end

function block_selection:reset(line, col)
	line, col = clamp_pos(self.editor, line, col)
	self.anchor_line, self.anchor_col = line, col
	self.line1, self.col1 = line, col
	self.line2, self.col2 = line, col
end

function block_selection:move(line, col)
	self.line1, self.col1 = self.anchor_line, self.anchor_col
	self.line2, self.col2 = clamp_pos(self.editor, line, col)
	--switch cursors if the end cursor is above the start cursor
	if self.line1 > self.line2 then
		self.line1, self.col1, self.line2, self.col2 =
		self.line2, self.col2, self.line1, self.col1
	end
end

function block_selection:cols(line)
	return self.editor:block_cols(line, self.line1, self.col1, self.line2, self.col2)
end

function block_selection:select()
	return self.editor:select_block(self.line1, self.col1, self.line2, self.col2)
end

function block_selection:remove()
	if self:isempty() then return end
	self.editor:remove_block(self.line1, self.col1, self.line2, self.col2)
	self:reset(self.line1, self.col1)
end






--multiple selections ----------------------------------------------------------------------------------------------------

function editor:select_selections(selections)
	selections = selections or self.selections
	if not next(next(selections)) then --fast path for single selection
		return next(selections):select()
	end
	--sort selections by first endpoint
	local t = {}
	for sel in pairs(selections) do
		t[#t+1] = sel
	end
	table.sort(t, function(sel1, sel2)
		return sel1.line1 < sel2.line1 or (sel1.line1 == sel2.line1 and sel1.col1 < sel2.col1)
	end)
	--concatenate selection lines
	local last_line = 1
	local lines = {''}
	for _,sel in ipairs(t) do
		local slines = sel:select()
		if sel.line1 == last_line then
			--selection is on the same line as the last selection: join the lines
			lines[#lines] = lines[#lines] .. table.remove(slines, 1)
		end
		glue.extend(lines, slines)
		last_line = sel.line2
	end
	return lines
end

function editor:selections_overlap(sel1, sel2)
	--check if line ranges overlap
	if sel1.line2 < sel2.line1 or sel2.line2 < sel1.line1 then
		return false
	end
	--lines overlap, check if line segments overlap
	for line1, col11, col12 in sel1:lines() do
		for line2, col21, col22 in sel2:lines() do
			if line1 == line2 and not (col12 < col21 or col22 < col11) then
				return true
			end
		end
	end
	return false
end

function editor:merge_selections()

end
