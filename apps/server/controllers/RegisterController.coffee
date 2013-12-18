
Controller = require './framework/Controller'

db     = require 'lib/db'
error  = require 'lib/error'
Cookie = require 'lib/Cookie'
validate = require 'lib/validate'
messageBus = require 'lib/messages/bus'

templates = require 'lib/templates'
messengers = require '../../../apps/notifier/messengers'

{VerifyMessage} = require 'lib/messages'

module.exports = class RegisterController extends Controller
	
	create:
		handler: (callback) ->
			
			debug 'register', @request.body

			unless @request.body?.terms? then return callback error.badRequest "You must accept the terms and conditions."
			
			{username, email, password} = @request.body
			for key, val of {username, email, password}
				debug 'register', 'check', key, val, validate[key]?
				unless val then return callback error.badRequest "#{key} is required"
				if validate[key]? and (err = validate[key] val) isnt true then return callback error.badRequest err

			username = username.toLowerCase().trim()
			email = email.toLowerCase().trim()
			
			query = db.users.get().or [
				{username: username},
				{email:    email}
			]

			async.series [
					(callback) =>
						query.exec (err, @user) =>
							if err? then return callback err
							
							if @user?
								debug 'register', 'user exists'
								return callback error.badRequest "A user with that username or email already exists"
							
							userObj = {
								username,
								email,
								password
							}
							
							db.users.create userObj, (err, @user) =>
								if err
									logError 'error on user create', err
									return callback err
									
								debug 'register', "User created: #{JSON.stringify @user}"

								messageBus.verify.publish new VerifyMessage @user
								messengers['email'].send {subject:"new User #{@user.username}", body: @user.email}, "ryan@mut8ed.com"

								callback()
									
					(callback) => 
						db.invites.handle @request.body.invite, @user, =>
							debug 'invite', 'handle callback'
							callback arguments...
				],
				(err) =>
					debug 'invite', 'register end'
					if err then return callback err
					return callback null, new Cookie(CONFIG.cookies.auth.name, @user.token)









