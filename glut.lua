local ffi = require'ffi'
local glut = ffi.load'glut32'

ffi.cdef[[
void glutSolidTeapot(GLdouble size);
void glutWireTeapot(GLdouble size);
]]

return glut
