module.exports = (particleTree) -> ->
  particles = JSON.stringify particleTree.getParticles()
  console.log particles.length
  console.log particles
  snapshotElement = $ '#snapshot'
  snapshotElement.html 'Taking Snapshot...'
  $.ajax '/takesnapshot',
    type: 'POST'
    data: particles
    contentType: 'application/json'
    success: (data) ->
      snapshotElement.html data.message
      setTimeout(
        ->
          snapshotElement.html 'Take Snapshot'
          return
        , 3000
      )
      return
    error: ->
      snapshotElement.html 'Snapshot Failed. Please try again'
      setTimeout(
        ->
          snapshotElement.html 'Take Snapshot'
          return
        , 3000
      )
      return
  return