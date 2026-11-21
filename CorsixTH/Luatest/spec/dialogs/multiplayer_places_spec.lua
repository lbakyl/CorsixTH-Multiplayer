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

-- The room's places: a click on a line acts on the player on that line. The
-- server knows players by peer number, and an assistant has one but no line
-- of its own, so after an assistant the line and the peer number differ
-- (Argus, 2026-11-21: a click acted on another player, some colours and
-- teams could not be changed).
describe("Multiplayer room places", function()
  setup(function()
    require("corsixth")
    require("class_test_base")
    require("TH")
    require("utility")
    require("mp_session")
    require("window")
    require("dialogs/resizable")
    require("dialogs/resizables/multiplayer")
  end)

  -- The host (peer 1) with an assistant (peer 2), Ann (peer 3) and a bot
  -- (peer 4): lines 1 to 3 are peers 1, 3 and 4, as _updateRoom lists them.
  local function room_window()
    local sent = {}
    local lobby = {
      room = {peer = "1", free = "1"},
      players = {
        [1] = {peer = "1", name = "Host", owner = "1", colour = "1", team = "1"},
        [2] = {peer = "2", name = "Bot Agnes", bot = "1", assists = "1", colour = "1", team = "1"},
        [3] = {peer = "3", name = "Ann", colour = "2", team = "1"},
        [4] = {peer = "4", name = "Bot Bert", bot = "1", colour = "3", team = "2"},
      },
    }
    function lobby.isFreeRoom() return true end
    function lobby.isOwner() return true end
    function lobby.canAddBots() return true end
    function lobby.setSeat(_, colour, team, peer) sent[#sent + 1] = {"seat", colour, team, peer} end
    function lobby.removeBot(_, peer) sent[#sent + 1] = {"remove", peer} end
    function lobby.addBot() sent[#sent + 1] = {"add"} end
    local window = setmetatable({lobby = lobby, row_peer = {1, 3, 4}}, {__index = _G["UIMultiplayer"]})
    return window, sent
  end

  it("gives the colour to the player on the line, not to the assistant", function()
    local window, sent = room_window()
    window:clickColour(2)
    assert.are.same({{"seat", 3, nil, "3"}}, sent)
  end)

  it("gives the team to the player on the line, not to the assistant", function()
    local window, sent = room_window()
    window:clickTeam(2)
    assert.are.same({{"seat", nil, 2, "3"}}, sent)
  end)

  it("takes away the bot on the line, not the player with that peer number", function()
    local window, sent = room_window()
    window:clickPlace(3)
    assert.are.same({{"remove", "4"}}, sent)
  end)

  it("still changes the host's own colour without a peer", function()
    local window, sent = room_window()
    window:clickColour(1)
    assert.are.same({{"seat", 2, nil, nil}}, sent)
  end)
end)
