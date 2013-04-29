--minizip binding (zip.h and unzip.h)
local ffi = require'ffi'
local glue = require'glue'
local zlib = require'zlib'
require'minizip_h'
local C = ffi.load'minizip'
local M = {C = C}

errors = {
	[C.UNZ_ERRNO] = 'errno',
	[C.UNZ_EOF] = 'eof',
	[C.UNZ_PARAMERROR] = 'invalid argument',
	[C.UNZ_BADZIPFILE] = 'bad zip file',
	[C.UNZ_INTERNALERROR] = 'internal error',
	[C.UNZ_CRCERROR] = 'crc error',
}

local function checkh(h)
	if h ~= nil then return h end
	error('minizip error')
end

local function checkz(ret)
	if ret == 0 then return end
	error(string.format('minizip error %d: %s', ret, errors[ret or 'unknown error']))
end

local function checkpoz(ret)
	if ret >= 0 then return ret end
	error(string.format('minizip error %d', ret))
end

local append_flags = {
	create = C.APPEND_STATUS_CREATE,
	create_after = APPEND_STATUS_CREATEAFTER,
	add_files = APPEND_STATUS_ADDINZIP,
}

function M.zip_open(filename, append)
	return ffi.gc(checkh(C.zipOpen64(filename, append_flags[append or 'create'])), M.zip_close)
end

function M.zip_close(file, global_comment)
	checkz(C.zipClose(file, global_comment))
	ffi.gc(file, nil)
end

local default_add_options = {
	date = nil,                           --table in os.date() format (if missing, current date will be used)
	internal_file_attr = 0,               --bitfield?
	external_file_attr = 0,               --bitfield?
	extrafield_local = nil,               --cdata
	extrafield_local_size = 0,            --autocomputed if extrafield_local is a string
	extrafield_global = nil,              --cdata
	extrafield_global_size = 0,           --autocomputed if extrafield_global is a string
	comment = nil,                        --string/char*
	method = 'deflate',                   --'deflate', 'store'
	level = zlib.C.Z_DEFAULT_COMPRESSION, --0..9
	raw = false,                          --write raw data
	windowBits = -zlib.C.Z_MAX_WBITS,     -- -8..-15
	memLevel = 8, --1..9 (1 = min. speed, min. memory; 9 = max. speed, max. memory)
	strategy = zlib.C.Z_DEFAULT_STRATEGY, --see zlib_h.lua
	password = nil,                       --encrypt file with a password
	crc = 0,                              --number; needed for encryption if a password is set
	versionMadeBy = 0,                    --?
	flagBase = 0,                         --?
	zip64 = true,                         --enable support for files larger than 4G
}

local methods = {
	deflate = zlib.C.Z_DEFLATED,
	store = 0,
}

function M.zip_add_file(file, t)
	if type(t) == 'string' then
		t = glue.update({filename = t}, default_add_options)
	else
		t = glue.update({}, default_add_options, t)
	end
	assert(t.filename, 'filename missing')

	local info = ffi.new'zip_fileinfo'
	info.dosDate = t.date and 0 or 1
	if t.date then
		info.tmz_date.tm_sec   = t.date.sec
		info.tmz_date.tm_min   = t.date.min
		info.tmz_date.tm_hour  = t.date.hour
		info.tmz_date.tm_mday  = t.date.day
		info.tmz_date.tm_mon   = t.date.month - 1
		info.tmz_date.tm_year  = t.date.year
	end
	info.internal_fa = t.internal_file_attr
	info.external_fa = t.external_file_attr

	if type(t.extrafield_local) == 'string' then
		t.extrafield_local_size = t.extrafield_local_size or #t.extrafield_local
	elseif t.extrafield_local then
		assert(t.extrafield_local_size, 'extrafield_local_size missing')
	end
	if type(t.extrafield_global) == 'string' then
		t.extrafield_global_size = #t.extrafield_global
	elseif t.extrafield_global then
		assert(t.extrafield_global_size, 'extrafield_global_size missing')
	end

	t.method = assert(methods[t.method], 'invalid method')

	checkz(C.zipOpenNewFileInZip4_64(file, t.filename, info,
			t.extrafield_local, t.extrafield_local_size, t.extrafield_global, t.extrafield_global_size,
			t.comment, t.method, t.level, t.raw,
			t.windowBits, t.memLevel, t.strategy,
			t.password, t.crc, t.versionMadeBy, t.flagBase, t.zip64))
end

function M.zip_write(file, data, sz)
	sz = sz or #data
	checkz(C.zipWriteInFileInZip(file, data, sz))
end

function M.zip_close_file(file)
	checkz(C.zipCloseFileInZip(file))
end

function M.zip_close_file_raw(file, uncompressed_size, crc32)
	checkz(C.zipCloseFileInZipRaw64(file, uncompressed_size, crc32))
end

ffi.metatype('zipFile_s', {__index = {
	close = M.zip_close,
	add_file = M.zip_add_file,
	write = M.zip_write,
	close_file = M.zip_close_file,
	close_file_raw = M.zip_close_file_raw,
}})

