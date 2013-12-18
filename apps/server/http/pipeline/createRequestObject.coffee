GoRequest = require 'GoRequest'

module.exports = () ->
	return (req, res, next) ->
		req.request = new GoRequest(req.route, req)
		next()
