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

require("class_test_base")
require("movie_player")

local MoviePlayer = _G["MoviePlayer"]

describe("The win video's letter buttons", function()
  -- A movie player showing the letter: the movie drawn from (x, y) at `vs`
  -- screen pixels per 640x480 pixel (1920x1080: x = 240, vs = 2.25).
  local function player(shown, typed)
    local chosen, stopped = {}, false
    local mp = setmetatable({}, {__index = MoviePlayer})
    mp.stop = function() stopped = true end
    mp.letter = {shown = shown, typed = typed ~= false and shown, x = 240, y = 0, vs = 2.25,
        choose = function(choice) chosen[#chosen + 1] = choice end}
    return mp, chosen, function() return stopped end
  end
  -- The middle of a button at (bx, by) on the 640x480 letter, on the screen.
  local function at(bx, by) return 240 + (bx + 20) * 2.25, (by + 20) * 2.25 end

  it("answers with the tick (first choice) or the cross (second)", function()
    local mp, chosen, stopped = player(true)
    assert.equal(1, mp:letterButtonAt(at(390, 401)).choice)
    assert.equal(2, mp:letterButtonAt(at(340, 401)).choice)
    assert.is_true(mp:letterClick(at(390, 401)))
    assert.same({1}, chosen)
    assert.is_true(stopped())
    assert.is_nil(mp.letter)
    -- The cross, on another letter.
    mp, chosen = player(true)
    mp:letterClick(at(340, 401))
    assert.same({2}, chosen)
  end)

  it("takes other clicks without an answer, and the movie goes on", function()
    local mp, chosen, stopped = player(true)
    assert.is_true(mp:letterClick(at(200, 250))) -- on the paper
    assert.is_true(mp:letterClick(at(390, 360))) -- above the tick
    -- Before the letter shows, a click on the tick's place does nothing either.
    local early, early_chosen, early_stopped = player(false)
    assert.is_true(early:letterClick(at(390, 401)))
    assert.same({}, chosen)
    assert.same({}, early_chosen)
    assert.is_false(stopped())
    assert.is_false(early_stopped())
  end)

  it("finishes typing with a click, and has its buttons only once typed", function()
    local mp, chosen, stopped = player(true, false)
    assert.is_nil(mp:letterButtonAt(at(390, 401)))
    assert.is_true(mp:letterClick(at(390, 401))) -- on the tick's place: typed
    assert.is_true(mp.letter.typed)
    assert.same({}, chosen)
    assert.is_false(stopped())
    assert.is_true(mp:letterClick(at(390, 401))) -- now the tick
    assert.same({1}, chosen)
  end)

  it("ends a letter without buttons with a click, once typed", function()
    local mp = player(false)
    mp.letter.choose = nil
    assert.is_false(mp:letterClick(100, 100)) -- (before the letter: as any movie)
    mp.letter.shown = true
    assert.is_true(mp:letterClick(100, 100)) -- typing: finished
    assert.is_false(mp:letterClick(100, 100)) -- typed: the movie ends
    assert.is_nil(mp:letterButtonAt(at(390, 401)))
  end)

  it("leaves clicks to the movie without a letter", function()
    local mp = setmetatable({}, {__index = MoviePlayer})
    assert.is_false(mp:letterClick(100, 100))
    assert.is_nil(mp:letterButtonAt(100, 100))
  end)
end)
