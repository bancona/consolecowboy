# Author: Alberto (Bertie) Ancona, bancona@mit.edu
# Date Created: January 07, 2016
# Last Modified: January 07, 2016

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
#
# Each node in @nodes maintains some relationship with its descendants as
# specified in @invariantFunction. The @updateInvariant function can be called
# to call this function on each node of the tree so that the relationship is
# maintained.
log2 = Math.log2 or (x) -> Math.log(x) / Math.LN2

class Particle
  constructor: (@vx = 0, @vy = 0, @mass = 1) ->

class Node
  constructor: (@parent, @x = 0, @y = 0, @mass = 0) ->
    @children = (null for [0...4])
    @level = parent.level if parent? else 0

  addChild: (position, child) =>
    unless 0 <= (position //= 1) < 4
      throw new RangeException(
        'Node.addChild: position must be an integer in range [0, 4)')
    @children[position] = child
    child

  getChild: (position) =>
    unless 0 <= (position //= 1) < 4
      throw new RangeException(
        'Node.addChild: position must be an integer in range [0, 4)')
    @children[position]

  updateValues: =>
    @x = 0
    @y = 0
    @mass = 0
    for child in @children
      @x += child.x
      @y += child.y
      @mass += child.mass
    @x //= 4
    @y //= 4
    this

class Leaf extends Node
  constructor: (@parent, @x = 0, @y = 0, @mass = 0) ->
    super @parent, @x, @y, @mass
    @particles = new Set()

  addParticle: (particle) =>
    @particles.add particle

class Quadtree
  constructor: (@size) ->
    # @size check found at:
    # exploringbinary.com/ten-ways-to-check-if-an-integer-is-a-power-of-two-in-c
    if (@size //= 1) <= 0 or @size & (@size - 1)
      throw new Error 'Quadtree size must be a positive power of 2.'

    @numLevels = (log2 @size**2) / 2
    @lastLevel = @numLevels - 1

    @root = Node null

  addParticle: (x, y, vx, vy, mass=1) =>
    currentNode = @root
    isNewLeaf = false
    until currentNode instanceof Leaf
      nextNodeIndex = 0
      if x >= @size / 2**(currentNode.level + 1)
        nextNodeIndex += 1
      if y >= @size / 2**(currentNode.level + 1)
        nextNodeIndex += 2
      previousNode = currentNode
      currentNode = previousNode.getChild nextNodeIndex
      unless currentNode?
        if previousNode.level is @lastLevel - 1
          previousNode.addChild Leaf previousNode
          isNewLeaf = true
        previousNode.addChild Node previousNode

    if isNewLeaf
      currentNode.x = x
      currentNode.y = y

    currentNode.addParticle Particle vx, vy, mass

  # Creates full Quadtree representing a two-dimensional space with dimensions
  # (@size by @size), whose relationship between its nodes and descendants is
  # defined in @invariantFunction. The initial value at each node is defined in
  # @initialValue.
  #
  # @size must be a positive power of 2 and @invariantFunction must take as its
  # parameters an index and an array of nodes.
  constructor: (@size, @initialValue, @invariantFunction) ->
    # @size check found at:
    # exploringbinary.com/ten-ways-to-check-if-an-integer-is-a-power-of-two-in-c
    if (@size //= 1) <= 0 or @size & (@size - 1)
      throw new Error 'Quadtree size must be a positive power of 2.'

    @reset()
    @lastLevel = @getLevelByIndex @nodes.length - 1

  # Creates full Quadtree with each node's value set at @initialValue.
  reset: =>
    # Number of nodes is count of all quadrants:
    #   Summation of n^2/4^i from i=0 to i=log_4(n^2) is (4*n**2-1)/3.
    @nodes = (@initialValue for [0...(4 * @size**2 - 1) / 3])
    this

  # Maintains specified invariant in Quadtree by calling @invariantFunction on
  # each node except the leaves of the tree, iterating upward.
  updateInvariant: =>
    for i in [@getStartIndexOfLevel(@lastLevel) - 1..0]
      @invariantFunction @nodes, i
    this

  # Returns array of @nodes of quadtree.
  getNodes: =>
    @nodes

  # Returns node corresponding to specified index of @nodes.
  getNodeAtIndex: (index) =>
    @nodes[index]

  # Returns 0-indexed level in the quadtree, calculated from @nodes array index.
  getLevelByIndex: (index) ->
    log2 = Math.log2 or (x) -> Math.log(x) / Math.LN2
    log2(3 * index + 1) // 2

  # Returns index of @nodes corresponding to the start of the specified level of
  # the quadtree.
  getStartIndexOfLevel: (level) ->
    (2**(2 * level) - 1) / 3

  # Returns relative index of node at specified index; that is, if the node is
  # the first in a level, returns 0, if second then return 1, etc.
  getPositionInLevel: (index, level) =>
    level ?= @getLevelByIndex index
    index - @getStartIndexOfLevel level

  # Returns indices of child nodes (four quadrants contained in index quadrant).
  getChildIndicesByIndex: (index) =>
    level = @getLevelByIndex index
    if level is @lastLevel then return [] # tree leaves have no children
    start = @getStartIndexOfLevel level + 1
    childPositionInLevel = 4 * @getPositionInLevel index, level
    (start + childPositionInLevel + i for i in [0...4])

  # Returns index of parent node, which is the quadrant containing the one
  # represented by node at index.
  getParentIndexByIndex: (index) =>
    level = @getLevelByIndex index
    parentLevel = level - 1
    @getStartIndexOfLevel(parentLevel) + @getPositionInLevel(index, level)//4

  # Returns position in @nodes corresponding to (x, y) position, where
  # "top-left" is (0, 0) and "bottom-right" is (@size, @size).
  convertCoordinatesToIndex: (x, y) =>
    # Convert to integers.
    x //= 1
    y //= 1

    unless 0 <= x < @size and 0 <= y < @size
      throw new RangeError "Coordinates must be in the range [0, #{@size})."

    # TODO: map coordinates to number in range [0, @size**2) in quadtree style

module.exports = Quadtree