module.exports =

	options:
		get:        'get     /'
		options:    'options *'

	register:
		create:     'post    /register'

	login:
		login:      'post    /login'
		
	me:
		get:        'get     /me'
		update:     'put     /me'
		password:   'post    /me/password'

	user:
		get:        'get     /users/:user'
		
	game:
		create:     'post    /games'
		get:        'get     /games/:game'
		move:       'post    /games/:game/board/:x/:y'
		pass:       'post    /games/:game/pass'
		chat:       'post    /games/:game/chats'

	challenge:
		create:     'post    /challenges'
		get:        'get     /challenges/:challenge'
		update:     'put     /challenges/:challenge'

	search:
		findUser:   'get     /users/search/:query'

	notification:
		register:   'post    /notifications/register'

	event:
		since:      'get     /events/since/:since'

	donation:
		postback:   'post    /wallet/postback'
		getJwt:     'get     /donation/wallet/:userId'

	share:
		share:      'post    /share'

	verify:
		verify:     'post    /verify'

