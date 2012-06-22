simple-monitor
==============

Runtime monitoring for node.js applications written in coffescript

Introduction
------------

simple-monitor gather vital statistics about your node.js application behavior
in development or/and production use.

It provides various type of notifiers which can be configured for different environments
and/or message types. Configuration is very flexible, so monitor have a lot of
uses cases suitable for diverse systems

It also gives you an event systems, for system resource usage (CPU and RAM), so you can scale
your system on fly depending on available resources or trigger notifications if system
is overloaded


Installation & Testing
----------------------

Node-monitor installs with *npm* and comes with an extensive suite of tests to 
make sure it performs well in your deployment environment.

To install and test node-monitor:

    $ npm install simple-monitor
    $ npm test


Error/Event Monitoring
----------------------

Define monitor module as variable 

    var monitor = require('simple-monitor')({ config settings });
    
By default 4 types of events are supported:
	
	monitor.debug('Debug message', variable = null);
	monitor.event('Some important event in application', variable = null);
	monitor.error('Error message', variable = null);
	monitor.critical('Some critical issue', variable = null);
	
All of those functions are shortcuts for: 
	
	monitor.log('Debug message', variable = null, event_type, callback);
	
You can define our own events, with custom *event_type*


### Configuration

Sample configuration

	monitor:
		enabled: true # Enable/disable monitor globaly
		project: 'cms-tweet-farmer@desk.no' # Used in reports
		
		# CPU and RAM usage 
		usage:	
			cycle: 0 # 0 - every system tick (nextTick), -1 - one time, false - disabled, other integer - period in milliseconds
			resources: 	
				ram: 
					enabled: true
					handler: '/node_modules/simple-monitor/lib/usage/ram' # Location of RAM handler logic
					
					listeners:
						overload: 500000 # If proccess uses more when 500000 bytes of RAM trigger event overload
					events:
						overload: (value, callback) -> # Handler for overload event
							console.log 'Sorrow: ' + value
							callback null, value
						
				cpu: 
					enabled: false
					handler: require global.APP_PATH + '/node_modules/simple-monitor/lib/usage/cpu'  # Location of CPU handler logic
				
		# Event log
		logger:
			critical: # Notifier for critical events
				enabled: true
				email: # node-mailer module configuration for email notificator
					service: 'SendGrid'
						auth:
							user: 'login'
							pass: 'password'
				mailer: 
					default: 'mail@gmail.com' # Email where to send default notifications
				handler: require '/node_modules/simple-monitor/lib/logger/email' # Email notifier handler
				
			default: # All other events should be written to log file
				enabled: true
				file: global.APP_PATH + '/logs/farm.log' # File to write logs
				handler: require '/node_modules/simple-monitor/lib/logger/file' # File notifier handler

You can use application environment in *logger* settings, for example:

	logger:
		production:
			critical:
				enabled: true
				email:
					service: 'SendGrid'
						auth:
							user: 'login'
							pass: 'password'
				mailer: 
					default: 'mail@gmail.com'
				handler: require '/node_modules/simple-monitor/lib/logger/email'
				
		development:
			default:
				enabled: true
				file: '/logs/events.log'
				handler: require '/node_modules/simple-monitor/lib/logger/file'
				
Monitor has some default settings, you can overwrite them by your config if needed:

	enabled: true
	project: 'My project'
	defaultType: 'error' # Default event type for *monitor.log*
	logger: # Default logger
	    file: __dirname + '/logs/error.log'
	    handler: unless process.env.NODE_ENV == 'test' then require __dirname + '/logger/file'
	monitorTypes: # Types of events which should be monitored depending of environment. For example, in production use we'll save only _critical_ events.
	    production:
	    	['critical']
	    stage:
	    	['critical', 'error', 'event']
	    test:
	    	['critical', 'error', 'event', 'debug']
	    development:
	    	['critical', 'error', 'event', 'debug']

Resource Usage Monitoring
-------------------------

With monitor you can enable system resources monitoring to provide your application
more flexible behavior depending on your system capabilities. For now CPU and RAM
monitoring are supported. Current CPU module works only on Linux systems.

In bootstrap of your application, enable _trackUsage_ once

	var monitor = require('simple-monitor')({ config settings });
	monitor.trackUsage(function(error) {
		monitor.critical('Resource usage tracking stopped', error);
	});
	
### Configuration
	
Depending on your configuration settings different events will be executed:

	usage:	
		cycle: 0 # 0 - every system tick (nextTick), -1 - one time, false - disabled, other integer - period in milliseconds
		resources: 	
		    ram: 
		    	enabled: true
		    	handler: '/node_modules/simple-monitor/lib/usage/ram' # Location of RAM handler logic
		    	
		    	listeners:
		    		overload: 500000 # If proccess uses more when 500000 bytes of RAM trigger event overload
		    	events:
		    		overload: (value, callback) -> # Handler for overload event
		    			console.log 'Sorrow: ' + value
		    			callback null, value
		    		
		    cpu: 
		    	enabled: false
		    	handler: require global.APP_PATH + '/node_modules/simple-monitor/lib/usage/cpu'  # Location of CPU handler logic
		    	
You can define your own events and their handlers simply by putting them in config file.
If you define listener as integer value, it will be compared with *>=* condition. You can also use
string values like: '>=INTEGER', '=INTEGER', '<=INTEGER', '<INTEGER', '>INTEGER'

License
-------
 
Released under the Apache License 2.0
 
See `LICENSE` file.
 
Copyright (c) 2012 Vyacheslav Voronchuk
