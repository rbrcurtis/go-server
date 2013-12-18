
module.exports = () ->
	return (req, res, next) ->
		log '[requests]',
			req.request.id
			(req.request.user?.username or 'unknown')
			req.method
			req.path
			(unless req.path.match /^\/(login|register)/ then req.request.body or 'empty' else 'hidden')


		log '[requests]', req.request.id, 'User Agent', req.header 'user-agent'
		if req.header 'x-device' then log '[requests]', req.request.id, 'device', req.header 'x-device'
		if req.header 'x-location' then log '[requests]', req.request.id, 'location', req.header 'x-location'
		if req.header 'x-href' then log '[requests]', req.request.id, 'href', req.header 'x-href'
		if req.header 'x-version' then log '[requests]', req.request.id, 'version', req.header 'x-version'
		if req.header 'x-adblocker' then log '[requests]', req.request.id, 'adblocker', req.header 'x-adblocker'

		next()
