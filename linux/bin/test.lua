#!/root/lua-files/linux/bin/luajit -jv
print(package.cpath)
print(package.path)
local lpeg = require'lpeg'
print(lpeg)
local j = 0
for i=1,100000 do
    j = j + 1
end
print(j)
