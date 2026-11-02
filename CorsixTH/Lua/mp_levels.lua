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
--! (a string of _S.multiplayer_window); name: the level's name; map_files:
--! a map of our own (in CorsixTH's Levels folder) by number of players,
--! instead of the original one.
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
  -- "Cutthroat", made for a race: level 8's rooms and research on map 3;
  -- with four players on Matroftt's map (Levels/cutthroat4.map, 2026-10-31).
  {campaign = 8, map = 3, cash = 50000, scenario = "cutthroat", intro = "level_intro_7",
    name = "CUTTHROAT", map_files = {[4] = "cutthroat4.map"},
    goals = {reputation = 650, balance = 150000, value = 150000, cured = 300, cure_rate = 55}},
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

--! Where each player's hospital lies on the map of a level for `players`:
--! {[player] = {x, y}}, the map's starting camera tiles (the same map file
--! Map:load uses), or nil if the file cannot be read.
function levels.hospitalTiles(app, players, level)
  local _, digits, mp_level = levels.parseLevelId(levels.levelId(players, level))
  local def = levels.LEVELS[levels.clamp(mp_level)]
  local own_map = def.map_files and def.map_files[players]
  local ok, data = pcall(app.readDataFile, app, "Levels",
      own_map and (app.level_dir .. own_map) or ("LEVEL.L" .. digits))
  -- (th_map.cpp: the player count is the first byte; camera tiles at 163876,
  -- two bytes each, y * 128 + x)
  if not ok or type(data) ~= "string" or #data < 163876 + 2 * players then return nil end
  local tiles = {}
  for i = 1, players do
    local lo, hi = data:byte(163876 + 2 * i - 1, 163876 + 2 * i)
    local index = hi * 256 + lo
    tiles[i] = {index % 128, math.floor(index / 128)}
  end
  return tiles
end

