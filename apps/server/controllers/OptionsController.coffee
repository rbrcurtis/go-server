
Controller = require './framework/Controller'

db = require 'lib/db'

module.exports = class RegisterController extends Controller
	
	get: # /
		handler: (callback) ->
			debug 'options', 'options controller get'
			return callback(null, 'here thar be dragons')

	options:
		handler: (callback) ->
			debug 'options', 'options controller options'
			return callback()
	
