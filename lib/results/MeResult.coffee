UserResult         = require './UserResult'
GameResult         = require './GameResult'
ChallengeResult    = require './ChallengeResult'

module.exports = class MeResult extends UserResult
	
	constructor: (user, games, challenges, users) ->
		debug 'me', 'me result', arguments...
		unless user and games and challenges then return
		super user
		@email      = user.email
		@games      = (new GameResult(game) for game in games)
		@challenges = (new ChallengeResult(c) for c in challenges)
		@friends    = user.friends
		@users      = (new UserResult(u) for u in users) or []
		@settings   = user.settings or {}
		# @subscribed = true
		@subscribed = user.subscribed?.length > 0
