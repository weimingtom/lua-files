local bmpconv = require'bmpconv'
local glue = require'glue'

local pixel_formats = glue.index{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr'}

for src in pairs(pixel_formats) do
	for dst in pairs(pixel_formats) do
		if src ~= dst and not bmpconv.converters[src][dst] then
			print('not implemented', src, dst)
		end
		if src ~= dst and not glue.index(bmpconv.preferred_formats[src])[dst] then
			print('not preferred', src, dst)
		end
	end
end
