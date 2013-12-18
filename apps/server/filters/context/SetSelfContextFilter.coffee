Filter = require '../framework/Filter'

module.exports = class SetSelfContextFilter extends Filter
	
	before: (callback) ->
		if @user? then @request.context = {user: @user.id}
		callback()

