// Generated by CoffeeScript 1.9.3
(function() {
  var Graphics, ParticleTree, config, mainLoop, particleQueue, particleTree;

  Graphics = require('./graphics');

  config = require('./config');

  ParticleTree = require('./quadtree').ParticleTree;

  particleTree = new ParticleTree(config.WIDTH, {
    x: 0,
    y: 0,
    width: 1024,
    height: 1024
  });

  particleQueue = require('./queue')();

  Graphics.gameContainer.mouseup = Graphics.gameContainer.touchend = function(args) {
    var localPoint;
    localPoint = Graphics.gameContainer.toLocal(args.data.global);
    return particleTree.addParticle(localPoint.x, localPoint.y);
  };

  mainLoop = function() {
    particleTree.update(1);
    Graphics.render(particleTree);
    return requestAnimationFrame(mainLoop);
  };

  mainLoop();

}).call(this);
