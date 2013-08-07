# Description:
#   Store messages for users who are unavailable


# running, loaded, connected

Util = require 'util'
console = require 'console'

allDevs = []

class MultiNick
	constructor: (@redisname, @regex) ->
		allDevs.push @

new MultiNick(  'everett',              /^ev(erett)?/i                   )
new MultiNick(  'Iman',                 /^iman/i                         )
new MultiNick(  'ironmagma',            /^ironmagma|^im(?!an)|^phil/i    )
new MultiNick(  'nedbat',               /^nedbat/i                       )
new MultiNick(  'matt',                 /matt/i                          )
new MultiNick(  'Nick',                 /(nick|shimmey)/i               )
new MultiNick(  'RR_phone',             /^(rr|rivrev)/i                  )
new MultiNick(  'will',                 /^will/i                         )
new MultiNick(  'zib',                  /^zib/i                          )
new MultiNick(  'Chad',                  /^chad/i                          )

alreadyMessaged = []

module.exports = (robot) ->
	robot.brain.constructor::usersForFuzzyName = (fuzzyName) ->
		matches = []
		for own dev in allDevs
			regex = dev.regex
			redisName = dev.redisname
			if regex.test(fuzzyName)
				user = @userForName(redisName)
				if user
					matches.push user
				else
					robot.logger.error "MultiNick: Undefined user #{redisName}"
		return matches

	deliverMessages = (room, user) ->
		targetUsers = robot.brain.usersForFuzzyName(user.name)
		if targetUsers.length == 0
			return
		else if targetUsers.length > 1
			if user.name not in alreadyMessaged
				robot.messageRoom room, "#{user.name}: I'd like to be your messenger, but there's some ambiguity in who you are. Please contact the bot administrator."
				alreadyMessaged.push user.name
			return

		singleUser = targetUsers[0]
		for own channel, msgs of singleUser.offmsgs
			continue if channel.toLowerCase() isnt room.toLowerCase()
			robot.messageRoom room, "#{user.name}: you have messages!" if msgs.length > 0
			while msgs.length > 0
				msg = msgs.shift()
				robot.messageRoom room, "#{user.name}: <#{msg.sender}> #{msg.message}"

	robot.enter (data) ->
		user = data.message.user
		room = data.message.room
		deliverMessages room, user

	robot.hear /^([a-zA-Z_-][a-zA-Z0-9_-]*)\)\s*(.+)$/i, (msg) ->
		user = msg.message.user
		room = user.room
		target = msg.match[1]
		message = msg.match[2]
		
		targetUsers = robot.brain.usersForFuzzyName(target)
		if targetUsers.length > 1
			msg.send "There's some ambiguity in who '#{target}' refers to."
			return
		else if targetUsers.length is 0
			msg.send "I don't know who #{target} is."
		return if not targetUsers.length

		targetUser = targetUsers[0]
		msg.send "#{user.name}: Stored that message for #{ (-> if (x=targetUser.realName)? then x else targetUser.name)() }"

		offmsgs = targetUser.offmsgs = (-> if (x=targetUser.offmsgs)? then x else {})()
		msgs = offmsgs[room] = (-> if (x=offmsgs[room])? then x else [])()
		msgs.push { sender: user.name, message: message }

	robot.hear /.*/, (msg) ->
		user = msg.message.user
		room = user.room
		deliverMessages room, user
