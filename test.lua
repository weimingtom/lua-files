local ffi=require'ffi'

local data = ffi.new('uint8_t[?]', 6, '\1\2\3\4\5\6')
local rows = ffi.new('uint8_t*[?]', 3)
rows[0] = data
rows[1] = data+2
rows[2] = data+4

rows2 = rows+1
print(rows2[0][0])
