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

Graphics.gameContainer.mousemove = (args) ->
  localPt = Graphics.gameContainer.toLocal args.data.global
  $('#mouselocation').html \
    if localPt.x? and localPt.x >= 0 and localPt.y? and localPt.y >= 0
      "(#{localPt.x // 1}, #{localPt.y // 1})"
    else
      ''
  return

document.takeSnapshot = ->
  particles = particleTree.getParticles()
  snapshotElement = $ '#snapshot'
  snapshotElement.html 'Taking Snapshot...'
  $.ajax '/takesnapshot',
    type: 'POST'
    data: particles
    success: (data) ->
      snapshotElement.html data.message
      setTimeout(
        ->
          snapshotElement.html('Take Snapshot')
          return
        , 3000
      )
      return
    error: ->
      snapshotElement.html 'Snapshot Failed. Please try again'
      setTimeout(
        ->
          snapshotElement.html('Take Snapshot')
          return
        , 3000
      )
      return
  return

do mainLoop = ->
  particleTree.update 1
  Graphics.render particleTree
  requestAnimationFrame mainLoop
  return
