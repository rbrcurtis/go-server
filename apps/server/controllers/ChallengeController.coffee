async = require 'async'
async = require 'async'
Controller = require './framework/Controller'

db    = require 'lib/db'
error = require 'lib/error'

{GameResult, ChallengeResult} = require 'lib/results'

module.exports = class ChallengeController extends Controller
	
	create:
		before: ['ensureIsAuthenticated']
		handler: (callback) ->
			
			debug 'challenge', 'create', @request.body
			
			@size = Number(@request.body.size)
			unless @size in [9,13,19] then return callback error.badRequest 'size must be 9, 13 or 19'
			@handicap = Number(@request.body.handicap)
			unless 0 <= @handicap <= 4 then return callback error.badRequest 'handicap must be between 0 and 4'

			if @request.body.opponent
				if @request.body.opponent is 'ai'
					return @_createAiGame(callback)
				else unless @request.body.opponent.length is 24
					return callback error.badRequest 'Invalid opponent user id'
				return @_create(callback)

			else
				return @_match(callback)

	_createAiGame: (callback) ->
		debug 'challenge', '_createAiGame', {@user}, {@size}
		db.users.getByUsername 'ai', (err, ai) =>
			# AI is always white, always goes second
			db.games.create @user, ai, @size, (err, game) =>
				return callback null, new GameResult game

	_match: (callback) ->
		debug 'challenge', '_match'
		# look for existing challenges based on rank and handicap
		q = {
			rank:
				$gte: @user.getRank()-@handicap
				$lte: @user.getRank()+@handicap
			size: @size
			locked: false
			challenger:
				$ne: @user._id
		}

		debug 'challenge', 'user', @user._id, 'query', q
		
		db.challenges.find(q).hint({rank:1, size:1}).sort(created:-1).exec (err, challenges) =>
			debug 'challenge', 'found', challenges
			# return callback()
			unless challenges.length then return @_create callback

			challenge = null
			async.until(
				=> 
					debug 'challenge', 'test', challenge?, {length:challenges.length}
					return challenge? or challenges.length is 0
				(callback) =>
					db.challenges.lock challenges.pop(), (err, c, locked) =>
						debug 'challenge', 'lock result', arguments
						if err then return callback err
						if locked is true
							debug 'challenge', 'set challenge', c
							challenge = c
						debug 'challenge', 'pretest', challenge, challenge?, {length:challenges.length}
						return callback()
				(err) =>
					if challenge then @_accept challenge, callback
					else @_create callback
			)

	# create a challenge
	_create: (callback) ->
		debug 'challenge', '_create'

		async.waterfall [
			# get the opponent
			(callback) => 
				if @request.body.opponent
					db.users.getById @request.body.opponent, callback
				else callback(null, null)
				
			# create the challenge
			(@opponent, callback) =>
				debug 'challenge', {@opponent}
				
				if @request.body.opponent and @opponent is null then return callback error.badRequest 'Invalid opponent user id'
					
				db.challenges.create @user, @opponent, @size, @handicap, callback 
			
			],
			(err, @challenge) =>
				debug 'challenge', 'waterfall', {@challenge}
	
				
				if @opponent? and @opponent._id isnt @user._id
					meta = {User:{}}
					meta.User[@user.id] = @user
					@opponent.addChallenge challenge
					@request.addUpdated @opponent, [@opponent]
					@request.addCreated @challenge, [@opponent], meta



				models = [@challenge, @user]
				if @opponent then models.push @opponent
				async.forEach models, ((model, cb) => model.save cb),
					(err) =>
						debug 'challenge', 'end'
						return callback err, new ChallengeResult challenge

	get:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) -> 
			debug 'challenge', @request.context
			unless String(@user._id) in [String(@request.context.challenge.challenger), String(@request.context.challenge.challenged)] then return callback error.unauthorized()
			return callback null, new ChallengeResult @request.context.challenge

	remove:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) -> 
			debug 'challenge', 'remove', @request.body.challenge, @user._id, @request.body.challenged is String(@user._id), false
			unless String(@user._id) is String(@request.context.challenger) then return callback error.unauthorized()
			@request.context.challenge.remove (err) ->
				if err then return callback err
				return callback()

	update:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) ->
			{challenge} = @request.context
			debug 'challenge', 'update', @request.body, @user._id, challenge.challenged
			unless String(@user._id) is String(challenge.challenged) and @request.body.challengedAccepts? then return callback error.unauthorized()

			if @request.body.challengedAccepts is 'false'
				challenge.remove (err) =>
					if err then return callback err
					@request.addDeleted challenge, [challenge.challenger, challenge.challenged]
					return callback()


			else @_accept(challenge, callback)


	# if joe challenges bob then it makes sense for joe to know that bob accepted or rejected the challenge.
	# if joe challenges random and bob challenges random and gets bob,
	# bob moves first because will be same or lesser rank so joe gets turn notif
	_accept: (challenge, callback) ->

		debug 'challenge', 'accepting challenge', challenge

		async.waterfall [
				(callback) => 
					debug 'challenge', 'creating game'
					# TODO weaker player or challenged takes black
					# black goes first unless there is a handicap.  sheesh
					async.parallel [
							# create the game
							(callback) => db.games.create @user, challenge.challenger, challenge.size, callback
							# get the challenger for meta
							(callback) => db.users.getById challenge.challenger, callback
						],
						callback
				([@game, @challenger], callback) =>

					meta = {User:{}}
					meta.User[String(@user._id)] = @user
					meta.User[String(@challenger._id)] = @challenger

					challenge.challengedAccepts = true
					# challenged gets the result, challenger gets @game notif only if its his turn due to rank diff
					rec = []
					if String(@game[@game.turn]) isnt @user.id then rec.push @game[@game.turn]
					@request.addCreated @game, rec, meta

					meta = _.clone meta
					meta.Game = {}
					meta.Game[String(@game._id)] = @game

					# challenger wants to know the challenge was accepted
					@request.addDeleted challenge, [challenge.challenger], meta

					challenge.remove callback
			],
			(err) =>
				debug 'challenge', 'completing'
				if err then return callback err
				return callback null, new GameResult(@game)

















