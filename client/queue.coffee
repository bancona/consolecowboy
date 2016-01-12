class Node
  constructor: (@value, @next = null, @prev = null) ->

class Queue
  head: null
  tail: null
  push: (value) ->
    if @head is null
      @head = @tail = Node value
    else
      @tail.next = Node value, null, @tail
      @tail = @tail.next
    value
  pop: ->
    toPop = @head.value
    @head = @head.next
    toPop

module.exports = Queue