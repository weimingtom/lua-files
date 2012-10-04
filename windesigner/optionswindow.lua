setfenv(1, require'namespace')

OptionsWindow = class(Window)

function OptionsWindow:__init(info)
	OptionsWindow.__index.__init(self, info)
end


