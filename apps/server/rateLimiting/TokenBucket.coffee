# Implementation based on node-restify by Mark Cavage <mcavage@gmail.com>

class TokenBucket
	
	constructor: (@capacity, @fillRate) ->
		@remaining = @capacity
		@lastFilled = Date.now()
	
	consume: (cost) ->
		@_refill()
		if cost > @remaining then return false
		@remaining -= cost
		return true
	
	_refill: ->
		now = Date.now()
		
		# Ensure the clock hasn't drifted.
		if now < @lastFilled then @lastFilled = now - 1000
		
		# If the bucket has earned additional tokens since it was last filled, fill it.
		if @remaining < @capacity
			earned = Math.floor @fillRate * ((now - @lastFilled) / 1000)
			@remaining = Math.min @capacity, @remaining + earned
			
		@lastFilled = now

module.exports = TokenBucket
