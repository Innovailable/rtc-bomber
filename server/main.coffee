app = require('express')()
{CallingServer, WebsocketChannel} = require('calling-signaling')

# server js

browserify = require('browserify-middleware')
browserify.settings('transform', [require('cjsxify'), require('envify')])
browserify.settings('extensions', ['.coffee', '.cjsx'])
browserify.settings('grep', /\.coffee$|\.js$|\.cjsx$/)

app.get('/js/bomber.js', browserify(__dirname + '/../src/main.cjsx'))

# signaling

calling_server = new CallingServer()

require('express-ws')(app)
app.ws '/signaling', (ws) ->
  channel = new WebsocketChannel(ws)
  calling_server.create_user(channel)

# prepare haml

app.engine 'haml', require('haml-coffee').__express
app.set('views', './views')


app.get '/', (req, res) ->
  res.render('index.haml')

app.listen(3000)
