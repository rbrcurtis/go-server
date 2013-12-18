module.exports =
	name: 'test'
	cluster: false
	
	run: ->

		global.assert = require 'assert'
		global.testLog = (args...) ->
			debug 'test', args...

		mocha = new (require 'mocha')
		if process.argv.length > 3
			mocha.addFile "#{__dirname}/#{file}.coffee" for file in process.argv.slice(3)
		else
			mocha.addFile "#{__dirname}/suite.coffee"
		mocha.run -> 
			
		hang = ->
			process.nextTick hang
			
		hang()
			
	
			


