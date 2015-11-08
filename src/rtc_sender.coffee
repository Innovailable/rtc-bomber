class exports.RtcSender

  constructor: (@game, @channels) ->
    @game.on 'ticked', () =>
      @send()

  send: () ->
    # dimensions + field + player amount + players
    buf = new ArrayBuffer(2 + @game.width * @game.height + 1 + @game.players.length * 9)
    view = new Uint8Array(buf)

    index = 0

    view[index++] = @game.width
    view[index++] = @game.height

    # create field

    for line in @game.field
      for cell in line
        view[index++] = cell

    extend_field = (x, y, value) =>
      byte = 2 + x + y * @game.width
      view[byte] = (view[byte] & 0xf) | (value << 4)

    # add explosions

    for explosion in @game.explosions
      extend_field(explosion.x, explosion.y, 0xe)

    # add bombs

    for bomb in @game.bombs
      extend_field(bomb.x, bomb.y, 0xf)

    # add players

    view[index++] = @game.players.length

    for player in @game.players
      data_view = new DataView(buf, index)
      index += 8

      data_view.setFloat32(0, player.x)
      data_view.setFloat32(4, player.y)
      view[index++] = player.direction

    # send out

    for channel in @channels
      channel.send(buf)
