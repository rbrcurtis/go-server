Message = require './framework/Message'

module.exports = class EventMessage extends Message

	constructor: (@event) ->
		super
