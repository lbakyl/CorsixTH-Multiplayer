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
require("mp_lobby")

local MultiplayerLobby = _G["MultiplayerLobby"]

-- A transport that records what is sent and returns queued server lines.
local function fake_transport()
  return {
    sent = {},
    inbox = {},
    send = function(self, line) self.sent[#self.sent + 1] = line end,
    receive = function(self) return table.remove(self.inbox, 1) end,
    close = function(self) self.closed = true end,
  }
end

local function make_lobby()
  local t = fake_transport()
  local lobby = MultiplayerLobby({transport = t, name = "Alice", build = "b1"})
  return lobby, t
end

describe("MultiplayerLobby", function()
  it("encodes like the server and the lockstep commands", function()
    assert.equal("JOIN password= room=Ward%207",
        MultiplayerLobby.encode("JOIN", {room = "Ward 7", password = ""}))
    assert.equal("READY ready=1", MultiplayerLobby.encode("READY", {ready = true}))
    local verb, f = MultiplayerLobby.decode("ERROR code=bad_password text=Wrong%20password")
    assert.equal("ERROR", verb)
    assert.same({code = "bad_password", text = "Wrong password"}, f)
    assert.equal("LIST", (MultiplayerLobby.decode("LIST")))
  end)

  it("caps speed requests at the room's maximum", function()
    assert.equal("Pause", MultiplayerLobby.clampSpeed("Pause", "Normal"))
    assert.equal("Slower", MultiplayerLobby.clampSpeed("Slower", "Normal"))
    assert.equal("Normal", MultiplayerLobby.clampSpeed("And then some more", "Normal"))
    assert.equal("Max speed", MultiplayerLobby.clampSpeed("Speed Up", "Max speed"))
  end)

  it("parses server addresses", function()
    assert.same({"example.org", 47800}, {MultiplayerLobby.parseAddress("example.org")})
    assert.same({"10.0.0.2", 5000}, {MultiplayerLobby.parseAddress(" 10.0.0.2:5000 ")})
    assert.same({"::1", 47801}, {MultiplayerLobby.parseAddress("[::1]:47801")})
    assert.is_nil(MultiplayerLobby.parseAddress(""))
  end)

  it("says hello, then lists the rooms once welcomed", function()
    local lobby, t = make_lobby()
    assert.equal("HELLO build=b1 name=Alice proto=1", t.sent[1])
    assert.equal("connecting", lobby.state)
    t.inbox = {"WELCOME id=7 proto=1 server=0.1",
      "ROOM build_ok=1 level=1 locked=1 max=2 mode=shared players=1 room=Ward%207 state=lobby",
      "ROOMS_END count=1"}
    lobby:poll()
    assert.equal("connected", lobby.state)
    assert.equal("LIST", t.sent[2])
    assert.equal(1, #lobby.rooms)
    assert.equal("Ward 7", lobby.rooms[1].room)
  end)

  it("tracks the room, its players and the pacing summary", function()
    local lobby, t = make_lobby()
    local events = {}
    lobby:addListener(function(_, event) events[#events + 1] = event end)
    t.inbox = {"WELCOME id=1 proto=1",
      "JOINED difficulty=full level=2 max=2 mode=coop owner=0 peer=2 room=r",
      "PLAYER name=Bob owner=1 peer=1 ready=0 rtt=12",
      "PLAYER name=Alice owner=0 peer=2 ready=0 rtt=30",
      "LOBBY count=2 delay=3 latency=162 max=2 speed=Max%20speed"}
    lobby:poll()
    assert.equal("in_room", lobby.state)
    assert.is_false(lobby:isOwner())
    assert.equal("Bob", lobby.players[1].name)
    assert.equal("30", lobby.players[2].rtt)
    assert.equal("Max speed", lobby.summary.speed)
    assert.same({"connected", "joined", "lobby"}, events)
    t.inbox = {"OWNER"}
    lobby:poll()
    assert.is_true(lobby:isOwner())
  end)

  it("answers pings and keeps errors", function()
    local lobby, t = make_lobby()
    t.inbox = {"WELCOME id=1 proto=1", "PING id=5", "ERROR code=room_full text=The%20room%20is%20full"}
    lobby:poll()
    assert.truthy(table.concat(t.sent, "\n"):find("PONG id=5", 1, true))
    assert.equal("room_full", lobby.error.code)
    assert.equal("connected", lobby.state)
  end)

  it("gives up when the server refuses the hello", function()
    local lobby, t = make_lobby()
    t.inbox = {"ERROR code=protocol text=old"}
    lobby:poll()
    assert.equal("closed", lobby.state)
    assert.is_true(t.closed)
  end)

  it("leaves a room and asks for the room list again", function()
    local lobby, t = make_lobby()
    t.inbox = {"WELCOME id=1 proto=1", "JOINED max=2 mode=shared owner=1 peer=1 room=r"}
    lobby:poll()
    lobby:leaveRoom()
    assert.equal("connected", lobby.state)
    assert.is_nil(lobby.room)
    assert.equal("LIST", t.sent[#t.sent])
    assert.equal("LEAVE", t.sent[#t.sent - 1])
  end)
end)
