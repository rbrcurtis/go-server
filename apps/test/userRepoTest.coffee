db = require 'lib/db'

describe 'UserRepo', ->
	it 'can get users for an id list', (done) ->
		db.users.getByIdList ["4fdd6b031d49f1fa561c0002","4fdddc753347872758170002","4fddda5530a5f7457ff00003","505a711fb88ae23781600003"],
		(err, users) =>
			testLog err, users
			assert.equal null, err
			assert.ok users.length is 4

			done()
