# Author: Alberto (Bertie) Ancona, bancona@mit.edu
# Date Created: January 02, 2016
# Last Modified: January 08, 2016

log2 = Math.log2 or (x) -> Math.log(x) / Math.LN2

# Quadtree Class
# ---------------------
# Space quadtree implementation, where each node's four children represent the
# four quadrants enclosed in the space represented, in the following order:
# top-left, top-right, bottom-left, bottom-right.
#
# Tree nodes are stored in @nodes, which is a one-dimensional array. Tree levels
# are stored in order, such that the first element of @nodes is the root of the
# tree, then the next four elements are the four largest quadrants, and the next
# sixteen are the next largest quadrants, etc.
class Quadtree
  # Creates full Quadtree representing a two-dimensional space with dimensions
  # (@size by @size).
  #
  # @size must be a positive power of 2.
  constructor: (@size) ->
    # @size check found at:
    # exploringbinary.com/ten-ways-to-check-if-an-integer-is-a-power-of-two-in-c
    if (@size //= 1) <= 0 or @size & (@size - 1)
      throw new Error 'Quadtree size must be a positive power of 2.'

    @nodes = '0': [0, 0, 0, {}]
    @lastLevel = log2 @size
    @startIndexOfLevel = ((2**(2 * level) - 1) / 3 for level in [0..@lastLevel])
    @maxNodes = (4 * @size**2 - 1) / 3

  # Returns node corresponding to specified index of @nodes.
  # Returns null if no node with that index exists.
  getNodeAtIndex: (index) ->
    if index of @nodes then @nodes[index] else null

  # Returns 0-indexed level in the quadtree, calculated from @nodes array index.
  getLevelByIndex: (index) ->
    #log2(3 * index + 1) // 2
    i = -1
    num = 3 * index + 1
    while num != 0
      num >>= 1
      i += 1
    i >> 1

  # Returns relative index of node at specified index; that is, if the node is
  # the first in a level, returns 0, if second then return 1, etc.
  getPositionInLevel: (index, level) ->
    level ?= @getLevelByIndex index
    index - @startIndexOfLevel[level]

  # Returns indices of child nodes (four quadrants contained in index quadrant).
  getChildIndicesByIndex: (index) ->
    level = @getLevelByIndex index
    if level is @lastLevel then return [] # tree leaves have no children
    start = @startIndexOfLevel[level + 1]
    childPositionInLevel = 4 * @getPositionInLevel index, level
    (start + childPositionInLevel + i for i in [0...4])

  # Returns indices of existent child nodes (non-empty quadrants)
  getValidChildIndicesByIndex: (index) ->
    (i for i in @getChildIndicesByIndex(index) when i of @nodes)

  # Returns index of parent node, which is the quadrant containing the one
  # represented by node at index.
  getParentIndexByIndex: (index) ->
    level = @getLevelByIndex index
    parentLevel = level - 1
    @startIndexOfLevel[parentLevel] + @getPositionInLevel(index, level) // 4

  toString: (index = 0) ->
    representation = "#{index}: #{@nodes[index]}"
    for i in @getValidChildIndicesByIndex index
      representation += "\n#{@toString i}"
    representation

  # Returns position in @nodes corresponding to (x, y) position.
  # Mapping from coordinates to indices by Jimmy Zeng, MIT Class of 2018.
  convertCoordinatesToIndex: (x, y) ->
    unless 0 <= (x //= 1) < @size and 0 <= (y //= 1) < @size
      #console.log @toString()
      throw new RangeError "Quadtree.convertCoordinatesToIndex(): Coordinates
                            must be in range [0, #{@size}). Input: (#{x}, #{y})."
    c = 1
    index = 0

    until x is 0 and y is 0
      if x & 1 then index |= c
      c <<= 1
      x >>= 1
      if y & 1 then index |= c
      c <<= 1
      y >>= 1

    index + @startIndexOfLevel[@lastLevel]

  # Returns (x, y) position represented by index of @nodes
  convertIndexToCoordinates: (index) ->
    @verifyIndex index

    x = 0
    y = 0
    c = 1
    index -= @startIndexOfLevel[@lastLevel]

    while c <= index
      x |= c & index
      index >>= 1
      y |= c & index
      c <<= 1

    [x, y]

  verifyIndex: (index) ->
    0 <= index < @maxNodes

  isLeaf: (index) ->
    isLeafBool = @getLevelByIndex(index) is @lastLevel
    isLeafBool

  isRoot: (index) ->
    index is 0

  getLeafIndices: ->
    leaves = new Set()
    addLeaves = (index) ->
      if @isLeaf index
        leaves.add index
      else
        for i in @getValidChildIndicesByIndex index
          addLeaves i
    addLeaves 0
    return

class ParticleTree extends Quadtree
  constructor: (@size, @bounds) ->
    super @size

    @_X = 0
    @_Y = 1
    @_MASS = 2
    @_PARTICLES = 3
    @_VX = 3
    @_VY = 4

    @_G = .1

    @MAX_PARTICLES = 1000
    @MAX_VELOCITY = 15

    @_particleID = 0
    @_particleCount = 0

  # Adds particle to tree then updates centroids up through the tree from the
  # leaf where the particle was added to the root. Returns true iff particle was
  # successfully added, that is, if the particle count is less than the max.
  addParticle: (x, y, mass = 1, vx = 0, vy = 0, id = undefined) ->
    if @_particleCount >= @MAX_PARTICLES
      return false
    try
      index = @convertCoordinatesToIndex x, y
    catch error
      #console.log error.message
      return false
    id ?= @_getNewID()
    particle = [x, y, mass, vx, vy]
    if index of @nodes
      @nodes[index][@_MASS] += mass
      @nodes[index][@_PARTICLES][id] = particle
    else
      @nodes[index] = [x // 1, y // 1, mass, "#{id}": particle]
    @_maintainCentroids index
    @_particleCount += 1

    true

  # Removes particle from leaf, then updates centroids up through the tree, then
  # deletes unused nodes starting at the leaf. Returns particle iff particle
  # was successfully removed, else returns false.
  removeParticle: (x, y, id) ->
    index = @convertCoordinatesToIndex x, y
    if index of @nodes and id of @nodes[index][@_PARTICLES]
      @nodes[index][@_MASS] -= @nodes[index][@_PARTICLES][id][@_MASS]
      particle = @nodes[index][@_PARTICLES][id].slice 0
      delete @nodes[index][@_PARTICLES][id]
      @_maintainCentroids index
      @_removeUnusedNodes index
      @_particleCount -= 1
      return particle
    false

  # Generates new particle ID String and returns it.
  _getNewID: ->
    ((@_particleID += 1) % @MAX_PARTICLES).toString()

  # Goes from index upward through the tree until the root, deleting node
  # indices from @nodes if the mass at that node is 0. Stops iterating when it
  # reaches a node with a non-zero mass.
  _removeUnusedNodes: (index) ->
    @verifyIndex index
    until @nodes[index][@_MASS] > 0 or @isRoot index
      delete @nodes[index]
      index = @getParentIndexByIndex index
    return

  # Iterates upward through the tree from index, updating the centroid values of
  # nodes above index by summing the mass and averaging the x and y values of
  # the children of each node.
  _maintainCentroids: (index) ->
    @verifyIndex index
    until @isRoot index
      index = @getParentIndexByIndex index
      if index of @nodes
        @nodes[index][i] = 0 for i in [0...3]
      else
        @nodes[index] = [0, 0, 0, {}]
      numChildren = 0
      for childIndex in @getValidChildIndicesByIndex index
        numChildren += 1
        for property in [0...3]
          @nodes[index][property] += @nodes[childIndex][property]
      @nodes[index][@_X] /= numChildren
      @nodes[index][@_Y] /= numChildren
    return

  # Checks if quadrant represented by node at index intersects any of the lines
  # x = x0, y = y0, y - y0 = x - x0, and y - y0 = -x + x0.
  _intercepts: (x0, y0, index) ->
    level = @getLevelByIndex index
    indexOnLevel = index - @startIndexOfLevel[level]
    [nodeX, nodeY] = @convertIndexToCoordinates indexOnLevel
    size = @size / 2**level
    nodeX *= size
    nodeY *= size
    # Check horizontal and vertical:
    if nodeX < x0 < nodeX + size or nodeY < y0 < nodeY + size or \
    # Check diagonals
        # y - y0 = x - x0
        nodeX < (nodeY + x0 - y0) < (nodeX + size) or \
        nodeX < (nodeY + size + x0 - y0) < (nodeX + size) or \
        nodeY < (nodeX - x0 + y0) < (nodeY + size) or \
        nodeY < (nodeX + size - x0 + y0) < (nodeY + size) or \
        # y - y0 = x0 - x
        nodeX < (-nodeY + x0 - y0) < (nodeX + size) or \
        nodeX < (-(nodeY + size) + x0 + y0) < (nodeX + size) or \
        nodeY < (nodeX + x0 + y0) < (nodeY + size) or \
        nodeY < (-(nodeX + size) + x0 + y0) < (nodeY + size)
      true
    else
      false

  #
  _sumForces: (x, y, id) ->
    do getForce = (index = 0) =>
      if @_intercepts x, y, index
        childForces = (getForce(i) for i in @getValidChildIndicesByIndex index)
        forceX = 0
        forceY = 0
        for force in childForces
          forceX += force[0]
          forceY += force[1]
      else
        node = @nodes[index]
        r2 = Math.max .01, (x - node[@_X])**2 + (y - node[@_Y])**2
        gMassR2 = @_G * node[@_MASS] / r2
        forceX = (node[@_X] - x) * gMassR2
        forceY = (node[@_Y] - y) * gMassR2
      [forceX, forceY]

  _accelerateParticles: (timeSteps, index = 0) ->
    if @isLeaf index
      x = @nodes[index][@_X]
      y = @nodes[index][@_Y]
      for own id, particle of @nodes[index][@_PARTICLES]
        [ax, ay] = @_sumForces x, y, id
        particle[@_VX] += ax * timeSteps
        particle[@_VY] += ay * timeSteps
        if Math.abs(particle[@_VX]) > @MAX_VELOCITY
          sign = if particle[@_VX] >= 0 then 1 else -1
          particle[@_VX] = sign * @MAX_VELOCITY
        if Math.abs(particle[@_VY]) > @MAX_VELOCITY
          sign = if particle[@_VY] >= 0 then 1 else -1
          particle[@_VY] = sign * @MAX_VELOCITY
    else
      for i in @getValidChildIndicesByIndex index
        @_accelerateParticles timeSteps, i
    return

  _moveParticles: (timeSteps, index = 0) ->
    do addVelocities = (i = index) =>
      if @isLeaf i
        x = @nodes[i][@_X]
        y = @nodes[i][@_Y]
        for own id, particle of @nodes[i][@_PARTICLES]
          particle[@_X] += (particle[@_VX] or 0) * timeSteps
          particle[@_Y] += (particle[@_VY] or 0) * timeSteps
          unless @bounds.x <= particle[@_X] < @bounds.x + @bounds.width
            particle[@_X] -= particle[@_VX] * timeSteps
            particle[@_VX] *= -1
          unless @bounds.y <= particle[@_Y] < @bounds.y + @bounds.height
            particle[@_Y] -= particle[@_VY] * timeSteps
            particle[@_VY] *= -1
      else
        for j in @getValidChildIndicesByIndex i
          addVelocities j
      return
    do fixTree = (i = index) =>
      if @isLeaf i
        x = @nodes[i][@_X]
        y = @nodes[i][@_Y]
        for own id, particle of @nodes[i][@_PARTICLES]
          if particle[@_X] // 1 isnt x or particle[@_Y] // 1 isnt y
            particle = @removeParticle x, y, id
            @addParticle particle..., id
      else
        for j in @getValidChildIndicesByIndex i
          fixTree j
      return
    return

  _combineParticles: (index) ->
    if @isLeaf(index) and Object.keys(@nodes[index][@_PARTICLES]).length > 1
      # m0*v0 + m1*v1 == (m0+m1)*vf --> vf == (m0*v0 + m1*v1) / (m0+m1)
      mass = 0
      combinedID = null
      momentumX = 0
      momentumY = 0
      count = -1
      for own id, particle of @nodes[index][@_PARTICLES]
        count += 1
        combinedID = id
        momentumX += particle[@_MASS] * particle[@_VX]
        momentumY += particle[@_MASS] * particle[@_VY]
        mass += particle[@_MASS]
      vx = momentumX / mass
      vy = momentumY / mass
      [x, y] = @convertIndexToCoordinates index
      @nodes[index][@_PARTICLES] =
        "#{combinedID}": [x, y, mass, vx, vy]
      @_particleCount -= count
    else
      for i in @getValidChildIndicesByIndex index
        @_combineParticles i

  update: (timeSteps) ->
    @_combineParticles 0
    @_accelerateParticles timeSteps
    @_moveParticles timeSteps
    return

  getParticles: ->
    particles = {}
    do innerGetParticles = (index = 0) =>
      if @isLeaf index
        for own id, particle of @nodes[index][@_PARTICLES]
          particles[id] = particle.slice 0
      else
        for i in @getValidChildIndicesByIndex index
          innerGetParticles i
      return
    particles

module.exports.ParticleTree = ParticleTree