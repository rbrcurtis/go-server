fs = require 'fs'
events = require 'events'
express = require 'express'

error = require 'lib/error'
uuid = require 'lib/uuid'

routes = require 'routes'

Dispatcher = require 'Dispatcher'

controllers = require 'controllers'
pipeline = require './pipeline'

module.exports = class HttpServer extends events.EventEmitter

	constructor: ->
		
		@dispatcher = new Dispatcher()
		
		opts = undefined
		if CONFIG.ssl?.enabled
			opts = {}
			opts.key = fs.readFileSync CONFIG.ssl.key
			opts.cert = fs.readFileSync CONFIG.ssl.cert
			@app = express.createServer opts
		else
			@app = express.createServer()
		
		@pipeline = [
			express.cookieParser()
			express.bodyParser()
			pipeline.createRequestObject()
			pipeline.createResponder()
			pipeline.setDefaultHeaders()
			pipeline.authenticate()
			pipeline.logRequest()
			# pipeline.throttle()
		]
		
		@app.error (err, req, res, next) ->
			if req.responder? and err instanceof error.RequestError
				req.responder.failure(err)
			else
				next(err)
		
		@_loadRoutes()
		
		@app.error (err, req, res, next) ->
			if err instanceof error.RequestError
				res.send err.message, err.status
			else next err
			
		
	start: ->
		@app.listen CONFIG.http.port, =>
			addr = @app.address()
			log "listening on http://#{addr.address}:#{addr.port}"

	_handleRequest: (req, res, next) =>
		@dispatcher.dispatch(req.request, req.user, req.responder.finish)

	_loadRoutes: ->
		for controller, actions of routes
			unless controllers[controller]?
				throw new Error("routes defined for non-existent controller #{controller}")
			for action, pattern of actions
				@_registerRoute(controller, action, pattern)
	
	_registerRoute: (controller, action, pattern) ->
		route = {controller: controller, action: action}
		[route.verb, route.pattern] = pattern.split(/\s+/, 2)
		attachRoute = (req, res, next) ->
			req.route = route
			next()
		@app[route.verb] route.pattern, attachRoute, @pipeline, @_handleRequest

