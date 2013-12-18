MemoryTokenTable = require './MemoryTokenTable'
error = require 'lib/error'

class RateLimiter
	
	constructor: (table) ->
		@tokens = table ? new MemoryTokenTable()
	
	throttle: (request, callback) ->
		if request.auth.method isnt 'apiKey' then return callback(null, null)
		@tokens.get request.auth.value, (err, bucket) =>
			if err? then return callback err
			if bucket.consume(1) is false then return callback error.tooManyRequests()
			callback null, {capacity: bucket.capacity, remaining: bucket.remaining}

module.exports = RateLimiter
