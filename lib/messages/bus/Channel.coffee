module.exports = class Channel
	
	constructor: (@messageBus, @exchangeName, @queueName, @MessageType, @options) ->
	
	subscribe: (handler) ->
		@messageBus.subscribe @exchangeName, @queueName, @options, (message) =>
			debug 'queue', 'received', message, 'from exchange', @exchangeName, 'queue', @queueName
			if @MessageType then handler new @MessageType(null, message) else handler message

	
	publish: (message) ->
		debug 'queue', 'publish', message, 'to', @exchangeName
		if @MessageType then unless message instanceof @MessageType
			logError "message must inherit from #{@MessageType.name}"
			return
		@messageBus.publish(@exchangeName, message)

