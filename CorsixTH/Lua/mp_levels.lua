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

--! The levels of a multiplayer game with a hospital each (co-op and
--! competitive). The map is one of Theme Hospital's original multiplayer maps
--! (LEVEL.L<players><n>), whose own level files (NET<players><n>.SAM) let
--! every disease come and every room be researched from the start, with a
--! reputation goal only. Instead, what a level has is taken from a single
--! player campaign level: the diseases that come and from when, the rooms and
--! machines there at the start, what can be researched, the emergencies and
--! how fast patients come. Level 1 has the fewest rooms. The goals and the
--! starting money are our own (below). Level 6 ("Emergency!") is a scenario
--! on level 3's rooms with events of its own (the end of this file).
local levels = {}

--! Criteria numbers of the level files (see endconditions.lua).
local REPUTATION, BALANCE, PERCENTAGE_CURED, NUM_CURED, PERCENTAGE_KILLED, VALUE = 1, 2, 3, 4, 5, 6

--! campaign: the single player level the diseases, rooms and research come
--! from; cash: starting money; goals: all of them to win (value: hospital
--! value above what the biggest starting plot is worth); map: which of the
--! original maps (LEVEL.L<players><map>; default level - 1); scenario: a
--! level with events of its own (levels.SCENARIOS); intro: its briefing
--! (a string of _S.multiplayer_window).
levels.LEVELS = {
  {campaign = 1, cash = 40000,
    goals = {reputation = 550, balance = 20000, value = 40000, cured = 40, cure_rate = 40}},
  {campaign = 3, cash = 50000,
    goals = {reputation = 600, balance = 50000, value = 70000, cured = 100, cure_rate = 45}},
  {campaign = 5, cash = 50000,
    goals = {reputation = 650, balance = 100000, value = 110000, cured = 200, cure_rate = 50}},
  {campaign = 8, cash = 60000,
    goals = {reputation = 700, balance = 200000, value = 150000, cured = 350, cure_rate = 55}},
  {campaign = 11, cash = 70000,
    goals = {reputation = 750, balance = 350000, value = 200000, cured = 500, cure_rate = 60}},
  -- On the map called EMERGENCY!, with level 3's rooms and research.
  {campaign = 5, map = 2, cash = 60000, scenario = "emergency", intro = "level_intro_6",
    goals = {reputation = 550, balance = 60000, value = 80000, cured = 150, cure_rate = 40}},
}
levels.COUNT = #levels.LEVELS

--! What a level takes from its campaign level.
local FROM_CAMPAIGN = {"visuals", "non_visuals", "visuals_available", "non_visuals_available",
    "expertise", "objects", "rooms", "emergency_control", "popn"}

--! The level (1 .. COUNT) a room's level number stands for.
function levels.clamp(level)
  level = math.floor(tonumber(level) or 1)
  return math.max(1, math.min(levels.COUNT, level))
end

--! The level id Map:load knows for a room with a hospital each: the original
--! multiplayer map "net<players><map>", plus "_<level>" when the level is not
--! the map's own (level 6 plays on level 3's map).
function levels.levelId(players, level)
  level = levels.clamp(level)
  players = math.max(2, math.min(4, players))
  local map = levels.LEVELS[level].map or level - 1
  local id = string.format("net%d%d", players, map)
  if map ~= level - 1 then id = id .. "_" .. level end
  return id
end

--! The other way: players, map digits ("42") and level of a level id, or nil.
function levels.parseLevelId(id)
  if type(id) ~= "string" then return nil end
  local players, map, level = id:match("^net(%d)(%d)_?(%d*)$")
  if not players then return nil end
  return tonumber(players), players .. map, tonumber(level) or tonumber(map) + 1
end

