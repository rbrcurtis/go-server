DocumentRepository = require './framework/DocumentRepository'

mongoose = require 'mongoose'
ObjectId = mongoose.Schema.ObjectId
Mixed    = mongoose.Schema.Types.Mixed

db   = require 'lib/db'
uuid = require 'lib/uuid'

ChatSchema = require('./ChatRepository').schema

plugins = require './plugins'

GameSchema = new mongoose.Schema
	_id:
		type: ObjectId
		mutable: false
		
	white:
		type: ObjectId
		
	black:
		type: ObjectId
		
	turn:
		type: String
		enum: ['white', 'black']

	turnCount:
		type: Number
		default: 0

	lastMove:
		type: Mixed
		default: null

	whiteScore:
		type: Number
		index:background:true

	blackScore:
		type: Number
		index:background:true

	ended: 
		type: Date
		default: null
		index:background:true

	winner:
		type: String
		default: null

	board:
		type: Array

	passes:
		type: Number
		default: 0

	chats:
		type: [ChatSchema]
		default: -> []

	
GameSchema.documentType = 'Game'
GameSchema.plugin(plugins.changeTracking)
GameSchema.plugin(plugins.timestamp)

Game = mongoose.model 'Game', GameSchema

module.exports = new class GameRepository extends DocumentRepository
	
	model: Game

	schema: GameSchema

	findUsersGames: (user, callback) ->
		@find {_id:$in:user.games}, callback
	
	create: (black, white, size, callback) ->
		
		unless white? and black? and size?
			logError 'create game called with missing data', arguments
			throw Error 'missing data'
		
		game = new Game
			_id:   uuid.generate()
			white: white
			black: black
			turn: 'black'
			score: 0
			board: []
		
		for i in [0...size]
			game.board[i] = []
			for j in [0...size]
				game.board[i][j] = null # empty cell
		

		saveUser = (user, callback) =>
			debug 'game', 'adding game to', user, typeof callback
			async.waterfall [
				(callback) =>
					unless user instanceof db.users.model
						db.users.getById user, callback
					else callback null, user
				(user, callback) =>
					user.addGame game
					user.save callback

				],
				callback
		async.parallel [
				(callback) => 
					debug 'game', 'saving game'
					game.save callback
				(callback) => saveUser white, callback
				(callback) => saveUser black, callback
			],
			(err) =>
				debug 'game', 'saves complete'
				callback err, game
		










