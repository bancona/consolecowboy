config = require './config'
Queue = require './queue'

connectedSockets = {}
numConnectedSockets = 0

spectatingSockets = Queue()

module.exports = (http, particleTree) ->
  io = require("socket.io") http
  io.on 'connection', (socket) ->
    if numConnectedSockets >= config.MAX_CONNECTIONS
      socket.emit 'Server full'
      spectatingSockets.push socket
    else
      numConnectedSockets += 1
      connectedSockets[socket.id] = socket
      socket.on 'New Particle', (particleData) ->
        x = particleData.x
        y = particleData.y
        mass = particleData.mass
        vx = particleData.vx
        vy = particleData.vy
        id = particleData.id
        particleTree.addParticle x, y, mass, vx, vy, socket.id + id
  io