rtc = require('rtc-lib')

{Game} = require('./game')
{Render} = require('./render')
{LocalPlayer} = require('./local_player')
{RtcPlayer} = require('./rtc_player')
{RtcInput} = require('./rtc_input')
{RtcSender} = require('./rtc_sender')
{RtcGame} = require('./rtc_game')
levels = require('./levels')

data_channel_conf = {
  ordered: false
}

class exports.Bomber

  constructor: (room, @background, @draw) ->
    global.room =@room = new rtc.Room(@signaling_url(room), {auto_connect: false, stun: 'stun:stun.palava.tv'})
    @peers = {}


  signaling_url: (room="") ->
    if process.env.SIGNALING_BASE?
      base = process.env.SIGNALING_BASE
    else
      loc = window.location
      base = 'ws://' + loc.hostname + ':' + loc.port + '/signaling/'

    console.log base

    return base + room


  join: (name, list) ->
    local = @room.local
    local.status('name', name)

    @room.on 'peer_joined', (peer) =>
      view = $('<li></li>').text(peer.status('name') || "unkown")
      list.append(view)

      id = peer.signaling.id

      peer.on 'message', (msg) =>
        switch msg.type
          when 'start'
            if not @game?
              @start()

          when 'connect'
            @room.local.status('playing', true)

            peer.addDataChannel(data_channel_conf).then (channel) =>
              channel.connect().then () =>
                player = new LocalPlayer()
                input = new RtcInput(channel, player)
                @game = new RtcGame(channel)
                @render = new Render(@background[0], @draw[0], @game)
                console.log('connected')

            peer.connect()

      peer.on 'left', () =>
        view.remove()
        delete @peers[id]

      @peers[id] = peer

    return @room.connect()


  minPeer: () ->
    peer_list = ([id, peer] for id, peer of @peers)

    if peer_list.length > 0
      return peer_list.reduce ([a_id, a_peer], [b_id, b_peer]) ->
        if a_id < b_id
          return [a_id, a_peer]
        else
          return [b_id, b_peer]
    else
      return [null, null]


  start: () ->
    promises = []

    [min_id, min_peer] = @minPeer()

    if min_id == null or @room.signaling.id < min_id
      @room.local.status('playing', true)

      # create game

      @game = new Game(levels.simple, @room.signaling.id)

      # create players

      @game.addPlayer(new LocalPlayer())

      channel_promises = []

      for id, peer of @peers
        channel_p = peer.addDataChannel(data_channel_conf).then (channel) =>
          @game.addPlayer(new RtcPlayer(channel))

          return channel.connect().then () ->
            return channel

        channel_promises.push(channel_p)

        peer.message({type: 'connect'})
        peer.connect()

      # wait for channels to be established

      Promise.all(channel_promises).then (channels) =>
        sender = new RtcSender(@game, channels)
        @render = new Render(@background[0], @draw[0], @game)

    else
      min_peer.message({type: 'start'})


