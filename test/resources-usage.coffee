assert = require 'assert' 
_ = require 'underscore'

defaultConfig = 
	usage:	
		cycle: 0
		resources: 	
		    ram:
		    	enabled: true
		    	handler: require '../lib/usage/ram'
		    	
		    	listeners:
		    		test: 100
		    	events:
		    		test: (value, callback) ->
		    			assert.equal value >= 100, true, 'RAM usage monitor fail'
		    			callback null, value

suite 'Resources Usage', ->		
	test 'Check RAM usage', (done) ->
		(require '../lib/usage/ram') (error, value) ->
			assert.equal error, null, error
			assert.notEqual (parseInt value), 0, 'No usage, smth wrong'
			console.log value
			done()

	test 'Check CPU usage', (done) ->
		(require '../lib/usage/cpu') (error, value) ->
			assert.equal error, null, error
			assert.notEqual (parseInt value), 0, 'No usage, smth wrong'
			if value > 1 then console.log value
			done()
			
	test 'Check usage event handlers', (done) ->
		monitor = (require '../lib/monitor') {}
		_.extend monitor.config, monitor.config, defaultConfig
								
		monitor.checkUsage (error, results) ->
			done()
			
	test 'Check if tracking is runned continuesly', (done) ->
		monitor = (require '../lib/monitor') {}
		_.extend monitor.config, monitor.config, defaultConfig
			
								
		monitor.trackUsage (error) ->
			assert.notEqual monitor.trackUsageCycles, null, 'Usage tracking was not runned properly' 
			if monitor.trackUsageCycles > 5
				monitor.config.usage.cycle = false
				done()
				
	test 'Check => comparation type', (done) ->
		monitor = (require '../lib/monitor') {}
		defaultConfig.usage.resources.ram.listeners.test = '>=100'
		defaultConfig.usage.resources.ram.events.test = (value, callback) ->
		    assert.equal value >= 100, true, 'RAM usage monitor fail'
		    done()
		    return
		_.extend monitor.config, monitor.config, defaultConfig
								
		monitor.checkUsage (error, results) ->
			assert.ok(false, '>= event was not triggered properly')
			
	test 'Check <= comparation type', (done) ->
		monitor = (require '../lib/monitor') {}
		defaultConfig.usage.resources.ram.listeners.test = '<=1000000000'
		defaultConfig.usage.resources.ram.events.test = (value, callback) ->
		    assert.equal value <= 1000000000, true, 'RAM usage monitor fail'
		    done()
		    return
		_.extend monitor.config, monitor.config, defaultConfig
								
		monitor.checkUsage (error, results) ->
			assert.ok(false, '<= event was not triggered properly')