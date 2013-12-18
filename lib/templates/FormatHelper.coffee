querystring = require 'querystring'
sprintf     = require('sprintf').sprintf
crypto      = require 'crypto'
require 'datejs'

MDASH = '&mdash;'

module.exports = class FormatHelper
	
	constructor: (options = {}) ->
		@timezoneOffset = options.timezoneOffset ? 0
		@dateFormat     = options.dateFormat     ? 'M/dd/yyyy'
		@destination    = options.destination    ? 'https://go-versus.com'
		if @destination.charAt(@destination.length - 1) is '/'
			@destination = @destination.substr(0, @destination.length - 1)
	
	unitToString: (number, unit) ->
		"#{number} #{unit}#{if number == 1 then '' else 's'}"
		
	percent: (decimal) ->
		if not decimal? then mdash else "#{Math.round(decimal*100)}%"

	toDays: (time ='') ->
		if time == '' then return mdash
		days =  Math.round(time/60/60/24)
		if days >= 1 then return @unitToString(days,'day')
		hours = Math.round(time/60/60)
		if hours >= 1 then return @unitToString(hours,'hour')
		minutes = Math.round(time/60)
		if minutes >= 1 then return @unitToString(minutes,'minute')
		return @unitToString(Math.round(time),'second')
	
	stripHtml: (html) ->
		html.replace(/<.*?>/g, '')
	
	truncatePlaintext: (str, length = 30) ->
		@truncate(@plaintext(str), length)

	truncate: (str, length = 30) ->
		if str.length > length then "#{str.substring(0, length)}..." else str

	plaintext: (str) ->
		str.replace(/<.*?>/g, '').replace(/&\w+?;/g, '').replace(/\n/g,' ').trim()
		
	time: (epochSeconds) ->
		if not epochSeconds? or epochSeconds is NaN then return mdash
		date = @_getUserTime(epochSeconds)
		"#{@date(epochSeconds)} at #{date.toString('h:mm tt')}"

	date: (epochSeconds) ->
		@_getUserTime(epochSeconds).toString(@dateFormat)
	
	url: (path) ->
		if path.charAt(0) isnt '/' then path = '/' + path
		@destination + path

	storyLink: (project, story) ->
		@url "/project/#{project.id}/story/#{story.ref}"
		
	projectLink: (project) ->
		@url "/project/#{project.id}/board"
		
	attachmentLink: (project, story, attachment) ->
		@url "/project/#{project.id}/story/#{story.ref}/attachment/#{attachment.id}/download/#{querystring.escape(attachment.fileName)}"
	
	gravatarLink: (user, size = 16) ->
		hash = crypto.createHash('md5')
		hash.update(user.email)
		md5 = hash.digest('hex')
		"https://secure.gravatar.com/avatar/#{md5}?s=#{size}&r=pg&d=identicon"
	
	user: (user) ->
		"<span style=\"padding: 2px 6px; color: #fff; background-color: #aaa; border-radius: 6px; white-space: nowrap\">#{if user? and user.name? then user.name else if user? then user else 'no one'}</span>"

	since: (start,end) ->
		if not start? or not end? then return ''
		seconds = Math.abs(Math.round(end - start))
		minutes = Math.round(seconds / 60)
		hours = Math.round(minutes / 60)
		days = Math.round(hours / 24)
		if days >= 1 then return "#{@unitToString(days, 'day')} ago"
		if hours >= 1 then return "#{@unitToString(hours, 'hour')} #{@unitToString(minutes % 60, 'minute')} ago"
		if minutes >= 5 then return "#{@unitToString(minutes, 'minute')} ago"
		else return 'moments ago'

	money: (amount) ->
		if amount >= 0
			sprintf('$%01.2f', amount)
		else			
			sprintf('($%01.2f)', Math.abs(amount))
			
	creditCard: (card) ->
		switch card.type
			when 'visa'       then name = 'Visa'
			when 'mastercard' then name = 'MasterCard'
			when 'amex'       then name = 'American Express'
			when 'discover'   then name = 'Discover'
		"#{name} ending in #{card.lastFourDigits}"

	_getUserTime: (epochSeconds) ->
		date = new Date(epochSeconds * 1000)
		serverOffset = date.getTimezoneOffset() / -60
		date.addHours(@timezoneOffset - serverOffset)
		return date


