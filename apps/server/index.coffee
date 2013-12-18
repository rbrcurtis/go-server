module.exports =
	name: 'server'
	cluster: true
	run: ->
		HttpServer = require './http/HttpServer'
		RealtimeServer = require './realtime/RealtimeServer'

		server = new HttpServer()
		server.start()

		realtime = new RealtimeServer(server.app)
		realtime.start()


