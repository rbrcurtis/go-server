async = require 'async'

controllers = require 'controllers'
filters = require 'filters'

error = require 'lib/error'

arrayify = (value) ->
	return if _.isArray(value) then value else [value]

module.exports = class Dispatcher
	
	dispatch: (request, user, callback) ->
		
		debug 'dispatch', 'dispatch', request, user
		
		unless controllers[request.controller]?
			return callback new Error("request received for non-existent controller #{request.controller}, what the actual fuck is going on")
			
		controller = new controllers[request.controller](request, user)
		spec = controller[request.action]
		
		debug 'dispatch', 'controller', controller
		debug 'dispatch', 'spec', spec

		unless spec?
			return callback new Error("don't know how to dispatch request for action #{request.action} on #{request.controller} controller")
		unless spec.handler? and spec.handler instanceof Function
			return callback new Error("invalid action definition for #{request.action} on #{request.controller} controller")
		
		next = (err) ->
			if err then return callback err
			else 
				try
					return spec.handler.apply controller, [callback]
				catch e
					return callback error.server(e)

		
		if spec.before?
			@_executeFilterChain arrayify(spec.before), 'before', request, user, next
		else
			next()
		
	
	_createFilter: (name, request, user) ->
		unless filters[name]?
			throw new Error("invalid filter #{name} defined for #{request.action} action on #{request.controller} controller")
		return new filters[name](request, user)
	
	_executeFilterChain: (filters, method, request, user, callback) ->
		
		async.forEachSeries filters,
			(filterName, callback) =>
				filter = @_createFilter(filterName, request, user)
				unless filter[method]? and filter[method] instanceof Function
					throw new Error("filter #{filterName} was defined in the #{method} chain for #{request.action} action on #{request.controller} controller, but it has no #{method}() method")
				filter[method] callback
			callback

