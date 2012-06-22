# CPU monitoring module
#
# Copyright (c) 2009-2012 [Vyacheslav Voronchuk](mailto:voronchuk@gmail.com), [Web management software](http://wm-software.com)
# Licensed to [Desk.no Ltd](http://www.desk.no) 
_ = require 'underscore'
fs = require 'fs'
path = require 'path'

module.exports = (callback) ->
	pid = "/proc/#{process.pid}/stat"
	
	unless path.existsSync pid
	    callback null, 1
	    console.log 'CPU monitor works only on Linux systems'
	    return
	
	fs.readFile pid, (error, data) ->
	    elems = data.toString().split ' '
	    utime = parseInt elems[13]
	    stime = parseInt elems[14]
	    callback error, (utime + stime)