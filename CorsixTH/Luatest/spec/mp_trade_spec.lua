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
local handlers = MultiplayerSession.default_handlers

-- Texts the handlers format for their notes (shown to nobody here).
local function with_texts(fn)
  local old_S = rawget(_G, "_S")
  rawset(_G, "_S", {multiplayer_window = setmetatable({}, {__index = function() return "%s %s" end})})
  local ok, err = pcall(fn)
  rawset(_G, "_S", old_S)
  if not ok then error(err, 0) end
end

local function hospital(rep)
  local h = {reputation = rep, reputation_max = 1000, name = "H"}
  function h.unconditionalChangeReputation(self, delta)
    self.reputation = math.max(0, math.min(self.reputation_max, self.reputation + delta))
  end
  return h
end

describe("Trading reputation", function()
  local function make(rep_a, rep_b, month, rivals)
    local a, b = hospital(rep_a), hospital(rep_b)
    local world = {hospitals = {a, b}, month = month or 1,
        mpMayTrade = function() return true end,
        mpRivals = function() return rivals or false end}
    function world.date() return {monthOfGame = function() return world.month end} end
    return world, a, b
  end

  it("moves points from the giver to the receiver", function()
    with_texts(function()
      local world, a, b = make(500, 400)
      assert.is_true(handlers.give_reputation(world, {hospital = 1, to = 2, amount = 30}))
      assert.equal(470, a.reputation)
      assert.equal(430, b.reputation)
    end)
  end)

  it("refuses rivals, bad amounts and itself", function()
    with_texts(function()
      local world = make(500, 400, 1, true)
      local ok, why = handlers.give_reputation(world, {hospital = 1, to = 2, amount = 30})
      assert.is_false(ok)
      assert.equal("not on your team", why)
      world = make(500, 400)
      for _, amount in ipairs({0, -5, 101, "x"}) do
        ok, why = handlers.give_reputation(world, {hospital = 1, to = 2, amount = amount})
        assert.is_false(ok)
        assert.equal("invalid amount", why)
      end
      ok, why = handlers.give_reputation(world, {hospital = 1, to = 1, amount = 5})
      assert.is_false(ok)
      assert.equal("no such hospital", why)
    end)
  end)

  it("keeps the giver above the floor and stops at the receiver's top", function()
    with_texts(function()
      local world, a, b = make(230, 990)
      -- Only 30 above the floor of 200, and 10 below the top.
      assert.is_true(handlers.give_reputation(world, {hospital = 1, to = 2, amount = 50}))
      assert.equal(220, a.reputation)
      assert.equal(1000, b.reputation)
      local ok, why = handlers.give_reputation(world, {hospital = 1, to = 2, amount = 5})
      assert.is_false(ok)
      assert.equal("their reputation is full", why)
      world, a = make(200, 100)
      ok, why = handlers.give_reputation(world, {hospital = 1, to = 2, amount = 5})
      assert.is_false(ok)
      assert.equal("reputation too low", why)
      assert.equal(200, a.reputation)
    end)
  end)

  it("limits what one hospital gives in a game month", function()
    with_texts(function()
      local world, a, b = make(900, 100)
      assert.is_true(handlers.give_reputation(world, {hospital = 1, to = 2, amount = 100}))
      assert.is_true(handlers.give_reputation(world, {hospital = 1, to = 2, amount = 100}))
      local ok, why = handlers.give_reputation(world, {hospital = 1, to = 2, amount = 1})
      assert.is_false(ok)
      assert.equal("monthly limit", why)
      assert.equal(700, a.reputation)
      assert.equal(300, b.reputation)
      -- The next month it starts again.
      world.month = 2
      assert.is_true(handlers.give_reputation(world, {hospital = 1, to = 2, amount = 40}))
      assert.equal(660, a.reputation)
      assert.equal(160, MultiplayerSession.reputationLeft(world, a))
    end)
  end)
end)
