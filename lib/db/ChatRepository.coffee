mongoose = require 'mongoose'

uuid = require 'lib/uuid'

EmbeddedDocumentRepository = require './framework/EmbeddedDocumentRepository'

ObjectId = mongoose.Schema.ObjectId

plugins = require './plugins'

ChatSchema = new mongoose.Schema
	_id: ObjectId
	
	text: 
		type: String
		required: true
	
	user: 
		type: ObjectId
		required: true

	created:
		type: Date
		default: -> new Date()
		
ChatSchema.documentType = 'Chat'
ChatSchema.strict = true
ChatSchema.plugin(plugins.changeTracking)


module.exports = new class ChatRepository extends EmbeddedDocumentRepository
	
	schema: ChatSchema

	setup: ->
		@_schema = ChatSchema
		@_parent = 'games'
		@_path   = 'chats'
	
	create: (game, user, text, callback) ->
		debug 'chat', 'create called for game', game?._id, 'user', user?._id, 'text', text
		unless game? and user? and text?.length then return

		id = uuid.generate()
		game.chats.push
			_id:     id
			user:    user
			text:    text

		game.save (err, game) =>
			if err? then return callback(err, null)
			callback null, game.chats.id(id)

