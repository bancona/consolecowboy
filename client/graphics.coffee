config = require './config'

stage = new PIXI.Container()
gameContainer = new PIXI.Graphics()
#stage.interactive = true
gameContainer.interactive = true
#stage.hitArea = new PIXI.Rectangle 0, 0, config.WIDTH, config.HEIGHT
gameContainer.hitArea = new PIXI.Rectangle 0, 0, config.WIDTH, config.HEIGHT
#console.log config.WIDTH
#console.log config.HEIGHT

stage.addChild gameContainer

renderer = PIXI.autoDetectRenderer config.WIDTH, config.HEIGHT
renderer.autoResize = true

document.body.appendChild renderer.view

colors = {}
getColor = (mass) ->
  if mass in colors
    colors[mass]
  else
    colors[mass] = ((20*mass) << 16) + ((8*mass) << 8) + (8*mass) + 0x111111

render = (particleTree) =>
  gameContainer.clear()
  do drawParticles = (index = 0) ->
    childIndices = particleTree.getValidChildIndicesByIndex index
    if childIndices.length is 0 # leaf
      [x, y] = particleTree.convertIndexToCoordinates index
      bounds = particleTree.bounds
      for id, particle of particleTree.nodes[index][particleTree._PARTICLES]
        radius = 2 + particle[2]
        if bounds.x > x + radius or bounds.x + bounds.width < x - radius \
            or bounds.y > y + radius or bounds.y + bounds.height < y - radius
          continue
        gameContainer.beginFill getColor particle[2]
        gameContainer.drawCircle particle[0], particle[1], radius
    else
      for i in childIndices
        drawParticles i
    return
  renderer.render stage

module.exports.render = render
module.exports.renderer = renderer
module.exports.gameContainer = gameContainer
module.exports.stage = stage