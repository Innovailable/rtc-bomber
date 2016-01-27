React = require('react')
ReactDOM = require('react-dom')

StateMachine = require('fsm-as-promised')

cookie = require('js-cookie')

rtc = require('rtc-lib')

{Game} = require('./game')
{LocalPlayer} = require('./local_player')
{VoidPlayer} = require('./void_player')
{RtcPlayer} = require('./rtc_player')
{RtcInput} = require('./rtc_input')
{RtcSender} = require('./rtc_sender')
{RtcGame} = require('./rtc_game')
levels = require('./levels')

gui = require('./gui')

relative_websocket_url = (path="") ->
  loc = window.location
  return 'ws://' + loc.hostname + ':' + loc.port + '/' + path

SIGNALING_URL = process.env.SIGNALING_URL || relative_websocket_url('signaling')
GAME_ID = process.env.GAME_ID || 'rtc-bomber.innnovailable.eu'

RTC_OPTIONS = {
  auto_connect: false
  stun: 'stun:stun.palava.tv'
}

DATACHANNEL_OPTIONS = {
  ordered: false
  maxRetransmits: 0
}

class HostSession

  constructor: (@room, @host, @peers) ->
    # create game

    game = new Game(levels.simple, @room.signaling.id)

    # create players

    game.addPlayer(new LocalPlayer())

    channel_promises = []

    for {id} in @peers
      peer = @room.peers[id]

      if not peer?
        console.log('peer not found', id)
        game.addPlayer(new VoidPlayer())
        continue

      channel_p = peer.addDataChannel(DATACHANNEL_OPTIONS).then (channel) =>
        game.addPlayer(new RtcPlayer(channel))

        return channel.connect().then () ->
          return channel
      .catch (err) ->
        return null

      peer.connect()

      channel_promises.push(channel_p)

    # wait for channels to be established

    @connect_p = Promise.all(channel_promises).then (channels) =>
      channels = channels.filter((c) -> return c != null)
      sender = new RtcSender(game, channels)
      return game


  game: () ->
    return @connect_p


class ClientSession

  constructor: (@room, @host, @peers) ->
    peer = @room.peers[@host.id]

    if not peer?
      @connect_p = Promise.reject(new Error("Host of the game left"))
      return

    @connect_p = peer.addDataChannel(DATACHANNEL_OPTIONS).then (channel) ->
      return channel.connect().then () ->
        player = new LocalPlayer()
        input = new RtcInput(channel, player)
        game = new RtcGame(channel)
        return game

    peer.connect()


  game: () ->
    return @connect_p


# connect it all

machine = StateMachine({
  events: [
    {
      name: 'init'
      from: 'none'
      to: 'start'
    }
    {
      name: 'connect'
      from: 'start'
      to: 'selection'
    }
    {
      name: 'join'
      from: 'selection'
      to: 'lobby'
    }
    {
      name: 'create'
      from: 'selection'
      to: 'lobby'
    }
    {
      name: 'host'
      from: 'lobby'
      to: 'game'
    }
    {
      name: 'client'
      from: 'lobby'
      to: 'game'
    }
    {
      name: 'close'
      from: ['error', 'lobby', 'game']
      to: 'selection'
    }
    {
      name: 'error'
      from: ['lobby', 'game']
      to: 'error'
    }
    {
      name: 'fatal'
      from: '*'
      to: 'fatal'
    }
  ]
  callbacks: {
    oninit: () ->
      @view = document.getElementById('view')
      channel = new rtc.signaling.WebSocketChannel(SIGNALING_URL)
      @calling = new rtc.signaling.Calling(channel, RTC_OPTIONS)

    onconnect: (event) ->
      @name = event.args[0]

      cookie.set('name', @name)

      return @calling.connect().then () =>
        return @calling.setStatus({name: @name})

    oncreate: (event) ->
      name = event.args[0]

      @room = @calling.room()

      return @room.connect().then () =>
        return @room.signaling.setRoomStatus('name', name)
      .then () =>
        return @room.signaling.register(GAME_ID)

    onjoin: (event) ->
      room = event.args[0]

      @room = @calling.room(room)

      return @room.connect()

    onhost: () ->
      game_state = {
        host: {
          id: @calling.id
          name: @name
        }
        peers: []
      }

      for peer_id, peer of @room.peers
        game_state.peers.push({
          id: peer_id
          name: peer.status('name')
        })

      return @room.signaling.setRoomStatusSafe('game', game_state, undefined).then () =>
        return @room.signaling.unregister(GAME_ID)
      .then () =>
        @session = new HostSession(@room, game_state.host, game_state.peers)

    onclient: () ->
      {host,peers} = @room.signaling.status.game
      @session = new ClientSession(@room, host, peers)

    onclose: () ->
      return @room.leave().then () =>
        delete @room

    onenteredstart: () ->
      name = cookie.get('name') || ''
      ReactDOM.render(<gui.ConnectScreen defaultName={name} connect={@connect} />, @view)

    onenteredselection: () ->
      return @calling.subscribe(GAME_ID).then (namespace) =>
        @namespace = namespace
        ReactDOM.render(<gui.GameSelectionScreen namespace={@namespace} join={@join} create={@create} />, @view)

    onleaveselection: () ->
      return @namespace.unsubscribe().then () =>
        delete @namespace

    onenteredlobby: () ->
      if not @room.signaling.status.name?
        @error('Sorry, game does not exist anymore')
        return

      new Promise (resolve) =>
        if @room.signaling.status.game?
          resolve(@room.signaling.status.game)
        else
          @room.signaling.on 'status_changed', () =>
            if @room.signaling.status.game?
              resolve(@room.signaling.status.game)
      .then (status) =>
        is_peer = () =>
          for {id} in status.peers
            if id == @calling.id
              return true

          return false

        if is_peer()
          @client()
        else
          @error('Sorry, the game started without you')

      ReactDOM.render(<gui.LobbyScreen game={@room} start={@host} leave={@close} />, @view)

    onenteredgame: () ->
      @session.game().then (game) =>
        players = @session.peers.slice(0)
        players.unshift(@session.host)
        ReactDOM.render(<gui.GameScreen game={game} players={players} leave={@close} />, @view)
      .catch (err) =>
        console.log(err)
        @error('Unable to create game')

    onenterederror: (event) ->
      error = event.args[0]
      ReactDOM.render(<gui.ErrorScreen error={error} continue={@close} />, @view)
  }
})

machine.init()

