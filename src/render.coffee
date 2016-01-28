{Game} = require('./game')

# taken from: http://stackoverflow.com/a/32798277/514230
setPixelated = (context) ->
  context['imageSmoothingEnabled'] = false;       # standard
  context['mozImageSmoothingEnabled'] = false;    # Firefox
  context['oImageSmoothingEnabled'] = false;      # Opera
  context['webkitImageSmoothingEnabled'] = false; # Safari
  context['msImageSmoothingEnabled'] = false;     # IE

class exports.Render

  @COLORS = [
    'rgb(255, 0, 0)'
    'rgb(0, 255, 0)'
    'rgb(0, 0, 255)'
  ]

  @POWERUP_COLORS = [
    'rgb(255, 0, 0)'
    'rgb(0, 0, 0)'
  ]

  SCALE = 20
  HALF_SCALE = SCALE * 0.5
  THIRD_SCALE = SCALE / 3

  constructor: (@draw, @game) ->
    @draw.width = @game.field[0].length * SCALE
    @draw.height = @game.field.length * SCALE

    @draw_ctx = @draw.getContext('2d')

    # periodically render dynamic stuff

    @interval = setInterval () =>
      @render()
    , 40

    # initial render

    @render()

  close: () ->
    clearInterval(@interval)
    # TODO: remove callback

  render: () ->
    ctx = @draw_ctx
    ctx.clearRect(0, 0, @draw.width, @draw.height)

    for line, y in @game.field
      for cell, x in line
        switch cell
          when Game.GRID_WALL
            ctx.fillStyle = 'rgb(90, 90, 90)'
          when Game.GRID_ROCK
            ctx.fillStyle = 'rgb(205,150,100)'
          else
            ctx.fillStyle = 'rgb(255,255,255)'

        x_pos = x * SCALE
        y_pos = y * SCALE
        ctx.fillRect(x_pos, y_pos, SCALE, SCALE)

    for powerup in @game.powerups
      x_pos = powerup.x * SCALE
      y_pos = powerup.y * SCALE

      ctx.fillStyle = '#66ccff'
      ctx.fillStyle = 'rgb(120, 200, 255)'
      ctx.beginPath()
      ctx.moveTo(x_pos, y_pos)
      ctx.lineTo(x_pos + SCALE, y_pos)
      ctx.lineTo(x_pos + SCALE, y_pos + SCALE)
      ctx.lineTo(x_pos, y_pos + SCALE)
      ctx.fill()

      ctx.fillStyle = Render.POWERUP_COLORS[powerup.type]
      ctx.beginPath()
      ctx.moveTo(x_pos + THIRD_SCALE, y_pos + THIRD_SCALE)
      ctx.lineTo(x_pos + SCALE - THIRD_SCALE, y_pos + THIRD_SCALE)
      ctx.lineTo(x_pos + SCALE - THIRD_SCALE, y_pos + SCALE - THIRD_SCALE)
      ctx.lineTo(x_pos + THIRD_SCALE, y_pos + SCALE - THIRD_SCALE)
      ctx.fill()

    ctx.fillStyle = 'rgb(0,0,0)'

    for bomb in @game.bombs
      x_pos = bomb.x * SCALE + HALF_SCALE
      y_pos = bomb.y * SCALE + HALF_SCALE
      ctx.beginPath()
      ctx.arc(x_pos, y_pos, SCALE * 0.4, 0, 2*Math.PI)
      ctx.fill()

    for player in @game.players
      x_pos = player.x * SCALE
      y_pos = player.y * SCALE
      ctx.fillStyle = Render.COLORS[player.color]
      ctx.beginPath()
      ctx.moveTo(x_pos + HALF_SCALE, y_pos)
      ctx.lineTo(x_pos + SCALE, y_pos + HALF_SCALE)
      ctx.lineTo(x_pos + HALF_SCALE, y_pos + SCALE)
      ctx.lineTo(x_pos, y_pos + HALF_SCALE)
      ctx.fill()

    ctx.strokeStyle = 'rgb(255,0,0)'

    for explosion in @game.explosions
      x_pos = explosion.x * SCALE
      y_pos = explosion.y * SCALE
      ctx.beginPath()
      ctx.moveTo(x_pos, y_pos)
      ctx.lineTo(x_pos + SCALE, y_pos + SCALE)
      ctx.stroke()
      ctx.moveTo(x_pos + SCALE, y_pos)
      ctx.lineTo(x_pos, y_pos + SCALE)
      ctx.stroke()

