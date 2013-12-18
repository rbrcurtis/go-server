ALLOW_HEADERS = [
	'Content-Type'
	'X-Href'
	'x-location'
	'x-device'
	'x-version'
	'x-adblocker'
].join(', ')
EXPOSE_HEADERS = [
	'X-Request-Id'
	'X-Response-Time'
	# 'X-RateLimit-Limit'
	# 'X-RateLimit-Remaining'
].join(', ')

module.exports = () ->
	return (req, res, next) ->
		res.header('X-Powered-By', 'BigBang')
		if req.request? then res.header('X-Request-Id', req.request.id)
		
		res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE')
		res.header('Access-Control-Allow-Credentials', 'true')
		
		if req.header('Origin')
			debug 'auth', 'orogin', req.header('Origin')
			res.header('Access-Control-Allow-Origin', req.header('Origin'))
		else
			res.header('Access-Control-Allow-Origin', '*')
			
		res.header('Access-Control-Allow-Headers', ALLOW_HEADERS)
		res.header('Access-Control-Expose-Headers', EXPOSE_HEADERS)

		res.header('Pragma', 'no-cache')
			
		next()




