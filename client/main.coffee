Graphics = require './graphics'
config = require './config'
ParticleTree = require('./quadtree').ParticleTree

particleTree = new ParticleTree config.WIDTH,
  x: 0
  y: 0
  width: 1024
  height: 1024

particleQueue = require('./queue')()

mainLoop = ->
  mouse = Graphics.renderer.plugins.interaction.mouse
  mouseLoc = mouse.getLocalPosition Graphics.gameContainer
  if mouse.originalEvent?.type is "mousedown"
    particleTree.addParticle mouseLoc.x, mouseLoc.y
    #console.log "particle added at (#{mouseLoc.x}, #{mouseLoc.y})"
  console.log "particle count: #{particleTree._particleCount}"

  particleTree.update 1
  Graphics.render particleTree
  requestAnimationFrame mainLoop

mainLoop()