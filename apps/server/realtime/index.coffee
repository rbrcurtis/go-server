module.exports =
	name: 'realtime'
	cluster: true
	run: ->
		RealtimeServer = require './RealtimeServer'
	
		server = new RealtimeServer()
		server.start()
