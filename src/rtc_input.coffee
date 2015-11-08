class exports.RtcInput

  constructor: (@channel, @player) ->
    @count = 0
    setInterval(@send.bind(@), 50)


  send: () ->
    buf = new ArrayBuffer(3)

    view = new Uint8Array(buf)
    view[0] = @count++
    view[1] = @player.input()
    view[2] = @player.wantsBomb()

    @channel.send(buf)

