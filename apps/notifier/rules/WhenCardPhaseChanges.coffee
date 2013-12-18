NotificationRule = require './NotificationRule'

class WhenCardPhaseChanges extends NotificationRule

	onUpdate: (request, change, send) ->
		if change.type is 'Card' and change.previous.phase?
			send('story-moved', change)

module.exports = WhenCardPhaseChanges
