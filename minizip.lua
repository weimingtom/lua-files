--low level minizip binding. zip standard here: http://www.pkware.com/documents/casestudies/APPNOTE.TXT
local ffi = require'ffi'
local glue = require'glue'
require'minizip_h'
local C = ffi.load'minizip'
local M = {C = C}

local errors = {
	[C.UNZ_ERRNO] = 'errno',
	[C.UNZ_END_OF_LIST_OF_FILE] = 'end of list',
	[C.UNZ_PARAMERROR] = 'invalid argument',
	[C.UNZ_BADZIPFILE] = 'bad zip file',
	[C.UNZ_INTERNALERROR] = 'internal error',
	[C.UNZ_CRCERROR] = 'crc error',
}

local function checkh(h)
	if h ~= nil then return h end
	error('minizip error')
end

local function check_function(check, ret)
	return function(ret)
		if check(ret) then return ret end
		error(string.format('minizip error %d: %s', ret, errors[ret or 'unknown error']))
	end
end

local checkz   = check_function(function(ret) return ret == 0 end)
local checkpoz = check_function(function(ret) return ret >= 0 end)
local checkeol = check_function(function(ret) return ret == 0 or ret == C.UNZ_END_OF_LIST_OF_FILE end)

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

--from zlib_h.lua so we don't have to import it (you'd probably not want to change these in most cases)
local Z_DEFLATED            = 8
local Z_DEFAULT_COMPRESSION = -1
local Z_MAX_WBITS           = 15
local Z_DEFAULT_STRATEGY    = 0

local default_add_options = {
	date = nil,                           --table in os.date() format (if missing, dosDate will be used)
	dosDate = 0,                          --date in DOS format
	internal_fa = 0,                      --2 bytes bitfield. format depends on versionMadeBy.
	external_fa = 0,                      --4 bytes bitfield. format depends on versionMadeBy.
	extrafield_local = nil,               --cdata
	extrafield_local_size = 0,            --autocomputed if extrafield_local is a string
	extrafield_global = nil,              --cdata
	extrafield_global_size = 0,           --autocomputed if extrafield_global is a string
	comment = nil,                        --string/char*
	method = Z_DEFLATED,                  --0 = store
	level = Z_DEFAULT_COMPRESSION,        --0..9
	raw = false,                          --write raw data
	windowBits = -Z_MAX_WBITS,            -- -8..-15
	memLevel = 8,                         --1..9 (1 = min. speed, min. memory; 9 = max. speed, max. memory)
	strategy = Z_DEFAULT_STRATEGY,        --see zlib_h.lua
	password = nil,                       --encrypt file with a password
	crc = 0,                              --number; needed for encryption if a password is set
	versionMadeBy = 0,                    --version of the zip standard to use. look at section 4.4.2 of the standard.
	flagBase = 0,                         --2 byte "general purpose bit flag"
	zip64 = true,                         --enable support for files larger than 4G
}

function M.zip_add_file(file, t)
	if type(t) == 'string' then
		t = glue.update({filename = t}, default_add_options)
	else
		t = glue.update({}, default_add_options, t)
	end
	assert(t.filename, 'filename missing')

	local info = ffi.new'zip_fileinfo'
	if t.date then
		info.dosDate = 0
		info.tmz_date.tm_sec   = t.date.sec
		info.tmz_date.tm_min   = t.date.min
		info.tmz_date.tm_hour  = t.date.hour
		info.tmz_date.tm_mday  = t.date.day
		info.tmz_date.tm_mon   = t.date.month - 1
		info.tmz_date.tm_year  = t.date.year
	else
		info.dosDate = t.dosDate
	end
	info.internal_fa = t.internal_fa
	info.external_fa = t.external_fa

	if type(t.extrafield_local) == 'string' then
		t.extrafield_local_size = t.extrafield_local_size or #t.extrafield_local
	elseif t.extrafield_local then
		assert(t.extrafield_local_size > 0, 'extrafield_local_size missing')
	end
	if type(t.extrafield_global) == 'string' then
		t.extrafield_global_size = #t.extrafield_global
	elseif t.extrafield_global then
		assert(t.extrafield_global_size > 0, 'extrafield_global_size missing')
	end

	checkz(C.zipOpenNewFileInZip4_64(file, t.filename, info,
			t.extrafield_local, t.extrafield_local_size, t.extrafield_global, t.extrafield_global_size,
			t.comment, t.method, t.level, t.raw,
			t.windowBits, t.memLevel, t.strategy,
			t.password, t.crc, t.versionMadeBy, t.flagBase, t.zip64))
end

function M.zip_write_cdata(file, data, sz)
	checkz(C.zipWriteInFileInZip(file, data, sz))
end

function M.zip_write(file, s)
	M.zip_write_cdata(file, s, #s)
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
	write_cdata = M.zip_write_cdata,
	write = M.zip_write,
	close_file = M.zip_close_file,
	close_file_raw = M.zip_close_file_raw,
}})

--unzip interface

function M.unzip_open(filename)
	return ffi.gc(checkh(C.unzOpen64(filename)), M.unzip_close)
end

function M.unzip_close(file)
	checkz(C.unzClose(file))
	ffi.gc(file, nil)
end

--return the number of entries in the zip file and the global comment
function M.unzip_get_global_info(file)
	local info = ffi.new'unz_global_info64'
	checkz(C.unzGetGlobalInfo64(file, info))
	local sz = info.size_comment
	local buf = ffi.new('uint8_t[?]', sz)
	sz = checkpoz(C.unzGetGlobalComment(file, buf, sz))
	local comment = sz > 0 and ffi.string(buf, sz) or nil
	local entries = info.number_entry
	return {
		entries = tonumber(entries),
		comment = comment,
	}
