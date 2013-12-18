Repository = require './Repository'
error = require 'lib/error'
async = require 'async'

class DocumentRepository extends Repository
	
	constructor: ->
		super
		@schema = @model.schema
	
	get: (query, fields, options, callback) ->
		@model.findOne(query, fields, options, callback)
	
	getById: (id, fields, options, callback) ->
		@model.findOne({_id:id}, fields, options, callback)
	
	getByRef: (ref, fields, options, callback) ->
		id = @_getIdFromRef ref
		unless id? then return callback error.badRequest()
		@getById(id, fields, options, callback)
	
	find: (query, fields, options, callback) ->
		@model.find(query, fields, options, callback)
	
	findAllById: (ids, fields, options, callback) ->
		@model.find({_id: { $in: ids }}, fields, options, callback)
	
	where: ->
		@model.where.apply @model, arguments
	
	save: (document, callback) ->
		unless document then return callback()
		document.save(callback)
	
	remove: (query, callback) ->
		@find query, (err, docs) =>
			if err then return callback err
			async.forEach(
				docs
				(doc, callback) -> doc.remove callback
				callback
			)
	
	_getIdFromRef: (ref) ->
		if _.isString(ref) then return ref
		if _.isObject(ref) and ref.id? then return ref.id
		return undefined

module.exports = DocumentRepository
