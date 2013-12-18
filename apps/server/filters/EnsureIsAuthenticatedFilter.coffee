Filter = require './framework/Filter'
error = require 'lib/error'

module.exports = class EnsureIsAuthenticatedFilter extends Filter
	
	before: (callback) ->
		debug 'filters', 'EnsureIsAuthenticatedFilter', user:@user 
		unless @user?
			return callback error.unauthorized()
		return callback()
	
