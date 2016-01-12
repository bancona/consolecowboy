config = require './config'

stage = new PIXI.Container()
gameContainer = new PIXI.Graphics()
stage.interactive = true
stage.addChild gameContainer

renderer = PIXI.autoDetectRenderer config.WIDTH, config.HEIGHT
renderer.autoResize = true

document.body.appendChild renderer.view

render = (particleTree) =>
  gameContainer.clear()
  drawParticles = (index) =>
    childIndices = particleTree.getValidChildIndicesByIndex index
    if childIndices.length is 0
      for id, particle of particleTree.nodes[index][particleTree._PARTICLES]
        gameContainer.beginFill 0x111111 * particle[2]
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