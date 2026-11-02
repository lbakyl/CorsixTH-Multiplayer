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
require("mp_session")
if not Window then class "Window" end
require("dialogs.hire_staff")

-- The hire window in multiplayer: every hospital hires from one list, so it
-- changes while a player looks at it.
describe("Multiplayer hire window", function()
  local function doctor(wage, skill) return {wage = wage, skill = skill} end
  local said
  local function window(pool, index)
    said = {}
    return setmetatable({
      category = "Doctor", current_index = index,
      world = {available_staff = {Doctor = pool}},
      ui = {adviser = {say = function(_, msg) said[#said + 1] = msg.text end}},
      updateTooltips = function() end,
    }, {__index = UIHireStaff})
  end
  local old_app
  before_each(function()
    old_app = _G.TheApp
    _G.TheApp = {mp_session = {}}
  end)
  after_each(function() _G.TheApp = old_app end)

  it("keeps showing the same person when someone before them is hired", function()
    local a, b, c = doctor(50, 0.5), doctor(60, 0.6), doctor(70, 0.7)
    local pool = {a, b, c}
    local w = window(pool, 2)
    w:_mpFollow()
    table.remove(pool, 1) -- another hospital hires a
    w:_mpFollow()
    assert.equal(1, w.current_index)
    assert.equal(b, pool[w.current_index])
    assert.same({}, said)
  end)

  it("shows the next one when another hospital hires the one shown", function()
    local a, b, c = doctor(50, 0.5), doctor(60, 0.6), doctor(70, 0.7)
    local pool = {a, b, c}
    local w = window(pool, 3)
    w:_mpFollow()
    table.remove(pool, 3) -- c, the last one, is hired elsewhere
    w:_mpFollow()
    assert.equal(2, w.current_index)
    assert.equal(1, #said)
    -- Then it follows b.
    table.remove(pool, 1)
    w:_mpFollow()
    assert.equal(b, pool[w.current_index])
  end)

  it("does not hire somebody else when the one shown was just taken", function()
    local a, b = doctor(50, 0.5), doctor(60, 0.6)
    local pool = {a, b}
    local w = window(pool, 1)
    local sounds = {}
    w.ui.playSound = function(_, name) sounds[#sounds + 1] = name end
    w.ui.tutorialStep = function() end
    w:_mpFollow() -- (drawn, showing a)
    table.remove(pool, 1) -- a hired elsewhere before the click
    w:hire()
    assert.same({"wrong2.wav"}, sounds)
    assert.equal(b, pool[w.current_index]) -- now showing b; a second click hires b
  end)

  it("says nothing when this player hired the one shown", function()
    local a, b = doctor(50, 0.5), doctor(60, 0.6)
    local pool = {a, b}
    local w = window(pool, 1)
    w:_mpFollow()
    w.mp_hiring = {[MultiplayerSession.staffProfileKey(a)] = true}
    table.remove(pool, 1)
    w:_mpFollow()
    assert.equal(b, pool[w.current_index])
    assert.same({}, said)
  end)
end)
