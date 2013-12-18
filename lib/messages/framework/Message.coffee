

module.exports = class Message

	constructor: (data, msg) ->

		if msg?
			for key, val of msg
				@[key] = val

		else
			name = @constructor.name
			@messageType = name.substring(0, name.indexOf('Message'))
			@created = new Date()
