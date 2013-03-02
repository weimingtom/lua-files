--go@ bin/luajit.exe -jdump *
local x = 1234534
local y = 0
for i=1,300 do
	y = x/16
end
print(y)
