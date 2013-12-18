Controller = require './framework/Controller'

db    = require 'lib/db'
error = require 'lib/error'
validate = require 'lib/validate'
messageBus = require 'lib/messages/bus'
{InviteMessage} = require 'lib/messages'

module.exports = class ShareController extends Controller

	share: 
		before: ['ensureIsAuthenticated']
		handler: (callback) ->

			debug 'share', 'share body', @request.body
			unless @request.body.recipients? then return callback error.badRequest "no recipients specified"
			async.forEach @request.body.recipients.split(','),
				(email, callback) =>
					debug 'share', 'inviting', email
					email = email.trim()
					if validate.email(email) is true

						db.invites.create 
							size: @request.body.size
							sender: @user
							email: email
							(err, invite) =>
								if err then return callback err

								messageBus.invites.publish new InviteMessage invite

				callback
