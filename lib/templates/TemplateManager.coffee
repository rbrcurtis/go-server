fs = require 'fs'
eco = require 'eco'

FormatHelper = require './FormatHelper'

module.exports = class TemplateManager
	
	constructor: ->
		@templates = {}
		@_compileTemplates __dirname
		@formatter = new FormatHelper
	
	render: (type, name, context) ->
		context.render = (child) => @_renderTemplate(type, child, context)
		context.body = @_renderTemplate(type, name, context)
		return context
	
	_renderTemplate: (type, name, context) ->
		if not @templates[type]? or not @templates[type][name]?
			throw new Error("Can't render non-existent template #{name} of type #{type}")

		@templates[type][name](_.extend context, {format:@formatter})
	
	_compileTemplates: (root) ->
		for type in fs.readdirSync root
			path = "#{root}/#{type}"
			if fs.statSync(path).isDirectory()
				@templates[type] = {} unless @templates[type]?
				for filename in fs.readdirSync(path)
					if filename.match /\.eco$/
						name   = filename.substr(0, filename.length - 4)
						source = fs.readFileSync "#{path}/#{filename}", 'utf-8'
						@templates[type][name] = eco.compile(source)

