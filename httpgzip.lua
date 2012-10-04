--RFC1952 http gzip/gunzip support
require'u'
require'httpclient'

function httpclient.decoders.gzip(chunks)
	return coroutine.wrap(function()
		for chunk in chunks do
			yield(chunk)
		end
	end)
end

function httpclient.encoders.gzip(chunks)
	return coroutine.wrap(function()
		for chunk in chunks do
			yield(chunk)
		end
	end)
end

