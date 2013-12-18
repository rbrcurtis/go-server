avatar = require 'lib/avatar'
DocumentResult = require './framework/DocumentResult'
UserResult = require './UserResult'

module.exports = class ChallengeResult extends DocumentResult
	
	constructor: (challenge, users) ->
		unless challenge then return
		super
		debug 'challenge', 'challengeresult', "\n", challenge
		
		for key in ['size', 'handicap', 'challenged', 'challenger']
			@[key] = challenge[key]

