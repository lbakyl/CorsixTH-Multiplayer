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

  it("is not stopped by somebody whose walk crosses it only further on", function()
    with_texts(function()
      -- Plot 4 is at tiles 5 and 6; the walk goes from 10 to 3 (plot 1),
      -- across it in 4 steps. (Jan, 2026-11-13: a plot with the map's
      -- entrance on it, patients always walking in across it.)
      local walker = {tile_x = 10, tile_y = 1, action_queue = {{name = "walk",
          path_x = {10, 9, 8, 7, 6, 5, 4, 3}, path_y = {1, 1, 1, 1, 1, 1, 1, 1}, path_index = 2}}}
      local world = make({entities = {walker}})
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 4}))
      -- Three steps from it: refused.
      world = make({entities = {walker}})
      walker.action_queue[1].path_index = 4
      local _, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.equal("people on the plot", why)
      -- Walking to a tile on it: refused, however far.
      walker.action_queue[1] = {name = "walk", path_x = {10, 9, 8, 7, 6}, path_y = {1, 1, 1, 1, 1}, path_index = 2}
      walker.tile_x = 10
      _, why = handlers.sell_plot(world, {hospital = 1, plot = 4})
      assert.equal("people on the plot", why)
    end)
  end)

  it("takes the doors of an entrance the map put on the plot along, to be made again", function()
    with_texts(function()
      local door = {object_type = {id = "entrance_left_door", supports_creation_for_map = true},
          tile_x = 5, tile_y = 1, direction = "west"}
      local world, hospitals, owner = make({objects = {[5] = {door}}})
      local destroyed = {}
      function world.destroyEntity(_, entity) destroyed[#destroyed + 1] = entity end
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 4}))
      assert.same({door}, destroyed)
      assert.equal(0, owner[4])
      local again = {}
      for info, plot in pairs(world.delayed_map_objects) do again[#again + 1] = {info, plot} end
      assert.same({{{"entrance_left_door", 5, 1, 1, "map object"}, 4}}, again)
      assert.equal(800, hospitals[1].balance)
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

  it("does not count land that was cut off from the hospital already", function()
    with_texts(function()
      -- Hospital 1: plot 1 (start) and 4 are joined; 6 is not (7 between).
      local world = plot_world({1, 4, 7, 6, 2}, {[1] = 1, [2] = 2, [4] = 1, [6] = 1})
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 4}))
      assert.is_true(handlers.sell_plot(world, {hospital = 1, plot = 6}))
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

  it("offers an empty plot, once, whether or not it touches the ally's land", function()
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
      -- A plot that does not touch the ally's land may be handed over too
      -- (it could have been bought, or won at an auction, as well).
      assert.is_true(handlers.offer_plot(world, {hospital = 1, to = 2, plot = 3, price = 0}))
      assert.equal(2, #queued)
      assert.equal(3, queued[2].message.mp_offer.plot)
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

describe("A bot offered a plot", function()
  local Manager = assert(loadfile("../../scripts/multiplayer/bot_manager.lua"))()

  -- A bot whose hospital has `inside` indoor tiles, `rooms` of them taken by rooms.
  local function bot_with(inside, rooms, balance)
    local bot_hospital = {balance = balance, loan = 0, value = 30000, getPlayerIndex = function() return 2 end}
    local th = {
      size = function() return inside, 1 end,
      getCellFlags = function(_, x, _, t)
        t = t or {}
        t.hospital, t.owner, t.roomId = true, 2, x <= rooms and 7 or 0
        return t
      end,
    }
    local world = {map = {th = th}, ui = {hospital = bot_hospital}}
    local manager = setmetatable({bot = {world = world}, log = function() end,
        pick = function(list) return list[1] end}, Manager)
    return manager
  end

  it("takes it when less than 35 percent of its land is free and it can pay", function()
    local accept, line = bot_with(100, 70, 20000):plotAnswer({plot = 5, price = 5000})
    assert.is_true(accept)
    assert.is_string(line)
  end)

  it("takes it with a loan when it lacks the money", function()
    local accept = bot_with(100, 70, 1000):plotAnswer({plot = 5, price = 9000})
    assert.is_true(accept) -- (the bank lends $10,000 or more)
  end)

  it("declines when it has plenty of room, or cannot pay even with a loan", function()
    local accept = bot_with(100, 50, 50000):plotAnswer({plot = 5, price = 0})
    assert.is_false(accept)
    accept = bot_with(100, 90, 1000):plotAnswer({plot = 5, price = 50000})
    assert.is_false(accept)
  end)

  it("takes a free plot whatever it has in the bank", function()
    local accept = bot_with(100, 90, 0):plotAnswer({plot = 5})
    assert.is_true(accept)
  end)
end)

describe("Trading with rivals", function()
  local function make(rivals)
    local a = {balance = 50000, name = "A", reputation = 300}
    local b = {balance = 50000, name = "B", reputation = 300}
    for _, h in ipairs({a, b}) do
      function h.spendMoney(self, n) self.balance = self.balance - n end
      function h.receiveMoney(self, n) self.balance = self.balance + n end
      function h.changeReputation(self, _, _, n) self.reputation = self.reputation + n end
    end
    local world = {hospitals = {a, b}, mp_coop = {},
        mpMayTrade = function(_, x, y) return x ~= y end,
        mpRivals = function() return rivals end}
    function world.getHospitalIndex(_, h) return h == a and 1 or 2 end
    return world, a, b
  end

  it("sends and asks for money only between allies", function()
    with_texts(function()
      local world, a = make(true)
      local ok, why = handlers.give_money(world, {hospital = 1, to = 2, amount = 1000})
      assert.is_false(ok)
      assert.equal("not on your team", why)
      assert.equal(50000, a.balance)
      ok, why = handlers.ask_money(world, {hospital = 1, to = 2, amount = 1000})
      assert.is_false(ok)
      assert.equal("not on your team", why)
      local b
      world, a, b = make(false)
      assert.is_true(handlers.give_money(world, {hospital = 1, to = 2, amount = 1000}))
      assert.equal(49000, a.balance)
      assert.equal(51000, b.balance)
    end)
  end)

  it("sells research to a rival for at least $1,000", function()
    with_texts(function()
      local old_app = rawget(_G, "TheApp")
      rawset(_G, "TheApp", {objects = {}})
      local world = make(true)
      local ok, why = handlers.offer_research(world, {hospital = 1, to = 2, items = "e:x_ray", price = 500})
      assert.is_false(ok)
      assert.equal("a rival pays at least $1,000", why)
      -- (The price is fine; there is nothing to share here.)
      ok, why = handlers.offer_research(world, {hospital = 1, to = 2, items = "e:x_ray", price = 1000})
      assert.is_false(ok)
      assert.equal("nothing to share", why)
      world = make(false)
      ok, why = handlers.offer_research(world, {hospital = 1, to = 2, items = "e:x_ray", price = 0})
      assert.is_false(ok)
      assert.equal("nothing to share", why)
      rawset(_G, "TheApp", old_app)
    end)
  end)

  it("gives reputation to both hospitals when a referred patient is cured", function()
    with_texts(function()
      local world, a, b = make(true)
      local patient = {mp_id = 7, mp_referred_by = 1}
      MultiplayerSession.referralCured(world, b, patient)
      assert.equal(300 + MultiplayerSession.REFERRAL_REPUTATION, a.reputation)
      assert.equal(300 + MultiplayerSession.REFERRAL_EXTRA, b.reputation)
      assert.is_nil(patient.mp_referred_by)
      -- Once only, and nothing for a patient of its own.
      MultiplayerSession.referralCured(world, b, patient)
      patient.mp_referred_by = 2
      MultiplayerSession.referralCured(world, b, patient)
      assert.equal(303, a.reputation)
      assert.equal(301, b.reputation)
    end)
  end)
end)
