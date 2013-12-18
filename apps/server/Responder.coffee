async = require 'async'

{Stream}  = require 'stream'

error = require 'lib/error'
Cookie = require 'lib/Cookie'

# messageBus = require 'lib/messageBus'
db = require 'lib/db'

module.exports = class Responder
	
	constructor: (@request, @httpRequest, @httpResponse) ->
	
	finish: (err, result = null) =>
		if err then return @failure err
		return @success result


	success: (result) ->
		@request.result = result
		
		if not result?
			@httpResponse.send(204)
			return
			
		if result instanceof Cookie
			@httpResponse.cookie result.name, result.value, result.data
			result = 204
		
		@_finish 'success', result
	
	failure: (err) ->
		
		debug 'requests', 'request error', err?.name, err?.status, err?.message
		if err instanceof error.RequestError
			# do nothing! leave it alone!
		else if err instanceof Error
			switch err.name
				when 'ValidationError'
					# logError err
					# for key, val of err then console.log key, '=', val
					obj = err.errors[_.keys(err.errors)[0]]
					err = error.badRequest "#{obj.path} #{obj.type}"
				when 'MongoError'
					if err.err?.match /duplicate/
						err = error.badRequest "the specified value is already in use and must be unique."
					else
						logError 'not sure how to handle response for', err
						debug 'requests', 'request error', err
						err = error.badRequest "#{err.err}"
				else
					logError err
					err = error.server()
		else
			err = error.badRequest(err)

		@request.error = err


		@_finish 'failure', err.message, err.status

	_finish: (status, send...) ->
		finished = new Date()
		
		_.extend @request,
			status:   status
			finished: finished
			duration: finished.getTime() - @request.started.getTime()

		@httpResponse.header 'X-Response-Time', @request.duration
		# log '[requests]', @request.id, (@request.user?.username or 'unknown'), @httpRequest.method, 'request to', @httpRequest.path, (@httpRequest.request.body or 'empty'), 'response-time', @request.duration
		log '[requests]', @request.id, 'response-time', @request.duration
		@httpResponse.send(send...)

		# debug 'event', 'committing events', (a?._id for a in @request.events)
		
		async.map @request.events, 
			(event, callback) =>
				unless event then return callback()
				event.commited = true
				db.events.save event, (err, event) ->
					if err? then callback(err)
					# messageBus.events.publish event
					callback null, event
		
			(err, events) =>
				if err? then logError err
				
		# messageBus.requests.publish @request
	
	

