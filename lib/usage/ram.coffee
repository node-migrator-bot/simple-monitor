# RAM monitoring module
#
# Copyright (c) 2009-2012 [Vyacheslav Voronchuk](mailto:voronchuk@gmail.com), [Web management software](http://wm-software.com)
# Licensed to [Desk.no Ltd](http://www.desk.no) 
module.exports = (callback) ->	
	callback null, process.memoryUsage().rss