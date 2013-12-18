mongoose = require 'mongoose'

uuid = require 'lib/uuid'

EmbeddedDocumentRepository = require './framework/EmbeddedDocumentRepository'

ObjectId = mongoose.Schema.ObjectId

plugins = require './plugins'

ChannelSchema = new mongoose.Schema
	_id: ObjectId
	
	type: 
		type: String
		enum: ['android']
		required: true
	
	token: 
		type: String
		required: true

ChannelSchema.documentType = 'Channel'
ChannelSchema.strict = true
ChannelSchema.plugin(plugins.changeTracking)
ChannelSchema.plugin(plugins.timestamp)


module.exports = new class ChannelRepository extends EmbeddedDocumentRepository
	
	schema: ChannelSchema

	setup: ->
		@_schema = ChannelSchema
		@_parent = 'users'
		@_path   = 'channels'
	
	create: (user, data, callback) ->
		debug 'channels', 'create called for user', user, 'with data', data
		channel = _.find user.channels, (channel) -> return channel.token is data.token or channel.type is data.type
		if channel
			debug 'channels', 'channel already exists', channel
			channel.token = data.token

		else
			debug 'channels', user, data, callback?, false
			id = uuid.generate()
			user.channels.push
				_id:     id
				type:    data.type
				token:   data.token

		user.save (err, user) =>
			if err? then return callback(err, null)
			callback null, user.channels.id(id)

