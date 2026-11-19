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

-- The litter bomb under the cursor: its fuse picture (whose frames carry the
-- original's beep) moves on a frame a game hour, as a bomb on the floor does,
-- not on every screen tick (Argus: a held bomb beeped like crazy).
describe("Litter bomb under the cursor", function()
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("utility")
    require("window")
    require("dialogs/resizable")
    require("dialogs/resizables/multiplayer_sabotage")
  end)

  local function held_bomb()
    local UIMultiplayerLitterBomb = _G["UIMultiplayerLitterBomb"]
    local window = setmetatable({world = {mp_hours = 100}, ticks = 0}, {__index = UIMultiplayerLitterBomb})
    window.preview = {tick = function() window.ticks = window.ticks + 1 end}
    return window
  end

  local saved
  before_each(function()
    saved = _G.UIResizable.onTick
    _G.UIResizable.onTick = function() end
  end)
  after_each(function()
    _G.UIResizable.onTick = saved
  end)

  it("stands still while no game hour passes (a paused game)", function()
    local window = held_bomb()
    for _ = 1, 30 do window:onTick() end
    assert.are.equal(0, window.ticks)
  end)

  it("moves on a frame for each game hour", function()
    local window = held_bomb()
    window:onTick()
    for _ = 1, 10 do
      -- Normal speed: an hour every third screen tick.
      window.world.mp_hours = window.world.mp_hours + 1
      window:onTick()
      window:onTick()
      window:onTick()
    end
    assert.are.equal(10, window.ticks)
  end)

  it("catches up only a little after a jump", function()
    local window = held_bomb()
    window:onTick()
    window.world.mp_hours = window.world.mp_hours + 50
    window:onTick()
    assert.are.equal(4, window.ticks)
  end)
end)
