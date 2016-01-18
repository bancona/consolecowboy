config = require './config'

connectedSockets = {}
numConnectedSockets = 0

spectatingSockets = {}


module.exports = (http) ->
  io = require("socket.io") http
  io.on 'connection', (socket) ->
    if numConnectedSockets >= config.MAX_CONNECTIONS
      socket.emit 'Server full'
    else
      numConnectedSockets += 1
      connectedSockets[socket.id] = socket
      socket.on 'New Particle', (particleData) ->
        x = particleData.x
        y = particleData.y
        vx = particleData.vx
        vy = particleData.vy
        mass = particleData.mass
  io