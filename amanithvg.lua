require'amanithvg_h_ext'
local API = require'openvg'
local ffi = require'ffi'
local C = ffi.load'libAmanithVG'
local M = API.bind(C)

if not ... then require'amanithvg_test' end

return M
