util = require "util"

strTwoDigits = (num) -> ('0'+num).slice(-2)

fmtDate = (date) ->
   date.getFullYear() + '-' +
      strTwoDigits(date.getMonth()+1) + '-' +
      strTwoDigits(date.getDate())

normChannel= (chan) ->
   chan.toLowerCase().slice(1)

pending = {

}

removeChannelFile = (cf) ->
   x = channelFiles[cf.normName]
   if x[fmtDate(cf.date)] == cf
      delete x[fmtDate(cf.date)]

getChannelFile = (channel, date, callback) ->
   norm = normChan(channel)
   fdate = fmtDate(date)
   mychann = (channelFiles[norm] ||= {})
   if date of mychann
      callback(mychann[date]) 
   else
      cf = mychann[date] = ChannelFile(channel, date, (err, fd) ->
         if err
            util.error("Could not load channel file for #{channel} and #{date}. Trying again in 1 second.", err)
            removeChannelFile(cf)
            setTimeout((-> getChannelFile(channel, date, callback)), 1000)
         else
            callback(err, fd)
      )

class ChannelFile
   constructor: (@name, @date, callback) ->
      @expireTimer
      @normName = normChan(@realName)
      @renewExpireTimer()
      fs.open(getFilename(@normName, @date), 'a', callback.bind(@))

   renewExpireTimer: () ->
      clearTimeout(@expireTimer)
      @expireTimer = setTimeout( 
         => 
            removeChannelFile(@)
            fs.close(@fd, (e)=> )
         , 1000 * (60 * 60 * 24 + 4)
      )

settlePending = (fdate) ->
   for own roomName, room of pending
      for own date, items of room
         a = 0
         b = items.length
         closeAfter = false
         if items[items.length-1] == null
            items.pop()
            closeAfter = true
         appendText = items.join('\n')




setInterval(->
   console.log pending
,4000)

module.exports = (robot) ->

   robot.hear /.*/, (msg) ->
      user = msg.message.user
      msg.message.text
      console.log msg.message
      room = normChannel(user.room)
      fdate = fmtDate(new Date())

      for own room in pending
         for own date of room
            if date < fdate and room[date].slice(-1)[0] != null
               room[date].push(null)

      mqueue = ((pending[room] ?= {})[fdate] ?= [])
      mqueue.push(user+': '+msg.message.text)
      settlePending(fdate)
