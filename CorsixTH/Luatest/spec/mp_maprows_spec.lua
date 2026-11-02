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

-- A desync report's map rows: one checksum per row of tile flags, so the
-- rows in which two games' maps differ show.
describe("Multiplayer desync map rows", function()
  local function fake_world(cells)
    local th = {
      size = function() return 3, 2 end,
      getCellFlags = function(_, x, y, t)
        for k in pairs(t) do t[k] = nil end
        for k, v in pairs(cells[y][x]) do t[k] = v end
        return t
      end,
      getCell = function() return 0, 0, 0 end,
    }
    return {map = {th = th}}
  end
  local function cells()
    return {
      {{passable = true}, {passable = true, buildable = true}, {passable = false}},
      {{passable = true}, {passable = true}, {passable = true, roomId = 4}},
    }
  end

  it("gives one checksum per row, and only the changed row differs", function()
    package.loaded.TH = package.loaded.TH or {CRC32File = function(text)
      local h = 0
      for i = 1, #text do h = (h * 31 + text:byte(i)) % 4294967296 end
      return h
    end}
    local a = MultiplayerSession.mapRows(fake_world(cells()))
    local changed = cells()
    changed[2][1].buildable = true
    local b = MultiplayerSession.mapRows(fake_world(changed))
    local ra, rb = {}, {}
    for row in a:gmatch("[^,]+") do ra[#ra + 1] = row end
    for row in b:gmatch("[^,]+") do rb[#rb + 1] = row end
    assert.equal(2, #ra)
    assert.equal(ra[1], rb[1])
    assert.not_equal(ra[2], rb[2])
    assert.truthy(ra[1]:match("^1:%x+$"))
  end)
end)
