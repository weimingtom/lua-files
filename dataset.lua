--in-memory datasets by Cosmin Apreutesei (unlicensed)
--features:
-- row-level change tracking with the ability to apply, merge or cancel changes.
-- apply changes with failure tracking and retry.
-- sorting by multiple columns; row order is preserved with inserts and updates.
--

--[[
TODO:
- master-detail
	- ?
- grouping
- undo/redo

- memory model
- mysql model
- firebird model
	- load field metadata
	- auto-generate select queries with sorting and filtering
	- auto-generate insert, update, delete queries

]]
local glue = require'glue'

--in-memory data model

local dataset = {}

function dataset:new(fields)
	self = glue.inherit(self)
	self.fields = self:parse_fields(fields)
	self:clear()
	return self
end

--clear the dataset and the change log
function dataset:clear()
	self.records = {}
	self.deleted = {}
	self.row_order_lost = nil --flag indicating that original_row lost its meaning
end

function dataset:row_count()
	return #self.records
end

function dataset:insert(row, record)
	if self.sort_cmp then
		row = self:sorted_row(record)
	else
		row = row or #self.records + 1
	end
	assert(row >= 1 and row <= #self.records + 1)
	record = record or {}
	record.status = 'new'
	table.insert(self.records, row, record)
end

function dataset:append(record)
	self:insert(#self.records + 1, record)
end

function dataset:delete(row)
	assert(row >= 1 and row <= #self.records)
	local record = self.records[row]
	table.remove(self.records, row)
	if record.status == 'changed' then
		table.insert(self.deleted, record.old)
	elseif not record.status then
		table.insert(self.deleted, record)
	end
end

function dataset:update(row)
	assert(row >= 1 and row <= #self.records)
	local record = self.records[row]
	if not record.status then
		record.status = 'changed'
		record.old = record
	end
end

function dataset:move(row1, row2)
	assert(not self.sort_cmp)
	assert(row1 >= 1 and row1 <= #self.records)
	assert(row2 >= 1 and row2 <= #self.records + 1)
	if row1 == row2 then return end
	local record = table.remove(self.records, row1)
	table.insert(self.records, row2, record)
	self.row_order_lost = true
end

function dataset:updated(row) --TODO: change this API
	assert(row >= 1 and row <= #self.records)
	local record = self.records[row]
	if not record.status then return end
	if self.sort_cmp then
		self:move(row, self:sorted_row(record))
	end
end

--merge changes back into the datset: remove any traces of record change without applying the changes
function dataset:merge()
	for row, record in ipairs(self.records) do
		record.status = nil
		record.old = nil
		record.original_row = row
		record.fail = nil
		record.fail_count = nil
	end
	self.deleted = {}
	self.row_order_lost = nil
end

--cancel changes: revert the dataset to the original state, before any changes were made
function dataset:cancel()
	assert(not self.dirty)
	--remove added records and revert updated ones
	local i = 1
	while self.records[i] do
		local record = self.records[i]
		if record.status == 'new' then
			table.remove(self.records, i)
		else
			if record.status == 'changed' then
				self.records[i] = record.old
			end
			i = i + 1
		end
	end
	--add deleted records back to their original places, or at the end, if row order was lost
	for i,record in ipairs(self.deleted) do
		local row = self.row_order_lost and #self.records + 1 or record.original_row
		table.insert(self.records, row, record)
	end
	--remove traces of record change
	self:merge()
end

function dataset:exec(cmd, record) end --stub

--apply changes to the backend, and log any failures
function dataset:apply()
	local fail_count = 0
	local success_count = 0
	for i = #self.deleted, 1, -1 do
		local record = self.deleted[i]
		if exec('delete', record) then
			table.remove(self.deleted, i)
			success_count = success_count + 1
		else
			record.fail = true
			record.fail_count = (record.fail_count or 0) + 1
			fail_count = fail_count + 1
		end
	end
	for row,record in ipairs(self.records) do
		if record.status then
			if exec(record.status == 'new' and 'insert' or 'update', record) then
				record.status = nil
				record.old = nil
				record.original_row = row
				success_count = success_count + 1
			else
				record.fail = true
				record.fail_count = (record.fail_count or 0) + 1
				fail_count = fail_count + 1
			end
		end
	end
	self.row_order_lost = success_count > 0 and self.fail_count > 0
	return self.fail_count == 0, fail_count, success_count
end

--field-based access

function dataset:parse_fields(fields)
	if type(fields) == 'string' then
		local t = {}
		local i = 1
		for name in glue.gsplit(fields, ',') do
			name = glue.trim(name)
			local field = {name = name, index = i}
			t[name] = field
			t[i] = field
			i = i + 1
		end
		return t
	else
		return fields
	end
end

function dataset:col(field_name)
	return self.fields[field_name].index
end

function dataset:get(row, field_name)
	return self.records[row][self:col(field_name)]
end

function dataset:set(row, field_name, value)
	assert(row >= 1 and row <= #self.records)
	assert(self.records[row].status)
	self.records[row][self:col(field_name)] = value
end

--given a list of fields and their direction, return a comparator function that compares two records.
function dataset:comparator(arg)
	local t = {} --{col1, 'asc' | 'desc', ...}
	if type(arg) == 'string' then --'field1[:asc|:dsc],...'
		for s in glue.gsplit(arg, ',') do
			s = glue.trim(s)
			local field, dir = s:match'^([^%:]+):?(.*)$'
			assert(dir == '' or dir == 'asc' or dir == 'desc')
			dir = dir == '' and 'asc' or dir
			table.insert(t, self:col(field))
			table.insert(t, dir)
		end
	else
		for i = 1, #arg, 2 do
			local field, dir = arg[i], arg[i+1]
			assert(dir == 'asc' or dir == 'desc')
			t[i], t[i+1] = self:col(field), dir
		end
	end
	if #t == 2 then --simple case: sort by one column
		local col, dir = t[1], t[2]
		if dir == 'asc' then
			return function(rec1, rec2)
				return rec1[col] < rec2[col]
			end
		else
			return function(rec1, rec2)
				return rec2[col] < rec1[col]
			end
		end
	end
	local function cmp(rec1, rec2, i)
		i = i or 1
		if i > #t then
			return false --all fields are equal
		end
		local col, dir = t[i], t[i+1]
		if rec1[col] == rec2[col] then
			return cmp(rec1, rec2, i + 2)
		elseif dir == 'asc' then
			return rec1[col] < rec2[col]
		else
			return rec2[col] < rec1[col]
		end
	end
	return cmp
end

--sort by one or more fields (expressed as a string or table) or by a custom function
function dataset:sort(arg)
	local cmp
	if type(arg) == 'function' then
		cmp = arg
	else
		cmp = self:comparator(arg)
	end
	table.sort(self.records, cmp)
	self.sort_cmp = cmp
	self.row_order_lost = true
end

--binary search over sorted rows

local function sorted_row_rec(rec, records, cmp, i, j)
	local m = math.floor((i + j) / 2 + 0.5)
	if cmp(rec, records[m]) then
		return m == i and i or sorted_row_rec(rec, records, cmp, i, m - 1) --tail call
	else
		return m == j and j + 1 or sorted_row_rec(rec, records, cmp, m + 1, j) --tail call
	end
end

local function sorted_row(rec, records, cmp)
	if #records == 0 then return 1 end
	return sorted_row_rec(rec, records, cmp, 1, #records)
end

function dataset:sorted_row(rec)
	return sorted_row(rec, self.records, self.sort_cmp)
end




if not ... then

local ds = dataset:new()

--not tracking deleting new records
ds:clear()
ds:insert()
assert(ds.records[1].status == 'new')
ds:delete(1)
assert(#ds.records == 0)
assert(#ds.deleted == 0)

--tracking deleting existing records and cancelling
ds:clear()
ds:insert()
ds:merge()
ds:delete(1)
assert(#ds.records == 0)
assert(ds.deleted[1].original_row == 1)
ds:cancel()
assert(not ds.records[1].status)
assert(#ds.deleted == 0)

--tracking updates and cancelling
ds:clear()
ds:insert()
ds:merge()
ds:update(1)
assert(ds.records[1].old)
assert(ds.records[1].status == 'changed')
ds:cancel()
assert(not ds.records[1].old)
assert(not ds.records[1].status)

--sorting
ds = dataset:new('id,name,descr')
for i=40000,1,-4 do
	ds:append{i-3,'foo','bla bla bla'}
	ds:append{i-1,'bar','bla bla bla'}
	ds:append{i-2,'bar','bla bla bla'}
	ds:append{i-0,'zab','bla bla bla'}
end
assert(ds:row_count() == 40000)
ds:merge()
ds:sort('name:desc,id:desc')

--row of sorted record
local function cmp(a, b) return a < b end
assert(sorted_row('a', {'b'}, cmp) == 1)
assert(sorted_row('b', {'a'}, cmp) == 2)
assert(sorted_row('a', {'a', 'b'}, cmp) == 2)
assert(sorted_row('a', {'a', 'a', 'a', 'b'}, cmp) == 4)
assert(sorted_row('b', {'a', 'c'}, cmp) == 2)
assert(sorted_row('d', {'a', 'c'}, cmp) == 3)

end

return dataset
