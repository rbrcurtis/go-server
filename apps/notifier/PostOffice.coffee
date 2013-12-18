async = require 'async'

db = require 'lib/db'
messageBus = require 'lib/messages/bus'
templates = require 'lib/templates'

messengers = require './messengers'

TEMPLATE_TYPES =
	email:       'email'

module.exports = new class PostOffice
	
	run: ->
		messageBus.invites.subscribe @onInvite
		messageBus.retrievals.subscribe @onRetrieval
		messageBus.welcome.subscribe @onWelcome
		messageBus.verify.subscribe @onVerify
		
	
	onWelcome: ({user}) =>
		log 'got welcome', {user}
		messenger = messengers['email']
		templateType = TEMPLATE_TYPES.email
		if templateType? and messenger?
			message = templates.render templateType, 'welcome', {user}
			messenger.send(message, user.email)
		
	onVerify: ({user}) =>
		log 'got verify', {user}
		messenger = messengers['email']
		templateType = TEMPLATE_TYPES.email
		if templateType? and messenger?
			message = templates.render templateType, 'verify', {user}
			messenger.send(message, user.email)
		
	onRetrieval: (retrieval) =>
		log 'got retrieval', {retrieval}
		db.users.get _id:retrieval.user, (err, user) =>
			messenger = messengers['email']
			templateType = TEMPLATE_TYPES.email
			if templateType? and messenger?
				message = templates.render templateType, 'password-reset', {retrieval}
				messenger.send(message, user.email)
		
	onInvite: ({invite}) =>
		log 'got invite', {invite}

		db.users.getById invite.sender, (err, user) =>
			if err then return logError err
			invite.sender = user
			messenger = messengers['email']
			templateType = TEMPLATE_TYPES.email
			if templateType? and messenger?
				message = templates.render templateType, "invite", {invite}
				messenger.send(message, invite.email)
			
