assert = require 'assert'

suite 'Send event', ->
	test 'Check if log message can be written to file', (done) ->
		fs = require 'fs'
		testConfig = 
			file: '/tmp/test'
		
		fileHandler = require '../lib/logger/file'
		fileHandler {}, testConfig, 'Test message', { test: 'object' }, 'test', ->
			fs.stat testConfig.file, (error, stats) ->
				assert.ifError error
				assert.notEqual stats.size, 0, 'Empty log file, write failed'
				
				fs.unlink testConfig.file, ->
					done()
					
	test 'Check if log message can send to email', (done) ->
		@timeout 10000
		emailHandler = require '../lib/logger/email'
		testMonitorConfig = 
			project: 'Test'
		testConfig = 
			enabled: true
			email: 'voronchuk@gmail.com'
			mailer: 
				service: 'SendGrid'
				auth:
					user: 'voronchuk'
					pass: '[jvgjllth'
					handler: emailHandler
					
		emailHandler testMonitorConfig, testConfig, 'Test message', { test: 'object' }, 'test', (error) ->
			assert.ifError error
			done()
					
		
		
		