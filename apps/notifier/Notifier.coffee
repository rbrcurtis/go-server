messagebus = require 'lib/messages/bus'
request = require 'request'
templates = require 'lib/templates'
messengers = require './messengers'
db = require 'lib/db'

{EventResult} = require 'lib/results'

module.exports = new class Notifier

	run: ->
		messagebus.notifications.subscribe @onMessage

	onMessage: ({event}) =>
		debug 'notifier', 'got message', event, event.receivers

		async.forEach event.receivers,
			(receiver, callback) =>
				result = new EventResult event, receiver
				unless result.summary then return callback()
				db.users.getById receiver, (err, user) =>
					if err
						logError err
						return callback()
					unless user?
						logError 'didnt find a user for notification', event
						return callback()
					if user.username is 'ai' then return callback()
					log '[notifier]', 'notifying', user._id, user.username, 'of', event.documentType, 'event'
					debug 'notifier', 'got user', err, user
					if err? then return callback err
					unless user? then return

					async.parallel [
							(callbkack) =>
								async.forEach user.channels or [],
									(channel, callback) =>
										if channel.type is 'android'

											options = 
												url: "https://android.googleapis.com/gcm/send"
												method: "POST"
												headers: 
													Authorization: 'key=AIzaSyDSdWYgEiOZdLlMlD_5GfLWgTJHgN-ZJi0'
												json:
													registration_ids: [channel.token]
													data:
														type: result.type
														action: result.action
														summary: result.summary


											request options, (e, response, body) ->
												if e or response.statusCode isnt 200 
													logError "[notifier]", receiver, channel, options, e, response.statusCode, body
													callback()
												log '[notifier]', 'GCM response', e, response.statusCode, body
												if body.results[0]?.error?
													message = templates.render 'email', 'event', {event:result}
													messengers['email'].send message, user.email, callback
												else callback()

										else
											logError 'unknown channel type', receiver, channel
											return callback()
									callback
								

							(callback) =>
								if user.channels.length then return callback()
								debug 'notifier', 'sending email'
								# unless user.settings.receiveEmailNotifications then return callback()
								message = templates.render 'email', 'event', {event:result}
								messengers['email'].send message, user.email, callback

						],
						(err) =>
							if err then logError "error sending notification", event, receiver
							else debug 'notifier', 'done notifying', receiver, 'for event', event

