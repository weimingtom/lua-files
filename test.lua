--go@ x:\work\lua-files\bin\luajit.exe -bl test.lua
local function invert2(data, sz, stride, dstride) -- ga -> ag and back
	local dj = 0
	for j=0,sz-1,stride do
		for i=0,0+stride-1,2 do
			data[dj+i],data[dj+i+1] = data[j+i+1],data[j+i]
		end
		dj = dj+dstride
	end
	return data, sz
end
