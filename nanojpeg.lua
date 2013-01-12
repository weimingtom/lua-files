--nanojpeg2 binding, see csrc/nanojpeg2.c
local ffi = require'ffi'
local glue = require'glue'
local C = ffi.load'nanojpeg2'

ffi.cdef[[
typedef struct nj_context_t_ nj_context_t;
nj_context_t* njInit(void);
int njDecode(nj_context_t* nj, const void* jpeg, const int size);
int njGetWidth(nj_context_t* nj);
int njGetHeight(nj_context_t* nj);
int njIsColor(nj_context_t* nj);
unsigned char* njGetImage(nj_context_t* nj);
int njGetImageSize(nj_context_t* nj);
void njDone(nj_context_t* nj);
]]

local error_messages = {
	'Not a JPEG file',
	'Unsupported format',
	'Out of memory',
	'Internal error',
	'Syntax error',
}

local function load_(data, sz)
	return glue.fcall(function(finally)
		local nj = C.njInit()
		finally(function() C.njDone(nj) end)
		local res = C.njDecode(nj, data, sz)
		assert(res == 0, error_messages[res])
		local w = C.njGetWidth(nj)
		local h = C.njGetHeight(nj)
		local iscolor = C.njIsColor(nj) == 1
		local pixel_format = iscolor and 'rgb' or 'g'
		local rowsize = w * (iscolor and 3 or 1)
		local sz = C.njGetImageSize(nj)
		local tmpdata = C.njGetImage(nj) --pointer to RGB888[] or G8[]
		local data = ffi.new('uint8_t[?]', sz)
		ffi.copy(data, tmpdata, sz)
		return {
			w = w, h = h,
			data = data,
			size = sz,
			format = {
				pixel = pixel_format,
				rows = 'top_down',
				rowsize = rowsize,
			},
		}
	end)
end

local function load(t)
	if t.string then
		return load_(t.string, #t.string)
	elseif t.cdata then
		return load_(t.cdata, t.size)
	elseif t.path then
		local data = assert(glue.readfile(t.path))
		return load_(data, #data)
	else
		error'unspecified data source: path, string or cdata expected'
	end
end

if not ... then require'nanojpeg_test' end

return {
	load = load,
	C = C,
}

