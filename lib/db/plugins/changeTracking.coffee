error = require 'lib/error'

module.exports = (schema) ->
	metadata = schema.tree
	schema.pre 'set', (next, path, value) ->
		if metadata[path]? and metadata[path].trackChanges isnt false
			@changes = {} unless @changes?
			current = @[path]
			@changes[path] = current unless value is current
		next()
