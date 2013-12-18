redis = require 'redis'
async = require 'async'

db = require 'lib/db'

Controller = require './framework/Controller'

GameResult = require 'lib/results/GameResult'
UserResult = require 'lib/results/UserResult'

module.exports = class PresenceController extends Controller
	
	@handlers:
		'whoami':'_onWhoAmI'
		'joinGame':'_onJoinGame'
		'leaveGame':'_onLeaveGame'
		'disconnect':'_onDisconnect'
		'setIdle':'_onIdle'
		'setActive':'_onActive'
		'chat':'_onChat'
		
	onConnection: (user, socket) ->
		super
		debug 'status', 'join'
		socket.join "user:#{user._id}"

	
	constructor: ->
		super
		
	_broadcastPresence: (gameId, userId, presenceState, since) ->
		debug 'presence', "_broadcastPresence:", gameId, userId, presenceState
		
		message = {presenceState, userId, since}
		@send gameId, 'presence', message
		

	# _broadcastChat: (gameId, userId, message) ->
		# debug 'presence', "broadcast chat message '#{message}' to game #{gameId} from user #{userId}"
		# for socketId, user of @channels[gameId]
			# @io.sockets.socket(socketId).emit 'presence',
				# email: userEmail
				# message: message
		

	_onWhoAmI: (context, callback) ->
		{user,socket} = context
		callback?(user._id)

	_onLeaveGame: (context, gameId) ->
		context.socket.leave('game:'+gameId)
			
	_onJoinGame: (context, gameId) ->
		{user,socket} = context
		debug 'presence', "#{user.username} wants to join game #{gameId}"
		if !gameId.match /[a-f0-9]+/
			logError 'presence', "user #{user.email} trying to connect to invalid game #{gameId}!"
			return
			
		db.games.getById gameId, null, null, (err, game) =>
			# debug 'presence', 'got game?', err, game
			if err?
				logError "error getting games", err
				return
				
			game = new GameResult game
				
			unless _.contains([String(game.white), String(game.black)], String(user._id))
				# user not a player
				debug 'presence', 'joinGame Failed', user._id, 'tried joining game with members', game.members, @io.sockets.clients(gameId)
				for member in game.members
					debug 'presence', member, typeof member, user._id, typeof user._id
				return

			socket.join("game:"+gameId) #joins the game room
			
			@_changeUserState context, 'active'
			
			async.map(
				@io.sockets.clients(gameId)
				(socket,callback) => 
					debug 'presence', 'getting user for setproj', socket.id
					socket.get 'user', (err, u) =>
						if err?
							logError 'error getting user for setproj', socket.id
							return callback err
						
						debug 'presence', 'got user for setproj', socket.id, u
						
						callback null, JSON.parse u
						
				(err, users) =>
					debug 'presence', 'joinGame got users', err, users
					if err then return logError 'error getting users out of socket store', err
					usersResult = {}
					for u in users
						unless u? then continue
						usersResult[u._id] = new UserResult(u)
			
					debug 'presence', 'informing', user.username, 'of users', usersResult
			
					socket.emit 'users', usersResult
			)


	_onDisconnect: (context) ->
		{user,socket} = context
		debug 'status', 'leave'
		debug 'presence', "#{user.email} disconnected", true
		
		@_changeUserState context, 'offline'


	_onIdle: (context, since) ->
		{user,socket} = context
		debug 'presence', "#{user.email} is idle"
		@_changeUserState context, 'idle'


	_onActive: (context) ->
		{user,socket} = context
		debug 'presence', "#{user.email} is active again"
		@_changeUserState context, 'active'

	_onChat: (context, message, room) ->
		{user,socket} = context
		@send room, 'chat', {from:user._id, message}

	# change the users state and decide whether to broadcast new user state based on multiple connections
	_changeUserState: (context, state) ->
		{user,socket} = context
		
		debug 'presence', 'changeUserState', user.username, state
		
		user.presenceState = state
		user.since = new Date().getTime()
		
		socket.set 'user', JSON.stringify(user), (err) =>
		
			# debug 'presence', 'rooms', @io.sockets.manager.roomClients
			
			for gameId of @io.sockets.manager.roomClients[socket.id]
				do (gameId, user) =>
					if not gameId? or gameId.trim() in ['', '/'] then return
					
					debug 'presence', 'changeUserState games', context.user.username, state, gameId
					gameId = gameId.substr 1
					usersInRoom = Object.keys(@io.sockets.clients(gameId)).length
					
					statesByRank = {offline:1, idle:2, active:3}
					
					next = =>
						debug 'presence', 'next'.white, gameId, user._id, user.presenceState, user.since
						@_broadcastPresence gameId, user._id, user.presenceState, user.since
		
					if user.presenceState is 'active' then return next()
						
					async.map(
						@io.sockets.clients(gameId)
						(socket, callback) => #callback(null, true) means broadcast ok, false means dont broadcast
							socket.get 'user', (err, socketUser) =>
								if err? then return callback err
								unless socketUser?
									logError 'no socketUser found for socket', socket?.id
									return callback()
									
								socketUser = JSON.parse socketUser
								debug 'presence', 'user check'.white, user, socketUser
								debug(
									'presence'
									'broadcast check'.white
									socket.id
									user.socketId
									socket.id is user.socketId
									statesByRank[user.presenceState]
									socketUser.presenceState
									statesByRank[socketUser.presenceState]
									statesByRank[user.presenceState] < statesByRank[socketUser.presenceState]
									false
								)
								if socket.id is user.socketId
									debug 'presence', 'same socket'.white
									return callback null, true
								debug( 
									'presence'
									'same user?'.white
									socketUser._id
									user._id
									String(socketUser._id) is String(user._id)
									false
								)
								if String(socketUser._id) is String(user._id) and statesByRank[user.presenceState] < statesByRank[socketUser.presenceState]
									debug 'presence', 'not broadcasting'.white
									return callback null, false
								else return callback null, true
						(err, results) =>
							debug 'presence', 'changeUserState results'.white, results 
							for result in results
								if result is false then return
							next()
					)		
				
				
		
		
		
		
		
		
		
		
		
