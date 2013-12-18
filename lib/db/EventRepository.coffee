crypto = require 'crypto'

DocumentRepository = require './framework/DocumentRepository'

mongoose = require 'mongoose'
ObjectId = mongoose.Schema.ObjectId
Mixed = mongoose.Schema.Types.Mixed

plugins = require './plugins'

uuid = require 'lib/uuid'

{messageBus, EventMessage} = require 'lib/messages'

EventSchema = new mongoose.Schema
	_id: ObjectId
	
	created:
		type: Date
		default: -> new Date()
		index: 
			background:	true
	
	user:
		type: ObjectId
		index:
			background:	true
		
	request:
		type: ObjectId
		index:
			background:	true

	receivers: 
		type: [ObjectId]
		index:
			background:	true

	action: 
		type: String
		enum: ['create', 'update', 'delete']
	
	documentType: 
		type: String
	
	documentId: 
		type: ObjectId
	
	# unaltered document. do not denormalize anything in this doc so that we can replay events when needed without multiple steps
	document: 
		type: Mixed
	
	# unaltered/normalized diffs.  do not denormalize
	previous: 
		type: Mixed
	
	# this should be a hash of {Type:[instanceof Type]}
	meta: 
		type: Mixed
	

EventSchema.documentType = 'Event'
EventSchema.strict = true
EventSchema.index({documentType:1, documentId:1}, {background:true})

Event = mongoose.model 'Event', EventSchema

module.exports = new class EventRepository extends DocumentRepository
	
	model: Event
	
	create: (document, action, request, user, receivers, meta, callback) ->
		debug 'events', 'create', arguments

		meta ?= {}
		meta.User ?= {}
		meta.User[user.id] = user

		event = new Event
			_id:          uuid.generate()
			action:         action
			created:      new Date()
			documentType: document.schema.documentType
			documentId:   document._id
			document:     document.toJSON()
			previous:     if document.changes? then document.changes else undefined
			request:      request
			user:         user
			receivers:    receivers
			meta:         meta

		delete document.changes

		debug 'events', 'new event', event

		event.save (err, event) =>
			if err? then return callback? err
			messageBus.events.publish new EventMessage event




