{Game} = require('./game')

key_mapping = {
  37: Game.MOVE_LEFT
  38: Game.MOVE_UP
  39: Game.MOVE_RIGHT
  40: Game.MOVE_DOWN
}

class exports.LocalPlayer

  constructor: () ->
    @keys_pressed = [Game.MOVE_NONE]
    @want_bomb = false

    document.addEventListener 'keydown', (event) =>
      direction = key_mapping[event.keyCode]

      if direction?
        if @keys_pressed.indexOf(direction) == -1
          @keys_pressed.unshift(direction)
      else if event.keyCode == 32
        @want_bomb = true

    document.addEventListener 'keyup', (event) =>
      direction = key_mapping[event.keyCode]

      if direction?
        index = @keys_pressed.indexOf(direction)
        if index != -1
          @keys_pressed.splice(index, 1)
        else
          console.log 'key released without being pressed'
      else if event.keyCode == 32
        @want_bomb = false


  tick: () ->
    return @keys_pressed[0]


  wantsBomb: () ->
    return @want_bomb

