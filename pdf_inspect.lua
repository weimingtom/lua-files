local glue = require'glue'

local function inspect(s)
	local xref_offset = s:match('startxref\r?\n(%d+)\r?\n%%%%EOF\r?\n?$', -32) + 1
	local first, n, ofs = s:match('^xref\r?\n(%d+)%s+(%d+)\r?\n()', xref_offset)
	first = tonumber(first)
	n = tonumber(n)
	for i=ofs,ofs+n*20-1,20 do
		local ofs, gen, flag = s:match('^(%d+) (%d+) ([nf]).-\n', i)
		if flag == 'n' then
			ofs = tonumber(ofs) + 1
			gen = tonumber(gen)
			local n, g, contents = s:match('^(%d+)%s+(%d+)%s+obj\r?\n(.-)\r?\nendobj\r?\n', ofs)
			n = tonumber(n)
			g = tonumber(g)
			assert(n == first)
			assert(g == gen)
			print''
			print(n)
			print''
			print(contents)
			print''
		end
		first = first + 1
	end
end

--inspect(glue.readfile'test.pdf')
inspect(glue.readfile'csrc/luahpdf/demo/line_demo.pdf')
