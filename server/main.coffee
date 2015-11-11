es = require('easy-signaling')

app = require('express')()

# server js

browserify = require('browserify-middleware')
browserify.settings('transform', [require('coffeeify'), require('envify')])
browserify.settings('extensions', ['.coffee'])
browserify.settings('grep', /\.coffee$|\.js$/)

app.get('/js/bomber.js', browserify(__dirname + '/../src/main.coffee'))

# signaling

hotel = new es.Hotel()

require('express-ws')(app)
app.ws '/signaling/*', (ws) ->
  channel = new es.WebsocketChannel(ws)
  room_id = ws.upgradeReq.url
  hotel.create_guest(channel, room_id)

# prepare haml

app.engine 'haml', require('haml-coffee').__express
app.set('views', './views')


app.get '/', (req, res) ->
  res.render('index.haml')

app.listen(3000)
