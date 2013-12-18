amqp   = require 'amqp'

Message = require 'lib/messages/framework/Message'

module.exports = class MessageBus
	
	constructor: ->
		
		@_exchanges = {}
		@_queues = {}
		@_readyQueue = []
		@_subscriptions = []
		
		@_ready = false
		@_connectCalled = false
		
	_connect: ->
		@_connectCalled = true
		log "[AMQP] connecting to #{CONFIG.rabbit.host}"
		delete @_queues[key] for key of @_queues
		delete @_exchanges[key] for key of @_exchanges
			
		@_connection = amqp.createConnection(host:CONFIG.rabbit.host)
		@_connection.on 'ready', =>
			log "[AMQP] connection established to #{CONFIG.rabbit.host}"
			@_ready = true
			callback() while callback = @_readyQueue.shift()
			for args in @_subscriptions then @_subscribe args...
		@_connection.on 'error', (e) =>
			logError 'messagebus caught error', e
			@_connect()
	
	publish: (exchangeName, message) ->
		args = arguments

		@_connectExchange exchangeName, (exchange) =>
			try
				exchange.publish '#', message, {contentType: "application/json"}
			catch e
				logError 'publish error', e
				@_connect()
				@publish args...
				
	subscribe: (exchangeName, queueName = "#{APP.name}-#{exchangeName}-#{process.pid}", options = {}, handler) ->
		@_subscriptions.push arguments
		@_subscribe arguments...
	
	_subscribe: (exchangeName, queueName, options, handler) ->
		debug 'queue', 'subscribe', arguments
		@_connectQueue exchangeName, queueName, options, (queue) =>
			queue.subscribe handler
			
	_onReady: (callback) ->
		unless @_connectCalled then @_connect()
		if @_ready then return callback()
		@_readyQueue.push callback
	
	_connectQueue: (exchangeName, queueName, options, callback) ->
		@_onReady =>

			if @_queues[queueName]? then return callback(@_queues[queueName])

			@_connectExchange exchangeName, (exchange) =>
				@_connection.queue queueName, options, (queue) =>
					@_queues[queueName] = queue
					queue.bind exchange, '#'
							
					callback queue
							
	_connectExchange: (channel, callback) ->
		@_onReady =>

			if @_exchanges[channel]? then return callback(@_exchanges[channel])
		
			@_connection.exchange channel, {type: 'fanout', durable: true}, (exchange) =>
				@_exchanges[channel] = exchange
				callback(exchange)
	

