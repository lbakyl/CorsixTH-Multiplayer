--[[ Copyright (c) 2026 Bruno Lima
Copyright (c) 2026 Joshua "gojomoso1" DeVries

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

require("utility")
require("persistance")

-- Load the modules world.lua depends on in the same order as app.lua does.
-- world.lua also reads the global _A (the app) while loading, so provide a
-- minimal stub for that.
local saved_A = _G._A
_G._A = {cheats = {}}
require("map")
require("entity")
require("entities.humanoid")
require("entities.object")
require("entities.machine")
require("room")
require("humanoid_action")
require("world")
_G._A = saved_A

local World = _G["World"]
local EntityMap = _G["EntityMap"]

describe("world.lua: ", function()
  local function makeWorld(entities)
    local world = {entities = entities, entities_to_destroy = {}}
    setmetatable(world, {__index = World})
    return world
  end

  local function makeEntity(name)
    local entity = {
      name = name,
      ticks = true,
      tick_count = 0,
    }
    function entity:tick()
      self.tick_count = self.tick_count + 1
    end
    function entity:onDestroy()
      self.destroyed = true
    end
    return entity
  end

  -- Simulates the entity tick loop of World:onTick, including the guard that
  -- skips entities queued for destruction and the flush after the loop.
  local function runTickLoop(world)
    for _, entity in ipairs(world.entities) do
      if entity.ticks and not entity.to_destroy then
        world.current_tick_entity = entity
        entity:tick()
      end
    end
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
  end

  -- Simulates the entity tickDay loop of World:onEndDay. Mirrors the real
  -- structure: humanoids and plants are dispatched separately, and plants
  -- also set current_tick_entity so deferred destruction applies to them.
  local function runTickDayLoop(world)
    for _, entity in ipairs(world.entities) do
      if entity.kind == "humanoid" and not entity.to_destroy then
        world.current_tick_entity = entity
        entity:tickDay()
      elseif entity.kind == "plant" and not entity.to_destroy then
        world.current_tick_entity = entity
        entity:tickDay()
      end
    end
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
  end

  -- Simulates the entity checkForDeadlock loop of World:onEndMonth.
  local function runDeadlockLoop(world)
    for _, entity in ipairs(world.entities) do
      if entity.checkForDeadlock and not entity.to_destroy then
        world.current_tick_entity = entity
        entity:checkForDeadlock()
      end
    end
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
  end

  it("removes entity immediately outside an entities loop", function()
    local e1, e2 = makeEntity("e1"), makeEntity("e2")
    local world = makeWorld({e1, e2})

    world:destroyEntity(e1)

    assert.are.equal(1, #world.entities)
    assert.is.equal(e2, world.entities[1])
    assert.is_true(e1.destroyed)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  it("destroys entity not present in the list", function()
    local e1 = makeEntity("e1")
    local world = makeWorld({})

    world:destroyEntity(e1)

    assert.is_true(e1.destroyed)
    assert.are.equal(0, #world.entities)
  end)

  it("defers removal while iterating the entities list", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    world.current_tick_entity = e2

    world:destroyEntity(e2)

    assert.are.equal(3, #world.entities)
    assert.are.equal(1, #world.entities_to_destroy)
    assert.is_true(e2.destroyed)
    assert.is_true(e2.to_destroy)

    world.current_tick_entity = nil
    world:_flushDestroyedEntities()

    assert.are.equal(2, #world.entities)
    assert.is.equal(e1, world.entities[1])
    assert.is.equal(e3, world.entities[2])
    assert.is_nil(e2.to_destroy)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  it("queues an entity for destruction only once", function()
    local e1 = makeEntity("e1")
    local world = makeWorld({e1})
    world.current_tick_entity = e1

    world:destroyEntity(e1)
    world:destroyEntity(e1)

    assert.are.equal(1, #world.entities_to_destroy)
  end)

  it("flushes multiple deferred destructions in one pass", function()
    local e1, e2, e3, e4 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3"), makeEntity("e4")
    local world = makeWorld({e1, e2, e3, e4})
    world.current_tick_entity = e2

    world:destroyEntity(e2)
    world:destroyEntity(e4)

    world.current_tick_entity = nil
    world:_flushDestroyedEntities()

    assert.are.equal(2, #world.entities)
    assert.is.equal(e1, world.entities[1])
    assert.is.equal(e3, world.entities[2])
  end)

  it("flush does nothing with an empty queue", function()
    local e1 = makeEntity("e1")
    local world = makeWorld({e1})

    world:_flushDestroyedEntities()

    assert.are.equal(1, #world.entities)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  it("does not skip entities when an earlier entity is destroyed mid-loop", function()
    local e1, e2, e3, e4 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3"), makeEntity("e4")
    local world = makeWorld({e1, e2, e3, e4})
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      -- Destroy an entity that already ticked (before the current index) and
      -- one that has not ticked yet (after the current index). Without the
      -- deferred removal, e3 would be skipped.
      world:destroyEntity(e1)
      world:destroyEntity(e4)
    end

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.are.equal(1, e3.tick_count)
    assert.is_true(e4.destroyed)
    assert.are.equal(0, e4.tick_count)
    assert.are.equal(2, #world.entities)
    assert.is.equal(e2, world.entities[1])
    assert.is.equal(e3, world.entities[2])
  end)

  it("does not tick an entity destroyed earlier in the same loop", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    e1.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.is_true(e3.destroyed)
    assert.are.equal(0, e3.tick_count)
    assert.are.equal(2, #world.entities)
  end)

  it("destroys itself during its tick and is removed after the loop", function()
    local e1, e2 = makeEntity("e1"), makeEntity("e2")
    local world = makeWorld({e1, e2})
    e1.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(self)
    end

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.is_true(e1.destroyed)
    assert.are.equal(1, #world.entities)
    assert.is.equal(e2, world.entities[1])
  end)

  it("handles cascading destructions during a single loop", function()
    local e1, e2, e3, e4 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3"), makeEntity("e4")
    local world = makeWorld({e1, e2, e3, e4})
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    -- Destroying e3 destroys e4 as well, mimicking a room crashing and
    -- taking its objects with it.
    e3.onDestroy = function(self)
      self.destroyed = true
      world:destroyEntity(e4)
    end

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.is_true(e3.destroyed)
    assert.is_true(e4.destroyed)
    assert.are.equal(0, e3.tick_count)
    assert.are.equal(0, e4.tick_count)
    assert.are.equal(2, #world.entities)
  end)

  it("ticks entities added to the list during the loop", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    local e4 = makeEntity("e4")
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      world.entities[#world.entities + 1] = e4
    end

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.are.equal(1, e3.tick_count)
    assert.are.equal(1, e4.tick_count)
    assert.are.equal(4, #world.entities)
  end)

  it("recovers when the loop is interrupted before flushing", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    world.current_tick_entity = e1
    world:destroyEntity(e2)
    -- The error handling in app.lua clears current_tick_entity without a
    -- flush, so the queue survives into the next loop.
    world.current_tick_entity = nil

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e3.tick_count)
    assert.is_true(e2.destroyed)
    assert.are.equal(0, e2.tick_count)
    assert.are.equal(2, #world.entities)
  end)

  it("does nothing when destroying an already queued entity outside a loop", function()
    local e1, e2 = makeEntity("e1"), makeEntity("e2")
    local world = makeWorld({e1, e2})
    world.current_tick_entity = e1
    world:destroyEntity(e2)
    world.current_tick_entity = nil

    world:destroyEntity(e2)

    assert.are.equal(2, #world.entities)
    assert.is_true(e2.to_destroy)
    world:_flushDestroyedEntities()
    assert.are.equal(1, #world.entities)
  end)

  it("destroys immediately outside a loop even with pending queued entities", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    world.current_tick_entity = e1
    world:destroyEntity(e1)
    world.current_tick_entity = nil

    world:destroyEntity(e3)

    assert.is_true(e3.destroyed)
    assert.is_nil(e3.to_destroy)
    assert.are.equal(1, #world.entities_to_destroy)
    world:_flushDestroyedEntities()
    assert.are.equal(1, #world.entities)
    assert.is.equal(e2, world.entities[1])
  end)

  it("reuses the queue across consecutive loops", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    e1.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e2)
    end

    runTickLoop(world)

    assert.are.equal(2, #world.entities)
    assert.is_true(e2.destroyed)
    assert.are.equal(0, #world.entities_to_destroy)
    e3.tick = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e1)
    end

    runTickLoop(world)

    assert.are.equal(1, #world.entities)
    assert.is.equal(e3, world.entities[1])
    assert.are.equal(2, e1.tick_count)
    assert.are.equal(2, e3.tick_count)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  it("does not skip entities destroyed during the tickDay loop", function()
    local e1 = makeEntity("e1")
    local e2, e3, e4 = makeEntity("e2"), makeEntity("e3"), makeEntity("e4")
    e1.kind, e2.kind, e3.kind, e4.kind = "humanoid", "humanoid", "humanoid", "humanoid"
    local world = makeWorld({e1, e2, e3, e4})
    e2.tickDay = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e1)
      world:destroyEntity(e4)
    end
    e1.tickDay = function(self) self.tick_count = self.tick_count + 1 end
    e3.tickDay = function(self) self.tick_count = self.tick_count + 1 end

    runTickDayLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.are.equal(1, e3.tick_count)
    assert.is_true(e4.destroyed)
    assert.are.equal(0, e4.tick_count)
    assert.are.equal(2, #world.entities)
  end)

  it("defers destruction triggered by a plant during the tickDay loop", function()
    local plant = makeEntity("plant")
    local e2, e3 = makeEntity("e2"), makeEntity("e3")
    plant.kind, e2.kind, e3.kind = "plant", "humanoid", "humanoid"
    local world = makeWorld({plant, e2, e3})
    plant.tickDay = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    e2.tickDay = function(self) self.tick_count = self.tick_count + 1 end

    runTickDayLoop(world)

    assert.are.equal(1, plant.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.is_true(e3.destroyed)
    assert.are.equal(0, e3.tick_count)
    assert.are.equal(2, #world.entities)
    assert.is.equal(plant, world.entities[1])
    assert.is.equal(e2, world.entities[2])
  end)

  it("does not skip entities destroyed during the checkForDeadlock loop", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    e1.checkForDeadlock = function(self)
      self.tick_count = self.tick_count + 1
      world:destroyEntity(e3)
    end
    e2.checkForDeadlock = function(self) self.tick_count = self.tick_count + 1 end

    runDeadlockLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.is_true(e3.destroyed)
    assert.are.equal(2, #world.entities)
  end)



  it("destroys an entity not in the list during a loop without side effects", function()
    local e1, e2 = makeEntity("e1"), makeEntity("e2")
    local stray = makeEntity("stray")
    local world = makeWorld({e1, e2})
    world.current_tick_entity = e1

    world:destroyEntity(stray)

    assert.is_true(stray.destroyed)
    assert.is_true(stray.to_destroy)
    assert.are.equal(1, #world.entities_to_destroy)
    world.current_tick_entity = nil
    world:_flushDestroyedEntities()
    assert.are.equal(2, #world.entities)
    assert.is_nil(stray.to_destroy)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  it("flush is safe to call twice in a row", function()
    local e1, e2 = makeEntity("e1"), makeEntity("e2")
    local world = makeWorld({e1, e2})
    world.current_tick_entity = e1
    world:destroyEntity(e2)
    world.current_tick_entity = nil

    world:_flushDestroyedEntities()
    world:_flushDestroyedEntities()

    assert.are.equal(1, #world.entities)
    assert.are.equal(0, #world.entities_to_destroy)
  end)

  it("destroys from a nested iteration still defer until the outer loop ends", function()
    local e1, e2, e3 = makeEntity("e1"), makeEntity("e2"), makeEntity("e3")
    local world = makeWorld({e1, e2, e3})
    e2.tick = function(self)
      self.tick_count = self.tick_count + 1
      -- Simulates code that iterates world.entities from inside a tick.
      for _, inner in ipairs(world.entities) do
        if inner == e3 then
          world:destroyEntity(e3)
        end
      end
    end

    runTickLoop(world)

    assert.are.equal(1, e1.tick_count)
    assert.are.equal(1, e2.tick_count)
    assert.is_true(e3.destroyed)
    assert.are.equal(0, e3.tick_count)
    assert.are.equal(2, #world.entities)
  end)

  it("adds rat buckets when loading an upstream version 265 save", function()
    local entity_map = {
      width = 1,
      height = 1,
      entity_map = {{{humanoids = {}, objects = {}}}},
    }
    setmetatable(entity_map, {__index = EntityMap})

    entity_map:afterLoad(265, 266)

    assert.same({}, entity_map.entity_map[1][1].rats)

    local rat = {}
    entity_map.entity_map[1][1].rats = {rat}
    entity_map:afterLoad(265, 266)
    assert.is.equal(rat, entity_map.entity_map[1][1].rats[1])
  end)

  it("detects a moving rat across the full proximity radius", function()
    local rat = {
      tile_x = 64,
      tile_y = 64,
      th = {getPosition = function() return -32, -16 end},
    }
    local map = {width = 128, height = 128}
    setmetatable(map, {__index = Map})
    local world = makeWorld({rat})
    world.map = map
    world.entity_map = {
      getRatsAtCoordinate = function(_, x, y)
        return x == rat.tile_x and y == rat.tile_y and {rat} or {}
      end,
    }

    -- The rat is drawn one tile west of its entity-map tile while moving.
    -- This cursor is exactly 24 pixels farther west, crossing another tile.
    assert.is_true(world:isNearRat(-56, 2000))
    assert.is_false(world:isNearRat(-57, 2000))
  end)
end)

describe("world.lua co-op staff transfers: ", function()
  -- A member of staff sent to another player's hospital in the middle of
  -- something that must happen first (an operation).
  local function makeTransfer()
    local operation = {name = "use_object", must_happen = true}
    local walk = {name = "walk", must_happen = true}
    local idle = {name = "idle"}
    local new_hospital = {staff = {}, notifyOfStaffChange = function() end, name = "IRIS"}
    local staff = {
      action_queue = {operation, walk, idle},
      mp_in_transit = {to = 2, x = 5, y = 6},
      mp_transfer_walk = walk,
      tile_x = 1, tile_y = 1, mp_id = 28,
      profile = {getFullName = function() return "P. ANDERS" end},
    }
    function staff:getCurrentAction() return self.action_queue[1] end
    function staff:setTile(x, y) self.tile_x, self.tile_y = x, y end
    function staff:setHospital(h) self.hospital = h end
    function staff:onPlaceInCorridor() end
    local world = setmetatable({mp_transfers = {staff}, hospitals = {{}, new_hospital}, app = {}},
        {__index = World})
    return world, staff, new_hospital, walk, idle
  end

  local saved
  before_each(function()
    saved = {MultiplayerSession = _G.MultiplayerSession, _S = _G._S}
    _G.MultiplayerSession = {tellPlayer = function() end}
    _G._S = {multiplayer_window = {staff_arrived_note = "%s"}}
  end)
  after_each(function()
    _G.MultiplayerSession, _G._S = saved.MultiplayerSession, saved._S
  end)

  it("someone still operating has not arrived yet", function()
    local world, staff, new_hospital = makeTransfer()
    world:_tickCoopTransfers()
    assert.is_not_nil(staff.mp_in_transit)
    assert.are.same({}, new_hospital.staff)
    assert.are.same({staff}, world.mp_transfers)
  end)

  it("they arrive once their walk over is done", function()
    local world, staff, new_hospital, _, idle = makeTransfer()
    table.remove(staff.action_queue, 1) -- the operation is over: walking now
    world:_tickCoopTransfers()
    assert.is_not_nil(staff.mp_in_transit)
    staff.action_queue = {idle} -- the walk is over
    world:_tickCoopTransfers()
    assert.is_nil(staff.mp_in_transit)
    assert.are.same({staff}, new_hospital.staff)
    assert.are.equal(new_hospital, staff.hospital)
    assert.are.equal(5, staff.tile_x)
  end)
end)

describe("world.lua co-op patients: ", function()
  local function makeWorld(open, attempts)
    local hospitals = {}
    for i, is_open in ipairs(open) do
      hospitals[i] = {opened = is_open, spawn_attempts = attempts or 0}
    end
    return setmetatable({hospitals = hospitals, mp_coop = {players = #open}}, {__index = World})
  end

  it("a patient whose turn is at a closed hospital goes to the next open one", function()
    local world = makeWorld({false, false, true})
    -- Turn of hospital 1 (closed), then 2 (closed), then 3 (open).
    assert.are.equal(world.hospitals[3], world:_coopPatientHospital())
    world.hospitals[1].spawn_attempts = 1
    assert.are.equal(world.hospitals[3], world:_coopPatientHospital())
    world.hospitals[1].spawn_attempts = 2
    assert.are.equal(world.hospitals[3], world:_coopPatientHospital())
  end)

  it("the next open hospital after the closed one, in hospital order", function()
    local world = makeWorld({true, false, true})
    world.hospitals[1].spawn_attempts = 1 -- turn of hospital 2 (closed)
    assert.are.equal(world.hospitals[3], world:_coopPatientHospital())
    world = makeWorld({true, true, false})
    world.hospitals[1].spawn_attempts = 2 -- turn of hospital 3 (closed): round to 1
    assert.are.equal(world.hospitals[1], world:_coopPatientHospital())
  end)

  it("open hospitals keep their own turns, and nobody comes while all are closed", function()
    local world = makeWorld({true, true, true})
    world.hospitals[2].spawn_attempts = 1
    assert.are.equal(world.hospitals[2], world:_coopPatientHospital())
    assert.is_nil(makeWorld({false, false}):_coopPatientHospital())
  end)
end)

