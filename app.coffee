express = require "express"
app = express()
http = require("http").Server app
io = require("socket.io") http

process.env.DEBUG = false

# Allow for use of jade files for views
app.set "view engine", "jade"

# If in development, set html to output prettily and
# set debug to true
if app.get "env" == "development"
  app.locals.pretty = true
  process.env.DEBUG = true

app.use express.static "public"

require("./routes") app, express

# Set up gameserver, which deals with input from clients and
# controls game state and updates clients
require("./controllers/game-server").init io

# Check if ip address and port are defined by OpenShift
ipaddress = process.env.OPENSHIFT_NODEJS_IP ? "127.0.0.1"
port = process.env.OPENSHIFT_NODEJS_PORT ? 8080

# Start listening on indicated port and ip address
http.listen port, ipaddress, ->
  if process.env.DEBUG then console.log "listening on port #{port}"