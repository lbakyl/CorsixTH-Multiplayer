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

local MultiplayerSession = _G["MultiplayerSession"]
local handlers = MultiplayerSession.default_handlers

-- Texts the handlers format for their notes (shown to nobody here).
local function with_texts(fn)
  local old_S = rawget(_G, "_S")
  rawset(_G, "_S", {multiplayer_window = setmetatable({}, {__index = function() return "%s" end}),
      transactions = {bank_loan = "loan"}})
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

-- A map of one row of tiles, two per plot: `layout` lists the plot of each
-- position (by two tiles), `owners` the owner of each plot. Plots 1 and 2 are
-- the players' starting plots.
local function plot_world(layout, owners, extra)
  extra = extra or {}
  local th = {}
  local owner = {}
  for p, o in pairs(owners) do owner[p] = o end
  local function plot_at(x) return layout[math.ceil(x / 2)] end
  function th.size() return #layout * 2, 1 end
  function th.getPlotCount() return 20 end
  function th.getPlayerCount() return 2 end
  function th.getPlotOwner(_, plot) return owner[plot] or 0 end
  function th.getCellFlags(_, x, _, t)
    t = t or {}
    t.parcelId = plot_at(x) or 0
    t.roomId = extra.room_tiles and extra.room_tiles[x] and 7 or 0
    return t
  end
  function th.updatePathfinding() end
  local removed_litter = {}
  local world = {map = {th = th, width = #layout * 2, height = 1}, entities = extra.entities or {},
      rooms = extra.rooms or {}, mp_coop = {players = 2}, mp_plot_paid = extra.paid,
      removed_litter = removed_litter}
  function world.map.getParcelPrice() return 1000 end
  function world.map._wallInRooms() end
  function world.getObjects(_, x) return extra.objects and extra.objects[x] end
  function world.setPlotOwner(_, plot, new) owner[plot] = new end
  local hospitals = {}
  for i = 1, 2 do
    local h = {ownedPlots = {}, ratholes = {}, staff = {}, balance = 0, name = "H" .. i, value = 0}
    function h.getPlayerIndex() return i end
    function h.spendMoney(self, amount) self.balance = self.balance - amount end
    function h.receiveMoney(self, amount, _, value)
      self.balance = self.balance + amount
      self.value = self.value - (value or 0)
    end
    hospitals[i] = h
  end
  world.hospitals = hospitals
  return world, hospitals, owner
end

describe("Selling a plot back", function()
  -- plots by position: 3 1 4 2 5; hospital 1 has 1, 3 and 4.
  local function make(extra, owners)
    return plot_world({3, 1, 4, 2, 5}, owners or {[1] = 1, [2] = 2, [3] = 1, [4] = 1}, extra)
  end

  it("pays back 80 percent of what was paid and frees the plot", function()
    with_texts(function()
      local world, hospitals, owner = make({paid = {[4] = 1500}})
      hospitals[1].ownedPlots = {1, 3, 4}
      hospitals[1].staff = {{parcelNr = 4}, {parcelNr = 3}}
      assert.is_nil(MultiplayerSession.plotRefusal(world, hospitals[1], 4))
      assert.equal(1200, MultiplayerSession.plotRefund(world, 4))
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 4}))
      assert.equal(1200, hospitals[1].balance)
      assert.equal(-1500, hospitals[1].value)
      assert.equal(0, owner[4])
      assert.is_nil(world.mp_plot_paid[4])
      assert.same({1, 3}, hospitals[1].ownedPlots)
      assert.equal(0, hospitals[1].staff[1].parcelNr)
      assert.equal(3, hospitals[1].staff[2].parcelNr)
    end)
  end)

  it("counts land bought before the price was kept at the list price", function()
    local world = make()
    assert.equal(800, MultiplayerSession.plotRefund(world, 3))
  end)

  it("never sells a starting plot or somebody else's plot", function()
    with_texts(function()
      local world, hospitals = make()
      local ok, why = handlers.sell_plot(world, {hospital = 1, plot = 1})
      assert.is_false(ok)
      assert.equal("starting plot", why)
      ok, why = handlers.sell_plot(world, {hospital = 2, plot = 3})
      assert.is_false(ok)
      assert.equal("not your plot", why)
      ok, why = handlers.sell_plot(world, {hospital = 1, plot = 5})
      assert.is_false(ok)
      assert.equal("not your plot", why)
      ok, why = handlers.sell_plot(world, {hospital = 1, plot = 99})
      assert.is_false(ok)
      assert.equal("no such plot", why)
      assert.equal(0, hospitals[1].balance)
    end)
  end)

  it("refuses a plot with a room, a room being built, an object or a person", function()
    with_texts(function()
      -- Plot 4 is at tiles 5 and 6.
      local _
      local world = make({room_tiles = {[6] = true}})
      local ok, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.is_false(ok)
      assert.equal("plot not empty", why)
      world = make({rooms = {{x = 5, y = 1, width = 1, height = 1}}})
      _, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.equal("plot not empty", why)
      world = make({objects = {[5] = {{object_type = {id = "bench"}}}}})
      _, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.equal("plot not empty", why)
      world = make({entities = {{action_queue = {}, tile_x = 6, tile_y = 1}}})
      _, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.equal("people on the plot", why)
      -- Somebody who is about to walk across it.
      world = make({entities = {{tile_x = 9, tile_y = 1, action_queue = {{name = "walk",
          path_x = {9, 8, 7, 6}, path_y = {1, 1, 1, 1}, path_index = 2}}}}})
      _, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.equal("people on the plot", why)
      -- (...but another plot is not stopped by it.)
      world.entities[1].action_queue[1].path_index = 4
      world.entities[1].tile_x = 6
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 3}))
      assert.equal(800, world.hospitals[1].balance)
    end)
  end)

  it("lets litter and rat holes go with the plot", function()
    with_texts(function()
      local removed = 0
      local litter = {object_type = {id = "litter"}, isCleanable = function() return true end,
          remove = function() removed = removed + 1 end}
      local world, hospitals = make({objects = {[5] = {litter}, [6] = {{object_type = {id = "rathole"}}}}})
      local hole = {x = 6, y = 1}
      hospitals[1].ratholes = {hole, {x = 1, y = 1}}
      local gone
      hospitals[1].removeRathole = function(_, h) gone = h end
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 4}))
      assert.equal(1, removed)
      assert.equal(hole, gone)
    end)
  end)

  it("refuses to cut off land that hangs together with the hospital through the plot", function()
    with_texts(function()
      -- Hospital 1: plot 1 (start), 4 and 5, in a row: 1 4 5 ... 2.
      local world = plot_world({1, 4, 5, 2}, {[1] = 1, [2] = 2, [4] = 1, [5] = 1})
      local ok, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.is_false(ok)
      assert.equal("joins your land", why)
      ok = handlers.sell_plot(world, {hospital = 1, plot = 5})
      assert.is_true(ok)
    end)
  end)

  it("waits while an auction is on", function()
    with_texts(function()
      local world = make()
      world.mp_auction = {}
      local ok, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.is_false(ok)
      assert.equal("an auction is on", why)
    end)
  end)
