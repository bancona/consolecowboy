Graphics = require './graphics'
config = require './config'
ParticleTree = require('./quadtree').ParticleTree

particleTree = new ParticleTree config.WIDTH,
  x: 0
  y: 0
  width: 1024
  height: 1024

particleQueue = require('./queue')()

Graphics.gameContainer.mouseup = Graphics.gameContainer.touchend = (args) ->
  localPoint = Graphics.gameContainer.toLocal args.data.global
  particleTree.addParticle localPoint.x, localPoint.y

mainLoop = ->
  particleTree.update 1
  Graphics.render particleTree
  requestAnimationFrame mainLoop

mainLoop()