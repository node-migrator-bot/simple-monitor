# Logic to send logs on email
#
# Copyright (c) 2009-2012 [Vyacheslav Voronchuk](mailto:voronchuk@gmail.com), [Web management software](http://wm-software.com)
# Licensed to [Desk.no Ltd](http://www.desk.no) 
module.exports = (monitorConfig, config, message, object, type, callback) ->
	_ = require 'underscore'
	fs = require 'fs'
	path = require 'path'
	nodemailer = require 'nodemailer'
	async = require 'async'
	
	# Create mailer transport
	smtpTransport = nodemailer.createTransport "SMTP", config.mailer
	
	# Basic email data 
	mailOptions =
		from: "#{monitorConfig.project} <no-reply@>simple-monitor.info"
		to: config.email
		subject: type.charAt(0).toUpperCase() + type.slice(1) + ": #{monitorConfig.project}"
	    
	# Send email logic
	send = (sendCallback, results) ->
		smtpTransport.sendMail mailOptions, (error, response) ->
			if error
				sendCallback error
				return
			
			smtpTransport.close()
			sendCallback()

	# Execution dependencies
	tasks =
		# Build text email
		build_text: (taskCallback) ->
			fs.readFile (config.textTemplate ? __dirname + '/resources/email.txt'), 'utf8', (error, data) ->
				if error
					taskCallback error
					return
				
				mailOptions.text = _.template data, 
					message: message
					type: type
					dump: (require 'util').inspect object
					date: new Date().toString()

				taskCallback null, mailOptions.text
		
		# Build HTML email
		build_html: (taskCallback) ->
			fs.readFile (config.htmlTemplate ? __dirname + '/resources/email.html'), 'utf8', (error, data) ->
				if error
					taskCallback error
					return
				
				mailOptions.html = _.template data, 
					message: message
					type: type
					dump: (require 'util').inspect object
					date: new Date().toString()
					
				taskCallback null, mailOptions.html
				
		# Send email after both templates were build
		send_email: ['build_text', 'build_html', send]
		
	# Run
	async.auto tasks, callback