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

local MultiplayerSession = _G["MultiplayerSession"]

-- Two in-memory transports wired to each other.
local function linked_transports()
  local a_to_b, b_to_a = {}, {}
  local function make(out_q, in_q)
    return {
      send = function(_, line) out_q[#out_q + 1] = line end,
      receive = function(_) return table.remove(in_q, 1) end,
    }
  end
  return make(a_to_b, b_to_a), make(b_to_a, a_to_b)
end

-- A toy world: a list of applied values; fingerprint is the list as text.
local handlers = {
  append = function(world, cmd)
    if cmd.value == "bad" then return false, "rejected value" end
    world.log[#world.log + 1] = cmd.value
    return true
  end,
}
local function fingerprint(world) return table.concat(world.log, ",") end

local function make_pair(delay)
  local ta, tb = linked_transports()
  local wa, wb = {log = {}}, {log = {}}
  local a = MultiplayerSession({world = wa, peer_id = 1, peers = {1, 2}, transport = ta,
      delay = delay, handlers = handlers, fingerprint = fingerprint})
  local b = MultiplayerSession({world = wb, peer_id = 2, peers = {1, 2}, transport = tb,
      delay = delay, handlers = handlers, fingerprint = fingerprint})
  return a, b, wa, wb
end

-- Run one step if allowed, like World:onTick does.
local function try_step(s)
  if not s:canStep() then return false end
  s:beforeStep()
  s:afterStep()
  return true
end

local function run_both(a, b, steps)
  for _ = 1, steps do
    assert(try_step(a), "peer 1 stalled")
    assert(try_step(b), "peer 2 stalled")
  end
end

describe("MultiplayerSession", function()
  it("encodes and decodes commands, including awkward characters", function()
    local cmd = {kind = "hire", name = "Dr. 100% Jones=Smith", x = 12, step = 7}
    local line = MultiplayerSession.encodeCommand(cmd)
    assert.equal("C ", line:sub(1, 2))
    assert.same(cmd, MultiplayerSession.decodeCommand(line))
    assert.is_nil(MultiplayerSession.decodeCommand("S 1 2 abc"))
  end)

  it("encodes keys in a fixed order", function()
    assert.equal(MultiplayerSession.encodeCommand({b = 1, a = 2, c = 3}), "C a=2 b=1 c=3")
  end)

  it("refuses a delay below 2 steps", function()
    assert.has_error(function() make_pair(1) end)
  end)

  it("applies a command on both peers at the scheduled step", function()
    local a, b, wa, wb = make_pair(2)
    local cmd = b:issue({kind = "append", value = "bench"})
    assert.equal(2, cmd.step)
    run_both(a, b, 1)
    assert.same({}, wa.log)
    run_both(a, b, 1)
    assert.same({"bench"}, wa.log)
    assert.same({"bench"}, wb.log)
    run_both(a, b, 3)
    assert.is_nil(a.desync)
    assert.is_nil(b.desync)
  end)

  it("orders same-step commands by peer then sequence on every peer", function()
    local a, b, wa, wb = make_pair(2)
    b:issue({kind = "append", value = "b1"})
    a:issue({kind = "append", value = "a1"})
    b:issue({kind = "append", value = "b2"})
    a:issue({kind = "append", value = "a2"})
    run_both(a, b, 3)
    assert.same({"a1", "a2", "b1", "b2"}, wa.log)
    assert.same(wa.log, wb.log)
    assert.is_nil(a.desync)
  end)

  it("rejects a command the same way on every peer", function()
    local a, b, wa, wb = make_pair(2)
    a:issue({kind = "append", value = "bad"})
    b:issue({kind = "append", value = "ok"})
    run_both(a, b, 3)
    assert.same({"ok"}, wa.log)
    assert.same({"ok"}, wb.log)
    assert.equal(1, a.stats.rejected)
    assert.equal(1, b.stats.rejected)
  end)

  it("stalls a peer that would run ahead of the other", function()
    local a, b = make_pair(2)
    -- With delay 2, a peer may be at most one step ahead.
    assert.is_true(try_step(a))
    assert.is_false(try_step(a))
    assert.is_true(a.stats.stalls > 0)
    assert.is_true(try_step(b))
    assert.is_true(try_step(a))
    assert.is_false(try_step(a))
  end)

  it("allows more run-ahead with a longer delay", function()
    local a = make_pair(4)
    assert.is_true(try_step(a))
    assert.is_true(try_step(a))
    assert.is_true(try_step(a))
    assert.is_false(try_step(a))
  end)

  it("never applies a command early even if it arrives early", function()
    local a, b, wa = make_pair(3)
    b:issue({kind = "append", value = "x"}) -- scheduled for step 3
    assert.is_true(try_step(a))
    assert.is_true(try_step(b))
    assert.is_true(try_step(a))
    assert.same({}, wa.log)
    assert.is_true(try_step(b))
    assert.is_true(try_step(a))
    assert.same({"x"}, wa.log)
  end)

  it("detects a desync on both peers", function()
    local a, b, wa = make_pair(2)
    run_both(a, b, 2)
    wa.log[#wa.log + 1] = "local-only change" -- applied without a command
    run_both(a, b, 3)
    assert.is_not_nil(a.desync)
    assert.is_not_nil(b.desync)
    assert.equal(3, a.desync.step)
    assert.equal(3, b.desync.step)
  end)

  it("flags a command that arrives after its step already ran", function()
    local a, b = make_pair(2)
    run_both(a, b, 3)
    -- Forge a command for a step that is already over.
    a.transport:send(MultiplayerSession.encodeCommand(
        {kind = "append", value = "late", step = 2, peer = 1, seq = 99}))
    b:poll()
    assert.is_not_nil(b.desync)
  end)
end)

describe("MultiplayerSession notices", function()
  local function pair_with_clock(now)
    local a_to_b, b_to_a = {}, {}
    local ta = {send = function(_, l) a_to_b[#a_to_b + 1] = l end,
                receive = function(_) return table.remove(b_to_a, 1) end}
    local notes = {}
    local a = MultiplayerSession({world = {log = {}}, peer_id = 1, peers = {1, 2}, transport = ta,
        handlers = {}, fingerprint = function() return "x" end,
        clock = function() return now[1] end,
        notify = function(msg) notes[#notes + 1] = msg end})
    return a, notes, b_to_a
  end

  it("tells the player once when waiting for the other peer for a while", function()
    local now = {0}
    local a, notes = pair_with_clock(now)
    a:beforeStep() a:afterStep() -- step 1 allowed without the peer
    assert.is_false(a:canStep())
    now[1] = 1000
    assert.is_false(a:canStep())
    assert.equal(0, #notes)
    now[1] = 2000
    assert.is_false(a:canStep())
    now[1] = 5000
    assert.is_false(a:canStep())
    assert.equal(1, #notes)
    assert.truthy(notes[1]:find("Waiting"))
  end)

  it("tells the player about a desync", function()
    local now = {0}
    local a, notes, inbox = pair_with_clock(now)
    a:beforeStep() a:afterStep()
    inbox[#inbox + 1] = "S 2 1 different"
    a:poll()
    assert.is_not_nil(a.desync)
    assert.truthy(notes[#notes]:find("out of sync"))
  end)
end)
