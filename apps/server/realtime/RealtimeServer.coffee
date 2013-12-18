fs = require 'fs'
util = require 'util'
async = require 'async'
events = require 'events'
express = require 'express'
connect = require 'connect'
socketio = require 'socket.io'

db = require 'lib/db'

UserResult = require 'lib/results/UserResult'

EventController = require './controllers/EventController'

module.exports = class RealtimeServer
	
	@controllers: [
		EventController
	]
	
	constructor: (@app) ->		

	start: ->
		@io = socketio.listen @app
		@io.set 'log level', 0
		
		redisPub = redisSub = redisClient = {host:CONFIG.redis.host}
		opts = {redisSub,redisPub,redisClient}
		@io.set 'store', new socketio.RedisStore opts
			
		@controllers = []
		for controller in @constructor.controllers
			@controllers.push new controller(@io)
		
		
		@io.set 'authorization', @_onAuthorization
		@io.sockets.on 'connection', @_onConnection
		
		setInterval @count, CONFIG.realtime.countInterval*1000
		
	count: =>
		debug 'count', 'count', @io.sockets.sockets
		async.map (val for key, val of @io.sockets.sockets),
			
			(socket, callback) =>
				debug 'count', 'socket.get', socket
				socket.get 'user', callback
					
			(err, users) =>
				counted = {}
				if err then return logError err
				unless users?.length then return # log 'no users online'
				
				for user in users
					try
						unless user then continue
						user = JSON.parse user
						if user?.presenceState is 'active' then counted[user._id] = true
					catch e
					
				debug 'status', 'counted', Object.keys(@io.sockets.sockets).length, 'active', Object.keys(counted).length
				
				@io.get('store').cmd.setex("userCount:#{process.pid}", Math.floor(CONFIG.realtime.countInterval*1.25), Object.keys(@io.sockets.sockets).length)
				@io.get('store').cmd.setex("userCountActive:#{process.pid}", Math.floor(CONFIG.realtime.countInterval*1.75), Object.keys(counted).length)
		

	_onConnection: (socket) =>
		user = socket.handshake.user
		user.socketId = socket.id
		user.token = socket.handshake.token
		user.presenceState = 'active'
		user.since = new Date().getTime()
		
		log '[realtime]', "user #{user.username} connected", {token:socket.handshake.token,socketId:socket.id}, true
		socket.join user._id #join room of userid so that we can send messages to the user directly and easily.
			
		socket.set 'user', JSON.stringify(user), (err) =>
			if err? then return logError 'error on user store for rt connection', user, error

			debug 'rtstore', 'user saved', socket.id, user
			
		for controller in @controllers
			controller.onConnection user, socket
	
	_onAuthorization: (data, accept) =>
		try
			cookies = if data.headers.cookie then connect.utils.parseCookie(data.headers.cookie) else {}
			data.token = cookies[CONFIG.cookies.auth.name]
			unless data.token?
				debug 'realtime', "cookie not found", cookies
				return accept(null, false)
			else
				debug 'realtime', "found auth cookie", data.token
				
				db.users.getByToken data.token, (err, user) =>
					if err?
						logError "error finding user", err
						return accept(null, false)
					if user?
						debug 'realtime', "authentication successful for user #{util.inspect user}", true
						data.user = JSON.parse JSON.stringify user
						return accept(null, true)
					else
						debug 'realtime', 'user not found'
						return accept(null, false)
				
		catch ex
			log "authentication exception: #{util.inspect ex}"
			return accept(null, false)
	
	
