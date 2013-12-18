async = require 'async'
Controller = require './framework/Controller'

db    = require 'lib/db'
error = require 'lib/error'
judge = require 'lib/judge'

{GameResult, ChatResult} = require 'lib/results'

module.exports = class GameController extends Controller
	
	get:
		before: ['setContext', 'ensureIsAuthenticated']
		handler: (callback) ->
			return callback null, new GameResult @request.context.game
			
	move:
		before: ['setContext', 'ensureIsPlaying']
		handler: (callback) ->
			
			game = @request.context.game
			x = @request.params.x
			y = @request.params.y

			debug 'game', x, y, game.turn
			
			if String(game[game.turn]) isnt String(@user._id) then return callback error.badRequest 'It is not your turn'
			unless x? and y? and game.board.length>x>=0 and game.board.length>y>=0 then return callback error.badRequest "Invalid move"
			if game.board[x][y]? then return callback error.badRequest "You can't move there"
			
			debug 'game', 'rowcol', {x,y}
			
			game.board[x][y] = game.turn
			game.markModified('board')
			game.passes = 0
			game.turnCount++
			game.turn = if game.turn is 'black' then 'white' else 'black'
			game.lastMove = {x,y}

			ruling = judge.rule game, {x,y}
			if typeof ruling is 'string' then return callback error.badRequest ruling
			else game.board = ruling

			game.save (err, game) =>
				if err then return callback error.server err
				opponent = if String(game.white)is @user.id then game.black else game.white
				@request.addUpdated game, [opponent]

				return callback null, new GameResult game

	pass:
		before: ['setContext', 'ensureIsPlaying']
		handler: (callback) ->

			game = @request.context.game

			debug 'turn', 'pass', game._id, game.turn, game[game.turn], game.passes, @user._id

			if String(game[game.turn]) isnt String(@user._id) then return callback error.badRequest 'It is not your turn'

			game.passes++
			game.turnCount++
			unless game.passes is 2
				game.turn = if game.turn is 'black' then 'white' else 'black'
				game.save (err, game) =>
					opponent = if String(game.white)is @user.id then game.black else game.white
					@request.addUpdated game, [opponent]
					return callback err, new GameResult game
			else
				# game over
				debug 'turn', 'game ended!'
				async.parallel [
						(callback) => db.users.getById game.black, callback
						(callback) => db.users.getById game.white, callback
					],
					(err, [black, white]) =>
						if err? then return callback err
						debug 'turn', 'pass load players', black, white
						{game, black, white} = judge.score game, {black, white}
						debug 'turn', 'after scoring', {game, black, white}

						meta = User:{}
						meta.User[black.id] = black
						meta.User[white.id] = white

						@request.addUpdated game, [black, white], meta
						if black.changes? then @request.addUpdated black, [black]
						if white.changes? then @request.addUpdated white, [white]
						black.games = _.reject black.games, (gid) -> gid.equals(game._id)
						white.games = _.reject white.games, (gid) -> gid.equals(game._id)
						white.save()
						black.save()
						game.save()

						return callback null, new GameResult game
	chat:
		before: ['setContext', 'ensureIsPlaying']
		handler: (callback) ->

			game = @request.context.game
			{text} = @request.body

			unless text?.trim?().length then return callback error.badRequest('Must specify text that is not empty.')

			db.chats.create game, @user, text, (err, chat) =>
				return callback err, new GameResult game










