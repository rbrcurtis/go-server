
Controller = require './framework/Controller'

db     = require 'lib/db'
error  = require 'lib/error'
hash   = require 'lib/hash'
Cookie = require 'lib/Cookie'

module.exports = class LoginController extends Controller
	
	login:
		handler: (callback) ->
			
			debug 'login', @request
			
			username = @request.body['username']
			password = @request.body['password']
			
			unless username and password
				debug 'login', 'somethings missing', {username, password}
				return callback error.badRequest()

			username = username.toLowerCase().trim()
			
			# TODO detect email and only do one query
			query = db.users.get().or [
				{username: username},
				{email:    username}
			]
			
			async.series [
				(callback) =>
					query.exec (err, @user) =>
						if err? then return callback error.server(err)
						if not @user? then return callback error.unauthorized("Invalid username or password")
						
						unless hash.verifyPassword(password, @user.password)
							return callback error.unauthorized("Invalid username or password")

						callback()

				(callback) => db.invites.handle @request.body.invite, @user, callback

				],
				(err) =>

					if err then return callback err

					sendCookie = =>
						return callback null, (new Cookie(CONFIG.cookies.auth.name, @user.token))
						
					if @user.token then return sendCookie()
					else 
						hash.setToken @user
						db.users.save @user, (err) ->
						if err? then return callback error.server(err)
						return sendCookie()
					
		





