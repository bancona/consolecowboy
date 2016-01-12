(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  module.exports = {
    WIDTH: 1024,
    HEGIHT: 1024,
    BACKGROUND: 0x000000,
    MAX_PARTICLES: 1000
  };

}).call(this);

},{}],2:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  var config, gameContainer, render, renderer, stage;

  config = require('./config');

  stage = new PIXI.Container();

  gameContainer = new PIXI.Graphics();

  stage.interactive = true;

  stage.addChild(gameContainer);

  gameContainer.width = config.WIDTH;

  gameContainer.height = config.HEIGHT;

  renderer = PIXI.autoDetectRenderer(config.WIDTH, config.HEIGHT);

  document.body.appendChild(renderer.view);

  render = (function(_this) {
    return function(particleTree) {
      var drawParticles;
      gameContainer.clear();
      gameContainer.beginFill(0x00FF00);
      drawParticles = function(index) {
        var childIndices, i, id, j, len, particle, ref, results, results1;
        childIndices = particleTree.getValidChildIndicesByIndex(index);
        if (childIndices.length === 0) {
          ref = particleTree.nodes[index][particleTree._PARTICLES];
          results = [];
          for (id in ref) {
            particle = ref[id];
            results.push(gameContainer.drawCircle(particle[0], particle[1], 5));
          }
          return results;
        } else {
          results1 = [];
          for (j = 0, len = childIndices.length; j < len; j++) {
            i = childIndices[j];
            results1.push(drawParticles(i));
          }
          return results1;
        }
      };
      drawParticles(0);
      return renderer.render(stage);
    };
  })(this);

  module.exports.render = render;

  module.exports.renderer = renderer;

  module.exports.gameContainer = gameContainer;

  module.exports.stage = stage;

}).call(this);

},{"./config":1}],3:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  var Graphics, ParticleTree, config, mainLoop, particleQueue, particleTree;

  Graphics = require('./graphics');

  config = require('./config');

  ParticleTree = require('./quadtree').ParticleTree;

  particleTree = new ParticleTree(config.WIDTH);

  particleQueue = require('./queue')();

  mainLoop = function() {
    var mouse, mouseLoc, ref;
    mouse = Graphics.renderer.plugins.interaction.mouse;
    mouseLoc = mouse.getLocalPosition(Graphics.gameContainer);
    if (((ref = mouse.originalEvent) != null ? ref.type : void 0) === "mousedown") {
      particleTree.addParticle(mouseLoc.x, mouseLoc.y);
    }
    particleTree.update(1);
    Graphics.render(particleTree);
    return requestAnimationFrame(mainLoop);
  };

  mainLoop();

}).call(this);

},{"./config":1,"./graphics":2,"./quadtree":4,"./queue":5}],4:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  var ParticleTree, Quadtree, log2,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  log2 = Math.log2 || function(x) {
    return Math.log(x) / Math.LN2;
  };

  Quadtree = (function() {
    function Quadtree(size1) {
      var level;
      this.size = size1;
      if ((this.size = Math.floor(this.size / 1)) <= 0 || this.size & (this.size - 1)) {
        throw new Error('Quadtree size must be a positive power of 2.');
      }
      this.nodes = {
        0: [0, 0, 0, {}]
      };
      this.lastLevel = log2(this.size);
      this.startIndexOfLevel = (function() {
        var k, ref, results;
        results = [];
        for (level = k = 0, ref = this.lastLevel; 0 <= ref ? k <= ref : k >= ref; level = 0 <= ref ? ++k : --k) {
          results.push((Math.pow(2, 2 * level) - 1) / 3);
        }
        return results;
      }).call(this);
      this.maxNodes = (4 * Math.pow(this.size, 2) - 1) / 3;
    }

    Quadtree.prototype.getNodeAtIndex = function(index) {
      if (index in this.nodes) {
        return this.nodes[index];
      } else {
        return null;
      }
    };

    Quadtree.prototype.getLevelByIndex = function(index) {
      return Math.floor(log2(3 * index + 1) / 2);
    };

    Quadtree.prototype.getPositionInLevel = function(index, level) {
      if (level == null) {
        level = this.getLevelByIndex(index);
      }
      return index - this.startIndexOfLevel[level];
    };

    Quadtree.prototype.getChildIndicesByIndex = function(index) {
      var childPositionInLevel, i, k, level, results, start;
      level = this.getLevelByIndex(index);
      if (level === this.lastLevel) {
        return [];
      }
      start = this.startIndexOfLevel[level + 1];
      childPositionInLevel = 4 * this.getPositionInLevel(index, level);
      results = [];
      for (i = k = 0; k < 4; i = ++k) {
        results.push(start + childPositionInLevel + i);
      }
      return results;
    };

    Quadtree.prototype.getValidChildIndicesByIndex = function(index) {
      var i, k, len, ref, results;
      ref = this.getChildIndicesByIndex(index);
      results = [];
      for (k = 0, len = ref.length; k < len; k++) {
        i = ref[k];
        if (i in this.nodes) {
          results.push(i);
        }
      }
      return results;
    };

    Quadtree.prototype.getParentIndexByIndex = function(index) {
      var level, parentLevel;
      level = this.getLevelByIndex(index);
      parentLevel = level - 1;
      return this.startIndexOfLevel[parentLevel] + Math.floor(this.getPositionInLevel(index, level) / 4);
    };

    Quadtree.prototype.toString = function(index) {
      var i, k, len, ref, representation;
      if (index == null) {
        index = 0;
      }
      representation = index + ": " + this.nodes[index];
      ref = this.getValidChildIndicesByIndex(index);
      for (k = 0, len = ref.length; k < len; k++) {
        i = ref[k];
        representation += "\n" + (this.toString(i));
      }
      return representation;
    };

    Quadtree.prototype.convertCoordinatesToIndex = function(x, y) {
      var c, index, ref, ref1;
      if (!((0 <= (ref = (x = Math.floor(x / 1))) && ref < this.size) && (0 <= (ref1 = (y = Math.floor(y / 1))) && ref1 < this.size))) {
        throw new RangeError("Quadtree.convertCoordinatesToIndex(): Coordinates must be in range [0, " + this.size + "). Input: (" + x + ", " + y + ").");
      }
      c = 1;
      index = 0;
      while (!(x === 0 && y === 0)) {
        if (x & 1) {
          index |= c;
        }
        c <<= 1;
        x >>= 1;
        if (y & 1) {
          index |= c;
        }
        c <<= 1;
        y >>= 1;
      }
      return index + this.startIndexOfLevel[this.lastLevel];
    };

    Quadtree.prototype.convertIndexToCoordinates = function(index) {
      var c, x, y;
      this.verifyIndex(index);
      x = 0;
      y = 0;
      c = 1;
      index -= this.startIndexOfLevel[this.lastLevel];
      while (c <= index) {
        y |= c & index;
        index >>= 1;
        x |= c & index;
        c <<= 1;
      }
      return [x, y];
    };

    Quadtree.prototype.verifyIndex = function(index) {
      return (0 <= index && index < this.maxNodes);
    };

    Quadtree.prototype.isLeaf = function(index) {
      var isLeafBool;
      isLeafBool = this.getLevelByIndex(index) === this.lastLevel;
      return isLeafBool;
    };

    Quadtree.prototype.isRoot = function(index) {
      return index === 0;
    };

    Quadtree.prototype.getLeafIndices = function() {
      var addLeaves, leaves;
      leaves = new Set();
      addLeaves = function(index) {
        var i, k, len, ref, results;
        if (this.isLeaf(index)) {
          return leaves.add(index);
        } else {
          ref = this.getValidChildIndicesByIndex(index);
          results = [];
          for (k = 0, len = ref.length; k < len; k++) {
            i = ref[k];
            results.push(addLeaves(i));
          }
          return results;
        }
      };
      addLeaves(0);
    };

    return Quadtree;

  })();

  ParticleTree = (function(superClass) {
    extend(ParticleTree, superClass);

    function ParticleTree(size1) {
      this.size = size1;
      ParticleTree.__super__.constructor.call(this, this.size);
      this._X = 0;
      this._Y = 1;
      this._MASS = 2;
      this._PARTICLES = 3;
      this._VX = 3;
      this._VY = 4;
      this._G = 1;
      this.MAX_PARTICLES = 1000;
      this._particleID = 0;
      this._particle_count = 0;
    }

    ParticleTree.prototype.addParticle = function(x, y, mass, vx, vy) {
      var error, id, index, obj, particle;
      if (mass == null) {
        mass = 1;
      }
      if (vx == null) {
        vx = 0;
      }
      if (vy == null) {
        vy = 0;
      }
      if (this._particle_count >= this.MAX_PARTICLES) {
        return false;
      }
      try {
        index = this.convertCoordinatesToIndex(x, y);
      } catch (_error) {
        error = _error;
        return false;
      }
      id = this._getNewID();
      particle = [x, y, mass, vx, vy];
      if (index in this.nodes) {
        this.nodes[index][this._MASS] += mass;
        this.nodes[index][this._PARTICLES][id] = particle;
      } else {
        this.nodes[index] = [
          Math.floor(x / 1), Math.floor(y / 1), mass, (
            obj = {},
            obj["" + id] = particle,
            obj
          )
        ];
      }
      this._maintainCentroids(index);
      this._particle_count += 1;
      return true;
    };

    ParticleTree.prototype.removeParticle = function(x, y, id) {
      var index, particle;
      index = this.convertCoordinatesToIndex(x, y);
      if (index in this.nodes && id in this.nodes[index][this._PARTICLES]) {
        this.nodes[index][this._MASS] -= this.nodes[index][this._PARTICLES][id][this._MASS];
        particle = this.nodes[index][this._PARTICLES][id].slice(0);
        delete this.nodes[index][this._PARTICLES][id];
        this._maintainCentroids(index);
        this._removeUnusedNodes(index);
        this._particle_count -= 1;
        return particle;
      }
      return false;
    };

    ParticleTree.prototype._getNewID = function() {
      return (this._particleID += 1).toString();
    };

    ParticleTree.prototype._removeUnusedNodes = function(index) {
      this.verifyIndex(index);
      while (!(this.nodes[index][this._MASS] > 0 || this.isRoot(index))) {
        delete this.nodes[index];
        index = this.getParentIndexByIndex(index);
      }
    };

    ParticleTree.prototype._maintainCentroids = function(index) {
      var childIndex, i, k, l, len, m, numChildren, property, ref;
      this.verifyIndex(index);
      while (!this.isRoot(index)) {
        index = this.getParentIndexByIndex(index);
        if (index in this.nodes) {
          for (i = k = 0; k < 3; i = ++k) {
            this.nodes[index][i] = 0;
          }
        } else {
          this.nodes[index] = [0, 0, 0, {}];
        }
        numChildren = 0;
        ref = this.getValidChildIndicesByIndex(index);
        for (l = 0, len = ref.length; l < len; l++) {
          childIndex = ref[l];
          numChildren += 1;
          for (property = m = 0; m < 3; property = ++m) {
            this.nodes[index][property] += this.nodes[childIndex][property];
          }
        }
        this.nodes[index][this._X] /= numChildren;
        this.nodes[index][this._Y] /= numChildren;
      }
    };

    ParticleTree.prototype._intercepts = function(x0, y0, index) {
      var indexOnLevel, level, nodeX, nodeY, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, size;
      level = this.getLevelByIndex(index);
      indexOnLevel = index - this.startIndexOfLevel[level];
      ref = this.convertIndexToCoordinates(indexOnLevel), nodeX = ref[0], nodeY = ref[1];
      size = this.size / Math.pow(2, level);
      nodeX *= size;
      nodeY *= size;
      if ((nodeX < x0 && x0 < nodeX + size) || (nodeY < y0 && y0 < nodeY + size)) {
        return true;
      }
      if ((nodeX < (ref1 = nodeY + x0 - y0) && ref1 < (nodeX + size)) || (nodeX < (ref2 = nodeY + size + x0 - y0) && ref2 < (nodeX + size)) || (nodeY < (ref3 = nodeX - x0 + y0) && ref3 < (nodeY + size)) || (nodeY < (ref4 = nodeX + size - x0 + y0) && ref4 < (nodeY + size))) {
        return true;
      }
      if ((nodeX < (ref5 = -nodeY + x0 - y0) && ref5 < (nodeX + size)) || (nodeX < (ref6 = -(nodeY + size) + x0 + y0) && ref6 < (nodeX + size)) || (nodeY < (ref7 = nodeX + x0 + y0) && ref7 < (nodeY + size)) || (nodeY < (ref8 = -(nodeX + size) + x0 + y0) && ref8 < (nodeY + size))) {
        return true;
      }
      return false;
    };

    ParticleTree.prototype._sumForces = function(x, y, id) {
      var getForce;
      getForce = (function(_this) {
        return function(index) {
          var childForces, force, forceX, forceY, gMassR2, i, k, len, node, r2;
          if (index == null) {
            index = 0;
          }
          if (_this._intercepts(x, y, index)) {
            childForces = (function() {
              var k, len, ref, results;
              ref = this.getValidChildIndicesByIndex(index);
              results = [];
              for (k = 0, len = ref.length; k < len; k++) {
                i = ref[k];
                results.push(getForce(i));
              }
              return results;
            }).call(_this);
            forceX = 0;
            forceY = 0;
            for (k = 0, len = childForces.length; k < len; k++) {
              force = childForces[k];
              forceX += force[0];
              forceY += force[1];
            }
          } else {
            node = _this.nodes[index];
            r2 = Math.max(.01, Math.pow(x - node[_this._X], 2) + Math.pow(y - node[_this._Y], 2));
            gMassR2 = _this._G * node[_this._MASS] / r2;
            forceX = (node[_this._X] - x) * gMassR2;
            forceY = (node[_this._Y] - y) * gMassR2;
          }
          return [forceX, forceY];
        };
      })(this);
      return getForce();
    };

    ParticleTree.prototype._accelerateParticles = function(timeSteps, index) {
      var ax, ay, i, id, k, len, particle, ref, ref1, ref2, x, y;
      if (index == null) {
        index = 0;
      }
      if (this.isLeaf(index)) {
        x = this.nodes[index][this._X];
        y = this.nodes[index][this._Y];
        ref = this.nodes[index][this._PARTICLES];
        for (id in ref) {
          if (!hasProp.call(ref, id)) continue;
          particle = ref[id];
          ref1 = this._sumForces(x, y, id), ax = ref1[0], ay = ref1[1];
          particle[this._VX] += ax * timeSteps;
          particle[this._VY] += ay * timeSteps;
        }
      } else {
        ref2 = this.getValidChildIndicesByIndex(index);
        for (k = 0, len = ref2.length; k < len; k++) {
          i = ref2[k];
          this._accelerateParticles(timeSteps, i);
        }
      }
    };

    ParticleTree.prototype._moveParticles = function(timeSteps, index) {
      var addVelocities, fixTree;
      if (index == null) {
        index = 0;
      }
      addVelocities = (function(_this) {
        return function(i) {
          var id, j, k, len, particle, ref, ref1, x, y;
          if (_this.isLeaf(i)) {
            x = _this.nodes[i][_this._X];
            y = _this.nodes[i][_this._Y];
            ref = _this.nodes[i][_this._PARTICLES];
            for (id in ref) {
              if (!hasProp.call(ref, id)) continue;
              particle = ref[id];
              particle[_this._X] += (particle[_this._VX] || 0) * timeSteps;
              particle[_this._Y] += (particle[_this._VY] || 0) * timeSteps;
            }
          } else {
            ref1 = _this.getValidChildIndicesByIndex(i);
            for (k = 0, len = ref1.length; k < len; k++) {
              j = ref1[k];
              addVelocities(j);
            }
          }
        };
      })(this);
      addVelocities(index);
      fixTree = (function(_this) {
        return function(i) {
          var id, j, k, len, particle, ref, ref1, x, y;
          if (_this.isLeaf(i)) {
            x = _this.nodes[i][_this._X];
            y = _this.nodes[i][_this._Y];
            ref = _this.nodes[i][_this._PARTICLES];
            for (id in ref) {
              if (!hasProp.call(ref, id)) continue;
              particle = ref[id];
              if (Math.floor(particle[_this._X] / 1) !== x || Math.floor(particle[_this._Y] / 1) !== y) {
                particle = _this.removeParticle(x, y, id);
                _this.addParticle.apply(_this, particle);
              }
            }
          } else {
            ref1 = _this.getValidChildIndicesByIndex(i);
            for (k = 0, len = ref1.length; k < len; k++) {
              j = ref1[k];
              fixTree(j);
            }
          }
        };
      })(this);
      fixTree(index);
    };

    ParticleTree.prototype.update = function(timeSteps) {
      this._accelerateParticles(timeSteps);
      this._moveParticles(timeSteps);
    };

    return ParticleTree;

  })(Quadtree);

  module.exports.ParticleTree = ParticleTree;

}).call(this);

},{}],5:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  var Node, Queue;

  Node = (function() {
    function Node(value1, next, prev) {
      this.value = value1;
      this.next = next != null ? next : null;
      this.prev = prev != null ? prev : null;
    }

    return Node;

  })();

  Queue = (function() {
    function Queue() {}

    Queue.prototype.head = null;

    Queue.prototype.tail = null;

    Queue.prototype.push = function(value) {
      if (this.head === null) {
        this.head = this.tail = Node(value);
      } else {
        this.tail.next = Node(value, null, this.tail);
        this.tail = this.tail.next;
      }
      return value;
    };

    Queue.prototype.pop = function() {
      var toPop;
      toPop = this.head.value;
      this.head = this.head.next;
      return toPop;
    };

    return Queue;

  })();

  module.exports = Queue;

}).call(this);

},{}]},{},[3]);
