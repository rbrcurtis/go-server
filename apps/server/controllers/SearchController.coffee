Controller = require './framework/Controller'

db    = require 'lib/db'
error = require 'lib/error'

{PageResult, UserResult} = require 'lib/results'

module.exports = class SearchController extends Controller
	
	findUser:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) ->
		handler: (callback) ->
			queryStr = @request.params.query
			debug 'search', 'search for', query
			
			unless queryStr?.length >= 3 then return callback()

			query = new RegExp "^#{queryStr}.*", 'i'

			if '@' in queryStr
				query = db.users.find(email:query).sort(email:1).limit(10)
			else
				query = db.users.find(username:query).sort(username:1).limit(10)

			query.exec (err, users) =>
				if err then return callback err

				return callback null, new PageResult users, (user)-> new UserResult user
