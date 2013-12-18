module.exports =
	server: "https://go-versus.com/"
	http:
		port: 4000
	cookies:
		auth:
			name: 'm8.t'
			lifetime: 1000 * 60 * 60 * 24 * 14
			domain: '.mut8ed.com'
	mongo:
		url: 'mongodb://localhost/go'
	redis:
		host: 'localhost'
	rabbit:
		host: 'localhost'
	realtime:
		port: 4100
		countInterval: 10
	rateLimit:
		requestsPerSecond: 1
		burst: 10
	email:
		fromAddress: 'Go Versus <support@go-versus.com>'
	aws:
		keyId:     ''
		key:       ''

	wallet:
		id:   ''
		key: ''


	ssl:
		enabled: false
		key: 'certs/'
		cert: 'certs/'

	ai:
		password: ''
