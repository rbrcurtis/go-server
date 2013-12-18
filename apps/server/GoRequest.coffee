os = require 'os'
uuid = require 'lib/uuid'

db = require "lib/db"

module.exports = class GoRequest
	
	constructor: (route, httpRequest) ->
		@id = uuid.generate()
		@auth = 'none'
		@status = 'pending'
		@started = new Date()
		@params = {}
		@context = {}
		@events = []
		@process =
			platform: process.platform
			arch:     process.arch
			pid:      process.pid
			uptime:   process.uptime()
			machine:  os.hostname()
			loadavg:  os.loadavg()
			totalmem: os.totalmem()
			freemem:  os.freemem()

		@controller = route.controller
		@action = route.action
		@http =
			address: httpRequest.header('x-forwarded-for') ? httpRequest.connection.remoteAddress
			pattern: route.pattern
			url: httpRequest.url
			verb: httpRequest.method
			headers: _.clone httpRequest.headers
			cookies: _.clone httpRequest.cookies

		for key in ['params', 'query', 'body', 'files', 'fields']
			@[key] = httpRequest[key]


	addCreated: (document, receivers, meta, callback) ->
		@_createEvent(document, 'create', receivers, meta, callback)
	
	addUpdated: (document, receivers, meta, callback) ->
		@_createEvent(document, 'update', receivers, meta, callback)
	
	addDeleted: (document, receivers, meta, callback) ->
		@_createEvent(document, 'delete', receivers, meta, callback)
		
	_createEvent: (document, action, receivers, meta, callback) ->
		debug 'events', "creating event", document, action, receivers, meta, callback:typeof callback
		
		db.events.create document, action, @id, @user, receivers, meta, (err, event) =>
			debug 'events', "created event\n", err, event
			if err then return callback? err
			
			@events.push event

			callback? arguments...

		
