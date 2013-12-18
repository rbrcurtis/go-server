avatar = require 'lib/avatar'
DocumentResult = require './framework/DocumentResult'

rank = require 'lib/rank'

module.exports = class UserResult extends DocumentResult
	
	constructor: (user) ->
		unless user then return
		super

		@username = user.username
		@avatar   = user.avatar or avatar.url(user)
		@rank     = rank.getRankString user

