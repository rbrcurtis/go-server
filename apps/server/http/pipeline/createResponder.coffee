Responder = require 'Responder'

module.exports = () ->
	return (req, res, next) ->
		req.responder = new Responder(req.request, req, res)
		next()
