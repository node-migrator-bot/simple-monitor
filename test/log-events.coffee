process.env.NODE_ENV = 'test'

assert = require 'assert'	
_ = require 'underscore'

monitor = (require '../lib/monitor') {}

handler = (monitorConfig, config, message, object, type, done) ->
	assert.equal message, 'Test', 'Wrong message'
	assert.deepEqual object, {}, 'Wrong object'
	done()

suite 'Log event', ->			
	test 'Check if monitor logging function was executed properly for direct handler', (done) ->
		_.extend monitor.config, monitor.config,
			logger:
				handler: handler
		monitor.log 'Test', {}, 'error', done
		
	test 'Check if monitor logging function was executed properly for environment handler', (done) ->
		_.extend monitor.config, monitor.config,
			logger:
				test:
					handler: handler
		monitor.critical 'Test', {}, done
		
	test 'Check if monitor logging function was executed properly for type handler', (done) ->
		_.extend monitor.config, monitor.config,
			logger:
				error:
					handler: handler
		monitor.error 'Test', {}, done
		
	test 'Check if monitor logging function was executed properly for environment->type handler', (done) ->			
		_.extend monitor.config, monitor.config,
			logger:
				test:
					event:
						handler: handler
		monitor.event 'Test', {}, done
		
	test 'Check if monitor logging function was executed properly for environment->type default handler', (done) ->
		_.extend monitor.config, monitor.config,
			logger:
				test:
					default:
						handler: handler
		monitor.debug 'Test', {}, done