--http date parsing to os.date() format except fields yday & isdst
module('httpdate',package.seeall)
require'glue'

local wdays = index{'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'}
local weekdays = index{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'}
local months = index{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}

function check(w,d,mo,y,h,m,s)
	return w and mo and d >= 1 and d <= 31 and y <= 9999
			and h <= 23 and m <= 59 and s <= 59
end

--wkday "," SP date1 SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP "GMT"
--eg. Sun, 06 Nov 1994 08:49:37 GMT
function rfc1123date(s)
	local w,d,mo,y,h,m,s = s:match'([A-Za-z]+), (%d+) ([A-Za-z]+) (%d+) (%d+):(%d+):(%d+) GMT'
	d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
	w = wdays[w]
	mo = months[mo]
	if check(w,d,mo,y,h,m,s) then
		return {wday = w, day = d, year = y, month = mo,
				hour = h, min = m, sec = s}
	end
end

--weekday "," SP 2DIGIT "-" month "-" 2DIGIT SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP "GMT"
--eg. Sunday, 06-Nov-94 08:49:37 GMT
function rfc850date(s)
	local w,d,mo,y,h,m,s = s:match'([A-Za-z]+), (%d+)%-([A-Za-z]+)%-(%d+) (%d+):(%d+):(%d+) GMT'
	d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
	w = weekdays[w]
	mo = months[mo]
	if y then y = y + (y > 50 and 1900 or 2000) end
	if check(w,d,mo,y,h,m,s) then
		return {wday = w, day = d, year = y,
				month = mo, hour = h, min = m, sec = s}
	end
end

--wkday SP month SP ( 2DIGIT | ( SP 1DIGIT )) SP 2DIGIT ":" 2DIGIT ":" 2DIGIT SP 4DIGIT
--eg. Sun Nov  6 08:49:37 1994
function asctimedate(s)
	local w,mo,d,h,m,s,y = s:match'([A-Za-z]+) ([A-Za-z]+) +(%d+) (%d+):(%d+):(%d+) (%d+)'
	d,y,h,m,s = tonumber(d),tonumber(y),tonumber(h),tonumber(m),tonumber(s)
	w = wdays[w]
	mo = months[mo]
	if check(w,d,mo,y,h,m,s) then
		return {wday = w, day = d, year = y, month = mo,
				hour = h, min = m, sec = s}
	end
end

function date(s)
	return rfc1123date(s) or rfc850date(s) or asctimedate(s)
end

if false and not ... then
	require'unit'
	local d = {day = 6, sec = 37, wday = 1, min = 49, year = 1994, month = 11, hour = 8}
	test(date'Sun, 06 Nov 1994 08:49:37 GMT', d)
	test(date'Sunday, 06-Nov-94 08:49:37 GMT', d)
	test(date'Sun Nov  6 08:49:37 1994', d)
	test(date'Sun Nov 66 08:49:37 1994', nil)
	test(date'SundaY, 06-Nov-94 08:49:37 GMT', nil)
end

for k,v in pairs(rfc850date'Sunday, 06-Nov-94 08:49:37 GMT') do print(k,v) end
