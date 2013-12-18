http = require 'http'

http.STATUS_CODES[429] = 'Too Many Requests'

class RequestError extends Error
	
	name: 'RequestError'
	
	constructor: (@status, @message) ->
		Error.call(this, @message)
		Error.captureStackTrace(this, arguments.callee)

errors =
	badDigest:        [400, 'Incorrect Content Digest']
	badLength:        [400, 'Incorrect Content Length']
	badRequest:       [400, 'Bad Request']
	unauthorized:     [401, 'Unauthorized']
	forbidden:        [403, 'Forbidden']
	notFound:         [404, 'Not Found']
	notAcceptable:    [406, 'Not Acceptable']
	conflict:         [409, 'Conflict']
	precondition:     [412, 'Precondition Failed']
	unsupportedMedia: [415, 'Unsupported Media Type']
	teapot:           [418, "I'm a teapot"]
	tooManyRequests:  [420, 'Enhance Your Calm. Too Many Requests']
	validationFailed: [422, 'Validation Failed']
	server:           [500, 'Something Bad Happened']

module.exports =
	RequestError: RequestError

for name, spec of errors
	do (name, spec) ->
		[status, defaultMessage] = spec
		module.exports[name] = (message) ->
			if name is 'server' and message
				logError message
				new RequestError(status, defaultMessage)
			else
				new RequestError(status, message ? defaultMessage)
