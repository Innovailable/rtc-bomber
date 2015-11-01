{Game} = require('./game')

# taken from: http://stackoverflow.com/a/32798277/514230
setPixelated = (context) ->
  context['imageSmoothingEnabled'] = false;       # standard
  context['mozImageSmoothingEnabled'] = false;    # Firefox
  context['oImageSmoothingEnabled'] = false;      # Opera
  context['webkitImageSmoothingEnabled'] = false; # Safari
  context['msImageSmoothingEnabled'] = false;     # IE


class exports.Render

  SCALE = 20
  HALF_SCALE = SCALE * 0.5

  constructor: (@background, @draw, @game) ->
    adjust_canvas = (canvas) =>
      canvas.width = @game.field[0].length * SCALE
      canvas.height = @game.field.length * SCALE

    adjust_canvas(@background)
    @background_ctx = @background.getContext('2d')

    adjust_canvas(@draw)
    @draw_ctx = @draw.getContext('2d')

    # periodically render dynamic stuff

    setInterval () =>
      @render()
    , 40

    # render field when needed

    @game.on 'field_changed', =>
      @render_background()

    # initial render

    @render_background()
    @render()

  render_background: () ->
    ctx = @background_ctx

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


  render: () ->
    ctx = @draw_ctx
    ctx.clearRect(0, 0, @draw.width, @draw.height)

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
      ctx.fillStyle = player.color
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

