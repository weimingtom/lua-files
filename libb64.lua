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

local function decode_cdata(data, size)
	local state_in = ffi.new'base64_decodestate'
	b64.base64_init_decodestate(state_in)
	local buf = ffi.new('uint8_t[?]', math.floor(size / 4 * 3))
	local sz = b64.base64_decode_block(data, size, buf, state_in)
	return buf, sz
end

local function decode_string(s)
	return ffi.string(decode_cdata(s, #s))
end

if not ... then
	assert(decode_string'YW55IGNhcm5hbCBwbGVhc3VyZS4=' == 'any carnal pleasure.')
	assert(decode_string'YW55IGNhcm5hbCBwbGVhc3VyZQ==' == 'any carnal pleasure')
	assert(decode_string'YW55IGNhcm5hbCBwbGVhc3Vy' == 'any carnal pleasur')
	assert(decode_string'YW55IGNhcm5hbCBwbGVhc3U=' == 'any carnal pleasu')
	assert(decode_string'YW55IGNhcm5hbCBwbGVhcw==' == 'any carnal pleas')
end

return {
	decode_string = decode_string,
	decode_cdata = decode_cdata,
	lib = b64,
}

