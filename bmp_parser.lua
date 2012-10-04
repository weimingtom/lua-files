--bitmap file parser in pure Lua

local function word(str, offset) --get word
  local lo = string.byte(str, offset)
  local hi = string.byte(str, offset + 1)
  return hi*256 + lo
end

local function dword(str, offset) --get dword
  local lo = word(str, offset)
  local hi = word(str, offset + 2)
  return hi*65536 + lo
end

local function parse_header(data)
	if not data:find'^BM' then return nil, 'Not a BMP file' end
	local bits_offset = word(data, 11)
	local offset = 15 --BITMAPINFOHEADER
	local w = dword(data, offset + 4)
	local h = dword(data, offset + 8)
	local bits = word(data, offset + 14)
	local comp = dword(data, offset + 16)
	return w, h, bits, comp, data:sub(bits_offset + 1)
end

-- Parse the bits of an open BMP file
local function decode(data)
	local w, h, bits, comp, data = parse_header(data)
	if not w then return w, h end
	if bits ~= 24 then return nil, 'Invalid BMP depth:' .. bits .. ' (must be 24-bit)' end
	if comp ~= 0 then return nil, 'Invalid BMP compression:' .. comp .. ' (must be uncompressed)' end
	return {
		w = w,
		h = h,
		bits = bits,
		data = ffi.new('unsigned char[?]', #data, data)
	}
end

return {
	parse_header = parse_header,
	decode = decode,
}

