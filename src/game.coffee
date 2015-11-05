seedrandom = require('seedrandom')
{EventEmitter} = require('events')

each = (array, cb) ->
  if array.length > 0
    for index in [array.length-1..0]
      del = () -> array.splice(index, 1)
      cb(array[index], del)

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

  # ms one tick takes
  TICK_TIME = 20
  # speed of players
  BASE_SPEED = 1 / 10
  # how far to slide sideways on collision
  SLIDE_PART = 0.4
  # grace radius of explosion hits
  EXPLOSION_GRACE = 0.1
  # how long does a bomb last?
  BOMB_TICKS = 75
  # how long does an explosion last?
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
    player.x = 3
    player.y = 3
    player.bombs = 1
    player.splash = 2
    player.color = player_colors[@players.length]

    @players.push(player)


  collision: (x, y) ->
    if @field[y][x]
      return true

    for bomb in @bombs
      if bomb.x == x and bomb.y == y
        return true

    return false


  tick: () ->
    field_changed = false

    # PLAYER INPUT

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

      direction = player.tick()

      switch direction
        when Game.MOVE_UP
          move('y', 'x', -1, (a, b) => @collision(b, a))
        when Game.MOVE_RIGHT
          move('x', 'y', 1, (a, b) => @collision(a, b))
        when Game.MOVE_DOWN
          move('y', 'x', 1, (a, b) => @collision(b, a))
        when Game.MOVE_LEFT
          move('x', 'y', -1, (a, b) => @collision(a, b))

      # spawn bombs

      if player.wantsBomb() and player.bombs > 0
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

          @bombs.push(bomb)

          player.bombs -= 1

    # BOMBS

    if @bombs.length
      for index in [@bombs.length-1..0]
        bomb = @bombs[index]

        if bomb.ticks <= 0
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

              done = false

              switch @field[y][x]
                when Game.GRID_ROCK
                  @field[y][x] = Game.GRID_OPEN
                  explode(x, y)
                  field_changed = true
                  done = true
                when Game.GRID_WALL
                  done = true
                else
                  explode(x, y)

              if done
                break

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

    # EXPLOSION HITS

    if @players.length and @explosions.length
      for index in [@players.length-1..0]
        player = @players[index]

        # where would we be hit?

        matches = []

        x = Math.floor(player.x)
        y = Math.floor(player.y)
        x_drift = player.x - x
        y_drift = player.y - y

        if x_drift < 1 - EXPLOSION_GRACE
          if y_drift < 1 - EXPLOSION_GRACE
            matches.push([x, y])
          if y_drift > EXPLOSION_GRACE
            matches.push([x, y + 1])
        if x_drift > EXPLOSION_GRACE
          if y_drift < 1 - EXPLOSION_GRACE
            matches.push([x + 1, y])
          if y_drift > EXPLOSION_GRACE
            matches.push([x + 1, y + 1])

        # check against explosions

        for explosion in @explosions
          for match in matches
            if explosion.x == match[0] and explosion.y == match[1]
              console.log('boom!')
              player.kill()
              @players.splice(index, 1)
              break

    # EVENTS

    if field_changed
      @emit('field_changed')

    @emit('players_moved')

exports.Game = Game
