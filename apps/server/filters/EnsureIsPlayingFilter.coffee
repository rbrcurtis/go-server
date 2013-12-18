Filter = require './framework/Filter'
error = require 'lib/error'

module.exports = class EnsureIsPlayingFilter extends Filter
	
	before: (callback) ->
		debug 'filters', 'EnsureIsPlayingFilter', user:@user, game:game = @request?.context?.game 
		unless @user? and game and (String(game.white) is String(@user._id) or String(game.black) is String(@user._id))
			return callback error.unauthorized()
		return callback()
	
