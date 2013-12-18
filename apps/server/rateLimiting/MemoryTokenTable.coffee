TokenBucket = require './TokenBucket'

class MemoryTokenTable
	
	constructor: ->
		@buckets = {}
	
	get: (key, callback) ->
		bucket = @buckets[key]
		unless bucket?
			bucket = new TokenBucket(CONFIG.rateLimit.burst, CONFIG.rateLimit.requestsPerSecond)
			return @set(key, bucket, callback)
		callback(null, bucket)
	
	set: (key, bucket, callback) ->
		@buckets[key] = bucket
		callback(null, bucket)

module.exports = MemoryTokenTable
