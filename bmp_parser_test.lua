local bmp = require'bmp'

if not ... then
local pp=require'pp'.pp
local readfile=require'glue'.readfile
for _,f in ipairs{
	'sample.bmp',
} do
	print(f,'----------------------------')
	pp(assert(decode(assert(readfile('test_images/'..f)))))
end
end
