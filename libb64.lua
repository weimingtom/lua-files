--libb64 ffi binding
local ffi = require'ffi'
local C = ffi.load'b64'

ffi.cdef[[
typedef struct
{
	int step;
	char plainchar;
} base64_decodestate;

void base64_init_decodestate(base64_decodestate* state_in);
int base64_decode_value(char value_in);
int base64_decode_block(const char* code_in, const int length_in, char* plaintext_out, base64_decodestate* state_in);

typedef struct
{
	int step;
	char result;
	int stepcount;
} base64_encodestate;

void base64_init_encodestate(base64_encodestate* state_in);
char base64_encode_value(char value_in);
int base64_encode_block(const char* plaintext_in, int length_in, char* code_out, base64_encodestate* state_in);
int base64_encode_blockend(char* code_out, base64_encodestate* state_in);
]]

local function decode_cdata(data, size, buf, state_in)
	if size == 0 then return '' end
	state_in = state_in or ffi.new'base64_decodestate'
	C.base64_init_decodestate(state_in)
	buf = buf or ffi.new('uint8_t[?]', math.floor(size * 3 / 4))
	local sz = C.base64_decode_block(data, size, buf, state_in)
	return buf, sz
end

local function decode_string(s)
	return ffi.string(decode_cdata(s, #s))
end

local function encode_cdata(data, size, buf, state_in)
	if size == 0 then return '' end
	state_in = state_in or ffi.new'base64_encodestate'
	C.base64_init_encodestate(state_in)
	buf = buf or ffi.new('uint8_t[?]', size * 2)
	local sz = C.base64_encode_block(data, size, buf, state_in)
	sz = sz + C.base64_encode_blockend(buf + sz, state_in)
	buf[sz-1] = 0 --replace \n
	return buf, sz-1
end

local function encode_string(s)
	return ffi.string(encode_cdata(s, #s))
end

if not ... then require'libb64_test' end

return {
	decode_cdata = decode_cdata,
	encode_cdata = encode_cdata,
	decode_string = decode_string,
	encode_string = encode_string,
	C = C,
}
