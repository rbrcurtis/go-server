db = require 'lib/db'
error = require 'lib/error'

module.exports = () ->
	return (req, res, next) ->

		
		done = (err, user) ->
			if err? then return next(err)
			if user?
				req.user = user
				req.request.user = user

				user.accessed = new Date()
				try
					meta = {}
					meta.ipAddress = req.header('x-forwarded-for') or req.connection.remoteAddress
					meta.userAgent = req.header('user-agent') or req.connection.remoteAddress
					if req.header 'x-device' then meta.device = req.header 'x-device'
					if req.header 'x-location' then meta.location = JSON.parse req.header 'x-location'
					if req.header 'x-version' then meta.version = req.header 'x-version'
					if req.header 'x-adblocker' then meta.adblocker = req.header 'x-adblocker'
					user.meta = meta
				catch e
				user.save (err, user) =>
					if user? then req.user = user
					next(err)
			else next()
			

		token = req.cookies[CONFIG.cookies.auth.name]
		debug 'auth', 'token or cookies', token or req.cookies
		if not token? then return next()
		
		req.request.auth = {method: 'cookie', value: token}

		return db.users.getByToken token, done
