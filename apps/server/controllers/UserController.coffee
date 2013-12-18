async = require 'async'

Controller = require './framework/Controller'
{UserResult} = require 'lib/results'

db = require 'lib/db'
error = require 'lib/error'
uuid = require 'lib/uuid'

module.exports = class UserController extends Controller
	
	get:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) ->
			
			debug 'user', 'get user', @request.context.user

			return callback null, new UserResult @request.context.user
