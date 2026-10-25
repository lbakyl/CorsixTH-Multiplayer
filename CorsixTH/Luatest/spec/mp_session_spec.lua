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

  it("lets a retry wait game hours, not steps (steps below Normal are shorter)", function()
    local tries = 0
    local h = {wait = function() tries = tries + 1 if tries < 2 then return false, "retry" end return true end}
    local ta, tb = linked_transports()
    local world = {log = {}, mp_hours = 0}
    local a = MultiplayerSession({world = world, peer_id = 1, peers = {1, 2}, transport = ta,
        handlers = h, fingerprint = fingerprint})
    local b = MultiplayerSession({world = {log = {}, mp_hours = 0}, peer_id = 2, peers = {1, 2},
        transport = tb, handlers = {wait = function() return true end}, fingerprint = fingerprint})
    a:issue({kind = "wait"})
    run_both(a, b, 12) -- no game hour passes: the retry keeps waiting
    assert.equal(1, tries)
    world.mp_hours = MultiplayerSession.RETRY_STEPS
    run_both(a, b, 2)
    assert.equal(2, tries)
    assert.equal(1, a.stats.applied)
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

  it("says whom the game waits for, and why", function()
    local now = {0}
    local a, notes = pair_with_clock(now)
    a.peer_name = function(p) return p == 2 and "iris" or nil end
    a.busy = {[2] = "UIFax"}
    a:beforeStep() a:afterStep()
    assert.is_false(a:canStep())
    now[1] = 2000
    assert.is_false(a:canStep())
    assert.equal("Waiting for iris: a fax is open.", notes[#notes])
    assert.equal("Waiting for the other player...", MultiplayerSession.waitingText({}, 2))
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

  it("reports a game that stops for no visible reason once, not a shared pause", function()
    local now = {0}
    local sent = {}
    local a = pair_with_clock(now)
    a.send_diagnostics = function(step, text) sent[#sent + 1] = text end
    local speed, user_paused = "Normal", false
    local world = {hours_per_tick = 1, ui = {windows = {}},
      isCurrentSpeed = function(_, s) return s == speed end,
      getCurrentSpeed = function() return speed end,
      isGameUserPaused = function() return user_paused end,
      isMustPauseActive = function() return false end}
    a:checkStall(world)
    now[1] = 14000
    a:checkStall(world)
    assert.equal(0, #sent)
    now[1] = 16000
    a:checkStall(world)
    a:checkStall(world)
    assert.equal(1, #sent)
    assert.truthy(sent[1]:find("^STALL at step 0 for 16s: speed Normal"))
    -- Running again, then a pause everybody chose: nothing to report.
    a:beforeStep() a:afterStep()
    a:checkStall(world)
    speed, user_paused = "Pause", true
    now[1] = 60000
    a:checkStall(world)
    assert.equal(1, #sent)
  end)

  it("reports each Lua error once", function()
    local sent = {}
    local a = pair_with_clock({0})
    a.send_diagnostics = function(step, text) sent[#sent + 1] = text end
    assert.is_true(a:reportError("screen tick", "audio.lua:410: oops\nstack traceback: ..."))
    assert.is_nil(a:reportError("screen tick", "audio.lua:410: oops\nstack traceback: elsewhere"))
    assert.is_true(a:reportError("timer handler", "world.lua:1: other"))
    assert.equal(2, #sent)
    assert.truthy(sent[1]:find("^ERROR at step 0 in the screen tick: audio.lua:410: oops"))
  end)

  it("tells only the player who asked when their action is turned down", function()
    local notes = {a = {}, b = {}}
    local ta, tb = linked_transports()
    local function make(id, t, list)
      return MultiplayerSession({world = {log = {}}, peer_id = id, peers = {1, 2}, transport = t,
          handlers = handlers, fingerprint = fingerprint,
          notify = function(msg) list[#list + 1] = msg end})
    end
    local a, b = make(1, ta, notes.a), make(2, tb, notes.b)
    a:issue({kind = "append", value = "bad"})
    run_both(a, b, 3)
    assert.equal(1, #notes.a)
    assert.truthy(notes.a[1]:find("rejected value"))
    assert.equal(0, #notes.b)
  end)
end)
