util = require 'util'

Controller = require './framework/Controller'

db            = require 'lib/db'
{messageBus}  = require 'lib/messages'

EventResult = require 'lib/results/EventResult'

module.exports = class EventController extends Controller
	
	@handlers: {}
	
	constructor: ->
		super
		@queue = messageBus.realtimeEvents
		@queue.subscribe @_onMessage
		

	onConnection:(user) ->
		super

	_onMessage: (msg) =>
		debug 'events', 'got message', msg
		
		event = msg?.event

		if event?.receivers?.length
		
			debug 'events', "broadcasting event", result
			for receiver in event.receivers
				result = new EventResult event, receiver
				debug 'events', 'sending to', receiver, typeof receiver
				@send receiver, 'event', result
		
