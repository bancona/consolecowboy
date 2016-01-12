config = require './config'

stage = new PIXI.Container()
gameContainer = new PIXI.Graphics()
stage.interactive = true
stage.addChild gameContainer

gameContainer.width = config.WIDTH
gameContainer.height = config.HEIGHT

renderer = PIXI.autoDetectRenderer config.WIDTH, config.HEIGHT

document.body.appendChild renderer.view

render = (particleTree) =>
  gameContainer.clear()
  gameContainer.beginFill 0x00FF00
  drawParticles = (index) =>
    childIndices = particleTree.getValidChildIndicesByIndex index
    if childIndices.length is 0
      for id, particle of particleTree.nodes[index][particleTree._PARTICLES]
        gameContainer.drawCircle particle[0], particle[1], 5
    else
      for i in childIndices
        drawParticles i
  drawParticles 0
  renderer.render stage

module.exports.render = render
module.exports.renderer = renderer
module.exports.gameContainer = gameContainer
module.exports.stage = stage