DocumentResult = require './framework/DocumentResult'
UserResult = require './UserResult'

module.exports = class EventResult extends DocumentResult

	constructor: (event, receiver) ->
		debug 'eventresult', 'new eventresult', event
		super

		# this allows us to not have to do String() gymnastics on comparisons to ids
		event = JSON.parse JSON.stringify event
		receiver = String receiver

		@user = event.user
		@request = event.request
		@action = event.action
		@documentType = event.documentType
		@documentId = event.documentId
		
		ResultClass = require "lib/results/#{event.documentType}Result"
		@document = new ResultClass event.document
		
		@meta = {}
		
		# convert all meta data into result objects
		for Type, dict of event.meta
			ResultClass = require "lib/results/#{Type}Result"
			@meta[Type] = {}
			for id, obj of dict
				debug 'events', "@meta[#{Type}][#{id}] = new ResultClass #{obj}"
				@meta[Type][id] = new ResultClass obj
		
		try
			@summary = @getSummary(event, receiver)
		catch e
			log "unknown summary for ", event
			logError e

			@summary = ""



	getSummary: (event, receiver) ->
		@url = ""
		switch event.documentType
			when 'Game' then return @getGameSummary(event, receiver)
			when 'Challenge' then return @getChallengeSummary(event, receiver)
			else return ""


	getGameSummary: (event, receiver) ->
		@url = "#/games/#{event.documentId}"
		switch event.action
			when 'create'
				# joe challenges bob, bob is lower so gets handicap. joe goes first
				game = event.document
				other = if game.turn is 'black' then game.white else game.black
				return "#{@meta.User[other].username} accepted your challenge, and its your move!"
			when 'update'
				game = event.document
				other = if game.turn is 'black' then game.white else game.black

				if game.turnCount is 1
					return "You have a new game against #{@meta.User[other].username} and its your move!"

				else if game.ended?
					if game.blackScore > game.whiteScore 
						winner = game.black
						other = game.white
					else
						winner = game.white
						other = game.black
					
					debug 'game', 'summary', winner, other, receiver, winner is receiver
					if winner is receiver then return "You won against #{@meta.User[other].username}!  The final score was #{game.blackScore} to #{game.whiteScore}."
					else return "You lost against #{@meta.User[winner].username}!  The final score was #{game.blackScore} to #{game.whiteScore}."

				return "It's your move against #{@meta.User[other].username}"
				
			when 'delete'
				return ''

	getChallengeSummary: (event) ->
		@url = "#/challenges/#{event.documentId}"
		switch event.action
			when 'create'
				# challenged gets notif
				return "You've been challenged to a game against #{@meta.User[@document.challenger].username}!"
			# when 'update'
			# 	# challenger gets notif
			# 	accepted = if @document.challengedAccepts then "accepted" else "denied"
			# 	return "#{@meta.User[@document.challenger].username} #{accepted} your challenge."
			# when 'delete'
			# 	# challenger gets notif
			# 	accepted = if @document.challengedAccepts then "accepted" else "denied"
			# 	return "#{@meta.User[@document.challenger].username} #{accepted} your challenge."


