local ft = require'freetype'

local lib = ft:new()

local face = lib:new_face'media/fonts/DejaVuSerif.ttf'
for i=0,face.num_charmaps-1 do
	face:select_charmap(face.charmaps[i].encoding)
	for char, glyph in face:chars() do
		print(char, glyph)
	end
end

face:free()
lib:free()
