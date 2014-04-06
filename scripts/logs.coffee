util = require "util"
fs = require "fs"

strTwoDigits = (num) -> ('0'+num).slice(-2)

fmtDate = (date) ->
   (date.getFullYear()+0) + '-' +
      strTwoDigits(date.getMonth()+1) + '-' +
      strTwoDigits(date.getDate())

dateFromFmt = (fdate) ->
   [year, month, date] = (parseInt(y, 10) for y in fdate.split('-'))
   new Date(year, month-1, date, 0, 0, 0, 0)

normChannel= (chan) ->
   chan.toLowerCase().slice(1)

pending = { }

channelFiles = { }

removeChannelFile = (cf) ->
   x = channelFiles[cf.normedName]
   if x[fmtDate(cf.date)] == cf
      delete x[fmtDate(cf.date)]
   else
      util.error "Critical Error: specified ChannelFile does not exist in map"

getChannelFile = (normedchannel, date, callback) ->
   fdate = fmtDate(date)
   mychann = (channelFiles[normedchannel] ||= {})
   if date of mychann
      callback(null, mychann[fdate].fd, mychann[fdate]) 
   else
      mychann[fdate] = new ChannelFile(normedchannel, date, (err, fd) ->
         if err
            util.error("Could not load channel file for #{channel} and #{date}.", err)
            removeChannelFile(@)
            callback(err, null, null)
         else
            @fd = fd
            callback(null, @fd, @)
      )
      
getFilename = (chan, date) -> "#{chan}.#{fmtDate(date)}.log"

class ChannelFile
   constructor: (@normedName, @date, callback) ->
      @expireTimer
      @renewExpireTimer()
      @fd = null
      fs.open(getFilename(@normedName, @date), 'a', callback.bind(@))

   renewExpireTimer: () ->
      clearTimeout(@expireTimer)
      @expireTimer = setTimeout(
         => 
            removeChannelFile(@)
            fs.close(@fd, (e)=>util.error("Couldn't close file", e))
         , 1000 * (60 * 60 * 24 + 4)
      )

settlePending = (fdate) ->
   for own normedRoomName, room of pending
      for own date, items of room
         if items.alreadyHasCallbackPending
            continue
         items.alreadyHasCallbackPending = true

         realdate = dateFromFmt(date)

         getChannelFile(normedRoomName, realdate, do (items) -> (err, fd, cf) ->
            # TODO (unlikely) what happens if this function is
            # called so long after getChannelFile was called that
            # the file descriptor has been closed? We'll need to reopen it.
            # This is unlikely because it would have to have been a day's worth
            # of delays between function calls.
            
            if err
               util.error('Error: could not get channel file', err)
               items.alreadyHasCallbackPending = false
               return
            else
               a = 0
               b = items.length
               closeAfter = false
               if items[b-1] == null
                  items.pop()
                  closeAfter = true
               appendText = items.join('\n') + '\n'
               length = appendText.length
               fs.write(fd, new Buffer(appendText), 0, length, null, (err) -> 
                  if err
                     util.error('Error: could not append file', err)
                  else
                     items.splice(0, items.length)
                     if closeAfter
                        fs.close(fd, (err) ->
                           if err   
                              util.error('Couldn\'t close file!')
                           else
                              removeChannelFile(cf)
                        )
                  items.alreadyHasCallbackPending = false
               )
         )



setInterval(->
   console.log pending
,4000)

padZero2 = (num) ->
   num += ''
   if num.length < 2
      "0#{num}"
   else
      num

module.exports = (robot) ->

   robot.hear /.*/, (msg) ->
      user = msg.message.user
      msg.message.text
      console.log msg.message
      console.log "user room is #{user.room}"
      room = normChannel(user.room)
      fdate = fmtDate(new Date())

      for room in pending
         for own date of room
            if date < fdate and room[date].slice(-1)[0] != null
               room[date].push(null)

      mqueue = ((pending[room] ?= {})[fdate] ?= [])
      cdate = new Date()
      time = (padZero2(x) for x in [cdate.getHours(), cdate.getMinutes(), cdate.getSeconds()]).join(':')
      mqueue.push("[#{time}] <#{user.name}> #{msg.message.text}")
      settlePending(fdate)
