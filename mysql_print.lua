--mysql table pretty printing

local function ellipsis(s,n)
	return #s > n and (s:sub(1,n-3) .. '...') or s
end

local align = {}

function align.left(s,n)
	s = tostring(s)
	s = s..(' '):rep(n - #s)
	return ellipsis(s,n)
end

function align.right(s,n)
	s = tostring(s)
	s = (' '):rep(n - #s)..s
	return ellipsis(s,n)
end

function align.center(s,n)
	s = tostring(s)
	local total = n - #s
	local left = math.floor(total / 2)
	local right = math.ceil(total / 2)
	s = (' '):rep(left)..s..(' '):rep(right)
	return ellipsis(s,n)
end

local function fit(s,n,al)
	return align[al or 'left'](s,n)
end

local function print_table(fields, rows, minsize, print)
	print = print or _G.print
	minsize = minsize or math.huge
	local max_sizes = {}
	for i=1,#rows do
		for j=1,#fields do
			max_sizes[j] = math.min(minsize, math.max(max_sizes[j] or 0, #tostring(rows[i][j])))
		end
	end

	local totalsize = 0
	for j=1,#fields do
		max_sizes[j] = math.max(max_sizes[j] or 0, #fields[j])
		totalsize = totalsize + max_sizes[j] + 3
	end

	print()
	local s, ps = '', ''
	for j=1,#fields do
		s = s .. fit(fields[j], max_sizes[j], 'center') .. ' | '
		ps = ps .. ('-'):rep(max_sizes[j]) .. ' + '
	end
	print(s)
	print(ps)

	for i=1,#rows do
		local s = ''
		for j=1,#fields do
			local val = rows[i][j]
			local align = type(rows[i][j]) == 'number' and 'right' or 'left'
			s = s .. fit(val, max_sizes[j], align) .. ' | '
		end
		print(s)
	end
	print()
end

local function invert_table(fields, rows, minsize)
	local ft, rt = {'field'}, {}
	for i=1,#rows do
		ft[i+1] = tostring(i)
	end
	for j=1,#fields do
		local row = {fields[j]}
		for i=1,#rows do
			row[i+1] = rows[i][j]
		end
		rt[j] = row
	end
	return ft, rt
end

local function format_cell(v)
	return v == nil and 'NULL' or v
end

local function print_result(res, minsize, print)
	local fields = {}
	for i,field in res:fields() do
		fields[i] = field.name
	end
	local rows = {}
	for i,row in res:rows'n' do
		local t = {}
		for j=1,#row do
			t[j] = format_cell(row[j])
		end
		rows[i] = t
	end
	print_table(fields, rows, minsize, print)
end

local function print_statement(stmt, minsize, print)
	stmt:store_result()
	local res = stmt:bind_result()
	local fields = {}
	for i,field in stmt:result_fields() do
		fields[i] = field.name
	end
	local rows = {}
	while stmt:fetch() do
		local row = {}
		for i=1,#fields do
			row[i] = format_cell(res:get(i, 's'))
		end
		rows[#rows+1] = row
	end
	stmt:close()
	print_table(fields, rows, minsize, print)
end

return {
	fit = fit,
	table = print_table,
	result = print_result,
	statement = print_statement,
}

