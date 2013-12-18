# CampfireMessenger = require './CampfireMessenger'
EmailMessenger    = require './EmailMessenger'
# HipChatMessenger  = require './HipChatMessenger'
# XmppMessenger     = require './XmppMessenger'

# TODO: JID formatting as strategy?

module.exports =
	# aim:         new XmppMessenger()
	# campfire:    new CampfireMessenger()
	email:       new EmailMessenger()
	# hipchat:     new HipChatMessenger()
	# icq:         new XmppMessenger()
	# windowslive: new XmppMessenger()
	# xmpp:        new XmppMessenger()
