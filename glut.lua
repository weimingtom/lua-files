local ffi = require'ffi'
require'gl_types'
local ok,glut = pcall(ffi.load,'glut') --platform-independent?
if not ok then glut = ffi.load('glut32') end --windows

ffi.cdef[[
void glutSolidTeapot(GLdouble size);
void glutWireTeapot(GLdouble size);
]]

return glut
