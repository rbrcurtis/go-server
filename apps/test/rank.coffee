db = require 'lib/db'

describe 'rank', ->
	it 'has a rating', ->
		user = new db.users.model
		rating = 0
		while true
			user.rating = rating
			console.log rating, '=', user.getRankString()
			rating += 10

			if rating > 3000 then break
