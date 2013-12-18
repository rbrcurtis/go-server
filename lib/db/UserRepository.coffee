DocumentRepository = require './framework/DocumentRepository'

db = require 'lib/db'
uuid = require 'lib/uuid'

mongoose = require 'mongoose'
ObjectId = mongoose.Schema.ObjectId
Mixed = mongoose.Schema.Types.Mixed

plugins = require './plugins'

ChannelSchema = require('./ChannelRepository').schema

hash = require 'lib/hash'
rank = require 'lib/rank'


UserSchema = new mongoose.Schema
	
	_id: ObjectId

	username:
		type: String
		lowercase: true
		required: true
		index:
			required: true
			unique: true
			background:true

	email:
		type: String
		lowercase: true
		required: true
		index:
			required: true
			unique: true
			background:true

	password:
		type: String
		set: (value) -> hash.hashPassword(value)

	token: String

	accessed: Date

	meta: Mixed

	verified: 
		type: Mixed
		default: -> {
			code: uuid.generate()
			lastAttempt: new Date()
			attempts: 1
		}

		index:
			background: true
			unique: true

	rank: Number
		
	rating:
		type: Number
		default: 0
		set: (rating) -> 
			@rank = rank.getRank(rating)
			return rating

		index:
			required: true
			background: true

	wins:
		type: Number
		default: 0

	losses:
		type: Number
		default: 0

	channels:
		type: [ChannelSchema]
		default: -> []
		
	# all games this user is in
	games: [ObjectId]
	
	# challenges to this user
	challenges: [ObjectId]

	# others this user has friended/starred
	friends: [ObjectId]

	subscribed: 
		type: Mixed
		default: null


	settings: 
		type: Mixed
		default: -> {
			receiveNotifications: true
			receiveEmailNotifications: true
		}

	
	
UserSchema.documentType = 'User'
UserSchema.plugin(plugins.changeTracking)
UserSchema.plugin(plugins.timestamp)

_.extend UserSchema.methods,
	addGame: (game) ->
		@games.push game._id
		@markModified("games")

	addChallenge: (challenge) ->
		@challenges.push challenge._id
		@markModified("challenges")
		
	addChannel: (data, callback) ->
		db.channels.create @, data, callback

	addFriend: (friend, callback) ->
		truth = _.any @friends, (f) -> return String(f) is String(friend._id or friend)
		unless truth then @friends.push friend
		@save callback

	getRank: ->
		return rank.getRank(@)

	getRankString: ->
		return rank.getRankString(@)
			
	

User = mongoose.model 'User', UserSchema

module.exports = new class UserRepository extends DocumentRepository
	
	model: User

	schema: UserSchema
	
	getByEmail: (email, fields, options, callback) ->
		@get {email}, fields, options, callback
		
	getByUsername: (username, fields, options, callback) ->
		@get {username}, fields, options, callback
		
	# token consists of the userid plus a random uuid.
	getByToken: (token, callback) ->
		unless token.length > 24 then return callback()
		id = token.substr 0, 24
		@getById id, (err, user) ->
			if user and user.token is token then return callback null, user
			else return callback()

	getByIdList: (ids, callback) ->
		debug 'me', 'getByIdList', ids
		@find {_id:$in:ids}, callback
	
	create: (data, callback) ->
		_id = uuid.generate()
		user = new User
			_id: _id
			email: data.email
			username: data.username
			password: data.password
			token: _id+hash.hash(Math.random())
		@save user, callback





