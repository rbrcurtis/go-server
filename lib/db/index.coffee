fs = require 'fs'
mongoose = require 'mongoose'

log "[MONGOOSE] connecting to #{CONFIG.mongo.url}"
mongoose.connect CONFIG.mongo.url, (error) => if error then logError "[MONGOOSE] connection error #{error}"
mongoose.connection.on 'open', => log "[MONGOOSE] connection established to #{CONFIG.mongo.url}"

files = fs.readdirSync __dirname

for fileName in files
	unless fileName.match /.*Repository.coffee/ then continue
	name = fileName.substring(0, fileName.indexOf('Repository.coffee')).toLowerCase()+"s"
	exports[name] = require "./#{fileName}"

