avatar = require 'lib/avatar'
DocumentResult = require './framework/DocumentResult'
ChatResult = require './ChatResult'

module.exports = class GameResult extends DocumentResult
	
	constructor: (game) ->
		unless game then return
		super

		debug 'game', 'gameresult', "\n", game
		
		for key in ['white', 'black', 'turn', 'turnCount', 'lastMove', 'whiteScore', 'blackScore', 'winner', 'board', 'passes', 'ended']
			@[key] = game[key]

		@size = @board.length
		@chats = (new ChatResult c for c in game.chats)
