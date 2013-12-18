aws  = require 'aws-lib'
smtp = require 'emailjs'



module.exports = class EmailMessenger
	
	constructor: ->
		@sesClient = aws.createSESClient(CONFIG.aws.keyId, CONFIG.aws.key)

	send: (message, recipient, cb) ->
		debug 'email', 'send', arguments...
		@sendViaSes message.subject, message.body, recipient, (err, response) =>
			if err?
				logError "[email] SES returned error", {error, response}
				cb? err

			else
				result = response.SendEmailResult
				log "[email] SES returned success", response
				cb? null, result
			

	sendViaSes: (subject, msg, address, cb) ->
		log "[email] Sending mail via SES with subject '#{subject}' to #{address} from", CONFIG.email.fromAddress
		
		parameters =
			'Destination.ToAddresses.member.1': address
			'Message.Body.Html.Charset': 'UTF-8'
			'Message.Body.Html.Data': msg
			'Message.Subject.Charset': 'UTF-8'
			'Message.Subject.Data': subject
			'Source': CONFIG.email.fromAddress

		debug 'email', 'params', parameters

		@sesClient.call "SendEmail", parameters, cb
			
			
