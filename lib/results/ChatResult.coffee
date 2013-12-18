DocumentResult = require './framework/DocumentResult'

module.exports = class ChatResult extends DocumentResult
	
	constructor: (chat) ->
		unless chat? then return
		super

		for key in ['created', 'text', 'user']
			@[key] = chat[key]