--! A race of teams: which hospital each player (or each colour: a hospital
--! its players share) gets, so that the members of a team are neighbours.
--! Teams choose in team order: of all the ways to give each team its
--! hospitals, the one with the smallest sum of squared distances between
--! team mates (all teams) wins; the first one in order on a tie. Team members
--! get their hospitals in the given order. Without `tiles`, the lowest team
--! gets the first hospitals.
--!param peers (table) the peer (or colour) numbers in start order
--!param teams (table) peer -> team (1 to 4)
--!param tiles (table) levels.hospitalTiles, or nil
--!return peer -> hospital index
function levels.teamSeats(peers, teams, tiles)
  local n = #peers
  local order, members = {}, {}
  for _, p in ipairs(peers) do
    local t = teams[p] or 1
    if not members[t] then
      members[t] = {}
      order[#order + 1] = t
    end
    local list = members[t]
    list[#list + 1] = p
  end
  table.sort(order)
  local function spread(set)
    local sum = 0
    for i = 1, #set do
      for j = i + 1, #set do
        local a, b = tiles[set[i]], tiles[set[j]]
        local dx, dy = a[1] - b[1], a[2] - b[2]
        sum = sum + dx * dx + dy * dy
      end
    end
    return sum
  end
  local best, best_cost
  local taken, sets = {}, {}
  -- Team k (in `order`) takes every set of its size from the hospitals the
  -- teams before it left, in increasing order.
  local function try(k, set, from, cost)
    if k > #order then
      if not best_cost or cost < best_cost then
        best, best_cost = {}, cost
        for i, s in ipairs(sets) do best[i] = {(table.unpack or unpack)(s)} end
      end
      return
    end
    if #set == #members[order[k]] then
      sets[k] = set
      try(k + 1, {}, 1, cost + (tiles and spread(set) or 0))
      sets[k] = nil
      return
    end
    for i = from, n do
      if not taken[i] then
        taken[i] = true
        set[#set + 1] = i
        try(k, set, i + 1, cost)
        set[#set] = nil
        taken[i] = nil
      end
    end
  end
  try(1, {}, 1, 0)
  local seats = {}
  for k, team in ipairs(order) do
    for j, p in ipairs(members[team]) do seats[p] = best[k][j] end
  end
  return seats
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
  -- Out of the race (or the team in trouble) at a year end: deep in debt,
  -- killing half the patients, or a reputation below 100 (warned below 200).
  config.lose_criteria = {
    [0] = goal(BALANCE, -20000, 1, -15000, 0),
    goal(PERCENTAGE_KILLED, 50, 2, 40),
    goal(REPUTATION, 100, 3, 200, 0),
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
-- Year one is the emergency season: four times a month the helicopter brings
-- emergency patients to the hospitals in turn: pharmacy, inflation and
-- psychiatry cases from month 2 (pharmacy ones least, the easy ones),
-- operating theatre cases from May, slack tongues and broken bones (research
-- first) from June. In May every hospital
-- gets a slack tongue emergency (announced in March), so the clinic must be
-- researched quickly. An emergency's disease counts as discovered for the
-- hospital it comes to. Fewer patients walk in meanwhile. From the second
-- year epidemics come in waves, every two or three months to every hospital.
-- Rats are about all the time. Plenty of consultants to hire at first, only
-- juniors from month 9. Refusing an emergency costs reputation; losing
-- patients to emergencies is forgiven more than on the other levels.
--
-- The events run in World:onEndDay (levels.onEndDay), so in the lockstep
-- simulation of every peer, with the game's own random numbers.

--! The emergencies' diseases (expertise ids, diseases/*.lua) by the room
--! that cures them: how many victims, the share that must be saved, and the
--! bonus per patient saved.
local EMERGENCY_KINDS = {
  -- uncommon cold, transparency, sleeping illness, the squits, gut rot
  pharmacy = {illnesses = {16, 15, 13, 29, 33}, min = 2, max = 4, win = 50, bonus = 500},
  inflation = {illnesses = {2}, min = 2, max = 4, win = 50, bonus = 600}, -- bloaty head
  psychiatry = {illnesses = {4, 22}, min = 2, max = 5, win = 50, bonus = 700}, -- king complex, tv personalities
  theatre = {illnesses = {18, 19}, min = 1, max = 3, win = 50, bonus = 1500}, -- spare ribs, kidney beans
  -- slack tongue clinic, fracture clinic (both researched)
  clinics = {illnesses = {7, 9}, min = 3, max = 6, win = 60, bonus = 1000},
}
--! How often each kind comes, from month `from` on (weights): the pharmacy
--! is the easy one, so it comes least; the operating theatre from May.
local EMERGENCY_PHASES = {
  {from = 2, weights = {pharmacy = 2, inflation = 4, psychiatry = 4}},
  {from = 5, weights = {pharmacy = 1, inflation = 2, psychiatry = 3, theatre = 4}},
  {from = 6, weights = {pharmacy = 1, inflation = 2, psychiatry = 2, theatre = 3, clinics = 2}},
}
local EMERGENCY_LAST_MONTH = 12
--! Days of each month that bring an emergency: one in each range.
local EMERGENCY_DAYS = {{3, 8}, {10, 15}, {17, 22}, {24, 28}}
--! The slack tongue emergency every hospital gets in May (expertise id 7),
--! announced at the start of March. A hospital busy then gets it as soon as
--! it is free (until the end of July). No other emergencies in May before it.
local SLACK_TONGUE = {illness = 7, month = 5, day = 5, until_month = 7, warn_month = 3,
    min = 4, max = 6, win = 60, bonus = 1000}
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
      Doctors = 4 * players + 2,
      Nurses = 3 * players + math.random(0, players),
      -- (The list is shared: at least one receptionist and handyman each.)
      Handymen = players + math.random(0, players),
      Receptionists = players + math.random(0, players),
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

--! An emergency for `hospital`, of disease `disease` (the victims, share to
--! save and bonus from `spec`: a phase or SLACK_TONGUE).
local function makeEmergency(disease, spec)
  local most = math.min(spec.max, TheApp.diseases[disease.id].emergency_number or spec.max)
  return {
    disease = disease,
    victims = math.random(math.min(spec.min, most), most),
    bonus = spec.bonus,
    percentage = spec.win / 100,
    killed_emergency_patients = 0,
    cured_emergency_patients = 0,
  }
end

local function diseaseOf(world, illness)
  for _, disease in ipairs(world.available_diseases) do
    if disease.expertise_id == illness then return disease end
  end
end

--! An emergency of month `month`: a kind by the weights of the phase begun
--! last, then one of its diseases (kinds without one on the level left out).
local function pickEmergency(world, month, phases)
  local phase
  for _, p in ipairs(phases or EMERGENCY_PHASES) do
    if p.from <= month then phase = p end
  end
  if not phase then return nil end
  local kinds, total = {}, 0
  -- (In a fixed order: pairs() would not be the same on every computer.)
  for _, name in ipairs({"pharmacy", "inflation", "psychiatry", "theatre", "clinics"}) do
    local weight, kind = phase.weights[name], EMERGENCY_KINDS[name]
    if weight then
      local diseases = {}
      for _, illness in ipairs(kind.illnesses) do
        diseases[#diseases + 1] = diseaseOf(world, illness)
      end
      if #diseases > 0 then
        kinds[#kinds + 1] = {kind = kind, weight = weight, diseases = diseases}
        total = total + weight
      end
    end
  end
  if total == 0 then return nil end
  local roll = math.random(1, total)
  for _, k in ipairs(kinds) do
    if roll <= k.weight then
      return makeEmergency(k.diseases[math.random(1, #k.diseases)], k.kind)
    end
    roll = roll - k.weight
  end
end

--! Start `emergency` in `hospital` if it can take one (helipad, staffed
--! desk): its disease becomes known there first, so it can be treated.
--!return (boolean) whether it started
local function startEmergency(hospital, emergency)
  if not (hospital:getHeliportSpawnPosition() and hospital:hasReceptionDesk(true)) then return false end
  local casebook = hospital.disease_casebook[emergency.disease.id]
  if casebook and not casebook.discovered then hospital.research:discoverDisease(emergency.disease) end
  return not hospital:createEmergency(emergency)
end

local function busy(hospital)
  return hospital.mp_place or hospital.mp_opening or hospital.emergency or hospital.epidemic
end

--! The next hospital in turn that can take an emergency gets one.
--!return (boolean) whether one did
local function sendEmergency(world, month, phases)
  for _ = 1, world.mp_coop.players do
    local hospital = world:_coopTurn("level_emergency")
    if not busy(hospital) then
      local emergency = pickEmergency(world, month, phases)
      if emergency and startEmergency(hospital, emergency) then return true end
    end
  end
  return false
end

--! The May slack tongue emergency to every hospital still waiting for it
--! that can take it now.
local function sendSlackTongue(world, state)
  local disease = diseaseOf(world, SLACK_TONGUE.illness)
  if not disease then state.slack_pending = {} return end
  for index = 1, world.mp_coop.players do
    local hospital = world.hospitals[index]
    if state.slack_pending[index] and not busy(hospital) and
        startEmergency(hospital, makeEmergency(disease, SLACK_TONGUE)) then
      state.slack_pending[index] = nil
    end
  end
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
    MultiplayerSession.tellPlayer(world, hospital, _S.multiplayer_window.level_rats_notice)
  end
  return spawned
end

--! Level 6's events, at the end of every day.
local function emergencyDay(world)
  local state = world.mp_level_events
  if not state then
    state = {days_to_wave = nil, days_to_rats = between(RAT_SWARM_DAYS)}
    world.mp_level_events = state
  end
  local date = world.game_date
  local month, day = date:monthOfGame(), date:dayOfMonth()
  -- Four times a month, on days chosen at the start of the month.
  if state.month ~= month then
    state.month = month
    state.waiting = 0
    state.emergency_days = {}
    for i, range in ipairs(EMERGENCY_DAYS) do state.emergency_days[i] = math.random(range[1], range[2]) end
    if month == SLACK_TONGUE.warn_month then
      MultiplayerSession.tellOthers(world, nil, _S.multiplayer_window.level_slack_tongue_warning)
    end
  end
  -- The slack tongue emergency of May, to every hospital.
  if month == SLACK_TONGUE.month and day == SLACK_TONGUE.day then
    state.slack_pending = {}
    for index = 1, world.mp_coop.players do state.slack_pending[index] = true end
  end
  if state.slack_pending then
    if month > SLACK_TONGUE.until_month then
      state.slack_pending = nil
    else
      sendSlackTongue(world, state)
    end
  end
  -- An emergency nobody can take on its day (each hospital has one at a
  -- time) waits for the first hospital that is free, until the month ends.
  if month >= EMERGENCY_PHASES[1].from and month <= EMERGENCY_LAST_MONTH and
      not (month == SLACK_TONGUE.month and day <= SLACK_TONGUE.day) then
    for _, d in ipairs(state.emergency_days) do
      if day == d then state.waiting = (state.waiting or 0) + 1 end
    end
    while (state.waiting or 0) > 0 and sendEmergency(world, month) do
      state.waiting = state.waiting - 1
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


-- Level 7, "Cutthroat" -------------------------------------------------------
--
-- A race with level 8's rooms and research, made for the dirty tricks
-- (mp_sabotage.lua). A truce until March; then the tricks unlock by what
-- they hit (sabotage.unlockMonth), level 3 of each from the second year.
-- Each month one trick costs half price (the trick of the month), the last
-- hospital in the race pays half for every trick and the leader half as
-- much again (sabotage.price). Things worth a trick: job fairs bring
-- specialists to the shared hiring list (months 4, 10, 16, 22: headhunters
-- poach them), race emergencies come to every hospital at once (months 8,
-- 14, 20: the first to save every patient gets a bonus), the first to
-- discover the X-ray, scanner or blood machine gets a breakthrough bonus (not
-- by espionage), the hospital that cures the most patients in a quarter
-- gains reputation (a smear campaign takes patients away), attack rats
-- shot pay a bounty, machines wear out faster (the evil handyman), and four
-- earthquakes shake every hospital.
-- In co-op the same events run, without the tricks.

--! When each trick can first be bought (month of the game), and the month
--! level 3 of every trick can (a truce until then: none before month 3).
local TRICK_UNLOCK = {rats = 3, smear = 3, boiler = 3, handyman = 6, epidemic = 6, espionage = 6,
    emergency = 9, headhunter = 9}
local TRICK_TOP_LEVEL_MONTH = 13
--! The trick of the month, from month 3 on, round and round.
local TRICK_ROTATION = {"rats", "smear", "boiler", "handyman", "epidemic", "espionage", "emergency",
    "headhunter"}
local TRICK_ROTATION_FROM = 3
--! Price factors: the trick of the month, the last hospital in the race and
--! the leader (by how close they are to the goals at the start of the month).
local PRICE_OF_THE_MONTH, PRICE_LAST, PRICE_LEADER = 0.5, 0.5, 1.5
--! Months whose hiring list has the specialists.
local JOB_FAIRS = {4, 10, 16, 22}
--! Race emergencies: months, the day they come, the bonus to the first
--! hospital to save every patient.
local RACE_EMERGENCY_MONTHS = {8, 14, 20}
local RACE_EMERGENCY_DAY = 3
local RACE_BONUS, RACE_REPUTATION = 10000, 20
--! The emergencies of the first year, one a month for each hospital.
local CUTTHROAT_PHASES = {
  {from = 2, weights = {pharmacy = 2, inflation = 3, psychiatry = 3}},
  {from = 6, weights = {pharmacy = 1, inflation = 2, psychiatry = 2, theatre = 3, clinics = 2}},
}
local CUTTHROAT_EMERGENCY_LAST_MONTH = 12
--! The first discovery of these machines earns a bonus.
local BREAKTHROUGHS = {"x_ray", "scanner", "blood_machine"}
local BREAKTHROUGH_BONUS, BREAKTHROUGH_REPUTATION = 10000, 15
--! The quarter's best: reputation for the hospital that cured the most.
local QUARTER_REPUTATION = 15
--! Paid for every attack rat shot.
local RAT_BOUNTY = 100
--! Earthquakes: in a window of months, of a strength (Earthquake class).
local CUTTHROAT_QUAKES = {
  {StartMonth = 7, EndMonth = 9, Severity = 2},
  {StartMonth = 13, EndMonth = 16, Severity = 3},
  {StartMonth = 19, EndMonth = 22, Severity = 4},
  {StartMonth = 26, EndMonth = 30, Severity = 5},
}

--! A hiring list with few specialists, but many at the job fairs, for
--! `players` hospitals sharing it. (An entry with Month = m is used for the
--! list from month m + 1 on.)
local function cutthroatStaff(players)
  local result, i = {}, 0
  local function entry(month, fair)
    result[i] = {
      Month = month,
      Doctors = fair and 3 * players + 2 or 2 * players + 1,
      Nurses = 3 * players + math.random(0, players),
      Handymen = players + math.random(0, players),
      Receptionists = players + math.random(0, players),
      -- One in two of the fair's doctors a surgeon, a psychiatrist, a
      -- researcher; one in three a consultant. Otherwise few of them, and
      -- half the doctors junior.
      ShrkRate = fair and 2 or 10, SurgRate = fair and 2 or 10, RschRate = fair and 2 or 10,
      ConsRate = fair and 3 or 0,
      JrRate = fair and 0 or 2,
    }
    i = i + 1
  end
  entry(0, false)
  for _, month in ipairs(JOB_FAIRS) do
    entry(month - 1, true)
    entry(month, false)
  end
  return result
end

levels.SCENARIOS.cutthroat = {
  apply = function(config, players)
    -- The level's own emergencies (levels.onEndDay) instead of the campaign's.
    config.emergency_control = {[0] = {StartMonth = 0, EndMonth = 0, Min = 0, Max = 0, Illness = 0,
        PercWin = 0, Bonus = 0}}
    config.mp_events = "cutthroat"
    config.staff_levels = cutthroatStaff(players)
    -- The dirty tricks' schedule and prices (mp_sabotage.lua).
    config.mp_tricks = {unlock = TRICK_UNLOCK, top_level_month = TRICK_TOP_LEVEL_MONTH}
    config.mp_rat_bounty = RAT_BOUNTY
    -- Machines last three quarters as long.
    for _, spec in pairs(config.objects or {}) do
      if type(spec) == "table" and spec.StartStrength then
        spec.StartStrength = math.max(1, math.floor(spec.StartStrength * 3 / 4))
      end
    end
    config.quake_control = {}
    for n, quake in ipairs(CUTTHROAT_QUAKES) do
      config.quake_control[n - 1] = {StartMonth = quake.StartMonth, EndMonth = quake.EndMonth,
          Severity = quake.Severity}
    end
  end,
}

--! The hospitals still racing (all of them in co-op), in hospital order.
local function racing(world)
  local list = {}
  for index = 1, world.mp_coop.players do
    local hospital = world.hospitals[index]
    if hospital and not hospital.mp_place then list[#list + 1] = hospital end
  end
  return list
end

--! How close `hospital` is to the goals: the average of each goal's share
--! reached (0 .. 1), in a fixed order of goals.
local function goalScore(world, hospital)
  local conditions = world.endconditions
  local goals = conditions and conditions.win_goals and conditions.win_goals[1]
  if not goals then return 0 end
  local names = {}
  for name in pairs(goals) do names[#names + 1] = name end
  table.sort(names)
  local total = 0
  for _, name in ipairs(names) do
    local goal = goals[name]
    local value = conditions:getAttribute(hospital, name) or 0
    local share
    if goal.max_min == 1 then
      share = goal.win_value > 0 and value / goal.win_value or 1
    else
      share = value <= goal.win_value and 1 or goal.win_value / math.max(value, 1)
    end
    total = total + math.max(0, math.min(1, share))
  end
  return #names > 0 and total / #names or 0
end

--! The leader and the last of the race (by hospital index): none when all
--! are as close to the goals. (A race of two teams ranks the teams: each
--! hospital counts with its team's average.)
local function rankRace(world)
  local ranks = {}
  local list = racing(world)
  if #list < 2 then return ranks end
  local team_sum, team_count = {}, {}
  for _, hospital in ipairs(list) do
    local team = world:mpTeam(hospital)
    if team then
      team_sum[team] = (team_sum[team] or 0) + goalScore(world, hospital)
      team_count[team] = (team_count[team] or 0) + 1
    end
  end
  local scores, best, worst = {}, nil, nil
  for _, hospital in ipairs(list) do
    local team = world:mpTeam(hospital)
    local share = team and team_sum[team] / team_count[team] or goalScore(world, hospital)
    local score = math.floor(share * 1000)
    scores[hospital] = score
    best = math.max(best or score, score)
    worst = math.min(worst or score, score)
  end
  if best == worst then return ranks end
  for _, hospital in ipairs(list) do
    local index = world:getHospitalIndex(hospital)
    if scores[hospital] == best then ranks[index] = "leader" end
    if scores[hospital] == worst then ranks[index] = "last" end
  end
  return ranks
end

local function tellAll(world, text)
  MultiplayerSession.tellOthers(world, nil, text)
end

--! The trick of month `month`, or nil (before the rotation starts).
function levels.trickOfTheMonth(month)
  if month < TRICK_ROTATION_FROM then return nil end
  return TRICK_ROTATION[(month - TRICK_ROTATION_FROM) % #TRICK_ROTATION + 1]
end

--! The price factor of a trick for `buyer` this month on a level with its
--! own trick rules (1 elsewhere).
function levels.trickPriceFactor(world, buyer, kind)
  local state = world.mp_level_events
  if not (world.map.level_config.mp_tricks and state) then return 1 end
  local factor = 1
  -- (By the date: the notice of the month comes at the end of its first day.)
  if world.mp_coop and world.mp_coop.competitive and
      levels.trickOfTheMonth(world.game_date:monthOfGame()) == kind then
    factor = factor * PRICE_OF_THE_MONTH
  end
  local rank = state.ranks and state.ranks[world:getHospitalIndex(buyer)]
  if rank == "last" then factor = factor * PRICE_LAST
  elseif rank == "leader" then factor = factor * PRICE_LEADER end
  return factor
end

--! A race emergency for every hospital still waiting for this month's.
local function sendRaceEmergency(world, state)
  local race = state.race
  for index = 1, world.mp_coop.players do
    local hospital = world.hospitals[index]
    if race.pending[index] and not hospital.mp_place and not busy(hospital) then
      local emergency = makeEmergency(race.disease, race.spec)
      emergency.victims = race.victims
      emergency.mp_race = race.month
      if startEmergency(hospital, emergency) then race.pending[index] = nil end
    end
  end
end

--! A race emergency ended in `hospital` (Hospital:resolveEmergency): the
--! first to save every patient gets the bonus.
function levels.raceEmergencyResolved(hospital, emergency)
  local world = hospital.world
  local race = world.mp_level_events and world.mp_level_events.race
  if not race or race.month ~= emergency.mp_race or race.winner then return end
  if emergency.cured_emergency_patients < emergency.victims then return end
  race.winner = world:getHospitalIndex(hospital)
  hospital:receiveMoney(RACE_BONUS, _S.multiplayer_window.level7_race_bonus)
  hospital:changeReputation(nil, nil, RACE_REPUTATION)
  tellAll(world, _S.multiplayer_window.level7_race_won:format(hospital.name, RACE_BONUS))
end

--! The first hospital to discover one of the BREAKTHROUGHS (not by
--! espionage, sabotage.spy) gets a bonus.
local function checkBreakthroughs(world, state)
  for _, id in ipairs(BREAKTHROUGHS) do
    local object = TheApp.objects and TheApp.objects[id]
    if state.breakthroughs[id] == nil then
      -- Open only when it is still to be researched by every hospital.
      local open = object ~= nil
      for index = 1, world.mp_coop.players do
        local progress = object and world.hospitals[index].research.research_progress[object]
        if not progress or progress.discovered then open = false end
      end
      state.breakthroughs[id] = open and "open" or false
    end
    if state.breakthroughs[id] == "open" then
      for _, hospital in ipairs(racing(world)) do
        local progress = hospital.research.research_progress[object]
        local spied = hospital.mp_spied and hospital.mp_spied[id]
        if state.breakthroughs[id] == "open" and progress and progress.discovered and not spied then
          state.breakthroughs[id] = world:getHospitalIndex(hospital)
          hospital:receiveMoney(BREAKTHROUGH_BONUS, _S.multiplayer_window.level7_breakthrough_bonus)
          hospital:changeReputation(nil, nil, BREAKTHROUGH_REPUTATION)
          tellAll(world, _S.multiplayer_window.level7_breakthrough:format(hospital.name,
              object.name, BREAKTHROUGH_BONUS))
        end
      end
    end
  end
end

--! The quarter's best: the hospital that cured the most since the last one.
local function quarterRanking(world, state)
  local best, winners = 0, {}
  for _, hospital in ipairs(racing(world)) do
    local index = world:getHospitalIndex(hospital)
    local cured = (hospital.num_cured or 0) - (state.quarter_start[index] or 0)
    if cured > best then best, winners = cured, {hospital}
    elseif cured == best and cured > 0 then winners[#winners + 1] = hospital end
  end
  for _, hospital in ipairs(winners) do
    hospital:changeReputation(nil, nil, QUARTER_REPUTATION)
    tellAll(world, _S.multiplayer_window.level7_quarter:format(hospital.name, best))
  end
  for index = 1, world.mp_coop.players do
    state.quarter_start[index] = world.hospitals[index].num_cured or 0
  end
end

local function isIn(list, value)
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

--! Level 7's events, at the end of every day.
local function cutthroatDay(world)
  local state = world.mp_level_events
  if not state then
    state = {breakthroughs = {}, quarter_start = {}}
    for index = 1, world.mp_coop.players do
      state.quarter_start[index] = world.hospitals[index].num_cured or 0
    end
    world.mp_level_events = state
  end
  local competitive = world.mp_coop.competitive
  local date = world.game_date
  local month, day = date:monthOfGame(), date:dayOfMonth()
  if state.month ~= month then
    state.month = month
    state.waiting = 0
    state.emergency_days = {}
    for i = 1, math.min(world.mp_coop.players, #EMERGENCY_DAYS) do
      state.emergency_days[i] = between(EMERGENCY_DAYS[i])
    end
    if competitive then
      state.ranks = rankRace(world)
      state.trick_of_month = levels.trickOfTheMonth(month)
      if month == TRICK_ROTATION_FROM then tellAll(world, _S.multiplayer_window.level7_truce_over) end
      if state.trick_of_month then
        tellAll(world, _S.multiplayer_window.level7_trick_of_month:format(
            _S.multiplayer_window["sabotage_" .. state.trick_of_month]))
      end
    end
    if isIn(JOB_FAIRS, month) then tellAll(world, _S.multiplayer_window.level7_job_fair) end
    if month > 1 and (month - 1) % 3 == 0 then quarterRanking(world, state) end
  end
  if day == 25 and isIn(JOB_FAIRS, month + 1) then
    tellAll(world, _S.multiplayer_window.level7_job_fair_soon)
  end
  -- The first year's emergencies, each hospital in turn (not in a month of
  -- a race emergency).
  if month >= CUTTHROAT_PHASES[1].from and month <= CUTTHROAT_EMERGENCY_LAST_MONTH and
      not isIn(RACE_EMERGENCY_MONTHS, month) then
    for _, d in ipairs(state.emergency_days) do
      if day == d then state.waiting = (state.waiting or 0) + 1 end
    end
    while (state.waiting or 0) > 0 and sendEmergency(world, month, CUTTHROAT_PHASES) do
      state.waiting = state.waiting - 1
    end
  end
  -- A race emergency: the same one for every hospital (one busy then gets
  -- it as soon as it is free, until the month ends).
  if isIn(RACE_EMERGENCY_MONTHS, month) and day == RACE_EMERGENCY_DAY then
    local emergency = pickEmergency(world, math.max(month, CUTTHROAT_PHASES[#CUTTHROAT_PHASES].from),
        CUTTHROAT_PHASES)
    if emergency then
      local spec = {min = emergency.victims, max = emergency.victims, win = emergency.percentage * 100,
          bonus = emergency.bonus}
      state.race = {month = month, disease = emergency.disease, spec = spec, victims = emergency.victims,
          pending = {}}
      for index = 1, world.mp_coop.players do state.race.pending[index] = true end
      tellAll(world, _S.multiplayer_window.level7_race_emergency:format(RACE_BONUS))
    end
  end
  if state.race and state.race.month == month then sendRaceEmergency(world, state) end
  checkBreakthroughs(world, state)
end

--! The level's events, at the end of every day (World:onEndDay).
function levels.onEndDay(world)
  if not world.mp_coop then return end
  local events = world.map.level_config.mp_events
  if events ~= "emergency" and events ~= "cutthroat" then return end
  corsixth.require("mp_session")
  if events == "emergency" then emergencyDay(world) else cutthroatDay(world) end
end

return levels
