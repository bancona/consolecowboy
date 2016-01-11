# Author: Alberto (Bertie) Ancona, bancona@mit.edu
# Date Created: January 02, 2016
# Last Modified: January 08, 2016

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

    @reset()
    @lastLevel = @getLevelByIndex @nodes.length - 1
    @startIndexOfLevel = ((2**(2 * level) - 1) / 3 for level in [0..@lastLevel])
    @maxNodes = (4 * @size**2 - 1) / 3

  # Empties @nodes and returns reference to tree for easy chaining.
  reset: =>
    @nodes = {}
    this

  # Returns node corresponding to specified index of @nodes.
  # Returns null if no node with that index exists.
  getNodeAtIndex: (index) =>
    if index of @nodes then @nodes[index] else null

  # Returns 0-indexed level in the quadtree, calculated from @nodes array index.
  getLevelByIndex: (index) ->
    log2 = Math.log2 or (x) -> Math.log(x) / Math.LN2
    log2(3 * index + 1) // 2

  # Returns relative index of node at specified index; that is, if the node is
  # the first in a level, returns 0, if second then return 1, etc.
  getPositionInLevel: (index, level) =>
    level ?= @getLevelByIndex index
    index - @startIndexOfLevel[level]

  # Returns indices of child nodes (four quadrants contained in index quadrant).
  getChildIndicesByIndex: (index) =>
    level = @getLevelByIndex index
    if level is @lastLevel then return [] # tree leaves have no children
    start = @startIndexOfLevel[level + 1]
    childPositionInLevel = 4 * @getPositionInLevel index, level
    (start + childPositionInLevel + i for i in [0...4])

  # Returns indices of existent child nodes (non-empty quadrants)
  getValidChildIndicesByIndex: (index) =>
    (index for index in @getChildIndicesByIndex when index of @nodes)

  # Returns index of parent node, which is the quadrant containing the one
  # represented by node at index.
  getParentIndexByIndex: (index) =>
    level = @getLevelByIndex index
    parentLevel = level - 1
    @startIndexOfLevel[parentLevel] + @getPositionInLevel(index, level) // 4

  # Returns position in @nodes corresponding to (x, y) position.
  # Mapping from coordinates to indices by Jimmy Zeng, MIT Class of 2018.
  convertCoordinatesToIndex: (x, y) =>
    unless 0 <= (x = int x) < @size and 0 <= (y = int y) < @size
      throw new RangeError "Quadtree.convertCoordinatesToIndex(): Coordinates
                            must be in range [0, #{@size})."
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
  convertIndexToCoordinates: (index) =>
    @verifyIndex index

    x = 0
    y = 0
    c = 1
    index -= @startIndexOfLevel[@lastLevel]

    while c <= index
      y |= c & index
      index >>= 1
      x |= c & index
      c <<= 1

    [x, y]

  verifyIndex: (index) =>
    unless index is int(index) and \
        @startIndexOfLevel[@lastLevel] <= index < @maxNodes
      throw new RangeError "Quadtree.verifyIndex(): index must be
                      in range [#{@startIndexOfLevel[@lastLevel]}, @maxNodes)."
    return

  isLeaf: (index) =>
    @verifyIndex index
    index >= @startIndexOfLevel[@lastLevel]

  isRoot: (index) =>
    index is 0

class ParticleTree extends Quadtree
  @_X = 0
  @_Y = 1
  @_MASS = 2
  @_PARTICLES = 3
  @_VX = 3
  @_VY = 4

  @_G = 1

  @MAX_PARTICLES = 1000

  _particleID: 0
  _particle_count: 0

  # Adds particle to tree then updates centroids up through the tree from the
  # leaf where the particle was added to the root. Returns true iff particle was
  # successfully added, that is, if the particle count is less than the max.
  addParticle: (x, y, vx = 0, vy = 0, mass = 1) =>
    if @_particle_count >= @MAX_PARTICLES
      return false
    index = @convertCoordinatesToIndex x, y
    id = @_getNewID()
    particle = [x, y, mass, vx, vy]
    if index of @nodes
      @nodes[index][@_MASS] += mass
      @nodes[index][@_PARTICLES][id] = particle
    else
      @nodes[index] = [int(x), int(y), mass, {id: particle}]
    @_maintainCentroids index
    @_particle_count += 1
    true

  # Removes particle from leaf, then updates centroids up through the tree, then
  # deletes unused nodes starting at the leaf. Returns true iff particle was
  # successfully removed.
  removeParticle: (x, y, id) =>
    index = @convertCoordinatesToIndex x, y
    if index of @nodes and id of @nodes[index][@_PARTICLES]
      @nodes[index][@_MASS] -= @nodes[index][@_PARTICLES][id][@_MASS]
      delete @nodes[index][@_PARTICLES][id]
      @_maintainCentroids index
      @_removeUnusedNodes index
      @_particle_count -= 1
      return true
    false

  # Generates new particle ID String and returns it.
  _getNewID: =>
    (_particleID += 1).toString()

  # Goes from index upward through the tree until the root, deleting node
  # indices from @nodes if the mass at that node is 0. Stops iterating when it
  # reaches a node with a non-zero mass.
  _removeUnusedNodes: (index) =>
    @verifyIndex index
    until @nodes[index][@_MASS] > 0 or @isRoot index
      delete @nodes[index]
      index = @getParentIndexByIndex index
    return

  # Iterates upward through the tree from index, updating the centroid values of
  # nodes above index by summing the mass and averaging the x and y values of
  # the children of each node.
  _maintainCentroids: (index) =>
    @verifyIndex index
    until @isRoot index
      index = @getParentIndexByIndex index
      @nodes[index] = [0, 0, 0] # [x, y, mass] of centroid
      numChildren = 0
      for childIndex in @getValidChildIndicesByIndex index
        numChildren += 1
        for property in [0...@nodes[index].length]
          @nodes[index][property] += @nodes[childIndex][property]
      @nodes[index][@_X] //= numChildren
      @nodes[index][@_Y] //= numChildren
    return

  _intercepts: (x, y, index) =>
    level = @getLevelByIndex index
    indexOnLevel = index - @startIndexOfLevel[level]
    [nodeX, nodeY] = @convertIndexToCoordinates indexOnLevel
    size = @size / 2**level
    nodeX *= size
    nodeY *= size
    # Check horizontal and vertical:
    if nodeX < x < nodeX + size or nodeY < y < nodeY + size
      return true
    # Check diagonals
    if nodeX < nodeY + x - y < nodeX + size or \
       nodeX < nodeY + size + x - y < nodeX + size or \
       nodeY < nodeX - x + y < nodeY + size or \
       nodeY < nodeX + size - x + y < nodeY + size
      return true
    false

  #
  _sumForces: (x, y, id) =>
    getForce = (index = 0) ->
      if @_intercepts x, y, index
        childForces = (getForce(i) for i in @getValidChildIndicesByIndex index)
        forceX = 0
        forceY = 0
        for force in childForces
          forceX += force[0]
          forceY += force[1]
      else
        node = @nodes[index]
        r2 = (x - node[@_X])**2 + (y - node[@_Y])**2
        gMassR2 = @_G * node[@_MASS] / r2
        forceX = (node[@_X] - x) * gMassR2
        forceY = (node[@_Y] - y) * gMassR2
      [forceX, forceY]
    getForce()