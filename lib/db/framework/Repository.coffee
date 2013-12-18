error = require 'lib/error'

class Repository
	
	map: (document, properties, callback) ->
		metadata = @schema.tree
		for name, value of properties
			if not metadata[name]?
				return callback error.badRequest("Cannot set non-existent property #{name}"), null
			if metadata[name].mutable is false
				return callback error.badRequest("Cannot change immutable property #{name}"), null
			document[name] = value
		# NOTE: I pulled the rule chain out for now. If we find a need to reintroduce it, it would
		# be called here.
		callback(null, document)

module.exports = Repository