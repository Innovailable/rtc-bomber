seedrandom = require('seedrandom')
{EventEmitter} = require('events')

player_colors = [
  'rgb(255, 0, 0)'
  'rgb(0, 255, 0)'
  'rgb(0, 0, 255)'
]

class Game extends EventEmitter

  # configuration

  WIDTH = 25
  HEIGHT = 17

  # physics

  TICK_TIME = 20
  BASE_SPEED = 1 / 10
  SLIDE_PART = 0.4
  BOMB_TICKS = 75
  EXPLOSION_TICKS = 15

  # constants

  @GRID_OPEN: 0
  @GRID_ROCK: 1
  @GRID_WALL: 2
  @GRID_BOMB: 3
  @GRID_SPAWN: 4

  @MOVE_NONE: 0
  @MOVE_UP: 1
  @MOVE_RIGHT: 2
  @MOVE_DOWN: 3
  @MOVE_LEFT: 4

  constructor: (level, seed) ->
    @players = []
    @bombs = []
    @explosions = []
    @powerups = []

    @rng = seedrandom(seed)
    @field = level.field(@rng)
    @spawns = []

    for line, y in @field
      for cell, x in line
        if cell == Game.GRID_SPAWN
          line[x] = Game.GRID_OPEN
          @spawns.push({x: x, y: y})

    setInterval(@tick.bind(@), TICK_TIME)


  addPlayer: (player) ->
    @players.push({
      x: 3
      y: 3
      bombs: 1
      splash: 1
      color: player_colors[@players.length]
      player: player
    })


  tick: () ->
    field_changed = false

    # PLAYERS

    for player in @players
      # this is a helper which allows movement in all directions
      # `a` is the direction we intend to move in, `b` might be changed if we are blocked
      move = (a_id, b_id, direction, check) ->
        # where would we move to?
        new_a = player[a_id] + BASE_SPEED * direction

        # round to the tile we are moving to in direction `a`
        round = (i) ->
          if direction == 1
            return Math.floor(i) + 1
          else
            return Math.floor(i)

        # which tile are we moving on?
        new_round_a = round(new_a)

        # which tiles could be in the way?
        floor_b = Math.floor(player[b_id])
        left = check(new_round_a, floor_b)
        right = check(new_round_a, floor_b + +1)

        # how far off are we to which side?
        b_drift = player[b_id] - floor_b

        if not left and (b_drift == 0 or not right)
          # all clear! ahead
          player[a_id] = new_a
        else if b_drift <= BASE_SPEED and not left
          # a little nudge to the left
          player[b_id] = floor_b
        else if b_drift >= 1 - BASE_SPEED and not right
          # a little nudge to the right
          player[b_id] = floor_b + 1
        else if b_drift > 1 - SLIDE_PART and not right
          # we have to move right
          player[b_id] += BASE_SPEED
        else if b_drift < SLIDE_PART and not left
          # we have to move left
          player[b_id] -= BASE_SPEED
        else
          # well ... we bounced!

      direction = player.player.tick()

      switch direction
        when Game.MOVE_UP
          move('y', 'x', -1, (a, b) => @field[a][b])
        when Game.MOVE_RIGHT
          move('x', 'y', 1, (a, b) => @field[b][a])
        when Game.MOVE_DOWN
          move('y', 'x', 1, (a, b) => @field[a][b])
        when Game.MOVE_LEFT
          move('x', 'y', -1, (a, b) => @field[b][a])

      # spawn bombs

      if player.player.wantsBomb() and player.bombs > 0
        x = Math.round(player.x)
        y = Math.round(player.y)

        if @field[y][x] == Game.GRID_OPEN
          bomb = {
            player: player
            ticks: BOMB_TICKS
            splash: player.splash
            x: x
            y: y
          }

          @field[y][x] = Game.GRID_BOMB
          @bombs.push(bomb)

          player.bombs -= 1

    # BOMBS

    if @bombs.length
      for index in [@bombs.length-1..0]
        bomb = @bombs[index]

        if bomb.ticks <= 0
          # clear tile

          @field[bomb.y][bomb.x] = Game.GRID_OPEN

          # clear rocks

          explode = (x, y) =>
            @explosions.push({
              x: x
              y: y
              ticks: EXPLOSION_TICKS
            })

          explode(bomb.x, bomb.y)

          for [x_dir, y_dir] in [[0,1], [1,0], [0,-1], [-1,0]]
            x = bomb.x
            y = bomb.y

            for i in [1..bomb.splash]
              x += x_dir
              y += y_dir

              switch @field[y][x]
                when Game.GRID_ROCK
                  @field[y][x] = Game.GRID_OPEN
                  explode(x, y)
                  field_changed = true
                  break
                when Game.GRID_WALL
                  break
                else
                  explode(x, y)

          # give player the bomb back

          bomb.player.bombs += 1

          # clear the bomb

          @bombs.splice(index, 1)

        else
          bomb.ticks -= 1

    # EXPLOSIONS

    if @explosions.length
      for index in [@explosions.length-1..0]
        explosion = @explosions[index]

        # still exploding?
        if explosion.ticks <= 0
          @explosions.splice(index, 1)
        else
          explosion.ticks -= 1

    # EVENTS

    if field_changed
      @emit('field_changed')

    @emit('players_moved')

exports.Game = Game
