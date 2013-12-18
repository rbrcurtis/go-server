Controller = require './framework/Controller'

db     = require 'lib/db'
error  = require 'lib/error'
Cookie = require 'lib/Cookie'

{PageResult, EventResult} = require 'lib/results'

module.exports = class EventController extends Controller

	since:
		before: ['ensureIsAuthenticated']
		handler: (callback) ->
			
			q = { created: { $gt: new Date(+this.request.params.since) }, receivers: this.user }

			debug 'events', 'since', @request.params.since, q
			
			db.events.find(q).sort(created:1).limit(41).exec (err, events) =>
				debug 'events', 'since results', err, events?.length
				if err then return callback err
				if events.length > 40 then return callback error.precondition "too many results"
				return callback err, new PageResult events, (event) -> new EventResult event


