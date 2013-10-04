--[[
--take the line segment starting at col and move it to target_vcol, indenting or outdenting it
function buffer:align_left(line, col, target_vcol)
	local vcol = self:visual_col(line, col)
	if vcol < target_vcol then --indent
		if self:use_tabs(line, col) then
			local tabs, spaces = tabs.tabs_and_spaces(vcol, target_vcol, self.editor.tabsize)
			print(tabs, spaces)
			self:insert_string(line, col, string.rep('\t', tabs) .. string.rep(' ', spaces))
		else
			self:insert_string(line, col, string.rep(' ', target_vcol - vcol))
		end
	elseif vcol > target_vcol then --outdent
		local s = self:getline(line)
		if not s then return end
		local i = str.byte_index(s, col)
		if not i then return end
		--remove spaces and tabs until no more vcols left to remove. if necessary break the last tab into spaces.
		local vcols_to_remove = vcol - target_vcol
		local chars_to_remove = 0
		local spaces_to_add = 0
		i = str.prev(s, i)
		vcol = vcol - 1
		while i and str.isspace(s, i) do
			local vcols = str.istab(s, i) and self:tab_width(vcol - self.editor.tabsize + 1) or 1
			print(vcol, str.istab(s, i), vcols, vcols_to_remove)
			vcols_to_remove = vcols_to_remove - vcols
			vcol = vcol - vcols
			chars_to_remove = chars_to_remove + 1
			if vcols_to_remove <= 0 then
				--print('>', vcol, vcols, vcols_to_remove, str.istab(s, i))
				spaces_to_add = vcols
				break
			end
			i = str.prev(s, i)
		end
		print(vcols_to_remove, chars_to_remove, spaces_to_add)
		self:remove_string(line, col - chars_to_remove, line, col)
		if spaces_to_add > 0 then
			self:insert_string(line, col - chars_to_remove, string.rep(' ', spaces_to_add))
		end
	else
		self:insert_string(line, col, '\t')
	end
end

function buffer:align_right(line, col, target_vcol)

end

function buffer:delete_
	if self.auto_indent then
		local indent_col = self.buffer:indent_col(self.line)
		if indent_col > 1 and self.col >= indent_col then --cursor is after the indent whitespace, we're auto-indenting
			indent = self.buffer:sub(self.line, 1, indent_col - 1)
		end
	end


function buffer:
	if false and (self.tab_align_list or self.tab_align_args) then
		--look in the line above for the vcol of the first non-space char after at least one space or '(', starting at vcol
		if str.first_nonspace(s1) < #s1 then
			local vcol = self.buffer:visual_col(self.line, self.col)
			local col1 = self.buffer:real_col(self.line-1, vcol)
			local stage = 0
			local s0 = self.buffer:getline(self.line-1)
			for i in str.byte_indices(s0) do
				if i >= col1 then
					if stage == 0 and (str.isspace(s0, i) or str.isascii(s0, i, '(')) then
						stage = 1
					elseif stage == 1 and not str.isspace(s0, i) then
						stage = 2
						break
					end
					col1 = col1 + 1
				end
			end
			if stage == 2 then
				local vcol1 = self.buffer:visual_col(self.line-1, col1)
				c = string.rep(' ', vcol1 - vcol)
			else
				c = string.rep(' ', self.editor.tabsize)
			end
		end
	elseif self.tabs == 'never' then
		self:insert_string(string.rep(' ', self.editor.tabsize))
		return
	elseif self.tabs == 'indent' then
		if self.buffer:getline(self.line) and self.col > self.buffer:indent_col(self.line) then
			self:insert_string(string.rep(' ', self.editor.tabsize))
			return
		end
	end
	self:insert_string'\t'
]]




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
