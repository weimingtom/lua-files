local sha2 = require'sha2'
local glue = require'glue'

sha = {
	SHA256 = function(...) return sha2.sum(256,...) end,
	SHA384 = function(...) return sha2.sum(384,...) end,
	SHA512 = function(...) return sha2.sum(512,...) end,
}

for file in io.popen('ls media/sha2/*.dat'):lines() do
	local name, ext = file:match('^(.-)%.(.*)$')
	if ext == 'dat' then
		local s = glue.readfile(file, 'rb')
		local hashes = {}
		do
			local f = assert(io.open(name..'.info'))
			do
				local name, hash
				for line in f:lines() do
					if line:find'^SHA' then
						name = line:match'^(SHA.?.?.?)'
						hash = ''
					elseif hash then
						if #line == 0 then
							hashes[name] = hash
							hash = nil
						elseif hash then
							hash = hash .. line:match'^%s*(.-)%s*$'
						end
					end
				end
			end
			f:close()
		end

		for k,v in pairs(hashes) do
			local h = sha[k](s)
			print(file, k..'x', #s, h == v and 'ok' or h .. ' ~= ' .. v)
		end
	end
end

