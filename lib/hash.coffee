bcrypt = require 'bcrypt'
crypto = require 'crypto'

module.exports = new class HashService
	
	hashPassword: (plaintext) ->
		salt = bcrypt.genSaltSync(10)
		pass = bcrypt.hashSync(plaintext, salt)
		return pass
		
	verifyPassword: (plaintext, hash) ->
		authed = bcrypt.compareSync plaintext, hash
		
	setToken: (user) ->
		# contains user's id so that it can be used as the shardkey
		user.token = String(user._id)+String(@hash(Math.random()))
		
	hash: (str) ->
		return crypto.createHash('sha256').update(str.toString()).digest('hex')
