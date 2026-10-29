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
  {id = "fractured_bones", expertise_id = 9, emergency_number = 16},
}
local FROM = { -- the month from which an emergency may bring a disease, by expertise id
  [16] = 2, [15] = 2, [13] = 2, [29] = 2, [33] = 2, [2] = 2, [4] = 2, [22] = 2,
  [18] = 4, [19] = 4,
  [7] = 6, [9] = 6,
}

-- A world with `players` hospitals, enough of one for levels.onEndDay.
local function fake_world(players, discovered)
  local world = {
    available_diseases = {}, spawn_points = {{x = 1, y = 1}}, hospitals = {},
    mp_coop = {players = players}, game_date = Date(1, 1, 1), entities = {},
    map = {level_config = {mp_events = "emergency"}},
    emergencies = {}, epidemics = {}, rats = {}, told = {},
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
    function hospital:getHeliportSpawnPosition() return 1, 1 end
    hospital.research = {discoverDisease = function(_, d) hospital.disease_casebook[d.id].discovered = true end}
    function hospital:createEmergency(e)
      assert(self.disease_casebook[e.disease.id].discovered, "emergency of an undiscovered disease")
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
    _G.MultiplayerSession = {tellPlayer = function() end, tellOthers = function(world, _, text)
      world.told[#world.told + 1] = {text = text, month = world.game_date:monthOfGame()}
    end}
    _G._S = {multiplayer_window = {level_rats_notice = "rats", level_slack_tongue_warning = "slack"}}
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
    assert.equal(14, staff[0].Doctors) -- 4 per hospital and 2
    for i = 0, #staff do
      if staff[i].Month >= 8 then
        assert.equal(1, staff[i].JrRate)
        assert.equal(0, staff[i].ConsRate)
      end
      assert.truthy(staff[i].Nurses >= 9)
      -- Every hospital can hire a receptionist and a handyman each month.
      assert.truthy(staff[i].Receptionists >= 3 and staff[i].Handymen >= 3)
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

  -- The level's random emergencies, and the May slack tongue ones apart.
  local function split(world)
    local random, slack = {}, {}
    for _, e in ipairs(world.emergencies) do
      if e.month == 5 and e.day == 5 and e.emergency.disease.expertise_id == 7 then
        slack[#slack + 1] = e
      else
        random[#random + 1] = e
      end
    end
    return random, slack
  end

  it("sends emergencies four times a month in the first year, by turns", function()
    local world = fake_world(2)
    play(world, 30) -- month 1: time to build
    assert.equal(0, #world.emergencies)
    play(world, 335)
    local random = split(world)
    local per_month = {}
    for i, e in ipairs(random) do
      per_month[e.month] = (per_month[e.month] or 0) + 1
      assert.equal(2 - i % 2, e.hospital) -- hospitals 1, 2, 1, 2, ...
      local from = FROM[e.emergency.disease.expertise_id]
      assert.truthy(from and from <= e.month, "disease too early: " .. e.emergency.disease.id)
      assert.truthy(e.emergency.victims >= 1 and e.emergency.victims <= e.emergency.disease.emergency_number)
      assert.truthy(not (e.month == 5 and e.day <= 5), "none in May before the slack tongues")
    end
    for month = 2, 12 do
      if month == 5 then
        assert.truthy(per_month[5] >= 3 and per_month[5] <= 4)
      else
        assert.equal(4, per_month[month], "month " .. month)
      end
    end
    play(world, 365)
    assert.equal(#random, #split(world)) -- none in the second year
  end)

  it("brings undiscovered diseases too, and makes them known", function()
    -- Nothing discovered at all (createEmergency asserts the disease is known by then).
    local world = fake_world(2, {{}, {}})
    play(world, 120)
    local kinds = {}
    for _, e in ipairs(world.emergencies) do kinds[e.emergency.disease.id] = true end
    -- February to April: more than pharmacy cases (inflation, psychiatry or theatre).
    assert.truthy(kinds.bloaty_head or kinds.king_complex or kinds.tv_personalities or kinds.spare_ribs)
  end)

  it("gives an emergency to a hospital that is free", function()
    -- Hospital 1 busy with an emergency: all of them go to hospital 2.
    local world = fake_world(2)
    world.hospitals[1].emergency = {}
    play(world, 90)
    assert.truthy(#world.emergencies >= 8)
    for _, e in ipairs(world.emergencies) do assert.equal(2, e.hospital) end
    -- Nobody free: the emergencies wait for a free hospital, until the month ends.
    world = fake_world(2)
    world.hospitals[1].emergency, world.hospitals[2].epidemic = {}, {}
    play(world, 47) -- to 16 February: the first two of February waiting
    assert.equal(0, #world.emergencies)
    world.hospitals[2].epidemic = nil
    play(world, 1) -- (fake emergencies do not keep a hospital busy)
    assert.truthy(#world.emergencies >= 2) -- (and the 17th may be a day of its own)
    for _, e in ipairs(world.emergencies) do assert.equal(2, e.hospital) end
    -- Not taken by the end of the month: dropped, not carried into the next.
    world = fake_world(2)
    world.hospitals[1].emergency, world.hospitals[2].emergency = {}, {}
    play(world, 60) -- to 1 March
    world.hospitals[1].emergency = nil
    play(world, 1)
    assert.equal(0, #world.emergencies)
  end)

  it("sends slack tongues to every hospital in May, announced in March", function()
    local world = fake_world(3, {{}, {}, {}})
    play(world, 151) -- to the end of May
    local _, slack = split(world)
    assert.equal(3, #slack)
    local got = {}
    for _, e in ipairs(slack) do
      got[e.hospital] = true
      assert.truthy(e.emergency.victims >= 4 and e.emergency.victims <= 6)
    end
    assert.truthy(got[1] and got[2] and got[3])
    assert.equal(1, #world.told)
    assert.equal(3, world.told[1].month)
    assert.equal("slack", world.told[1].text)
    -- A hospital busy in May gets it when it is free (until July).
    world = fake_world(2)
    world.hospitals[2].emergency = {}
    play(world, 130) -- 10 May
    for _, e in ipairs(world.emergencies) do assert.equal(1, e.hospital) end
    world.hospitals[2].emergency = nil
    play(world, 1)
    local last = world.emergencies[#world.emergencies]
    assert.equal(2, last.hospital)
    assert.equal(7, last.emergency.disease.expertise_id)
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
