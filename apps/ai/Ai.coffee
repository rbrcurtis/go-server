request = require 'request'

messagebus = require 'lib/messages/bus'

module.exports = new class Ai

	run: ->

		setTimeout =>

			@url = if CONFIG.ssl.enabled then "https://localhost:4000/" else "http://localhost:4000/"

			request.post {url:@url+'login', json:{username:'ai', password: CONFIG.ai.password}}, (err, resp, body) =>
				if err or not resp?.statusCode in [200,204]
					logError "[ai]", 'login error', err, resp?.statusCode, body
					return @run()
				
				request.get {url:@url+'me'}, (err, resp, body) =>
					if err or not resp?.statusCode in [200,204]
						logError "[ai]", 'me error', err, resp?.statusCode, body
						return @run()
					@me = JSON.parse body
					debug 'ai', 'got me result', @me

					log 'AI ready'

					messagebus.ai.subscribe ({event}) =>
						debug 'ai', 'checking event', event.documentType, event.document.turn, event.document.white, String(@me.id), String(event.document.white) is String(@me.id)
						unless event.documentType is 'Game' then return
						unless event.document.turn is 'white' and event.document.white is String(@me.id) then return
						if event.document.ended then return
						debug 'ai', 'turning', event.document
						@turn event.document
		, 1000


	turn: (game) ->
		log '[ai]', 'playing turn on game', game._id
		size = game.board.length

		callback = (err, resp, body) =>
			if err or resp.statusCode isnt 200 
				return logError "[ai]", game._id, err, resp.statusCode, body

		if game.passes # or Math.random() < .01
			log '*********** PASS ************'.yellow
			return request.post {url:@url+"games/#{game._id}/pass", json:{}}, callback

		loop
			x = Math.floor(Math.random()*size)
			y = Math.floor(Math.random()*size)
			unless game.board[x][y]? then break

		return request.post {url:@url+"games/#{game._id}/board/#{x}/#{y}", json:{}}, callback


