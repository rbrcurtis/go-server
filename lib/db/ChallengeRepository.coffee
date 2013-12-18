DocumentRepository = require './framework/DocumentRepository'

mongoose = require 'mongoose'
ObjectId = mongoose.Schema.ObjectId
Mixed    = mongoose.Schema.Types.Mixed

db   = require 'lib/db'
uuid = require 'lib/uuid'

plugins = require './plugins'

ChallengeSchema = new mongoose.Schema
	_id:
		type: ObjectId
		mutable: false
		
	# TODO shard on id

	challenger:
		type: ObjectId
		index:
			required: true
			background: true
			
	challenged:
		type: ObjectId
		index:
			background: true

	challengerAccepts:
		type: Boolean
		default: true

	challengedAccepts:
		type: Boolean
		default: false
		
	#challenger's rank
	rank: 
		type: Number
		required: true
		index:
			required: true
			background: true
			
	handicap:
		type: Number

	# lock atomically before accepting/deleting
	# so we don't have multiple people accept the
	# same challenge
	locked: 
		type: Boolean
		default: false
		
	size:
		type: Number
		required: true


ChallengeSchema.documentType = 'Challenge'
ChallengeSchema.plugin(plugins.changeTracking)
ChallengeSchema.plugin(plugins.timestamp)
ChallengeSchema.index({rank:1, size:1}, {background:true})

Challenge = mongoose.model 'Challenge', ChallengeSchema

module.exports = new class ChallengeRepository extends DocumentRepository
	
	model: Challenge

	schema: ChallengeSchema
	
	getUserChallenges: (user, callback) ->
		@find {_id:$in:user.challenges}, callback
	
	create: (challenger, challenged, size, handicap, callback) ->
		
		unless challenger? and size? then throw Error 'missing data'
		
		challenge = new Challenge
			_id:         uuid.generate()
			challenger:  challenger
			challenged:  challenged
			rank:        challenger.getRank()
			size:        size
			handicap:    handicap
			
		@save challenge, callback

	lock: (challenge, callback) ->
		debug 'challenge', 'locking', challenge
		challenge.collection.findAndModify {_id:challenge._id, locked:false}, [], {$set:locked:true}, (err, challenge, ret) =>
			debug 'challenge', 'lock callback', arguments
			if err then return callback err
			unless ret.ok is 1 then return callback null, challenge, false

			@getById challenge._id, (err, challenge) =>
				return callback err, challenge, true