function M.unzip_open(filename)
	return ffi.gc(checkh(C.unzOpen64(filename)), M.unzip_close)
end

function M.unzip_close(file)
	checkz(C.unzClose(file))
	ffi.gc(file, nil)
end

function M.unzip_get_global_info(file, info)
	info = info or ffi.new'unz_global_info64[1]'
	checkz(C.unzGetGlobalInfo64(file, info))
	return info
end

function M.unzip_get_global_comment(file)
	local sz = 4096
	local buf = ffi.new('char[?]', sz)
	sz = checkpoz(C.unzGetGlobalComment(file, buf, sz))
	return ffi.string(buf, sz)
end

function M.unzip_first_file(file)
	checkz(C.unzGoToFirstFile(file))
end

function M.unzip_next_file(file)
	local ret = C.unzGoToNextFile(file)
	assert(ret == 0 or ret == C.UNZ_END_OF_LIST_OF_FILE)
	return ret == 0
end

function M.unzip_locate_file(file, filename, case_sensitive)
	local ret = C.unzLocateFile(file, filename, case_sensitive and 1 or 2)
	assert(ret == 0 or ret == C.UNZ_END_OF_LIST_OF_FILE)
	return ret == 0
end

function M.unzip_get_file_pos(file, pos)
	pos = pos or ffi.new'unz64_file_pos[1]'
	checkz(C.unzGetFilePos64(file, pos))
	return pos
end

function M.unzip_goto_file_pos(file, pos)
	checkz(C.unzGoToFilePos64(file, pos))
end

function M.unzip_get_file_info(file, info, filename, filename_sz, extra_field, extra_field_sz, comment, comment_sz)
	info = info or ffi.new'unz_file_info64[1]'
	filename_sz = filename_sz or 4096
	filename = filename or ffi.new('char[?]', filename_sz)
	extra_field_sz = extra_field_sz or 4096
	extra_field = extra_field or ffi.new('char[?]', extra_field_sz)
	comment_sz = comment_sz or 4096
	comment = comment or ffi.new('char[?]', comment_sz)
	checkz(C.unzGetCurrentFileInfo64(file, info, filename, filename_sz, extra_field, extra_field_sz, comment, comment_sz))
end

function M.unzip_get_zstream_pos(file)
	return C.unzGetCurrentFileZStreamPos64(file)
end

function M.unzip_open_file(file, password, raw, method, level)
	raw = raw or 0
	checkz(C.unzOpenCurrentFile3(file, method, level, raw, password))
	return method, level
end

function M.unzip_close_file(file)
	checkz(C.unzCloseCurrentFile(file))
end

function M.unzip_read(file, buf, sz)
	sz = checkpoz(C.unzReadCurrentFile(file, buf, sz))
	return buf, sz
end

function M.unzip_bytes(file, buf, sz)
	if not buf then
		sz = sz or 65536
		buf = ffi.new('char[?]', sz)
	end
	return function()
		local _, read_sz = M.unzip_read(file, buf, sz)
		if read_sz == 0 then return end
		return ffi.string(buf, read_sz)
	end
end

function M.unzip_tell(file)
	return C.unztell64(file)
end

function M.unzip_eof(file)
	return C.unzeof(file) == 1
end

function M.unzip_get_local_extra_field(file, buf, sz)
	if not buf then
		sz = checkpoz(C.unzGetLocalExtrafield(file, nil, 0))
		buf = ffi.new('char[?]', sz)
	end
	sz = checkpoz(C.unzGetLocalExtrafield(file, buf, sz))
	return buf, sz
end

function M.unzip_get_offset(file)
	return C.unzGetOffset64(file)
end

function M.unzip_set_offset(file)
	C.unzSetOffset64(file, pos)
end

ffi.metatype('unzFile_s', {__index = {
	close = M.unzip_close,
	get_global_info = M.unzip_get_global_info,
	get_global_comment = M.unzip_get_global_comment,
	first = M.unzip_first_file,
	next = M.unzip_next_file,
	locate = M.unzip_locate_file,
	get_file_pos = M.unzip_get_file_pos,
	goto_file_pos = M.unzip_goto_file_pos,
	get_zstream_pos = M.unzip_get_zstream_pos,
	open_file = M.unzip_open_file,
	close_file = M.unzip_close_file,
	read = M.unzip_read,
	bytes = M.unzip_bytes,
	tell = M.unzip_tell,
	eof = M.unzip_eof,
	get_local_extra_field = M.unzip_get_local_extra_field,
	get_offset = M.unzip_get_offset,
	set_offset = M.unzip_set_offset,
}})

function M.open(filename, mode)
	if not mode or mode == 'r' or mode == 'read' then
		return M.unzip_open(filename)
	elseif mode == 'w' or mode == 'write' then
		return M.zip_open(filename, 'create')
	elseif mode == 'a' or mode == 'append' then
		return M.zip_open(filename, 'add_files')
	elseif mode == 'create_after' then
		return M.zip_open(filename, 'create_after')
	else
		error("invalid mode. nil, 'r', 'read', 'w', 'write', 'a', 'append', 'create_after' expected.")
	end
end

if not ... then require'minizip_test' end

return M
