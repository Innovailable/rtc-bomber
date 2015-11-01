{Game} = require('./game')

module.exports = {
  simple: {
    name: "Simple"
    max_players: 4
    field: (rng) ->
      res = []

      for y in [0..16]
        line = new Array(17)
        res.push(line)

        for x in [0..24]
          if x == 0 or x == 24 or y == 0 or y == 16
            line[x] = Game.GRID_WALL
          else if x % 2 == 0 and y % 2 == 0
            line[x] = Game.GRID_WALL
          else if rng() < 0.5
            line[x] = Game.GRID_ROCK
          else
            line[x] = Game.GRID_OPEN

      spawn = (x, y) ->
        res[y-1][x] = Game.GRID_OPEN
        res[y+1][x] = Game.GRID_OPEN
        res[y][x+1] = Game.GRID_OPEN
        res[y][x-1] = Game.GRID_OPEN
        res[y][x] = Game.GRID_SPAWN

      spawn(3, 3)
      spawn(21, 13)

      return res
  }

  test: {
    name: "Test Map"
    max_players: 1
    field: (rng) ->
      res = []

      for y in [0..16]
        line = new Array(17)
        res.push(line)

        for x in [0..24]
          if x == 0 or x == 24 or y == 0 or y == 16
            line[x] = Game.GRID_WALL
          else
            line[x] = Game.GRID_OPEN

      res[8][8] = Game.GRID_WALL
      res[8][9] = Game.GRID_WALL
      res[9][8] = Game.GRID_WALL
      res[9][9] = Game.GRID_WALL
      res[6][8] = Game.GRID_WALL
      res[6][9] = Game.GRID_WALL
      res[8][6] = Game.GRID_WALL
      res[9][6] = Game.GRID_WALL

      return res
  }
}
