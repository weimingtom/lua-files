local b64 = require'libb64'
local decode_string = b64.decode_string
local encode_string = b64.encode_string

assert(decode_string'YW55IGNhcm5hbCBwbGVhc3VyZS4=' == 'any carnal pleasure.')
assert(decode_string'YW55IGNhcm5hbCBwbGVhc3VyZQ==' == 'any carnal pleasure')
assert(decode_string'YW55IGNhcm5hbCBwbGVhc3Vy' == 'any carnal pleasur')
assert(decode_string'YW55IGNhcm5hbCBwbGVhc3U=' == 'any carnal pleasu')
assert(decode_string'YW55IGNhcm5hbCBwbGVhcw==' == 'any carnal pleas')
assert(decode_string'., ? !@#$%^& \n\r\n\r YW55IGNhcm5hbCBwbGVhcw== \n\r' == 'any carnal pleas')

assert(encode_string'any carnal pleasure.' == 'YW55IGNhcm5hbCBwbGVhc3VyZS4=')
assert(encode_string'any carnal pleasure' == 'YW55IGNhcm5hbCBwbGVhc3VyZQ==')
assert(encode_string'any carnal pleasur' == 'YW55IGNhcm5hbCBwbGVhc3Vy')
assert(encode_string'any carnal pleasu' == 'YW55IGNhcm5hbCBwbGVhc3U=')
assert(encode_string'any carnal pleas' == 'YW55IGNhcm5hbCBwbGVhcw==')

assert(decode_string(encode_string'') == '')
assert(decode_string(encode_string'x') == 'x')
assert(decode_string(encode_string'xx') == 'xx')
assert(decode_string'.!@#$%^&*( \n\r\t' == '')