end

function M.unzip_first_file(file)
	checkz(C.unzGoToFirstFile(file))
	return true
end

function M.unzip_next_file(file)
	return checkeol(C.unzGoToNextFile(file)) == 0 or nil
end

function M.unzip_locate_file(file, filename, case_sensitive)
	return checkeol(C.unzLocateFile(file, filename, case_sensitive and 1 or 2)) == 0
end

function M.unzip_get_file_pos(file)
	local pos = ffi.new'unz64_file_pos'
	checkz(C.unzGetFilePos64(file, pos))
	return pos
end

function M.unzip_goto_file_pos(file, pos)
	checkz(C.unzGoToFilePos64(file, pos))
end

function M.unzip_get_file_info(file)
	local info = ffi.new'unz_file_info64'
	checkz(C.unzGetCurrentFileInfo64(file, info, nil, 0, nil, 0, nil, 0))
	local filename     = info.size_filename > 0 and ffi.new('uint8_t[?]', info.size_filename) or nil
	local file_extra   = info.size_filename > 0 and ffi.new('uint8_t[?]', info.size_file_extra) or nil
	local file_comment = info.size_file_comment > 0 and ffi.new('uint8_t[?]', info.size_file_comment) or nil
	checkz(C.unzGetCurrentFileInfo64(file, info,
								filename,     info.size_filename,
								file_extra,   info.size_file_extra,
								file_comment, info.size_file_comment))

	return {
		version        = info.version,
		version_needed = info.version_needed,
		flag    = info.flag,
		method  = info.compression_method,
		dosDate = info.dosDate,
		crc     = info.crc,
		compressed_size   = tonumber(info.compressed_size),
		uncompressed_size = tonumber(info.uncompressed_size),
		internal_fa = info.internal_fa,
		external_fa = info.external_fa,
		date = {
			sec  = info.tmu_date.tm_sec,
			min  = info.tmu_date.tm_min,
			hour = info.tmu_date.tm_hour,
			day  = info.tmu_date.tm_mday,
			mon  = info.tmu_date.tm_mon + 1,
			year = info.tmu_date.tm_year,
		},
		filename = filename     and ffi.string(filename, info.size_filename),
		extra    = file_extra   and ffi.string(file_extra, info.size_file_extra),
		comment  = file_comment and ffi.string(file_comment, info.size_file_comment),
	}
end

function M.unzip_get_file_size(file)
	local info = ffi.new'unz_file_info64'
	checkz(C.unzGetCurrentFileInfo64(file, info, nil, 0, nil, 0, nil, 0))
	return tonumber(info.uncompressed_size)
end

function M.unzip_get_zstream_pos(file)
	return tonumber(C.unzGetCurrentFileZStreamPos64(file))
end

function M.unzip_open_file(file, password, raw, method, level)
	raw = raw or 0
	method = method or ffi.new'uint32_t[1]'
	level = level or ffi.new'uint32_t[1]'
	checkz(C.unzOpenCurrentFile3(file, method, level, raw, password))
	return method, level
end

function M.unzip_close_file(file)
	checkz(C.unzCloseCurrentFile(file))
end

function M.unzip_read_cdata(file, buf, sz)
	return checkpoz(C.unzReadCurrentFile(file, buf, sz))
end

function M.unzip_tell(file)
	return C.unztell64(file)
end

function M.unzip_eof(file)
	return C.unzeof(file) == 1
end

function M.unzip_get_local_extra_field(file, buf, sz)
	if not buf then
		sz = sz or checkpoz(C.unzGetLocalExtrafield(file, nil, 0))
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

--unzip hi-level API

function M.unzip_files(file)
	local more = M.unzip_first_file(file)
	return function()
		if not more then return end
		local info = M.unzip_get_file_info(file)
		more = M.unzip_next_file(file)
		return info
	end
end

function M.unzip_uncompress(file)
	local sz = M.unzip_get_file_size(file)
	local buf = ffi.new('char[?]', sz)
	assert(M.unzip_read_cdata(file, buf, sz) == sz)
	return ffi.string(buf, sz)
end

ffi.metatype('unzFile_s', {__index = {
	close = M.unzip_close,
	get_global_info = M.unzip_get_global_info,
	--file catalog
	first_file = M.unzip_first_file,
	next_file = M.unzip_next_file,
	locate_file = M.unzip_locate_file,
	get_file_pos = M.unzip_get_file_pos,
	goto_file_pos = M.unzip_goto_file_pos,
	get_file_info = M.unzip_get_file_info,
	unzip_get_file_size = M.unzip_get_file_size,
	get_zstream_pos = M.unzip_get_zstream_pos,
	--file i/o
	open_file = M.unzip_open_file,
	close_file = M.unzip_close_file,
	read = M.unzip_read,
	tell = M.unzip_tell,
	eof = M.unzip_eof,
	get_local_extra_field = M.unzip_get_local_extra_field,
	get_offset = M.unzip_get_offset,
	set_offset = M.unzip_set_offset,
	--hi-level API
	files = M.unzip_files,
	uncompress = M.unzip_uncompress,
}})

function M.open(filename, mode)
	if not mode or mode == 'r' then
		return M.unzip_open(filename)
	elseif mode == 'w' then
		return M.zip_open(filename)
	elseif mode == 'a' then
		return M.zip_open(filename, 'add_files')
	else
		error("invalid mode. nil, 'r', 'w', 'a', expected.")
	end
end

if not ... then require'minizip_test' end

return M
