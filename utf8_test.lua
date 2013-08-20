local utf8 = require'utf8'

assert(utf8.next('') == nil)
assert(utf8.next('a') == 1)
assert(utf8.next('ab', 1) == 2)
assert(utf8.next('ab', 2) == nil)

assert(utf8.len('') == 0)
assert(utf8.len('a') == 1)
assert(utf8.len('ab') == 2)

assert(utf8.byte_index('', -1) == 0)
assert(utf8.byte_index('', 0) == 0)
assert(utf8.byte_index('', 1) == 1)
assert(utf8.byte_index('', 2) == 1)
assert(utf8.byte_index('abc', 3) == 3)
assert(utf8.byte_index('abc', 5) == 4)

assert(utf8.char_index('', -1) == 0)
assert(utf8.char_index('', 0) == 0)
assert(utf8.char_index('', 1) == 1)
assert(utf8.char_index('', 2) == 1)
assert(utf8.char_index('abc', 3) == 3)
assert(utf8.char_index('abc', 5) == 4)

--TODO: utf8.prev

assert(utf8.sub('abc', 1, 2) == 'ab')
assert(utf8.sub('abc', 2, 5) == 'bc')
assert(utf8.sub('abc', 2, 0) == '')
assert(utf8.sub('abc', 2, 1) == '')
assert(utf8.sub('abc', 3, 3) == 'c')

assert(utf8.contains('abcde', 3, 'cd') == true)
assert(utf8.contains('abcde', 2, '') == true)
assert(utf8.contains('abcde', 7, '') == false)

assert(utf8.count('\n\r \n \r \r\n \n\r', '\n\r') == 2)
assert(utf8.count('', 'x') == 0)

assert(utf8.find('abcde', 'cd') == 3)
assert(utf8.find('abcde', '') == 1)
assert(utf8.find('abcde', 'cd', 3) == 3)
assert(utf8.find('abcde', '', 4) == 4)
assert(utf8.find('abcde', 'cd', 3, true) == 3)
assert(utf8.find('abcde', 'cd', 4, true) == nil)
assert(utf8.find('abcde', '', 4, true) == 4)
assert(utf8.find('abcde', '', 6, true) == nil)
assert(utf8.find('abcde', '.', 1, true) == nil)

assert(utf8.find(' \t abc', '^[^\t ]') == 4)

--TODO: isvalid, next_valid, valid_byte_indices, validate

--TODO: replace, sanitize, escape, unescape, upper, lower
