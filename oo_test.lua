local oo = require'oo'

--inheritance
local c1 = oo.class()
c1.classname = 'c1'
c1.a = 1
c1.b = 1
local c2 = oo.class(c1)
c2.classname = 'c2'
c2.b = 2
c2.c = 2
assert(c2.super == c1)
assert(c2.unknown == nil)
assert(c2.a == 1)
assert(c2.b == 2)
assert(c2.c == 2)
assert(c2.init == c1.init)

--polymorphism
function c1:before_init(...) print('c1 before_init',...); self.b = ...; assert(self.b == 'o'); return self.b end
function c1:after_init() print('c1 after_init') end
function c2:before_init(...) print('c2 before_init',...); return ... end
function c2:after_init() print('c2 after_init') end
assert(c2.init ~= c1.init)
local o = c2('o')
assert(o.a == 1)
assert(o.b == 'o')
assert(o.c == 2)
assert(o.super == c2)
assert(o.unknown == nil)

--virtual properties
function o:get_x() assert(self.__x == 42) return self.__x end
function o:set_x(x) assert(x == 42) self.__x = x end
o.x = 42
assert(o.x == 42)

--stored properties
function o:set_s(s) print('set_s', s) assert(s == 13) end
o.s = 13
assert(o.s == 13)
assert(o.state.s == 13)

--inspect
print'-------------- (before collapsing) -----------------'
o:inspect()

--detach
o:detach()
assert(rawget(o, 'a') == 1)
assert(rawget(o, 'b') == 'o')
assert(rawget(o, 'c') == 2)

--inherit, not overriding
local c3 = oo.class()
c3.c = 3
o:inherit(c3)
assert(o.c == 2)

--inherit, overriding
o:inherit(c3, true)
assert(o.c == 3)

print'--------------- (after collapsing) -----------------'
o:inspect()

