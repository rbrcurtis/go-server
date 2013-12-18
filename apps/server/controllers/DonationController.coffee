Controller = require './framework/Controller'

jwt = require 'jwt-simple'

db = require 'lib/db'
error = require 'lib/error'

module.exports = class BillingController extends Controller


	postback:
		handler: (callback) ->
			try
				debug 'donate', 'postBack from', @request.http?.address, 'body', @request.body
				body = jwt.decode @request.body.jwt, CONFIG.wallet.key
				debug 'donate', "donation", body
				if body.response?.orderId 
					userId = body.request.sellerData.match(/[a-f0-9]{24}/)[0]
					orderId = body.response.orderId+""
					db.users.getById userId, (err, user) =>
						if user?
							user.subscribed ?= []
							user.subscribed.push {orderId, date: Date(), amount: body.request.price}
							# user.subscribed = user.subscribed
							user.markModified 'subscribed'
							# debug 'donate', 'recorded sub from user', JSON.stringify user
							log '[donate]', 'received donation', body, user
							user.save (err) -> if err? then logError "error saving user", err

						else
							logError "couldnt find user for donation", err, @request.body
							
						return callback null, orderId

				else return callback error.badRequest()
			catch e
				return callback e

	getJwt:
		handler: (callback) ->
			debug 'donate', 'getJwt', @request.query, @request.params.userId

			async.parallel [
					(callback) =>
						unless @request.params.userId?.length is 24
							logError '[donate]', @request.id, 'no userId specified for getJwt!', @request
							if @user?
								logError '[donate]', @request.id, 'using logged in user', @user
								return callback null, @user
							else return callback error.unauthorized()
						db.users.getById @request.params.userId, (err, user) =>
							if err
								logError '[donate]', @request.id, 'error getting user on donation request', err
								return callback err
							unless user
								logError '[donate]', @request.id, 'no user found for', @request.params.userId, @request
							if not user?
								if @user?
									logError '[donate]', @request.id, 'using logged in user', @user
									return callback null, @user
								else return callback error.unauthorized()
							callback null, user
				],
				(err, [@user]) =>
					if err then return callback err
					debug 'donate', 'found user', @user
					amount = Number @request.query.amount
					unless amount >= 1
						logError '[donate]', 'amount not specified, defaulting to 3', @request
						amount = 3

					data = 
						iss: CONFIG.wallet.id
						aud: 'Google'
						typ: 'google/payments/inapp/item/v1'
						iat: Math.floor(Date.now()/1000)
						exp: Math.floor(Date.now()/1000)+3600
						request:
							name: 'Mut8ed Games'
							description: 'Donation for Online Gameplay for user '+@user.username
							price: amount+".00"
							currencyCode: 'USD'
							sellerData: "user: #{@user.id}"

					log '[donate]', 'returning jwt', data


					return callback null, {jwt:jwt.encode(data, CONFIG.wallet.key)}
