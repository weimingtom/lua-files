local bezier3_hit = require'path_bezier3_hit'

local d,x,y,t = bezier3_hit(3.5, 2.0, 0, 0, 1, 2, 3, 3, 4, 2)
local function assertf(x,y) assert(math.abs(x-y) < 0.0000001, x..' ~= '..y) end
assertf(t, 0.886311733891)
assertf(x, 3.623099)
assertf(y, 2.264984)
