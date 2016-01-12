Graphics = require './graphics'
config = require './config'
ParticleTree = require('./quadtree').ParticleTree

particleTree = new ParticleTree config.WIDTH
particleQueue = require('./queue')()

mainLoop = ->
  mouse = Graphics.renderer.plugins.interaction.mouse
  mouseLoc = mouse.getLocalPosition Graphics.gameContainer
  if mouse.originalEvent?.type is "mousedown"
    particleTree.addParticle mouseLoc.x, mouseLoc.y

  particleTree.update 1
  Graphics.render particleTree
  requestAnimationFrame mainLoop

mainLoop()