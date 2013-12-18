class NotificationRule

	execute: (request, sendCallback) ->
		if @onCreate? and @request.changes.created?
			for change in @request.changes.created
				@onCreate(request, change, sendCallback)
				
		if @onUpdate? and @request.changes.updated?
			for change in @request.changes.updated
				@onUpdate(request, change, sendCallback)
				
		if @onDelete? and @request.changes.delete?
			for change in @request.changes.delete
				@onDelete(request, change, sendCallback)

module.exports = NotificationRule
