async = require 'async'

Filter = require '../framework/Filter'

db = require 'lib/db'
error = require 'lib/error'

module.exports = class SetContextFilter extends Filter
	
	before: (callback) ->
		
		debug 'filters', 'setContext'
		
		async.parallel [
			(callback) =>
				if gameId = @request.params.game
					unless gameId.match /[0-9a-f]{24}/ then return callback error.notFound()
					db.games.getById gameId, (err, game) =>
						unless game? then return callback err or error.notFound()
						
						@request.context.game = game
						return callback()
				else callback()
			(callback) =>
				if challengeId = @request.params.challenge
					unless challengeId.match /[0-9a-f]{24}/ then return callback error.notFound()
					db.challenges.getById challengeId, (err, challenge) =>
						unless challenge? then return callback err or error.notFound()
						
						@request.context.challenge = challenge
						return callback()
				else callback()
			(callback) =>
				if userId = @request.params.user
					unless userId.match /[0-9a-f]{24}/ then return callback error.notFound()
					db.users.getById userId, (err, user) =>
						unless user? then return callback err or error.notFound()
						
						@request.context.user = user
						return callback()
				else callback()
			],
			callback
				
