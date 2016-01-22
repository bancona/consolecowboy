io = null
init = (http) ->
  io = require('socket.io') http

module.exports = io