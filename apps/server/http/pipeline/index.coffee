
fs = require 'fs'

files = fs.readdirSync __dirname

for fileName in files
	if fileName.match /index/ then continue
	name = fileName.substring 0, fileName.indexOf '.coffee'
	exports[name] = require "./#{fileName}"
