
class Judge

	marked: []

	rule: ({@board,@_id}, {@x,@y}) ->
		@x = +@x
		@y = +@y
		color = @board[@x][@y]
		debug 'judge', 'color', color

		for [xi,yi] in [[@x,@y-1],[@x+1,@y],[@x,@y+1],[@x-1,@y]]
			debug 'judge', '1:checking', xi, yi, @board[xi]?[yi], @board.length
			unless 0 <= xi < @board.length then continue
			unless 0 <= yi < @board.length then continue
			debug 'judge', '2:checking', xi, yi, @board[xi][yi]
			if @board[xi][yi] isnt color and @board[xi][yi]
				@marked = {}
				try
					captured = false
					captured = @check {x:xi, y:yi}
				catch e #no capture
					unless e is 'not captured' then return logError e
				if captured then @clean()

		# check self-capture
		@marked = []
		try
			captured = false
			captured = @check {@x,@y}
		catch e #no self-capture
			unless e is 'not captured' then return logError e
		if captured then @clean()

		return @board
		return


	check: ({x,y}) ->
		debug 'judge', '@check', x, y, @board[x][y]
		@marked[[x,y]] = true
		color = @board[x][y]
		for [xi,yi] in [[x,y-1],[x+1,y],[x,y+1],[x-1,y]]
			unless 0 <= xi < @board.length then continue
			unless 0 <= yi < @board.length then continue
			
			if @marked[[xi,yi]]
				debug 'judge', 'pre-marked', [xi, yi]
				continue

			if @board[xi][yi] is color # not a capture so far
				debug 'judge', 'is', color, [xi,yi]
				@check {x:xi, y:yi}
			
			else if @board[xi][yi] is null
				debug 'judge', 'safe!', [xi,yi]
				throw 'not captured'

		return true

	clean: ->
		debug 'judge', 'capture', Object.keys(@marked)
		for key of @marked
			[x,y] = key.split(',')
			debug 'judge', 'captured', [x,y], @board[x][y]
			@board[x][y] = null

	### SCORING ###

	score: (game, {@black, @white}) ->
		debug 'judge', 'start', game, @black, @white
		{@board} = game
		
		x = y = 0
		@marked = {}
		@scoreCheck x,y
		blackPoints = []
		whitePoints = []
		debug 'judge', 'score', 'before', @marked
		for x in [0...@board.length]
			for y in [0...@board.length]
				key = [x,y]
				val = @marked[key]
				switch val
					when 'black' then blackPoints.push key
					when 'white' then whitePoints.push key
					when 'both' then continue
					# else debug 'judge', 'score', 'fail!', key, val

		debug 'judge', 'score', 'black', blackPoints.length, blackPoints.sort()
		debug 'judge', 'score', 'white', whitePoints.length, whitePoints.sort()

		game.blackScore = blackPoints.length
		game.whiteScore = whitePoints.length+6.5
		game.winner = win = if game.whiteScore >= game.blackScore then 'white' else 'black'
		lose = if win is 'white' then 'black' else 'white'
		@[win].wins++
		@[lose].losses++

		game.ended = new Date()

		epsilon = .016
		rB = if win is 'black' then 1 else 0
		rW = (rB+1)%2
		[conB, aB] = @varianceTable[@black.rating-@black.rating%100]
		[conW, aW] = @varianceTable[@white.rating-@white.rating%100]
		SeB = (1/(Math.exp((@white.rating-@black.rating)/aB)+1))-epsilon/2
		SeW = 1 - epsilon - SeB
		@black.rating = Math.max(0,Math.floor(@black.rating+(conB*(rB-SeB))))
		@white.rating = Math.max(0,Math.floor(@white.rating+(conW*(rW-SeW))))

		debug 'judge', 'black rating change', @black.changes?.rating, @black.rating
		debug 'judge', 'white rating change', @white.changes?.rating, @white.rating

		debug 'judge', win, 'wins!'

		return {game, @black, @white}

	varianceTable:
		0: [130, 205]
		100: [116, 200]
		200: [110, 195]
		300: [105, 190]
		400: [100, 185]
		500: [95, 180]
		600: [90, 175]
		700: [85, 170]
		800: [80, 165]
		900: [75, 160]
		1000: [70, 155]
		1100: [65, 150]
		1200: [60, 145]
		1300: [55, 140]
		1400: [51, 135]
		1500: [47, 130]
		1600: [43, 125]
		1700: [39, 120]
		1800: [35, 115]
		1900: [31, 110]
		2000: [27, 105]
		2100: [24, 100]
		2200: [21, 95]
		2300: [18, 90]
		2400: [15, 85]
		2500: [13, 80]
		2600: [11, 75]
		2700: [10, 70]

	scoreCheck: (x, y, color) ->
		debug 'judge', 'scoreCheck', x, y, color, @board[x][y], @marked[[x,y]]
		# if @board[x][y] and color and @board[x][y] isnt color then return
		switch @marked[[x,y]]
			when undefined
				debug 'judge', 'mark undefined = ', color or true
				@marked[[x,y]] = color or true
			when true
				unless color?
					debug 'judge', 'mark true not color'
					return
				else
					debug 'judge', 'mark true color'
					@marked[[x,y]] = color
			when 'both'
				debug 'judge', 'mark both'
				return
			when color
				debug 'judge', 'mark color'
				return
			else
				unless color then return
				debug 'judge', 'mark else'
				@marked[[x,y]] = 'both'

		for [xi,yi] in [[x,y-1],[x+1,y],[x,y+1],[x-1,y]]
			# debug 'judge', 'scoreCheck loop first', xi, yi
			unless 0 <= xi < @board.length then continue
			unless 0 <= yi < @board.length then continue
			# debug 'judge', 'scoreCheck loop second', xi, yi
			@scoreCheck xi, yi, @board[xi][yi] or color




module.exports = 
	rule: ->
		return new Judge().rule arguments...
	score: ->
		return new Judge().score arguments...




