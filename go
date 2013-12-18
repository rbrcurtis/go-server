#!/usr/bin/env ./node_modules/coffee-script/bin/coffee

global.util = require 'util'
global.async = require 'async'
cluster = require 'cluster'
os = require 'os'
proc = require 'child_process'
fs = require 'fs'
colors = require 'colors'

if process.argv.length < 3
	console.log 'Usage: ./go <app>'
	process.exit(1)
	return


prodMode = if process.argv[3] is '-p' then true else false

global._      = require 'underscore'
global.CONFIG = require './config'
global.APP    = require "./apps/#{process.argv[2]}"

logPrefix = "#{APP.name} [#{if cluster.isMaster then 'master' else 'worker'} #{process.pid}]"

global.log = (args...) -> unless CONFIG.logging is false then console.log "#{new Date().toLocaleString()} #{logPrefix}", args...

global.logError = (args...) ->
	msg = "#{new Date().toLocaleString()} [ERROR] #{logPrefix}"
	for i,arg of args
		if arg?.stack
			stack = true
			args[i] = arg.stack
	console.log msg.red, args...
	unless stack then console.trace()
	
global.debug = (type, args...) ->
	if CONFIG.debug? and ((typeof CONFIG.debug is 'string' and CONFIG.debug is type) or (typeof CONFIG.debug is 'object' and _.contains CONFIG.debug, type))
		console.log "#{new Date().toLocaleString()} #{logPrefix} [#{type}]".cyan, args...

global.notify = (title, msg, error = false) ->
	if error and msg is 'The "sys" module is now called "util". It should have a similar interface.'
		return
		
	proc.spawn 'growlnotify', ["-m", msg, title]
	if error
		logError "#{title} : #{msg}"
	else
		console.log "#{title} : #{msg}".green
		

appPath = "#{__dirname}/apps/#{process.argv[2]}"
process.env.NODE_PATH+=":#{appPath}:#{__dirname}"

# process.on 'uncaughtException', (err) ->
# 	notify "[#{APP.name}] UNCAUGHT EXCEPTION", err.stack or err, true
# 	if prodMode then process.exit(1)

if process.env.PROC_MASTER or APP.name is 'repl'
	
	if cluster.isMaster and APP.cluster is true
		log 'ima master', process.pid
		process.on 'exit', ->
			log 'exit!'
			for id, worker of cluster.workers
				worker.destroy()
			
			
		numWorkers = CONFIG.workers ? os.cpus().length
		for idx in [1..numWorkers]
			worker = cluster.fork()
			notify "[#{APP.name}] birth", "worker #{worker.process.pid} started"
			

		log "spawned #{numWorkers} workers"
		cluster.on 'exit', (worker, code, signal) ->
			if code
				notify "[#{APP.name}] death", "worker #{worker.process.pid} died :(", true
			else
				notify "[#{APP.name}] death", "worker #{worker.process.pid} exited", false
			if prodMode
				if code isnt 0
					cluster.fork()
					notify "[#{APP.name}] birth", "worker #{worker.process.pid} started"
				
				if Object.keys(cluster.workers).length is 0
					notify "[#{APP.name}] exit", "no workers remaining"
					process.exit 0
			else
				hang = ->
					process.nextTick hang
				hang()
					
				
	else
		APP.run()
	
	
else
	master = null
	startMaster = ->
		master = proc.spawn __filename, process.argv.slice(2), _.extend process.env, {PROC_MASTER:true}
		master.stdout.on 'data', (buffer) -> process.stdout.write buffer.toString()
		master.stderr.on 'data', (buffer) -> 
			unless buffer.toString().match /WARNING/ then notify "ERROR FROM MASTER", buffer.toString().trim(), true
		process.stdin.resume()
		process.stdin.pipe master.stdin
		master.on 'exit', exit
		return master
	exit = (code, signal) ->
		# notify "master #{master.pid} exit", "exit with code #{code}, signal #{signal}", false
		if signal is 'SIGABRT' 
			master = startMaster()
		else if code is 0
			process.exit 0

		# else do nothing

	master = startMaster()
	
	
	
	onChange = (file) =>
		notify "#{process.argv[2]} Restarting", "#{file.substr file.lastIndexOf('/')+1} changed"
		if master.exitCode?
			master = startMaster()
		else
			master.kill('SIGABRT')
		
	watching = {}
	
	watchDir = (dir) ->
		fs.readdir dir, (err, files) =>
			if err?
				notify "error", err, true
				return
			for file in files
				file = dir+"/"+file
				do (file) =>
					if watching[file]? then return
					watching[file] = true
					fs.stat file, (err, stats) =>
						throw err if err?
						if stats.isDirectory()
							watchDir file
							
						fs.watchFile file, {interval: 500, persistent: true}, (cur, prev) =>
							if cur and +cur.mtime isnt +prev.mtime
								if stats.isDirectory()
									watchDir file
								onChange(file)
				
	watchDir appPath
	watchDir './lib'
	watchDir './config'
	
	 
