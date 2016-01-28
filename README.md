# rtc-bomber

## About

This is a game about bombing rocks and sometimes other players. It is running
in browsers and provides multiplayer using WebRTC.

## Technical Details

Here are some random technical details you might or might not be interested in:

* written in CoffeeScript
* the surrounding user interface is written in ReactJS and CJSX
* actual game is rendered on a `<canvas>`
* multiplayer through WebRTC peer to peer connections using
  [rtc-lib](https://github.com/Innovailable/rtc-lib)
* [calling-signaling](https://github.com/Innovailable/calling-signaling) helps
  clients connect and find games
* code can be compiled to static JavaScript and HTML files, only the non game
  specific signaling server has to run on some server
* one player acts as server and sends the game state to all other players and
  receives their input

## Setup

### Play Online

You can play the game online [here](http://innovailable.github.io/rtc-bomber/).

### Integrated Server

The game can be started using an integrated HTTP server which also contains the
signaling server.

Install the dependencies with

    npm install

Run the server with

    coffee server/main.coffee

The server will then listen on port 3000

    http://localhost:3000/

### Compiled Files

An alternative way to use the game is to compile the static files. You will
have to specify a signaling server URL on compile time.

    SIGNALING_URL=wss://calling.innovailable.eu make

You can then upload the files from the `out/` directory to any server or use
them locally.

## TODO

* actual graphics
* more maps
* private games
* invite players
* spectator mode

