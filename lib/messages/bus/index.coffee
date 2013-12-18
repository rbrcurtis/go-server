Channel = require './Channel'
MessageBus = require './MessageBus'
messages = require 'lib/messages'

messageBus = new MessageBus()

module.exports =
	requests:           new Channel(messageBus, 'go.requests', null, {})
	events:             new Channel(messageBus, 'go.events', null, messages.EventMessage, {})
	notifications:      new Channel(messageBus, 'go.events', 'notifications', messages.EventMessage, {durable:true, autoDelete: false})
	realtimeEvents:     new Channel(messageBus, 'go.events', 'realtime', messages.EventMessage, {})
	ai:                 new Channel(messageBus, 'go.events', 'ai', messages.EventMessage, {durable:true, autoDelete: false})
	invites:            new Channel(messageBus, 'go.invites', 'invites', messages.InviteMessage, {durable:true, autoDelete: false})
	retrievals:         new Channel(messageBus, 'go.retrievals', 'retrievals', null, {durable:true, autoDelete: false})
	welcome:            new Channel(messageBus, 'go.welcome', 'welcome', null, {durable: true, autoDelete: false})
	verify:             new Channel(messageBus, 'go.verify', 'verify', messages.VerifyMessage, {durable: true, autoDelete: false})
	emailValidation:    new Channel(messageBus, 'go.emailValidation', 'emailValidation', null, {durable: true, autoDelete: false})
	test:               new Channel(messageBus, 'go.test', 'test', messages.TestMessage, {durable:true, autoDelete: false})
