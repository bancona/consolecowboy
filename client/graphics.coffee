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

'''
document.getElementById('nav').style.margin = '0'
document.getElementById('nav').style.border = '0'
document.getElementById('nav').style['border-radius'] = '0'
document.getElementById('nav').style['background-color'] = '#AAA'

for a in document.getElementById('nav').getElementsByTagName 'a'
  a.style.color = '#FFF'
  a.style['margin-right'] = '10px'
'''

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