--[[ Copyright (c) 2026 CorsixTH-Multiplayer contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

require("corsixth")
require("class_test_base")
require("date")
require("mp_session")

local MultiplayerSession = _G["MultiplayerSession"]

-- A world of three hospitals: 2 played by a hard bot, 3 by an easy one.
local function make(levels)
  local world = {mp_coop = {players = 3, bot_hospitals = {[2] = true, [3] = true}, bot_levels = levels}}
  world.hospitals = {}
  for i = 1, 3 do world.hospitals[i] = {world = world, index = i} end
  function world.getHospitalIndex(_, hospital) return hospital.index end
  return world
end

describe("Bot levels", function()
  it("are the server's, for hospitals only bots play", function()
    local world = make({[2] = "hard", [3] = "easy"})
    assert.equal("hard", MultiplayerSession.botLevel(world, 2))
    assert.equal("easy", MultiplayerSession.botLevel(world, 3))
    -- A person's hospital, and a game without levels: normal.
    assert.equal("normal", MultiplayerSession.botLevel(world, 1))
    assert.equal("normal", MultiplayerSession.botLevel(make(nil), 2))
    -- Taken over by a person (no longer only bots): normal.
    world.mp_coop.bot_hospitals[2] = nil
    assert.equal("normal", MultiplayerSession.botLevel(world, 2))
  end)

  it("count every second death of a hard bot's hospital", function()
    local world = make({[2] = "hard"})
    local counted = 0
    for _ = 1, 5 do
      if MultiplayerSession.countsDeath(world.hospitals[2]) then counted = counted + 1 end
    end
    assert.equal(3, counted) -- (5 deaths, half rounded up)
    for _ = 1, 5 do assert.is_true(MultiplayerSession.countsDeath(world.hospitals[3])) end
    assert.is_true(MultiplayerSession.countsDeath({world = {}})) -- (no multiplayer)
  end)
end)

-- Four hospitals of people; goals: reputation 600 and $50,000.
local function game(month)
  local world = {mp_coop = {players = 4}, hospitals = {}}
  world.game_date = {monthOfGame = function() return month[1] end}
  world.endconditions = {
    win_goals = {{reputation = {win_value = 600, max_min = 1}, balance = {win_value = 50000, max_min = 1}}},
    getAttribute = function(_, hospital, name) return hospital[name] end,
  }
  local shape = {{600, 50000}, {540, 40000}, {480, 30000}, {300, 10000}}
  for i = 1, 4 do
    world.hospitals[i] = {world = world, index = i, name = "H" .. i, reputation = shape[i][1], balance = shape[i][2]}
  end
  function world.getHospitalIndex(_, hospital) return hospital.index end
  return world
end

describe("A bot standing in for a person who left", function()
  it("measures the way to the goals", function()
    local world = game({1})
    assert.equal(1, MultiplayerSession.goalProgress(world, world.hospitals[1]))
    assert.near(0.25 + 0.1, MultiplayerSession.goalProgress(world, world.hospitals[4]), 1e-9)
    world.hospitals[4].balance = -5000 -- (in debt: no way to the goal at all)
    assert.equal(0.25, MultiplayerSession.goalProgress(world, world.hospitals[4]))
  end)

  it("plays at hard for a year when the hospital is behind, then normal", function()
    local month = {5}
    local world = game(month)
    local h3, h4 = world.hospitals[3], world.hospitals[4]
    h4.mp_player_away = true
    local changes = MultiplayerSession.standInLevels(world)
    assert.equal(1, #changes)
    assert.same({index = 4, level = "hard"}, changes[1])
    assert.equal("hard", MultiplayerSession.botLevel(world, 4))
    -- A year on it plays at normal again, and stays so for this stand-in.
    month[1] = 16
    assert.equal(0, #MultiplayerSession.standInLevels(world))
    month[1] = 17
    assert.same({{index = 4, level = "normal"}}, MultiplayerSession.standInLevels(world))
    assert.equal("normal", MultiplayerSession.botLevel(world, 4))
    month[1] = 18
    assert.equal(0, #MultiplayerSession.standInLevels(world))
    -- Not behind: hospital 3 (0.7 against 0.73 for the others, not the lowest).
    h3.mp_player_away = true
    assert.equal(0, #MultiplayerSession.standInLevels(world))
    assert.equal("normal", MultiplayerSession.botLevel(world, 3))
  end)

  it("ends the hard year at once when a person takes the place", function()
    local world = game({3})
    local h4 = world.hospitals[4]
    h4.mp_player_away = true
    MultiplayerSession.standInLevels(world)
    h4.mp_player_away = nil
    assert.equal("normal", MultiplayerSession.botLevel(world, 4))
    assert.same({{index = 4, level = "normal", back = true}}, MultiplayerSession.standInLevels(world))
    -- A new stand-in later may get its own year.
    h4.mp_player_away = true
    assert.same({{index = 4, level = "hard"}}, MultiplayerSession.standInLevels(world))
  end)
end)
