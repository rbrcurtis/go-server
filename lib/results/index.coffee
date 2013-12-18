
fs = require 'fs'

files = fs.readdirSync __dirname

exports.PageResult = require './framework/PageResult'

for fileName in files
	unless fileName.match /.*Result.coffee/ then continue
	name = fileName.substring 0, fileName.indexOf '.coffee'
	exports[name] = require "./#{fileName}"
