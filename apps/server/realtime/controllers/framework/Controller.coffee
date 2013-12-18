

module.exports = class Controller
	
	# 'message type':'handler'
	# handlers should all be of the format (context, arguments)
	@handlers: {}
	
	constructor: (@io) ->
		
	onConnection: (user, socket) ->
			
		for message, handler of @constructor.handlers
			debug 'realtime', 'handle'.yellow, message, handler
			do (message, handler) =>
				socket.on message, =>
					@[handler].apply @, [{user,socket}, arguments...]
					
	send: (room, type, message) ->
		
		debug 'realtime', 'sending', typeof message, message
		
		@io.sockets.in(room).emit type, message