end)

describe("Handing a plot to an ally", function()
  -- plots by position: 3 1 4 2 5; hospital 1 has 1, 3 and 4, hospital 2 has 2.
  local function make(extra)
    local world, hospitals, owner = plot_world({3, 1, 4, 2, 5}, {[1] = 1, [2] = 2, [3] = 1, [4] = 1}, extra)
    local queued = {}
    local panel = {
      queueMessage = function(_, kind, message, _, timeout, choice, _, to)
        world.next_message_id = (world.next_message_id or 0) + 1
        queued[#queued + 1] = {kind = kind, message = message, id = world.next_message_id, timeout = timeout}
        assert.equal(2, choice)
        assert.is_not_nil(to)
      end,
      findMessageIcon = function(_, id)
        for _, m in ipairs(queued) do if m.id == id and not m.answered then return m end end
      end,
    }
    world.ui = {bottom_panel = panel}
    world.app = {}
    world.mpMayTrade = function() return true end
    world.mpRivals = function() return false end
    world.getHospitalIndex = function(_, h) return h == hospitals[1] and 1 or 2 end
    for _, h in ipairs(hospitals) do h.loan = 0 end
    return world, hospitals, owner, queued
  end

  it("offers an empty plot that touches the ally's land, once", function()
    with_texts(function()
      local world, hospitals, owner, queued = make()
      hospitals[1].ownedPlots = {1, 3, 4}
      -- Plot 4 touches plot 2, the ally's.
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4, price = 2500}))
      assert.equal(1, #queued)
      assert.equal(2500, queued[1].message.mp_offer.price)
      assert.equal(4, queued[1].message.mp_offer.plot)
      assert.equal(1, owner[4]) -- nothing changes before the answer
      local ok, why = handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4, price = 0})
      assert.is_false(ok)
      assert.equal("already offered", why)
      -- A plot that does not touch the ally's land.
      ok, why = handlers.offer_plot(world, {hospital = 1, to = 2, plot = 3, price = 0})
      assert.is_false(ok)
      assert.equal("does not touch their land", why)
    end)
  end)

  it("checks price, ally, starting plot and emptiness", function()
    with_texts(function()
      local world = make({objects = {[5] = {{object_type = {id = "bench"}}}}})
      local function why_not(cmd)
        local ok, why = handlers.offer_plot(world, cmd)
        assert.is_false(ok)
        return why
      end
      assert.equal("invalid price", why_not({hospital = 1, to = 2, plot = 4, price = 50001}))
      assert.equal("invalid price", why_not({hospital = 1, to = 2, plot = 4, price = -1}))
      assert.equal("no such hospital", why_not({hospital = 1, to = 1, plot = 4, price = 0}))
      assert.equal("starting plot", why_not({hospital = 1, to = 2, plot = 1, price = 0}))
      assert.equal("plot not empty", why_not({hospital = 1, to = 2, plot = 4, price = 0}))
      world.mpRivals = function() return true end
      assert.equal("not on your team", why_not({hospital = 1, to = 2, plot = 4, price = 0}))
    end)
  end)

  it("moves the plot and the price when the ally accepts", function()
    with_texts(function()
      local world, hospitals, owner, queued = make({paid = {[4] = 3000}})
      hospitals[1].ownedPlots = {1, 3, 4}
      hospitals[1].value, hospitals[2].value = 10000, 10000
      hospitals[2].balance = 4000
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4, price = 2500}))
      local offer = queued[1].message.mp_offer
      MultiplayerSession.resolveOffer(world, offer, true)
      assert.equal(2, owner[4])
      assert.same({1, 3}, hospitals[1].ownedPlots)
      assert.same({4}, hospitals[2].ownedPlots)
      assert.equal(1500, hospitals[2].balance)
      assert.equal(2500, hospitals[1].balance)
      assert.equal(7000, hospitals[1].value)
      assert.equal(13000, hospitals[2].value)
      assert.is_nil(world.mp_plot_offers[4])
      -- The price paid to the bank stays with the plot.
      assert.equal(3000, MultiplayerSession.plotPaid(world, 4))
    end)
  end)

  it("changes nothing when declined or when the ally cannot pay", function()
    with_texts(function()
      local world, hospitals, owner, queued = make()
      hospitals[2].balance = 100
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4, price = 2500}))
      MultiplayerSession.resolveOffer(world, queued[1].message.mp_offer, false)
      assert.equal(1, owner[4])
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4, price = 2500}))
      MultiplayerSession.resolveOffer(world, queued[2].message.mp_offer, true)
      assert.equal(1, owner[4])
      assert.equal(100, hospitals[2].balance)
      -- A free plot needs no money.
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4}))
      MultiplayerSession.resolveOffer(world, queued[3].message.mp_offer, true)
      assert.equal(2, owner[4])
    end)
  end)

  it("is void when the plot is no longer empty", function()
    with_texts(function()
      local extra = {}
      local world, _, owner, queued = make(extra)
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4}))
      extra.objects = {[5] = {{object_type = {id = "bench"}}}}
      MultiplayerSession.resolveOffer(world, queued[1].message.mp_offer, true)
      assert.equal(1, owner[4])
    end)
  end)

  it("lets a bot borrow what it lacks, and only a bot", function()
    with_texts(function()
      local world, hospitals, owner, queued = make()
      hospitals[2].balance, hospitals[2].value = 1000, 30000
      world.mp_coop = {players = 2, bot_hospitals = {[2] = true}}
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 4, price = 6000}))
      MultiplayerSession.resolveOffer(world, queued[1].message.mp_offer, true)
      assert.equal(2, owner[4])
      assert.is_true(hospitals[2].loan > 0)
      assert.is_true(hospitals[2].balance >= 0)
    end)
  end)
end)
