crypto = require 'crypto'

exports.url = (user) ->
	md5 = crypto.createHash('md5').update(user.email).digest('hex')
	return "https://secure.gravatar.com/avatar/#{md5}?d=identicon"