--! Put level `level`'s content into `config` (the multiplayer map's level
--! config): the sections above from `campaign` (the campaign level's
--! config), the starting money, and the goals. The value goal is set later
--! by levels.setValueGoal, once the map's plots are known.
--!param players (number) how many hospitals (2 .. 4)
function levels.apply(config, campaign, level, players)
  local def = levels.LEVELS[levels.clamp(level)]
  for _, key in ipairs(FROM_CAMPAIGN) do
    config[key] = campaign[key]
  end
  -- Every level but the first has the training room from the start (with
  -- its projector, lecture chairs, skeleton and bookcase): the staff to hire
  -- are few, so training must begin early. (object numbers: TheApp.objects)
  if levels.clamp(level) > 1 then
    for _, thob in ipairs({36, 37, 56, 60}) do
      local spec = config.objects and config.objects[thob]
      if spec then spec.StartAvail, spec.AvailableForLevel = 1, 1 end
    end
  end
  -- (a multiplayer map's level number is no campaign town: `town` is used)
  config.town = {StartCash = def.cash, StartRep = 500, InterestRate = 100, OverdraftDiff = 200}
  local g = def.goals
  local function goal(criterion, value, group, bound, max_min)
    return {Criteria = criterion, MaxMin = max_min or 1, Value = value, Group = group, Bound = bound or 0}
  end
  config.win_criteria = {
    [0] = goal(REPUTATION, g.reputation, 1),
    goal(BALANCE, g.balance, 1),
    goal(VALUE, g.value, 1),
    goal(NUM_CURED, g.cured, 1),
    goal(PERCENTAGE_CURED, g.cure_rate, 1),
  }
  -- Out of the race (or the team in trouble) at a year end: deep in debt, or
  -- killing half the patients.
  config.lose_criteria = {
    [0] = goal(BALANCE, -20000, 1, -15000, 0),
    goal(PERCENTAGE_KILLED, 50, 2, 40),
  }
  config.mp_level = levels.clamp(level)
  if def.scenario then levels.SCENARIOS[def.scenario].apply(config, players or 2) end
end

--! The value goal: what the biggest of the players' starting plots is worth
--! (with the 20000 every hospital starts with) plus the level's amount.
--!param map (Map) loaded, with the plots counted
function levels.setValueGoal(map)
  local config = map.level_config
  local def = levels.LEVELS[config.mp_level]
  local start = 0
  for plot = 1, map.th:getPlayerCount() do
    start = math.max(start, map:getParcelPrice(plot) + 20000)
  end
  -- (rounded up to $5,000)
  local goal = math.ceil((start + def.goals.value) / 5000) * 5000
  for _, crit in pairs(config.win_criteria) do
    if crit.Criteria == VALUE then crit.Value = goal end
  end
end


-- Level 6, "Emergency!" -------------------------------------------------------
--
-- Year one is the emergency season: twice a month the helicopter brings
-- emergency patients to the hospitals in turn, easy ones (pharmacy,
-- inflation) first, then psychiatry, then the ones that need research or the
-- operating theatre. Fewer patients walk in meanwhile. From the second year
-- epidemics come in waves, every two or three months to every hospital.
-- Rats are about all the time. Plenty of consultants to hire at first, only
-- juniors from month 9. Refusing an emergency costs reputation; losing
-- patients to emergencies is forgiven more than on the other levels.
--
-- The events run in World:onEndDay (levels.onEndDay), so in the lockstep
-- simulation of every peer, with the game's own random numbers.

--! The emergencies' diseases (expertise ids, diseases/*.lua), from month
--! `from` on: how many victims, the share that must be saved, and the bonus
--! per patient saved.
local EMERGENCY_PHASES = {
  -- uncommon cold, transparency, bloaty head, sleeping illness, the squits, gut rot
  {from = 2, illnesses = {16, 15, 2, 13, 29, 33}, min = 2, max = 4, win = 50, bonus = 400},
  -- king complex, tv personalities, heaped piles, corrugated ankles
  {from = 5, illnesses = {4, 22, 32, 24}, min = 3, max = 5, win = 60, bonus = 700},
  -- slack tongue, broken bones, spare ribs, kidney beans
  {from = 8, illnesses = {7, 9, 18, 19}, min = 3, max = 6, win = 65, bonus = 1000},
}
local EMERGENCY_LAST_MONTH = 12
local EPIDEMIC_FIRST_MONTH = 14
local EPIDEMIC_DAYS = {60, 90}       -- between waves
local EPIDEMIC_PATIENTS = {2, 3}     -- per hospital and wave
local RAT_SWARM_DAYS = {45, 75}      -- between swarms, each to the next hospital
local RAT_SWARM_SIZE = {3, 5}

--! A doctor pool with many consultants first, then only juniors, for
--! `players` hospitals sharing it; nurses, handymen and receptionists vary.
--! (An entry with Month = m is used for the list from month m + 1 on.)
local function staffLevels(players)
  local result = {}
  local months = {0, 3, 5, 8, 11, 14, 17, 20, 23}
  for i, month in ipairs(months) do
    local juniors_only = month >= 8
    result[i - 1] = {
      Month = month,
      Doctors = 2 * players + 2,
      Nurses = players + math.random(1, players + 1),
      Handymen = math.random(1, players + 1),
      Receptionists = math.random(1, players),
      ShrkRate = 3, SurgRate = 3, RschRate = 4,
      -- One in two doctors a consultant at first (none junior); then all junior.
      ConsRate = juniors_only and 0 or 2,
      JrRate = juniors_only and 1 or 0,
    }
  end
  return result
end

levels.SCENARIOS = {
  emergency = {
    apply = function(config, players)
      -- The level's own events (levels.onEndDay) instead of the campaign's emergencies.
      config.emergency_control = {[0] = {StartMonth = 0, EndMonth = 0, Min = 0, Max = 0, Illness = 0,
          PercWin = 0, Bonus = 0}}
      config.mp_events = "emergency"
      -- Few patients walk in during the emergency season (per hospital; the
      -- first month counts twice, see World:onEndMonth), more from month 13.
      config.popn = {
        [0] = {Month = 0, Change = 2},
        {Month = 1, Change = 1},
        {Month = 3, Change = 0},
        {Month = 12, Change = 2},
        {Month = 17, Change = 0},
        {Month = 30, Change = 1},
        {Month = 32, Change = 0},
      }
      config.staff_levels = staffLevels(players)
      -- More rats (Hospital:onEndDay; the defaults are 0.05, 0.5 and 200).
      config.mp_rats = {chance = 0.15, litter = 1.0, tiles_per_rat = 100}
      -- Refusing (or not answering) an emergency fax.
      config.mp_refused_emergency = -15
      -- Deaths from emergencies are expected: a hospital fails a year end
      -- only when it kills more than 70 % (warning from 60 %).
      for _, crit in pairs(config.lose_criteria) do
        if crit.Criteria == PERCENTAGE_KILLED then crit.Value, crit.Bound = 70, 60 end
      end
    end,
  },
}

local function between(range)
  return math.random(range[1], range[2])
end

--! An emergency of month `month` for `hospital`: of the newest phase with a
--! disease it has discovered (it must know what it is treating), or nil.
local function pickEmergency(world, hospital, month)
  for p = #EMERGENCY_PHASES, 1, -1 do
    local phase = EMERGENCY_PHASES[p]
    if phase.from <= month then
      local candidates = {}
      for _, illness in ipairs(phase.illnesses) do
        for _, disease in ipairs(world.available_diseases) do
          local casebook = hospital.disease_casebook[disease.id]
          if disease.expertise_id == illness and casebook and casebook.discovered then
            candidates[#candidates + 1] = disease
          end
        end
      end
      if #candidates > 0 then
        local disease = candidates[math.random(1, #candidates)]
        local most = math.min(phase.max, TheApp.diseases[disease.id].emergency_number or phase.max)
        return {
          disease = disease,
          victims = math.random(math.min(phase.min, most), most),
          bonus = phase.bonus,
          percentage = phase.win / 100,
          killed_emergency_patients = 0,
          cured_emergency_patients = 0,
        }
      end
    end
  end
  return nil
end

local function busy(hospital)
  return hospital.mp_place or hospital.mp_opening or hospital.emergency or hospital.epidemic
end

--! The next hospital in turn that can take an emergency gets one.
--!return (boolean) whether one did
local function sendEmergency(world, month)
  for _ = 1, world.mp_coop.players do
    local hospital = world:_coopTurn("level_emergency")
    if not busy(hospital) then
      local emergency = pickEmergency(world, hospital, month)
      if emergency and not hospital:createEmergency(emergency) then return true end
    end
  end
  return false
end

--! A contagious disease for an epidemic in `hospital`: one it has discovered
--! if there is one (so it can be diagnosed), else any.
local function epidemicDisease(world, hospital)
  local known, any = {}, {}
  for _, disease in ipairs(world.available_diseases) do
    if disease.contagious then
      any[#any + 1] = disease
      local casebook = hospital.disease_casebook[disease.id]
      if casebook and casebook.discovered then known[#known + 1] = disease end
    end
  end
  local list = #known > 0 and known or any
  return #list > 0 and list[math.random(1, #list)] or nil
end

--! A wave: every hospital that is open and not busy gets a few contagious
--! patients walking in, the start of an epidemic.
local function epidemicWave(world)
  local started = 0
  for index = 1, world.mp_coop.players do
    local hospital = world.hospitals[index]
    if not busy(hospital) and not hospital.epidemics_disabled and hospital.opened and
        #hospital.future_epidemics_pool == 0 and hospital:hasReceptionDesk(true) and
        #world.spawn_points > 0 then
      local disease = epidemicDisease(world, hospital)
      if disease then
        for _ = 1, between(EPIDEMIC_PATIENTS) do
          local patient = world:newEntity("Patient", 2, 1)
          patient:setDisease(disease)
          patient:setNextAction(SpawnAction("spawn", world.spawn_points[math.random(1, #world.spawn_points)]))
          patient:setHospital(hospital)
          hospital:addToEpidemic(patient)
        end
        started = started + 1
      end
    end
  end
  return started
end

--! A swarm of rats in the next hospital in turn (with holes for them).
local function ratSwarm(world)
  local hospital = world:_coopTurn("level_rats")
  if not hospital.opened then return 0 end
  hospital:mpAddRatholes(3)
  local spawned = 0
  for _ = 1, between(RAT_SWARM_SIZE) do
    if hospital:spawnRat() then spawned = spawned + 1 end
  end
  if spawned > 0 then
    corsixth.require("mp_session")
    MultiplayerSession.tellPlayer(world, hospital, _S.multiplayer_window.level_rats_notice)
  end
  return spawned
end

--! The level's events, at the end of every day (World:onEndDay).
function levels.onEndDay(world)
  if world.map.level_config.mp_events ~= "emergency" or not world.mp_coop then return end
  local state = world.mp_level_events
  if not state then
    state = {days_to_wave = nil, days_to_rats = between(RAT_SWARM_DAYS)}
    world.mp_level_events = state
  end
  local date = world.game_date
  local month = date:monthOfGame()
  -- Twice a month, on two days chosen at the start of the month.
  if state.month ~= month then
    state.month = month
    state.emergency_days = {math.random(3, 12), math.random(17, 26)}
  end
  if month >= EMERGENCY_PHASES[1].from and month <= EMERGENCY_LAST_MONTH then
    local day = date:dayOfMonth()
    if day == state.emergency_days[1] or day == state.emergency_days[2] then
      sendEmergency(world, month)
    end
  end
  if month >= EPIDEMIC_FIRST_MONTH then
    state.days_to_wave = (state.days_to_wave or 1) - 1
    if state.days_to_wave <= 0 then
      epidemicWave(world)
      state.days_to_wave = between(EPIDEMIC_DAYS)
    end
  end
  state.days_to_rats = state.days_to_rats - 1
  if state.days_to_rats <= 0 then
    ratSwarm(world)
    state.days_to_rats = between(RAT_SWARM_DAYS)
  end
end

return levels
