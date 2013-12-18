
fs = require 'fs'

files = fs.readdirSync __dirname

for fileName in files
	unless fileName.match /.*Controller.coffee/ then continue
	name = fileName.substring(0, fileName.indexOf('Controller.coffee')).toLowerCase()
	exports[name] = require "./#{fileName}"
