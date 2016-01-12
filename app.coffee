express = require 'express'
app = express()
http = require('http').Server app
io = require('socket.io') http

process.env.DEBUG = false

# Allow for use of jade files for views
app.set 'view engine', 'jade'

# If in development, set html to output prettily and
# set debug to true
if app.get 'env' == 'development'
  app.locals.pretty = true
  process.env.DEBUG = true

app.use express.static 'public'

ipaddress = '127.0.0.1'
port = 8080

# Start listening on indicated port and ip address
http.listen port, ipaddress, ->
  if process.env.DEBUG then console.log "listening on port #{port}"