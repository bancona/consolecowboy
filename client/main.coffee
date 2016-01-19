Graphics = require './graphics'
config = require './config'
ParticleTree = require('./quadtree').ParticleTree

particleTree = new ParticleTree config.WIDTH,
  x: 0
  y: 0
  width: config.WIDTH
  height: config.WIDTH

Graphics.gameContainer.mouseup = Graphics.gameContainer.touchend = (args) ->
  localPoint = Graphics.gameContainer.toLocal args.data.global
  particleTree.addParticle localPoint.x, localPoint.y

Graphics.gameContainer.mousemove = (args) ->
  localPoint = Graphics.gameContainer.toLocal args.data.global
  if localPoint.x? and localPoint.y? and localPoint.x >= 0 and localPoint.y >= 0
    locationText = "(#{localPoint.x // 1}, #{localPoint.y // 1})"
  else
    locationText = ''
  document.getElementById('mouselocation').innerHTML = locationText

#(exports ? this).takeSnapshot = ->


do mainLoop = ->
  particleTree.update 1
  Graphics.render particleTree
  requestAnimationFrame mainLoop
