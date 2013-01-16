--image file loader: common interface for loading multiple image file formats.

local libs = {
	png = 'libpng',
	jpeg = 'turbojpeg', --alternative: 'nanojpeg'
	gif = 'giflib',
	bmp = 'bmp',
}

local function detect_type(path)
	local s = path:match'%.(%w+)$'
	s = s and s:lower()
	if s == 'jpg' then s = 'jpeg' end
	return s
end

local function load(t, opt)
	local itype = t.type
	if not itype then
		assert(t.path, 'image: missing type')
		itype = assert(detect_type(t.path), 'image: unknown file type')
	end
	local lib = assert(libs[itype], string.format('image: unsupported type %s', itype))
	local lib = require(lib)
	local img = lib.load(t, opt)
	if itype == 'gif' then
		img = img.frames[1]
	end
	return img
end

return {
	detect_type = detect_type,
	load = load,
}

