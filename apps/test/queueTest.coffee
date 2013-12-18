


{messageBus, TestMessage} = require 'lib/messages'


messageBus.test.publish ({test:'fail'})
setInterval (->messageBus.test.publish new TestMessage(new Date())), 1000



messageBus.test.subscribe (message) ->
	log 'received message', message instanceof TestMessage, message
