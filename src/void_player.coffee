{Game} = require('./game')

class exports.VoidPlayer

  input: () ->
    return Game.MOVE_NONE


  wantsBomb: () ->
    return false


  kill: () ->
