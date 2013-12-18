module.exports =
	name: 'notifications'
	cluster: false
	run: ->
		(new require('./PostOffice')).run()
		(new require('./Notifier')).run()
