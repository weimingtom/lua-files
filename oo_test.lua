local oo = require'oo'

--inheritance
local c1 = oo.class(nil, 'c1')
c1.a = 'a.c1'
c1.b = 'b.c1'
local c2 = oo.class(c1, 'c2')
c2.b = 'b.c2'
c2.c = 'c.c2'
assert(c2.super == c1)
assert(c2.unknown == nil)
assert(c2.a == 'a.c1')
assert(c2.b == 'b.c2')
assert(c2.c == 'c.c2')
assert(c2.init == c1.init)

--polymorphism
function c1:before_init(b) print('c1 before_init', b); self.b = b return b end
function c1:after_init() print('c1 after_init') end
function c2:before_init(...) print('c2 before_init',...); return ... end
function c2:after_init() print('c2 after_init') end
assert(c2.init ~= c1.init)
local o2 = c2('b.o2')
assert(o2.a == 'a.c1')
assert(o2.b == 'b.o2')
assert(o2.c == 'c.c2')
assert(o2.super == c2)
assert(o2.unknown == nil)

--virtual properties
function o2:get_x() print('o2 get_x') return self.__x end
function o2:set_x(x) print('o2 set_x', x) self.__x = x end
o2.x = 13
assert(o2.x == 13)

--stored properties
function o2:set_s() print('o2 set_s') end
o2.s = 'z'
assert(o2.s == 'z')
assert(o2.state.s == 'z')

o2:inspect()
