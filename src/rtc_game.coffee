{EventEmitter} = require('events')

player_colors = [
  'rgb(255, 0, 0)'
  'rgb(0, 255, 0)'
  'rgb(0, 0, 255)'
]

class exports.RtcGame extends EventEmitter

  constructor: (@channel) ->
    @width = 25
    @height = 17

    @explosions = []
    @bombs = []
    @players = []
    @powerups = []

    @field = []

    for y in [0..16]
      @field.push(new Array(@width))

    @channel.on 'message', (buf) =>
      @parse(buf)


  parse: (buf) ->
    view = new Uint8Array(buf)

    index = 0

    @width = view[index++]
    @height = view[index++]

    @players = []
    @explosions = []
    @bombs = []
    @powerups = []

    for y in [0..@height-1]
      for x in [0..@width-1]
        # get value

        cur = view[index++]

        # set field

        @field[y][x] = cur & 0xf

        # add special stuff

        special = (cur & 0xf0) >> 4

        if special
          if special < 3
            @powerups.push({x: x, y: y, type: special - 1})
          else
            switch special
              when 0xf
                @bombs.push({x: x, y: y})
              when 0xe
                @explosions.push({x: x, y: y})
              else
                console.log 'unknown special stuff', special

    player_count = view[index++]

    if player_count
      for player_num in [0..player_count-1]
        data_view = new DataView(buf, index)
        index += 8

        @players.push({
          x: data_view.getFloat32(0)
          y: data_view.getFloat32(4)
          direction: view[index++]
          color: view[index++]
        })

    @emit('ticked')
    @emit('field_changed')
