Graphics = require './graphics'
config = require './config'
ParticleTree = require('./quadtree').ParticleTree

socket = io()

particleTree = new ParticleTree config.WIDTH,
  x: 0
  y: 0
  width: config.WIDTH
  height: config.WIDTH

Graphics.gameContainer.mouseup = Graphics.gameContainer.touchend = (args) ->
  localPt = Graphics.gameContainer.toLocal args.data.global
  particleTree.addParticle localPt.x, localPt.y
  return

require('./mouse-location-watch') Graphics.gameContainer

document.takeSnapshot = require('./take-snapshot') particleTree

do mainLoop = ->
  particleTree.update 1
  Graphics.render particleTree
  requestAnimationFrame mainLoop
  return
