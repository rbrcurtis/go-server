config = require './default'

try
	local = require './local'
	for key, val of local
		if typeof val is 'object' and config[key]? then _.extend config[key], val
		else config[key] = val
		
catch ex
try
	config = _.extend config, require './debug'
catch ex

module.exports = config
