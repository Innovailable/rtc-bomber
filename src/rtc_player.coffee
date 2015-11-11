{Game} = require('./game')

class exports.RtcPlayer

  constructor: (@channel) ->
    @_direction = Game.MOVE_NONE
    @_wants_bomb = false

    @channel.on 'message', (buf) =>
      view = new Uint8Array(buf)
      tick = view[0]
      @_direction = view[1]
      @_wants_bomb = view[2]


  input: () ->
    return @_direction


  wantsBomb: () ->
    return @_wants_bomb


  kill: () ->
