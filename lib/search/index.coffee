async     = require 'async'

elastical = require 'elastical'
db        = require 'lib/db'

AttachmentResult = require 'lib/results/AttachmentResult'

module.exports = new class Searcher
	
	limit: 10
	
	constructor: ->
		@searcher = new elastical.Client CONFIG.search.host
		
		@highlight = 
			fields: {}
			
		for type,repo of db
			for key of repo.schema.tree
				@highlight.fields[key] = {}
				
		# file attachments
		@highlight.fields.filename = {}
		@highlight.fields.filetype = {}
		
		# github attachments
		@highlight.fields.msg = {}
		@highlight.fields.url = {}
		
		
	save: (type, doc, callback) ->

		 # this is dumb.  mongoose doesn't have a way to convert the model to a standard json object.  toJSON looks good but the objectids get converted poorly
		doc = JSON.parse(JSON.stringify(doc))

		log "indexing", doc
		
		index = (id) => @searcher.index CONFIG.search.indexName, type, doc, {id}, (err, res) =>
			logError "search index err", err if err?
			log "search index res", res, 99
			callback err, res

		if type is 'Card'
			async.map(
				doc.owners
				(owner, callback) ->
					db.users.get _id:owner, callback
				(err, results) ->
					if err then return callback err, null
					
					owners = (user.username for user in results)
					doc.owners = owners
					
					index(doc._id)
					
			)
		else if type is 'Attachment'
			doc = new AttachmentResult doc
			index(doc.id)

		else index(doc._id)
		
			
	remove: (type, id, callback) ->
		@searcher.delete CONFIG.search.indexName, type, id, {}, (err, res) =>
			logError "search delete err", err if err?
			log "search delete res", res, 99
			if callback then callback err, res
			
	search: (project, query, callback) ->
		
		opts = 
			index:CONFIG.search.indexName
			query:query
			filter:
				term:
					{project}
			highlight: @highlight
				
		log 'highlight', @highlight, 99
		

		@searcher.search opts, (err, results, res) =>
			if results.hits.length > @limit
				results.hits.splice @limit #, results.hits.length-@limit
			logError "search err", err if err?
			log "search results", results, 99
			log "search res", res, 99
			
			callback err, results, res

	


