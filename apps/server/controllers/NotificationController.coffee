Controller = require './framework/Controller'

db     = require 'lib/db'
error  = require 'lib/error'
Cookie = require 'lib/Cookie'

module.exports = class NotificationController extends Controller

	register:
		before: ['ensureIsAuthenticated']
		handler: (callback) ->
			debug 'notifications', 'notifications register', @request.body, @user
			@user.addChannel @request.body, (err, channel) => return callback err


