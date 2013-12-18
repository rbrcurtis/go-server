DocumentRepository = require './framework/DocumentRepository'

mongoose = require 'mongoose'
ObjectId = mongoose.Schema.ObjectId
Mixed    = mongoose.Schema.Types.Mixed

uuid = require 'lib/uuid'

plugins = require './plugins'

InviteSchema = new mongoose.Schema

	_id:	ObjectId
	
	created:
		type: Date
		default: -> new Date()
		index:
			background: true
			
	sender:
		type: ObjectId
		required: true
		index:
			required: true
			background: true
		
	email:
		type: String
		lowercase: true
		required: true
		index:
			background: true
			required: true

	size:
		type: Number
			
	accepted:
		type: Date
		default: null
		index:
			background: true
		
InviteSchema.documentType = 'Invite'
InviteSchema.strict = true

Invite = mongoose.model 'Invite', InviteSchema

module.exports = new class InviteRepository extends DocumentRepository
	
	model: Invite

	schema: InviteSchema

	create: (data, callback) ->
		
		debug 'invite', 'creating invite', data
		invite = new Invite
			_id:         uuid.generate()
			size:        data.size or 9
			sender:      data.sender
			email:       data.email
				
		@save invite, callback
		

	handle: (code, user, callback) ->
		debug 'invite', 'handle invite', code, user, callback?
		unless code? and code.length then return callback?()
		@getById code, (err, invite) =>
			if err
				logError err
				callback?()
			unless invite? then return callback?()

			invite.used = new Date()
			async.parallel [
					(callback) => invite.save callback
					(callback) => user.addFriend invite.sender, callback
				],
				callback

			



