RateLimiter = require '../../rateLimiting/RateLimiter'
limiter = new RateLimiter()

module.exports = () ->
	return (req, res, next) ->
		limiter.throttle req.request, (err, limit) ->
			if err? then return next(err)
			if limit?
				res.header(CONFIG.http.headers.rateLimit, limit.capacity)
				res.header(CONFIG.http.headers.rateLimitRemaining, limit.remaining)
			next()
