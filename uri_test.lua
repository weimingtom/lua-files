require'unit'
local uri = require'uri'

test(uri.escape('some&some=other', '&='), 'some%26some%3dother')
test(uri.format{scheme = 'http', host = 'dude.com', path = '/', fragment = 'top'}, 'http://dude.com/#top')
test(uri.format{scheme = 'http', host = 'dude.com', path = '//../.'}, 'http://dude.com//../.')
test(uri.format{scheme = 'http', host = 'dude.com', query = 'a=1&b=2 3'}, 'http://dude.com?a=1&b=2+3')
test(uri.format{scheme = 'http', host = 'dude.com', args = {b='2 3',a='1'}}, 'http://dude.com?a=1&b=2+3')
test(uri.format{scheme = 'http', host = 'dude.com', path = '/redirect',
		args={a='1',url='http://dude.com/redirect?a=1&url=http://dude.com/redirect?a=1&url=https://dude.com/'}},
	'http://dude.com/redirect?a=1&url=http%3a%2f%2fdude.com%2fredirect%3fa=1%26url=http%3a%2f%2fdude.com%2fredirect%3fa=1%26url=https%3a%2f%2fdude.com%2f')
local function revtest(s,t)
	local pt = uri.parse(s)
	test(pt, t)
	test(uri.format(pt), s)
end
revtest('', {})
revtest(':', {scheme=''})
revtest('s:', {scheme='s'})
revtest('//', {host=''})
revtest('//:', {host='',port=''})
revtest('//@', {user='',host=''})
revtest('//:@', {user='',pass='',host=''})
revtest('//h', {host='h'})
revtest('//u@h', {user='u',host='h'})
revtest('//u:@h', {user='u',pass='',host='h'})
revtest('//:p@h', {user='',pass='p',host='h'})
revtest('/', {path='/',segments={'',''}})
revtest(':/', {scheme='',path='/',segments={'',''}})
revtest('s:', {scheme='s'})
revtest(':relative/path', {scheme='',path='relative/path',segments={'relative','path'}})
revtest('://:@?#', {scheme='',user='',pass='',host='',query='',fragment='',args={}})
revtest('://:@/?#', {scheme='',user='',pass='',host='',path='/',query='',fragment='',args={},segments={'',''}})
revtest('s://u:p@h/p?q=#f', {scheme='s',user='u',pass='p',host='h',path='/p',query='q=',fragment='f',args={q=''},segments={'','p'}})
revtest('?q=', {query='q=',args={q=''}})
revtest('#f', {fragment='f'})
revtest('?q=#f', {query='q=',args={q=''},fragment='f'})
test(uri.parse'?a=1&b=2&c=&d&f=hidden&f=visible&g=a=1%26b=2', {query='a=1&b=2&c=&d&f=hidden&f=visible&g=a=1&b=2',
				args={a='1',b='2',c='',d='',f='visible',g='a=1&b=2'}})
test(uri.parse'http://user:pass@host/a/b?x=1&y=2&z&w=#fragment',
				{scheme='http',user='user',pass='pass',host='host',path='/a/b',query='x=1&y=2&z&w=',fragment='fragment',
				args={x='1',y='2',z='',w=''},segments={'','a','b'}})
