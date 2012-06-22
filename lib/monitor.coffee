# Entry point for monitor logic
#
# Copyright (c) 2009-2012 [Vyacheslav Voronchuk](mailto:voronchuk@gmail.com), [Web management software](http://wm-software.com)
# Licensed to [Desk.no Ltd](http://www.desk.no) 

# Module settings
# ---------------
# + __enable__: true/false
# + __defaultType__: default type of monitoring event
# + __project__: name of project to monitor (used in some subsystems)
# + __logger__: function which saves monitored event, or object for diffirent types of events/environments ({ production: { error: loggerFunction } })
# + __monitorTypes__: array with types which are monitored, can be object with diffirent arrays for environments ({ production: ['error', 'important'] })
module.exports = (config) ->
	_ = require 'underscore'
	async = require 'async'
	
	monitor = {}
	
	# Set config
	defaultConfig = 
		enabled: true
		project: 'My project'
		defaultType: 'error'
		logger: 
			file: __dirname + '/logs/error.log'
			handler: unless process.env.NODE_ENV == 'test' then require __dirname + '/logger/file'
		monitorTypes: 
			production:
				['critical']
			stage:
				['critical', 'error', 'event']
			test:
				['critical', 'error', 'event', 'debug']
			development:
				['critical', 'error', 'event', 'debug']
		
	_.extend monitor.config = {}, defaultConfig, config
	
	
	
	# Monitor resource usage
	# ----------------------
	monitor.trackUsageCycles = 0
	monitor.trackUsage = (callback) ->
		# No usage tracking if disabled
		unless monitor.config.enabled
			callback()
			return
			
		# Recursion check function
		check = (error) ->
			# System stop without callback
			if monitor.config.usage.cycle == false
				return
		
			# Error
			if error
				callback error
			
			# Add usage cycle	
			monitor.trackUsageCycles++
			
			# Recursion handler
			recursiveFn = async.apply monitor.checkUsage, check
			
			switch monitor.config.usage.cycle
				# System stop without callback
				when false then return
				
				# Run logic one time
				when -1 then 1
				
				# Run logic every tick
				when 0 then async.nextTick recursiveFn
				
				# Run logic by timer
				else setTimeout recursiveFn, monitor.config.usage.cycle
			
			# Cycle callback
			callback()

		# Run recursion
		monitor.checkUsage check
	
	
	# Track system resource usage
	# ---------------------------
	monitor.checkUsage = (callback = ->) -> 
		# No usage tracking if disabled
		unless monitor.config.enabled
			callback()
			return
			
		# Check resource
		checkResource = (config, eventsCallback = ->) ->
			# Check if usage monitor is enabled for that service
			unless (_.isUndefined config.enabled) or config.enabled == true
				eventsCallback()
				return

			# Check if handler function was defined properly
			unless _.isFunction config.handler
				eventsCallback 'Unknown usage handler'
				return
				
				
			# Setup event handlers if event occur
			events = []
			value = config.handler (error, value) -> 
				for event, condition of config.listeners
					# Default comparation
					if typeof condition == 'integer'
						if value >= condition
							if _.isFunction config.events[event]
								events.push async.apply config.events[event], value
						continue
					
					# Unsupported type
					else unless typeof condition == 'string'
						continue
						
						
					# Complex comparation
					buffer = condition.match /([<>=]+)(\d+)/
					unless buffer then continue
					
					# Supported comparations
					buffer[2] = parseInt buffer[2]
					switch buffer[1] 
						when '>'
							if value > buffer[2]
								if _.isFunction config.events[event]
									events.push async.apply config.events[event], value
									
						when '>='
							if value >= buffer[2]
								if _.isFunction config.events[event]
									events.push async.apply config.events[event], value
									
						when '<'
							if value < buffer[2]
								if _.isFunction config.events[event]
									events.push async.apply config.events[event], value
									
						when '<='
							if value <= buffer[2]
								if _.isFunction config.events[event]
									events.push async.apply config.events[event], value
									
						when '='
							if value == buffer[2]
								if _.isFunction config.events[event]
									events.push async.apply config.events[event], value
							
			# Run event logic in parallel
			async.parallel events, eventsCallback
			
			
		# Use separate trackers for each resource
		resources = []
		for resource, config of monitor.config.usage.resources
			resources.push async.apply checkResource, config
			
		# Run resource logic in parallel
		async.parallel resources, callback

	
	
	# Monitor of user-executed events
	# -------------------------------
	monitor.log = (message, object = null, type = monitor.defaultType, callback = ->) -> 
		# No logs if disabled
		unless monitor.config.enabled
			callback()
			return
	
		# Don't save event types which are not monitored
		validTypes = if _.isArray(monitor.config.monitorTypes) then monitor.config.monitorTypes else monitor.config.monitorTypes[process.env.NODE_ENV]
		if _.indexOf(validTypes, type) == -1
			callback()
			return

		# Log event
		unless _.isFunction monitor.config.logger.handler
			unless _.isUndefined monitor.config.logger[process.env.NODE_ENV]
				unless _.isFunction monitor.config.logger[process.env.NODE_ENV].handler
					unless _.isUndefined monitor.config.logger[process.env.NODE_ENV][type]
						if _.isFunction monitor.config.logger[process.env.NODE_ENV][type].handler
							logger = monitor.config.logger[process.env.NODE_ENV][type]
					else unless _.isUndefined monitor.config.logger[process.env.NODE_ENV]['default']
						if _.isFunction monitor.config.logger[process.env.NODE_ENV]['default'].handler
							logger = monitor.config.logger[process.env.NODE_ENV]['default']
				else
					logger = monitor.config.logger[process.env.NODE_ENV]
			
			else unless logger
				unless _.isUndefined monitor.config.logger[type]
					if _.isFunction monitor.config.logger[type].handler
						logger = monitor.config.logger[type]
				else unless _.isUndefined monitor.config.logger['default']
					if _.isFunction monitor.config.logger['default'].handler
						logger = monitor.config.logger['default']
		else
			logger = monitor.config.logger
		unless logger
			callback 'Unknown logging function'
			return
						
		# Check if specific handler was disabled
		unless (_.isUndefined logger.enabled) or logger.enabled == true
			callback()
			return

		# Delegate to logger
		logger.handler monitor.config, logger, message, object, type, callback
		
		
		
	# Shortcut for critical messages
	monitor.critical = (message, object = null, callback = ->) ->
		monitor.log message, object, 'critical', callback	
		
	# Shortcut for errors
	monitor.error = (message, object = null, callback = ->) ->
		monitor.log message, object, 'error', callback
	
	# Shortcut for events
	monitor.event = (message, object = null, callback = ->) ->
		monitor.log message, object, 'event', callback
		
	# Shortcut for debug messages
	monitor.debug = (message, object = null, callback = ->) ->
		monitor.log message, object, 'debug', callback
		
	# Self-reference
	monitor