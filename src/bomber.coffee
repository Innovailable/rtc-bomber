{Game} = require('./game')
{Render} = require('./render')
{LocalPlayer} = require('./local_player')
levels = require('./levels')

global.init = () ->
  console.log(levels)
  game = new Game(levels.simple, '123test')
  game.addPlayer(new LocalPlayer())
  render = new Render(document.getElementById('background'), document.getElementById('draw'), game)

