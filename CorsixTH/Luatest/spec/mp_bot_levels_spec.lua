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
