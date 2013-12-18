
module.exports = class DocumentResult
	
	constructor: (document) ->
		@type = @constructor.name
		@type = @type.substring 0, @type.indexOf 'Result'
		@id = String(document?._id)
		@created = document?.created
		@updated = document?.updated

