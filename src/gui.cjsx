React = require('react')

{Render} = require('./render')

# helper

name_cmp = (a, b) ->
  return a.name < b.name

# connect

ConnectScreen = React.createClass
  getInitialState: () ->
    return {
      name: @props.defaultName
      blocked: false
    }

  connect: (e) ->
    e.preventDefault()
    @setState({blocked: true})
    @props.connect(@state.name)

  handleNameChange: (e) ->
    @setState({name: e.target.value})

  render: () ->
    return <div>
      <form onSubmit={@connect}>
        Name: 
        <input type="input" ref={(i) -> i?.focus()} value={@state.name} onChange={@handleNameChange} disabled={@state.blocked} />
        <input type="submit" value="Connect" disabled={@state.blocked || @state.name.length == 0} />
      </form>
    </div>

# global lobby

GameEntry = React.createClass
  render: () ->
    peers = @props.peers.map (peer) ->
      <li key={peer.id}>{peer.name}</li>

    return <div>
      <h3>{@props.name}</h3>
      <ul>{peers}</ul>
      <input type="button" value="Join" onClick={@props.join} />
    </div>

GameList = React.createClass
  render: () ->
    games = @props.games.map (game) =>
      return <GameEntry key={game.id} name={game.name} peers={game.peers} join={@props.join.bind(null, game.id)} />

    if games.length > 0
      return <div>
        {games}
      </div>
    else
      return <div>No open games</div>

GameCreator = React.createClass
  getInitialState: () ->
    return {
      title: ''
    }

  handleTitleChange: (e) ->
    @setState({title: e.target.value})

  create: (e) ->
    e.preventDefault()
    @props.create(@state.title)

  render: () ->
    return <div>
      <form onSubmit={@create}>
        <input type="input" value={@state.title} onChange={@handleTitleChange} />
        <input type="submit" value="Create" disabled={@state.title.length == 0} />
      </form>
    </div>

GameSelectionScreen = React.createClass
  getInitialState: () ->
    @props.namespace.on 'room_changed', () =>
      @setState({games: @gameList()})

    return {
      games: @gameList()
    }

  gameList: () ->
    games = []

    for room_id, room of @props.namespace.rooms
      peers = []

      for peer_id, peer of room.peers
        peers.push({
          id: peer_id
          name: peer.status.name
          pending: peer.pending
        })

      peers.sort(name_cmp)

      games.push({
        id: room_id
        name: room.status.name
        peers: peers
      })

    games.sort(name_cmp)

    return games

  render: () ->
    return <div>
      <h2>Create new game</h2>
      <GameCreator create={@props.create} />
      <h2>Join game</h2>
      <GameList games={@state.games} join={@props.join} />
    </div>

# game lobby

PeerList = React.createClass
  render: () ->
    peers = @props.peers.map (peer) ->
      return <li key={peer.id}>{peer.name}</li>

    return <div>
      <h2>Other Players</h2>
      <ul>{peers}</ul>
    </div>

LobbyScreen = React.createClass
  getInitialState: () ->
    update_cb = () =>
      @setState({peers: @peerList()})

    @props.game.on('peer_joined', update_cb)
    @props.game.on('peer_status_changed', update_cb)
    @props.game.on('peer_left', update_cb)

    @props.game.on 'status_changed', (status) =>
      @setState({name: status.name})

    return {
      peers: @peerList()
      name: @props.game.signaling.status.name || ''
    }

  peerList: () ->
    peers = []

    for peer_id, peer of @props.game.peers
      peers.push({
        id: peer_id
        name: peer.status('name')
      })

    peers.sort(name_cmp)

    return peers

  render: () ->
    return <div>
      <h2>Game</h2>
      Name: {@props.game.signaling.status.name}
      <PeerList peers={@state.peers} />
      <input type="button" value="Start" onClick={@props.start} />
      <input type="button" value="Leave" onClick={@props.leave} />
    </div>

# game screen

PlayerList = React.createClass
  render: () ->
    players = @props.players.map (player) ->
      return <li key={player.id}>
        <span style={{
          display: 'inline-block'
          backgroundColor: player.color
          width: '0.5em'
          height: '0.5em'
          border: '1px solid black'
        }} /> {player.name}
      </li>

    return <ul>
      {players}
    </ul>

GameScreen = React.createClass
  componentDidMount: () ->
    @game_render = new Render(@refs.draw, @props.game)

  componentWillUnmount: () ->
    @game_render.close()

  render: () ->
    players = @props.players.map (player, i) =>
      return {
        id: player.id
        name: player.name
        color: Render.COLORS[i]
      }

    return <div>
      <h2>Players</h2>
      <PlayerList players={players} />
      <h2>Game</h2>
      <canvas ref="draw" />
      <br /><br />
      <input type="button" value="Leave" onClick={@props.leave} />
    </div>

# error screen

ErrorScreen = React.createClass
  render: () ->
    return <div>
      {@props.error}<br/>
      <input type="button" value="OK" onClick={@props.continue} />
    </div>

# fatal screen

FatalScreen = React.createClass
  render: () ->
    return <div>{@props.error}</div>

# module stuff

module.exports = {
  ConnectScreen: ConnectScreen
  GameSelectionScreen: GameSelectionScreen
  LobbyScreen: LobbyScreen
  GameScreen: GameScreen
  ErrorScreen: ErrorScreen
  FatalScreen: FatalScreen
}
