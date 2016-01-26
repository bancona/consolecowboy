(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  module.exports = {
    WIDTH: 1024,
    HEIGHT: 1024,
    BACKGROUND: 0x000000,
    MAX_PARTICLES: 1000
  };

}).call(this);

},{}],2:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  var colors, config, gameContainer, getColor, render, renderer, stage,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  config = require('./config');

  stage = new PIXI.Container();

  gameContainer = new PIXI.Graphics();

  gameContainer.interactive = true;

  gameContainer.hitArea = new PIXI.Rectangle(0, 0, config.WIDTH, config.HEIGHT);

  stage.addChild(gameContainer);

  renderer = PIXI.autoDetectRenderer(config.WIDTH, config.HEIGHT);

  renderer.autoResize = true;

  document.body.appendChild(renderer.view);

  colors = {};

  getColor = function(mass) {
    if (indexOf.call(colors, mass) >= 0) {
      return colors[mass];
    } else {
      return colors[mass] = ((20 * mass) << 16) + ((8 * mass) << 8) + (8 * mass) + 0x111111;
    }
  };

  render = (function(_this) {
    return function(particleTree) {
      var drawParticles;
      gameContainer.clear();
      (drawParticles = function(index) {
        var bounds, childIndices, i, id, j, len, particle, radius, ref, ref1, x, y;
        childIndices = particleTree.getValidChildIndicesByIndex(index);
        if (childIndices.length === 0) {
          ref = particleTree.convertIndexToCoordinates(index), x = ref[0], y = ref[1];
          bounds = particleTree.bounds;
          ref1 = particleTree.nodes[index][particleTree._PARTICLES];
          for (id in ref1) {
            particle = ref1[id];
            radius = 2 + particle[2];
            if (bounds.x > x + radius || bounds.x + bounds.width < x - radius || bounds.y > y + radius || bounds.y + bounds.height < y - radius) {
              continue;
            }
            gameContainer.beginFill(getColor(particle[2]));
            gameContainer.drawCircle(particle[0], particle[1], radius);
          }
        } else {
          for (j = 0, len = childIndices.length; j < len; j++) {
            i = childIndices[j];
            drawParticles(i);
          }
        }
      })(0);
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
  var Graphics, ParticleTree, config, mainLoop, particleTree;

  Graphics = require('./graphics');

  config = require('./config');

  ParticleTree = require('./quadtree').ParticleTree;

  particleTree = new ParticleTree(config.WIDTH, {
    x: 0,
    y: 0,
    width: config.WIDTH,
    height: config.WIDTH
  });

  $('#hint').html('Click anywhere to start!');

  Graphics.gameContainer.mousedown = function() {
    $('#hint').html('');
    Graphics.gameContainer.mousedown = function() {};
  };

  Graphics.gameContainer.mouseup = Graphics.gameContainer.touchend = function(args) {
    var localPt;
    localPt = Graphics.gameContainer.toLocal(args.data.global);
    particleTree.addParticle(localPt.x, localPt.y);
  };

  require('./mouse-location-watch')(Graphics.gameContainer);

  document.takeSnapshot = require('./take-snapshot')(particleTree);

  (mainLoop = function() {
    particleTree.update(1);
    Graphics.render(particleTree);
    requestAnimationFrame(mainLoop);
  })();

}).call(this);

},{"./config":1,"./graphics":2,"./mouse-location-watch":4,"./quadtree":5,"./take-snapshot":6}],4:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  module.exports = function(gameContainer) {
    gameContainer.mousemove = function(args) {
      var localPt;
      localPt = gameContainer.toLocal(args.data.global);
      $('#mouselocation').html((localPt.x != null) && localPt.x >= 0 && (localPt.y != null) && localPt.y >= 0 ? "(" + (Math.floor(localPt.x / 1)) + ", " + (Math.floor(localPt.y / 1)) + ")" : '');
    };
  };

}).call(this);

},{}],5:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  var ParticleTree, Quadtree, log2,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

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
        '0': [0, 0, 0, {}]
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
      var i, num;
      i = -1;
      num = 3 * index + 1;
      while (num !== 0) {
        num >>= 1;
        i += 1;
      }
      return i >> 1;
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
        x |= c & index;
        index >>= 1;
        y |= c & index;
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

    function ParticleTree(size1, bounds) {
      this.size = size1;
      this.bounds = bounds;
      ParticleTree.__super__.constructor.call(this, this.size);
      this._X = 0;
      this._Y = 1;
      this._MASS = 2;
      this._PARTICLES = 3;
      this._VX = 3;
      this._VY = 4;
      this._G = .1;
      this.MAX_PARTICLES = 1000;
      this.MAX_VELOCITY = 15;
      this._particleID = 0;
      this._particleCount = 0;
    }

    ParticleTree.prototype.addParticle = function(x, y, mass, vx, vy, id) {
      var error, index, obj, particle;
      if (mass == null) {
        mass = 1;
      }
      if (vx == null) {
        vx = 0;
      }
      if (vy == null) {
        vy = 0;
      }
      if (id == null) {
        id = void 0;
      }
      if (this._particleCount >= this.MAX_PARTICLES) {
        return false;
      }
      try {
        index = this.convertCoordinatesToIndex(x, y);
      } catch (_error) {
        error = _error;
        return false;
      }
      if (id == null) {
        id = this._getNewID();
      }
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
      this._particleCount += 1;
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
        this._particleCount -= 1;
        return particle;
      }
      return false;
    };

    ParticleTree.prototype._getNewID = function() {
      return ((this._particleID += 1) % this.MAX_PARTICLES).toString();
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
      if ((nodeX < x0 && x0 < nodeX + size) || (nodeY < y0 && y0 < nodeY + size) || (nodeX < (ref1 = nodeY + x0 - y0) && ref1 < (nodeX + size)) || (nodeX < (ref2 = nodeY + size + x0 - y0) && ref2 < (nodeX + size)) || (nodeY < (ref3 = nodeX - x0 + y0) && ref3 < (nodeY + size)) || (nodeY < (ref4 = nodeX + size - x0 + y0) && ref4 < (nodeY + size)) || (nodeX < (ref5 = -nodeY + x0 - y0) && ref5 < (nodeX + size)) || (nodeX < (ref6 = -(nodeY + size) + x0 + y0) && ref6 < (nodeX + size)) || (nodeY < (ref7 = nodeX + x0 + y0) && ref7 < (nodeY + size)) || (nodeY < (ref8 = -(nodeX + size) + x0 + y0) && ref8 < (nodeY + size))) {
        return true;
      } else {
        return false;
      }
    };

    ParticleTree.prototype._sumForces = function(x, y, id) {
      var getForce;
      return (getForce = (function(_this) {
        return function(index) {
          var childForces, force, forceX, forceY, gMassR2, i, k, len, node, r2;
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
      })(this))(0);
    };

    ParticleTree.prototype._accelerateParticles = function(timeSteps, index) {
      var ax, ay, i, id, k, len, particle, ref, ref1, ref2, sign, x, y;
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
          if (Math.abs(particle[this._VX]) > this.MAX_VELOCITY) {
            sign = particle[this._VX] >= 0 ? 1 : -1;
            particle[this._VX] = sign * this.MAX_VELOCITY;
          }
          if (Math.abs(particle[this._VY]) > this.MAX_VELOCITY) {
            sign = particle[this._VY] >= 0 ? 1 : -1;
            particle[this._VY] = sign * this.MAX_VELOCITY;
          }
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
      (addVelocities = (function(_this) {
        return function(i) {
          var id, j, k, len, particle, ref, ref1, ref2, ref3, x, y;
          if (_this.isLeaf(i)) {
            x = _this.nodes[i][_this._X];
            y = _this.nodes[i][_this._Y];
            ref = _this.nodes[i][_this._PARTICLES];
            for (id in ref) {
              if (!hasProp.call(ref, id)) continue;
              particle = ref[id];
              particle[_this._X] += (particle[_this._VX] || 0) * timeSteps;
              particle[_this._Y] += (particle[_this._VY] || 0) * timeSteps;
              if (!((_this.bounds.x <= (ref1 = particle[_this._X]) && ref1 < _this.bounds.x + _this.bounds.width))) {
                particle[_this._X] -= particle[_this._VX] * timeSteps;
                particle[_this._VX] *= -1;
              }
              if (!((_this.bounds.y <= (ref2 = particle[_this._Y]) && ref2 < _this.bounds.y + _this.bounds.height))) {
                particle[_this._Y] -= particle[_this._VY] * timeSteps;
                particle[_this._VY] *= -1;
              }
            }
          } else {
            ref3 = _this.getValidChildIndicesByIndex(i);
            for (k = 0, len = ref3.length; k < len; k++) {
              j = ref3[k];
              addVelocities(j);
            }
          }
        };
      })(this))(index);
      (fixTree = (function(_this) {
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
                _this.addParticle.apply(_this, slice.call(particle).concat([id]));
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
      })(this))(index);
    };

    ParticleTree.prototype._combineParticles = function(index) {
      var combinedID, count, i, id, k, len, mass, momentumX, momentumY, obj, particle, ref, ref1, ref2, results, vx, vy, x, y;
      if (this.isLeaf(index) && Object.keys(this.nodes[index][this._PARTICLES]).length > 1) {
        mass = 0;
        combinedID = null;
        momentumX = 0;
        momentumY = 0;
        count = -1;
        ref = this.nodes[index][this._PARTICLES];
        for (id in ref) {
          if (!hasProp.call(ref, id)) continue;
          particle = ref[id];
          count += 1;
          combinedID = id;
          momentumX += particle[this._MASS] * particle[this._VX];
          momentumY += particle[this._MASS] * particle[this._VY];
          mass += particle[this._MASS];
        }
        vx = momentumX / mass;
        vy = momentumY / mass;
        ref1 = this.convertIndexToCoordinates(index), x = ref1[0], y = ref1[1];
        this.nodes[index][this._PARTICLES] = (
          obj = {},
          obj["" + combinedID] = [x, y, mass, vx, vy],
          obj
        );
        return this._particleCount -= count;
      } else {
        ref2 = this.getValidChildIndicesByIndex(index);
        results = [];
        for (k = 0, len = ref2.length; k < len; k++) {
          i = ref2[k];
          results.push(this._combineParticles(i));
        }
        return results;
      }
    };

    ParticleTree.prototype.update = function(timeSteps) {
      this._combineParticles(0);
      this._accelerateParticles(timeSteps);
      this._moveParticles(timeSteps);
    };

    ParticleTree.prototype.getParticles = function() {
      var i, masses, storeParticles, vxs, vys, xs, ys;
      xs = new Array(this._particleCount);
      ys = new Array(this._particleCount);
      masses = new Array(this._particleCount);
      vxs = new Array(this._particleCount);
      vys = new Array(this._particleCount);
      i = 0;
      (storeParticles = (function(_this) {
        return function(index) {
          var id, j, k, len, particle, ref, ref1;
          if (_this.isLeaf(index)) {
            ref = _this.nodes[index][_this._PARTICLES];
            for (id in ref) {
              if (!hasProp.call(ref, id)) continue;
              particle = ref[id];
              xs[i] = Math.floor(particle[_this._X] / 1);
              ys[i] = Math.floor(particle[_this._Y] / 1);
              masses[i] = particle[_this._MASS];
              vxs[i] = (Math.floor((particle[_this._VX] * 100) / 1)) / 100;
              vys[i] = (Math.floor((particle[_this._VY] * 100) / 1)) / 100;
              i += 1;
            }
          } else {
            ref1 = _this.getValidChildIndicesByIndex(index);
            for (k = 0, len = ref1.length; k < len; k++) {
              j = ref1[k];
              storeParticles(j);
            }
          }
        };
      })(this))(0);
      return {
        xs: xs,
        ys: ys,
        masses: masses,
        vxs: vxs,
        vys: vys
      };
    };

    return ParticleTree;

  })(Quadtree);

  module.exports.ParticleTree = ParticleTree;

}).call(this);

},{}],6:[function(require,module,exports){
// Generated by CoffeeScript 1.9.3
(function() {
  module.exports = function(particleTree) {
    var snapshotElement;
    snapshotElement = $('#snapshot');
    snapshotElement.html('Take Snapshot');
    return function() {
      var particles;
      particles = JSON.stringify(particleTree.getParticles());
      console.log(particles.length);
      console.log(particles);
      snapshotElement.html('Taking Snapshot...');
      $.ajax('/takesnapshot', {
        type: 'POST',
        data: particles,
        contentType: 'application/json',
        success: function(data) {
          snapshotElement.html(data.message);
          setTimeout(function() {
            snapshotElement.html('Take Snapshot');
          }, 3000);
        },
        error: function() {
          snapshotElement.html('Snapshot Failed. Please try again');
          setTimeout(function() {
            snapshotElement.html('Take Snapshot');
          }, 3000);
        }
      });
    };
  };

}).call(this);

},{}]},{},[3]);
