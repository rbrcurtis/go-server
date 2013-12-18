

module.exports = class Cookie
	
	constructor: (@name, @value, data = {}) ->
		@data = _.extend { expires: new Date("1/1/2020"), httpOnly: true}, data

