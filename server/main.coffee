app = require('express')()

browserify = require('browserify-middleware')
browserify.settings('transform', [require('coffeeify')])
browserify.settings('extensions', ['.coffee'])
browserify.settings('grep', /\.coffee$|\.js$/)

app.get('/js/bomber.js', browserify(__dirname + '/../src/bomber.coffee'))

app.engine 'haml', require('haml-coffee').__express
app.set('views', './views')

app.get '/', (req, res) ->
  res.render('index.haml')

app.listen(3000)
