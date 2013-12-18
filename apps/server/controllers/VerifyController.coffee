Controller = require './framework/Controller'

db = require 'lib/db'
error = require 'lib/error'
Cookie = require 'lib/Cookie'

module.exports = class VerifyController extends Controller


	verify:
		handler: (callback) ->
			debug 'verify', @request.body

			{code} = @request.body
			unless code? then return error.badRequest("no code specified")

			userId = code.substr 0,24
			code = code.substr 24

			debug 'verify', 'userId', userId, 'code', code

			db.users.getById userId, (err, user) =>
				if err then return callback err
				unless user then return callback error.badRequest "Invalid Verification Code. Error 1."
				unless user.verified.code is code then return callback error.badRequest "Invalid Verification Code. Error 2."

				# user.verified = new Date()
				# user.markModified 'verified'
				user.save (err) =>
					return callback err, (new Cookie(CONFIG.cookies.auth.name, user.token))
