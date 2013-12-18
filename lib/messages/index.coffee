
fs = require 'fs'

files = fs.readdirSync __dirname

for fileName in files
	unless fileName.match /.*Message.coffee/ then continue
	name = fileName.substring 0, fileName.indexOf '.coffee'
	exports[name] = require "./#{fileName}"

exports.messageBus = require './bus'
