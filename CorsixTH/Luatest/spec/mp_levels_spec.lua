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

local levels = require("mp_levels")

-- Expertise ids of the diseases level 6 (level 3's campaign level) has, with
-- whether they are contagious and their most emergency victims.
local DISEASES = {
  {id = "uncommon_cold", expertise_id = 16, contagious = true, emergency_number = 18},
  {id = "transparency", expertise_id = 15, emergency_number = 12},
  {id = "bloaty_head", expertise_id = 2, emergency_number = 18},
  {id = "sleeping_illness", expertise_id = 13, contagious = true, emergency_number = 18},
  {id = "king_complex", expertise_id = 4, emergency_number = 18},
  {id = "tv_personalities", expertise_id = 22, contagious = true, emergency_number = 14},
  {id = "slack_tongue", expertise_id = 7, emergency_number = 18},
  {id = "spare_ribs", expertise_id = 18, contagious = true, emergency_number = 4},
}
local PHASES = { -- what the level's phases may bring, by expertise id
  [16] = 1, [15] = 1, [2] = 1, [13] = 1, [29] = 1, [33] = 1,
  [4] = 2, [22] = 2, [32] = 2, [24] = 2,
  [7] = 3, [9] = 3, [18] = 3, [19] = 3,
}

-- A world with `players` hospitals, enough of one for levels.onEndDay.
local function fake_world(players, discovered)
  local world = {
    available_diseases = {}, spawn_points = {{x = 1, y = 1}}, hospitals = {},
    mp_coop = {players = players}, game_date = Date(1, 1, 1), entities = {},
    map = {level_config = {mp_events = "emergency"}},
    emergencies = {}, epidemics = {}, rats = {},
  }
  _G.TheApp = {diseases = {}}
  for _, d in ipairs(DISEASES) do
    world.available_diseases[#world.available_diseases + 1] = d
    TheApp.diseases[d.id] = d
  end
  function world:_coopTurn(event) -- as World:_coopTurn
    self.mp_turns = self.mp_turns or {}
    local turn = (self.mp_turns[event] or 0) % self.mp_coop.players + 1
    self.mp_turns[event] = turn
    return self.hospitals[turn]
  end
  function world:newEntity()
    local patient = {}
    function patient:setDisease(d) self.disease = d end
    function patient:setNextAction() end
    function patient:setHospital(h) self.hospital = h end
    return patient
  end
  for index = 1, players do
    local hospital = {index = index, opened = true, future_epidemics_pool = {}, disease_casebook = {},
        ratholes = {}}
    for _, d in ipairs(DISEASES) do
      hospital.disease_casebook[d.id] = {discovered = not discovered or discovered[index][d.id] or false}
    end
    function hospital:hasReceptionDesk() return true end
    function hospital:createEmergency(e)
      world.emergencies[#world.emergencies + 1] = {hospital = self.index, month = world.game_date:monthOfGame(),
          day = world.game_date:dayOfMonth(), emergency = e}
    end
    function hospital:addToEpidemic(patient)
      world.epidemics[#world.epidemics + 1] = {hospital = self.index, patient = patient,
          day = world.day, month = world.game_date:monthOfGame()}
    end
    function hospital:mpAddRatholes() end
    function hospital:spawnRat()
      world.rats[#world.rats + 1] = {hospital = self.index, day = world.day}
      return {}
    end
    world.hospitals[index] = hospital
  end
  return world
end

-- Run levels.onEndDay for `days` days.
local function play(world, days)
  for _ = 1, days do
    world.day = (world.day or 0) + 1
    levels.onEndDay(world)
    world.game_date = world.game_date:plusDays(1)
  end
end

describe("Multiplayer levels", function()
  local saved_spawn, saved_session, saved_strings
  before_each(function()
    math.randomseed(42)
    saved_spawn, saved_session, saved_strings = _G.SpawnAction, _G.MultiplayerSession, _G._S
    _G.SpawnAction = function() return {} end
    _G.MultiplayerSession = {tellPlayer = function() end}
    _G._S = {multiplayer_window = {level_rats_notice = "rats"}}
    corsixth.require = function() end
  end)
  after_each(function()
    _G.SpawnAction, _G.MultiplayerSession, _G._S = saved_spawn, saved_session, saved_strings
    corsixth.require = require
  end)

  it("names the original maps, and level 6 on the map of level 3", function()
    assert.equal("net20", levels.levelId(2, 1))
    assert.equal("net44", levels.levelId(4, 5))
    assert.equal("net32", levels.levelId(3, 3))
    assert.equal("net42_6", levels.levelId(4, 6))
    assert.equal("net22_6", levels.levelId(1, 9)) -- (2 to 4 players, levels 1 to 6)
    local players, digits, level = levels.parseLevelId("net42_6")
    assert.equal(4, players)
    assert.equal("42", digits)
    assert.equal(6, level)
    players, digits, level = levels.parseLevelId("net31")
    assert.equal(3, players)
    assert.equal("31", digits)
    assert.equal(2, level)
    assert.is_nil(levels.parseLevelId("net4"))
    assert.is_nil(levels.parseLevelId(5))
    assert.is_nil(levels.parseLevelId("/levels/net42.level"))
  end)

  it("gives level 6 its goals, staff, patients and rules", function()
    local campaign = {emergency_control = {[0] = {StartMonth = 6, EndMonth = 8}}, popn = {[0] = {Month = 0, Change = 4}},
        rooms = {"campaign rooms"}, objects = {}}
    local config = {}
    levels.apply(config, campaign, 6, 3)
    assert.equal(6, config.mp_level)
    assert.equal("emergency", config.mp_events)
    assert.same({"campaign rooms"}, config.rooms)
    -- The campaign's own emergencies are off (an entry that ends before it starts).
    assert.equal(0, config.emergency_control[0].EndMonth)
    assert.is_nil(config.emergency_control[1])
    assert.equal(-15, config.mp_refused_emergency)
    assert.equal(550, config.win_criteria[0].Value)
    for _, crit in pairs(config.lose_criteria) do
      if crit.Criteria == 5 then assert.equal(70, crit.Value) end
    end
    -- Many consultants and no juniors first, only juniors from month 9.
    local staff = config.staff_levels
    assert.equal(0, staff[0].Month)
    assert.equal(2, staff[0].ConsRate)
    assert.equal(0, staff[0].JrRate)
    assert.equal(8, staff[0].Doctors) -- 2 per hospital and 2
    for i = 0, #staff do
      if staff[i].Month >= 8 then
        assert.equal(1, staff[i].JrRate)
        assert.equal(0, staff[i].ConsRate)
      end
      assert.truthy(staff[i].Nurses >= 4 and staff[i].Receptionists >= 1)
    end
    -- Patients: few in the first year, more from month 13.
    assert.equal(2, config.popn[0].Change)
    assert.truthy(config.mp_rats.chance > 0.05)
    -- The other levels keep the campaign's emergencies and no events.
    local plain = {}
    levels.apply(plain, campaign, 3, 3)
    assert.equal(campaign.emergency_control, plain.emergency_control)
    assert.is_nil(plain.mp_events)
  end)

  it("sends emergencies twice a month in the first year, by turns, easy ones first", function()
    local world = fake_world(2)
    play(world, 30) -- month 1: time to build
    assert.equal(0, #world.emergencies)
    play(world, 335)
    assert.equal(22, #world.emergencies) -- months 2 to 12
    local per_month = {}
    for i, e in ipairs(world.emergencies) do
      per_month[e.month] = (per_month[e.month] or 0) + 1
      assert.equal(2 - i % 2, e.hospital) -- hospitals 1, 2, 1, 2, ...
      local phase = PHASES[e.emergency.disease.expertise_id]
      assert.truthy(phase, "disease of no phase")
      if e.month < 5 then assert.equal(1, phase) end
      if e.month >= 8 then assert.equal(3, phase) end
      assert.truthy(e.emergency.victims >= 2 and e.emergency.victims <= e.emergency.disease.emergency_number)
      assert.truthy(e.emergency.percentage >= 0.5 and e.emergency.percentage <= 0.65)
    end
    for month = 2, 12 do assert.equal(2, per_month[month]) end
    play(world, 365)
    assert.equal(22, #world.emergencies) -- none in the second year
  end)

  it("gives an emergency only for a known disease, and to a hospital that is free", function()
    -- Hospital 2 knows only the uncommon cold.
    local world = fake_world(2, {{uncommon_cold = true, king_complex = true, slack_tongue = true},
        {uncommon_cold = true}})
    play(world, 365)
    for _, e in ipairs(world.emergencies) do
      if e.hospital == 2 then assert.equal("uncommon_cold", e.emergency.disease.id) end
      -- Hospital 1 gets the newest phase it knows.
      if e.hospital == 1 and e.month >= 8 then assert.equal("slack_tongue", e.emergency.disease.id) end
    end
    -- Hospital 1 busy with an emergency: both of a month go to hospital 2.
    world = fake_world(2)
    world.hospitals[1].emergency = {}
    play(world, 90)
    assert.truthy(#world.emergencies >= 4)
    for _, e in ipairs(world.emergencies) do assert.equal(2, e.hospital) end
    -- Nobody free: the emergency is skipped, not queued.
    world = fake_world(2)
    world.hospitals[1].emergency, world.hospitals[2].epidemic = {}, {}
    play(world, 90)
    assert.equal(0, #world.emergencies)
  end)

  it("sends epidemics to every hospital in waves from month 14", function()
    local world = fake_world(3)
    play(world, 365 * 3)
    assert.truthy(#world.epidemics > 0)
    local waves, last = {}, nil
    for _, e in ipairs(world.epidemics) do
      assert.truthy(e.month >= 14)
      assert.truthy(e.patient.disease.contagious)
      if e.day ~= last then waves[#waves + 1] = {day = e.day, hospitals = {}} end
      last = e.day
      local wave = waves[#waves]
      wave.hospitals[e.hospital] = (wave.hospitals[e.hospital] or 0) + 1
    end
    for i, wave in ipairs(waves) do
      for h = 1, 3 do
        local n = wave.hospitals[h]
        assert.truthy(n and n >= 2 and n <= 3, "hospital " .. h .. " in wave " .. i)
      end
      if i > 1 then
        local gap = wave.day - waves[i - 1].day
        assert.truthy(gap >= 60 and gap <= 90, "gap " .. gap)
      end
    end
    assert.truthy(#waves >= 7) -- about two years of waves
    -- A hospital with an epidemic on (or coming) gets no new one.
    world = fake_world(2)
    world.hospitals[2].future_epidemics_pool = {{}}
    play(world, 365 * 2)
    for _, e in ipairs(world.epidemics) do assert.equal(1, e.hospital) end
  end)

  it("lets rats swarm into the hospitals by turns", function()
    local world = fake_world(2)
    play(world, 365)
    local swarms, last = {}, nil
    for _, r in ipairs(world.rats) do
      if r.day ~= last then swarms[#swarms + 1] = r end
      last = r.day
    end
    assert.truthy(#swarms >= 4 and #swarms <= 8)
    for i, swarm in ipairs(swarms) do assert.equal(2 - i % 2, swarm.hospital) end
  end)

  it("does nothing on the other levels", function()
    local world = fake_world(2)
    world.map.level_config.mp_events = nil
    play(world, 365 * 2)
    assert.equal(0, #world.emergencies + #world.epidemics + #world.rats)
  end)
end)
