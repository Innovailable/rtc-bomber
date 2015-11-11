$ = require('jquery-browserify')

{Bomber} = require('./bomber')

$ () ->
  game_id = window.location.search

  if game_id.length > 0
    bomber = new Bomber(game_id, $('#background'), $('#draw'))

    $('#start').attr('disabled', true)

    $('#join').click () ->
      $('#login input').attr('disabled', true)

      bomber.join($('#name').val(), $('#user_list')).then () ->
        $('#start').attr('disabled', false)

    $('#start').click () ->
      bomber.start()
      $('#start').attr('disabled', true)
      $('#draw').focus()

  else
    console.log 'get a game!'

