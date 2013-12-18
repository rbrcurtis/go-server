Message = require './framework/Message'

module.exports = class InviteMessage extends Message

	constructor: (@invite) ->
		super
