# Logic to save events in files
#
# Copyright (c) 2009-2012 [Vyacheslav Voronchuk](mailto:voronchuk@gmail.com), [Web management software](http://wm-software.com)
# Licensed to [Desk.no Ltd](http://www.desk.no) 
module.exports = (monitorConfig, config, message, object, type, callback) ->
	_ = require 'underscore'
	fs = require 'fs'
	path = require 'path'
	
	
	# Log message builder
	createMessage = (message, object, type = 'message') -> 
	    text = new Date().toString() + ":#{type}: #{message}\n"
	    unless (_.isUndefined object) or _.isNull object
	    	util = require 'util'
	    	text += util.inspect object
	    	text += "\n"
	    text += "\n"
	    
	    
	# Write log message to file
	fs.open config.file, 'a', 0o644, (error, fd) ->
		if error
			callback error
			return
	
		buffer = new Buffer createMessage(message, object, type)
		fs.write fd, buffer, 0, buffer.length, null, (error, written) ->
			if error
				callback error
				return

			fs.close fd, callback