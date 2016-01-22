module.exports = (gameContainer) ->
  gameContainer.mousemove = (args) ->
    localPt = gameContainer.toLocal args.data.global
    $('#mouselocation').html \
      if localPt.x? and localPt.x >= 0 and localPt.y? and localPt.y >= 0
        "(#{localPt.x // 1}, #{localPt.y // 1})"
      else
        ''
    return
  return