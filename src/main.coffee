$ = require('jquery-browserify')
cookie = require('js-cookie')
uuid = require('node-uuid')

{Bomber} = require('./bomber')
{Render} = require('./render')

$ () ->
  game_id = window.location.search

  $status = $('#status')
  $background = $('#background')
  $draw = $('#draw')
  $user_list = $('#user_list')
  $name = $('#name')

  if game_id.length > 0
    bomber = new Bomber(game_id, $background[0], $draw[0])

    # display peers

    bomber.on 'peer_joined', (peer) ->
      view = $('<li></li>')

      set_name = () ->
        view.text(peer.name || 'unknown')

      peer.on('name_changed', set_name)
      set_name()

      peer.on 'left', () ->
        view.remove()

      $user_list.append(view)

    # game starts

    bomber.on 'starting', () ->
      $status.text("Game is running")

      $('#start').hide()
      $('#draw').focus()

      render = new Render($background[0], $draw[0], bomber.game)

    # start button

    $('#start').click () ->
      $('#start').attr('disabled', true)
      bomber.start()

    # name handling

    name = cookie.get('name') || 'unknown'

    $name.val(name)
    bomber.setName(name)

    $name.change () ->
      name = $name.val()

      bomber.setName(name)
      cookie.set('name', name)

    # connect

    $status.text("Connecting ...")
    $('#start').attr('disabled', true)

    bomber.join().then () ->
      $status.text("Waiting for game to start")
      $('#start').attr('disabled', false)

  else
    location.href = location.href + "?" + uuid.v4()

