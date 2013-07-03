# Description:
#   Allow scripts to refer to users who have more than one IRC nickname

# running, loaded, connected

Util = require 'util'
console = require 'console'

# allDevs = []
# 
# class MultiNick
# 	constructor: (@redisname, @regex) ->
# 		allDevs.push @
# 
# new MultiNick(	'ironmagma',			/ironmagma|^im/i		)
# new MultiNick(	'zib',					/zib/i					)
# new MultiNick(	'nedbat',				/nedbat/i				)
# new MultiNick(	'RR_phone',				/(rr|rivrev)/i			)
# new MultiNick(	'Nick',					/(nick|shimmey)$/i		)
# new MultiNick(	'matt',					/matt/i					)
# new MultiNick(	'will',					/^will/i				)
# 
# alreadyMessaged = []
# 
module.exports = (robot) ->
# 	robot.brain.constructor::usersForFuzzyName = (fuzzyName) ->
# 		matches = []
# 		for own dev in allDevs
# 			regex = dev.regex
# 			redisName = dev.redisname
# 			if regex.test(fuzzyName)
# 				user = @userForName(redisName)
# 				if user
# 					matches.push user
# 				else
# 					robot.logger.error "MultiNick: Undefined user #{redisName}"
# 		return matches
