module.exports =
	name: 'ai'
	cluster: true
	run: ->

		setTimeout @start, 5000

	start: ->
		request = require 'request'
		db = require 'lib/db'

		url = 'http://go.mut8ed.com:4000/'

		ryan = request.jar()
		joe = request.jar()

		async.parallel [
				(callback) => 
					request.post {url:url+'login', json:{username:'ryan', password:'qwe123'}, jar:ryan}, (err, response, body) =>
						request.get {url:url+'games/509713728cdbe57cc4b4000c', json:true, jar:ryan}, (err, response, body) => callback err, body

				(callback) => request.post {url:url+'login', json:{username:'joe', password:'qwe123'}, jar:joe}, callback
			], 
			(err, [game]) =>
				log 'auth complete', err, game, {ryan, joe}

				players = [ryan, joe]

				i = 0
				size = game.board.length
				next = =>
					log 'next', game?.board?

					callback = (err, resp, body) =>
						log 'response', err, resp?, game?.board?, body
						if err
							logError err
						else if body?.board? 
							game = body
						log 'before next', game?.board?
						return setTimeout(next, 500)

					if game.ended?
						log '%%%%%%%%%%%%%%% ENDED %%%%%%%%%%%%%%%'.yellow
						return setTimeout(
							=>
								db.games.getById game.id, (err, g) ->
									g.board = [[null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null], [null, null, null, null, null, null, null, null, null]]
									g.ended = null
									g.passes = 0
									g.save (err, g) =>
										game = g
									return setTimeout next, 500
							5000
						)


					if game.passes or Math.random() < .01
						log '*********** PASS ************'.yellow
						return request.post {url:url+"games/#{game.id}/pass", json:{}, jar:players[i++%2]}, callback

					loop
						x = Math.floor(Math.random()*size)
						y = Math.floor(Math.random()*size)
						unless game.board[x][y]? then break

					return request.post {url:url+"games/#{game.id}/board/#{x}/#{y}", json:{}, jar:players[i++%2]}, callback

				return next()
