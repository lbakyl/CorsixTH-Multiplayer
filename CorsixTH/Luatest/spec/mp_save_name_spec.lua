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
require("mp_lobby")

-- The multiplayer save box starts with the level's name and the game date
-- (Jan, 2026-11-21).
describe("Multiplayer save box", function()
  it("starts with the level's name and the game date", function()
    local date = Date(1, 7, 16)
    assert.equal("MOUNT EVEREST y1-m07-d16", MultiplayerSession.saveStartName("MOUNT EVEREST", date))
    assert.equal("y1-m07-d16", MultiplayerSession.saveStartName("", date))
    assert.equal("MOUNT EVEREST", MultiplayerSession.saveStartName("MOUNT EVEREST", nil))
  end)

  it("shortens a long name so that the date fits the 30 letters of the box", function()
    local name = MultiplayerSession.saveStartName("A VERY LONG LEVEL NAME INDEED HERE", Date(12, 11, 30))
    assert.is_true(#name <= 30)
    assert.equal("y12-m11-d30", name:sub(-11))
  end)

  it("writes the file name with the date once", function()
    local name = MultiplayerSession.saveStartName("MOUNT EVEREST", Date(1, 7, 16))
    assert.equal("MOUNT EVEREST Jan y1-m07-d16", MultiplayerLobby.saveLabel(name, "Jan", 1, 7, 16))
  end)
end)
