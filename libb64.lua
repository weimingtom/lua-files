--libb64 ffi binding
local ffi = require'ffi'
local b64 = ffi.load'b64'

ffi.cdef[[
typedef enum
{
	step_a, step_b, step_c, step_d
} base64_decodestep;

typedef struct
{
	base64_decodestep step;
	char plainchar;
} base64_decodestate;

void base64_init_decodestate(base64_decodestate* state_in);
int base64_decode_value(char value_in);
int base64_decode_block(const char* code_in, const int length_in, char* plaintext_out, base64_decodestate* state_in);

typedef enum
{
	step_A, step_B, step_C
} base64_encodestep;

typedef struct
{
	base64_encodestep step;
	char result;
	int stepcount;
} base64_encodestate;

void base64_init_encodestate(base64_encodestate* state_in);
char base64_encode_value(char value_in);
int base64_encode_block(const char* plaintext_in, int length_in, char* code_out, base64_encodestate* state_in);
int base64_encode_blockend(char* code_out, base64_encodestate* state_in);
]]

local function toobig(work, bufsize)
	bufsize = bufsize or 65536
	local buf = ffi.new('uint8_t[?]', bufsize)
	local function load(data, size)
		data = ffi.cast('uint8_t*', data)
		while size > bufsize do
			work(data, bufsize)
			size = size - bufsize
			data = data + bufsize
		end
		if size > 0 then
			work(data, size)
		end
	end
	local function flush()

	end
	return function(data, size)
		if data then
			return load(data, size)
		else
			return flush()
		end
	end
end

local function decode_cdata(data, size, buf)
	local state_in = ffi.new'base64_decodestate'
	b64.base64_init_decodestate(state_in)
	buf = buf or ffi.new('uint8_t[?]', math.floor(size / 4 * 3))
	local sz = b64.base64_decode_block(data, size, buf, state_in)
	return buf, sz
end

local function decode(data, size, buf)
	if type(data) == 'string' then
		size = math.min(size or #data, #data)
	end
	return decode_cdata(data, size, buf)
end

local function encoder(bufsize)
	local state_in = ffi.new'base64_encodestate'
	b64.base64_init_encodestate(state_in)
	bufsize = bufsize or 65536
	local buf = ffi.new('uint8_t[?]', bufsize)
	local maxsize = math.floor(bufsize / 2)
	local sz
	return function(data, size)
		if data then
			while size > maxsize do
				sz = b64.base64_encode_block(data + size, maxsize, buf, state_in)
				size = size - maxsize
			end
			sz = b64.base64_encode_block(data + size, size, buf, state_in)
			return buf, sz
		else
			if not sz then return buf, 0 end
			sz = sz + b64.base64_encode_blockend(buf + sz, state_in)
			buf[sz] = 0
			return buf, sz
		end
	end
end

local function encode(data, size, bufsize)
	local encode = encoder(bufsize)
	encode(data, size)
	return encode()
end

if not ... then require'libb64_test' end

return {
	decode = decode,
	decode_cdata = decode_cdata,
	encode_string = encode_string,
	encode_cdata = encode_cdata,
	lib = b64,
}

