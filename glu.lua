local ffi = require'ffi'
require'glu_h'
local ok,glu = pcall(ffi.load,'glu') --platform-independent?
if not ok then glu = ffi.load('glu32') end --windows
return glu
