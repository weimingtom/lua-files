--nanojpeg binding, see: http://keyj.emphy.de/nanojpeg/
local ffi = require'ffi'
local nj = ffi.load'nanojpeg'
local glue = require'glue'
local bmpconv = require'bmpconv'

ffi.cdef[[
typedef enum _nj_result {
	NJ_OK = 0,        // no error, decoding successful
	NJ_NO_JPEG,       // not a JPEG file
	NJ_UNSUPPORTED,   // unsupported format
	NJ_OUT_OF_MEM,    // out of memory
	NJ_INTERNAL_ERR,  // internal error
	NJ_SYNTAX_ERROR,  // syntax error
	__NJ_FINISHED,    // used internally, will never be reported
} nj_result_t;

void njInit(void);
nj_result_t njDecode(const void* jpeg, const int size);
int njGetWidth(void);
int njGetHeight(void);
int njIsColor(void);
unsigned char* njGetImage(void);
int njGetImageSize(void);
void njDone(void);
]]

local error_messages = {
	[nj.NJ_NO_JPEG] = 'Not a JPEG file',
	[nj.NJ_UNSUPPORTED] = 'Unsupported format',
	[nj.NJ_OUT_OF_MEM] = 'Out of memory',
	[nj.NJ_INTERNAL_ERR] = 'Internal error',
	[nj.NJ_SYNTAX_ERROR] = 'Syntax error',
}

local function load_(data, sz, accept)
	return glue.fcall(function(finally)
		nj.njInit()
		finally(nj.njDone)

		local res = nj.njDecode(data, sz)
		if res ~= nj.NJ_OK then
			error(error_messages[res])
		end

		local data = nj.njGetImage() --pointer to RGB888[] or G8[]
		local sz = nj.njGetImageSize()
		local w = nj.njGetWidth()
		local h = nj.njGetHeight()
		local iscolor = nj.njIsColor() == 1
		local pixel_format = iscolor and 'rgb' or 'g'
		local rowsize = w * (iscolor and 3 or 1)
		local format = {pixel = pixel_format, rows = 'top_down', rowsize = rowsize}
		local data, sz, format = bmpconv.convert_best(data, sz, format, accept, true)

		return {
			w = w,
			h = h,
			format = format,
			data = data,
			size = sz,
		}
	end)
end

local function load(t, opt)
	if t.string then
		return load_(t.string, #t.string, opt and opt.accept)
	elseif t.cdata then
		return load_(t.cdata, t.size, opt and opt.accept)
	elseif t.path then
		local data = assert(glue.readfile(t.path))
		return load_(data, #data, opt and opt.accept)
	else
		error'unspecified data source: path, string or cdata expected'
	end
end

return {
	load = load,
	lib = nj,
}

