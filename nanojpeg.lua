--nanojpeg2 binding, see csrc/nanojpeg
local ffi = require'ffi'
local glue = require'glue'
local stdio = require'stdio'
local C = ffi.load'nanojpeg2'

ffi.cdef[[
typedef struct nj_context_t_ nj_context_t;
nj_context_t* njInit(void);
int njDecode(nj_context_t* nj, const void* jpeg, const int size);
int njGetWidth(nj_context_t* nj);
int njGetHeight(nj_context_t* nj);
int njIsColor(nj_context_t* nj);
uint8_t* njGetImage(nj_context_t* nj);
void njFreeImage(uint8_t* image);
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

local function decompress(data, sz, opt)
	return glue.fcall(function(finally)
		local nj = C.njInit()
		finally(function() C.njDone(nj) end)

		local res = C.njDecode(nj, data, sz)
		assert(res == 0, error_messages[res])

		local img = {}
		img.w = C.njGetWidth(nj)
		img.h = C.njGetHeight(nj)
		img.pixel = C.njIsColor(nj) == 1 and 'rgb' or 'g'
		img.stride = img.w * #img.pixel
		img.orientation = 'top_down'
		img.size = C.njGetImageSize(nj)
		img.data = C.njGetImage(nj) --pointer to RGB888[] or G8[]
		ffi.gc(img.data, C.njFreeImage)

		if opt and opt.accept then
			local bmpconv = require'bmpconv'
			img = bmpconv.convert_best(img, opt and opt.accept)
		end

		return img
	end)
end

local function load(t, opt)
	if t.string then
		return decompress(t.string, #t.string, opt)
	elseif t.cdata then
		return decompress(t.cdata, t.size, opt)
	elseif t.path then
		local data, sz = stdio.readfile(t.path)
		return decompress(data, sz, opt)
	else
		error'unspecified data source: path, string or cdata expected'
	end
end

if not ... then require'nanojpeg_test' end

return {
	load = load,
	C = C,
}

