

module.exports =
	name: 'repl'
	run: ->
		require 'colors'
		readline = require 'readline'
		coffee = require 'coffee-script'
		rl = readline.createInterface process.stdin, process.stdout
		
		db = require 'lib/db'
		
		_this = @

		query = ->
			rl.question '>', (data) ->
				try
					c = coffee.compile data.toString(), {bare:true}
					c = c.replace /var [^;]+;/gi, ""
					if c.trim().length
						res = eval c
						console.log if typeof res is 'undefined' then 'undefined'.grey else res
				catch e
					logError e
				query()
		
		query()
