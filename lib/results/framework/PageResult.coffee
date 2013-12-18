
module.exports = class PageResult
	
	constructor: (docs, convert) ->
		unless docs then return
		@[index] = convert(doc) for doc, index in docs
		@length  = docs.length
	
	toJSON: ->
		_.toArray this

