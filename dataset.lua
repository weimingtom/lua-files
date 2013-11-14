--in-memory datasets by Cosmin Apreutesei (unlicensed)
--features:
-- row-level change tracking with the ability to apply, merge or cancel changes
-- apply changes with failure tracking and retry.

--[[
TODO:
- master-detail
	- ?
- grouping
- sorting
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
	self.fields = fields
	self:clear()
	return self
end

--clear the dataset and the change log
function dataset:clear()
	self.records = {}
	self.deleted = {}
	self.dirty = nil
end

function dataset:row_count()
	return #self.records
end

function dataset:insert(row)
	row = row or #self.records + 1
	assert(row >= 1 and row <= #self.records + 1)
	local record = {status = 'new'}
	table.insert(self.records, row, record)
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

--merge changes back into the datset: remove any traces of record change without applying the changes
function dataset:merge()
	for row, record in ipairs(self.records) do
		record.status = nil
		record.old = nil
		record.original_row = row
		record.fail = nil
	end
	self.deleted = {}
	self.dirty = nil
end

--cancel changes: revert the dataset to the original state, before any changes were made
function dataset:cancel()
	assert(not self.dirty)
	--TODO: unsort

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
	--add deleted records back to their original places
	for i,record in ipairs(self.deleted) do
		table.insert(self.records, record.original_row, record)
	end
	--remove traces of record change
	self:merge()
end

--apply changes to the backend, and log any failures

function dataset:exec(cmd, record) end --stub

function dataset:apply()
	local fail_count = 0
	for i = #self.deleted, 1, -1 do
		local record = self.deleted[i]
		if exec('delete', record) then
			table.remove(self.deleted, i)
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
			else
				record.fail = true
				record.fail_count = (record.fail_count or 0) + 1
				fail_count = fail_count + 1
			end
		end
	end
	self.dirty = self.fail_count > 0
	return not self.dirty, fail_count
end

--sort records

function dataset:sort(comp)
	table.sort(self.records, comp)
	--TODO: fix original_row
end

--dataset with fields

local function parse_fields(s)
	local fields = {}
	for s in glue.gsplit(s, ',') do
		local field, dir = s:match'(.-)([%>%<]$'
		table.insert(fields, field)
	end
	return fields
end

function dataset:sort_fields(fields)
	if type(fields) == 'string' then
		field = parse_fields(fields)
	end
	self:sort(function(rec1, rec2)
		--
	end)
end

--check unique keys
function dataset:check_unique(row, values)
	for i,s in ipairs(self.unique_key) do

	end
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


end

return dataset
