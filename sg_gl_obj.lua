--scenegraph/gl/obj_model: render wavefront obj files.
local SG = require'sg_gl'
local obj_loader = require 'obj_loader'
require'sg_gl_mesh'

function SG.type:obj_model(e)
	local objects = self.cache:get(e.file)
	if not objects then
		objects = obj_loader.load(e.file.path, e.file.use_cache)
		self.cache:set(e.file, objects)
	end
	self:render_object(objects)
end

if not ... then require'sg_gl_test' end

