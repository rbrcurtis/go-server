async = require 'async'

Controller = require './framework/Controller'
{MeResult} = require 'lib/results'

db = require 'lib/db'
error = require 'lib/error'
uuid = require 'lib/uuid'
validate = require 'lib/validate'

module.exports = class MeController extends Controller
	
	get:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) ->
			
			debug 'me', 'get me', @user, @user.getRank()

			async.parallel(
				games: (cb) =>
					db.games.findUsersGames @user, cb
				challenges: (cb) =>
					db.challenges.find {_id:$in:@user.challenges}, cb
				(err, results) =>
					debug 'me', 'results', err, results
					if err then return callback err
					{games, challenges} = results
					userIds = {}
					
					for c in challenges
						userIds[String(c.challenger)] = false
						if c.challenged? then userIds[String(c.challenged)] = false
					
					for g in games
						userIds[String(g.white)] = false
						userIds[String(g.black)] = false

					for f in @user.friends then userIds[String(f)] = false
						
					db.users.getByIdList _.keys(userIds), (err, users) =>
						if err then return callback err
						return callback null, new MeResult(@user, games, challenges, users)
			)


	update:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) ->
			if @request.body.siteAdmin? then return callback error.badRequest()
			
			async.forEachSeries Object.keys(@request.body).sort(),
				(key, callback) =>
					unless key in ['username', 'email', 'settings'] then return callback error.badRequest()
					val = @request.body[key]
					
					if validate[key]?
						if (err = validate[key](val)) isnt true
							return callback err
					
					@user[key] = val
					debug 'user', 'applied', key
		
					callback()
					
				(err) =>
					if err then return callback err
					@user.save (err) =>
						debug 'user', 'save', arguments...
						if err
							logError "error saving user", arguments...
							return callback err
						
						_.bind(@get.handler, @, callback)()

	password: 
		before: ['setSelfContext', 'ensureIsAuthenticated']
		handler: (callback) ->
			debug 'user', 'password', @request.body
			
			unless @request.body then return callback error.badRequest()
			
			{current, newpw} = @request.body
			unless current and newpw then return callback "Must specify both current password and new password as current and newpw"
			unless auth.verifyPassword(current, String(@user.password)) then return callback error.forbidden()
			unless (err = validate newpw) is true then return callback error.badRequest err
			
			@user.password = newpw
			@user.save (err) =>
				if err then return callback err
		
			return callback()



