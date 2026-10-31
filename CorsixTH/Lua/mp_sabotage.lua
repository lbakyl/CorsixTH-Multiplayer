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

--! Multiplayer competitive: dirty tricks a player buys against a rival's
--! hospital (MULTIPLAYER > DIRTY TRICKS, UIMultiplayerSabotage), each at
--! three levels:
--!  * an evil handyman: walks over and wanders the rival's hospital like one of
--!    their staff, but nobody pays him and he does no work (level 1), drops
--!    litter (level 2) and also wears machines down until they nearly break
--!    (level 3). The rival throws him out with the sack button of his staff
--!    window; he then walks back to the buyer and works for them as an
--!    ordinary handyman (the buyer pays his wages from then on).
--!  * an epidemic: contagious patients of one disease arrive at the rival's
--!    hospital (2, 4 or 7 of them).
--!  * an emergency the rival cannot refuse: the helicopter just comes (3, 6
--!    or 10 patients; level 3 may bring a disease they have not discovered).
--!  * a rat attack: 5, 10 or 20 rats come out of new holes in the rival's
--!    walls and keep running between them; each one costs that hospital a
--!    reputation point a day until it is shot (a click on it, as any rat),
--!    for 60 days at most.
--!  * a headhunter: one of the rival's doctors gets a better offer and asks
--!    for a big pay rise (a junior, a doctor, or a consultant or specialist).
--!    The rival pays it or loses them: they leave for the hiring list, kept
--!    there for the buyer for two weeks.
--!  * a broken boiler: the rival's heating fails (too cold in winter, too hot
--!    in summer) until their handymen have repaired it; the more handymen,
--!    the sooner.
--!  * a smear campaign: for one, two or three months a share of the patients
--!    who would come to the rival go to the other hospitals instead.
--!  * espionage: the buyer gets an improvement (level 1), a discovery (level
--!    2) or two of either (level 3) that the rival has and they do not; at
--!    level 3 the rival also loses half of the progress on their research.
--! Every purchase is the lockstep command `sabotage` {trick, level, to}; the
--! rival is not told who sent an epidemic or an emergency.

local sabotage = {}

--! Prices by kind and level.
sabotage.PRICES = {
  handyman = {5000, 12500, 20000},
  epidemic = {6000, 12000, 20000},
  emergency = {5000, 10000, 18000},
  rats = {4000, 9000, 15000},
  headhunter = {4000, 9000, 16000},
  boiler = {3000, 7000, 12000},
  smear = {5000, 10000, 18000},
  espionage = {6000, 12000, 20000},
}
sabotage.KINDS = {"handyman", "epidemic", "emergency", "rats", "headhunter", "boiler", "smear", "espionage"}

-- Evil handymen at once in one hospital, at most.
local MAX_HANDYMEN = 3
-- Contagious patients sent, and emergency patients, by level.
local EPIDEMIC_PATIENTS = {2, 4, 7}
local EMERGENCY_PATIENTS = {3, 6, 10}
local RATS = {5, 10, 20}
local MAX_RATS = 30 -- attack rats alive in one hospital, at most
-- Headhunter: the pay rise asked, as a share of the wage, and how long the
-- rival has to answer (ticks; 50 in a day); a poached doctor is kept on the
-- hiring list for the buyer for HEADHUNT_RESERVED_DAYS.
local HEADHUNT_RISE = {0.5, 0.75, 1.0}
local HEADHUNT_TICKS = 50 * 10
local HEADHUNT_RESERVED_DAYS = 14
-- Broken boiler: repair work needed (Hospital:_fixBoiler takes 1 to 3 a
-- day, by the number of handymen).
local BOILER_REPAIR = {15, 30, 50}
-- Smear campaign: months, and the share of patients who go elsewhere.
local SMEAR_MONTHS = {1, 2, 3}
local SMEAR_SHARE = {0.3, 0.4, 0.5}
-- The evil handyman's habits, in game hours (one tick each; 50 in a day).
sabotage.LITTER_EVERY = 25    -- level 2 and 3: litter twice a day
sabotage.DAMAGE_EVERY = 150   -- level 3: a machine every three days
-- How long he stays (game days from when he was sent; about 30 in a month):
-- the stronger, the shorter.
sabotage.STAY_DAYS = {120, 90, 60}
local DAMAGE_GIVE_UP_HOURS = 300 -- gives up a machine he cannot get to

local handlers = MultiplayerSession.default_handlers

local function S() return _S.multiplayer_window end

local function log(text)
  local session = TheApp and TheApp.mp_session
  if session then session.log(string.format("sabotage (step %d): %s", session.step, text)) end
end

--! Why the buyer's hospital cannot play this trick on `target` now (nil: it can).
function sabotage.refusal(world, buyer, target, kind, level)
  if not (world.mp_coop and world.mp_coop.competitive) then return "only in a competitive game" end
  local prices = sabotage.PRICES[kind]
  if not prices or not prices[level] then return "no such trick" end
  if not target or target == buyer then return "no such hospital" end
  if buyer.mp_place then return "you are out of the race" end
  if target.mp_place then return "they are out of the race" end
  if not target.opened or target.mp_opening then return "their hospital is not open yet" end
  if kind == "handyman" then
    local count = 0
    for _, entity in ipairs(world.entities) do
      if entity.mp_saboteur and entity.mp_saboteur.target == world:getHospitalIndex(target) then
        count = count + 1
      end
    end
    if count >= MAX_HANDYMEN then return "they have enough of those already" end
    if not (target.ownedPlots and target.ownedPlots[1]) then return "no room at the other hospital" end
  elseif kind == "epidemic" then
    if target.epidemics_disabled then return "no epidemics on this level" end
    if target.epidemic or #target.future_epidemics_pool > 0 then return "they have an epidemic already" end
    if target.emergency then return "they have an emergency on" end
    if not target:hasReceptionDesk(true) then return "they have no staffed reception desk" end
  elseif kind == "rats" then
    if sabotage.countRats(world, target) + RATS[level] > MAX_RATS then return "they have enough rats already" end
  elseif kind == "headhunter" then
    if not sabotage.headhuntTarget(target, level) then return "they have nobody of that kind to poach" end
  elseif kind == "boiler" then
    if target.heating.heating_broke then return "their heating is broken already" end
    if target:countRadiators() == 0 then return "they have no radiators" end
  elseif kind == "smear" then
    if target.mp_smear then return "a smear campaign against them is running already" end
    local others = false
    for _, h in ipairs(world.hospitals) do
      if h ~= target and h.opened and not h.mp_place then others = true end
    end
    if not others then return "there is no other hospital for their patients to go to" end
  elseif kind == "espionage" then
    if #sabotage.stealable(target, buyer, level) == 0 then return "they know nothing that you do not" end
  elseif kind == "emergency" then
    if target.emergency or target.mp_emergency_timer then return "they have an emergency on" end
    if target.epidemic then return "they have an epidemic on" end
    if not target:hasReceptionDesk(true) then return "they have no staffed reception desk" end
    if not target:getHeliportSpawnPosition() then return "they have no helipad" end
  end
  if buyer.balance < prices[level] then return "not enough money" end
  return nil
end

--! Buy a dirty trick against another player's hospital: {trick, level, to}.
function handlers.sabotage(world, cmd)
  local buyer = world.hospitals[cmd.hospital or 1]
  local target = world.hospitals[tonumber(cmd.to) or 0]
  -- (`kind` names the command itself: the trick is `trick`.)
  local kind, level = cmd.trick, math.floor(tonumber(cmd.level) or 0)
  local why = sabotage.refusal(world, buyer, target, kind, level)
  if why then return false, why end
  local ok
  if kind == "handyman" then
    ok, why = sabotage.sendHandyman(world, buyer, target, level)
  elseif kind == "epidemic" then
    ok, why = sabotage.startEpidemic(world, target, level)
  elseif kind == "rats" then
    ok, why = sabotage.ratAttack(world, target, level)
  elseif kind == "headhunter" then
    ok, why = sabotage.headhunt(world, buyer, target, level)
  elseif kind == "boiler" then
    ok, why = sabotage.breakBoiler(world, target, level)
  elseif kind == "smear" then
    ok, why = sabotage.smear(world, target, level)
  elseif kind == "espionage" then
    ok, why = sabotage.spy(world, buyer, target, level, cmd.items)
  else
    ok, why = sabotage.sendEmergency(world, target, level)
  end
  if not ok then return false, why end
  local price = sabotage.PRICES[kind][level]
  buyer:spendMoney(price, S().sabotage_transaction)
  log(string.format("hospital %d bought %s level %d against hospital %d",
      world:getHospitalIndex(buyer), kind, level, world:getHospitalIndex(target)))
  MultiplayerSession.tellPlayer(world, buyer, S().sabotage_done[kind]:format(target.name))
  return true
end

--! The evil handyman: a new handyman sets off from the buyer's hospital and
--! walks over to the target's, like a transferred member of staff
--! (World:_tickCoopTransfers); on arrival he starts his mischief.
function sabotage.sendHandyman(world, buyer, target, level)
  local sx, sy = MultiplayerSession.arrivalTile(world, buyer)
  local tx, ty = MultiplayerSession.arrivalTile(world, target)
  if not sx or not tx then return false, "no room at the other hospital" end
  local profile = StaffProfile(world, "Handyman", _S.staff_class["handyman"])
  profile:randomise(world.game_date:monthOfGame())
  local handyman = world:newEntity("Handyman", 2, 2)
  handyman:setProfile(profile)
  handyman:setTile(sx, sy)
  handyman:setHospital(buyer)
  handyman.mp_saboteur = {
    owner = world:getHospitalIndex(buyer),
    target = world:getHospitalIndex(target),
    level = level,
    hours = 0,
  }
  handyman.mp_in_transit = {to = world:getHospitalIndex(target), x = tx, y = ty}
  handyman.speed, handyman.slow_animation = "transit", false
  local walk = WalkAction(tx, ty):setMustHappen(true)
  handyman.mp_transfer_walk = walk
  handyman:setNextAction(walk)
  handyman:queueAction(IdleAction())
  world.mp_transfers = world.mp_transfers or {}
  world.mp_transfers[#world.mp_transfers + 1] = handyman
  return true
end

--! An evil handyman has walked into the target's hospital (from
--! World:_tickCoopTransfers): he looks like one of their staff, but is on
--! nobody's payroll and keeps to their plots.
function sabotage.arrived(world, handyman)
  local s = handyman.mp_saboteur
  local target = world.hospitals[s.target]
  handyman:setHospital(target)
  handyman.speed = "normal"
  -- He does not meander (that wanders off over the plot outside); the tick
  -- walks him between corridor tiles of their building.
  handyman:setNextAction(IdleAction())
  s.next_move = s.hours
  local owner = world.hospitals[s.owner]
  log(string.format("handyman #%d arrived at hospital %d", handyman.mp_id, s.target))
  MultiplayerSession.tellPlayer(world, owner, S().sabotage_arrived:format(target.name))
end

--! A corridor tile inside `hospital`'s building near its start view (a few
--! tries at random, the same on every peer), or nil.
function sabotage.corridorTile(world, hospital)
  local th = world.map.th
  local cx, cy = th:getCameraTile(hospital:getPlayerIndex())
  local width, height = th:size()
  for _ = 1, 30 do
    local x, y = cx + math.random(-15, 15), cy + math.random(-15, 15)
    if x >= 1 and y >= 1 and x <= width and y <= height and hospital:isInHospital(x, y) and
        th:getCellFlags(x, y).passable and not world:getRoom(x, y) then
      return x, y
    end
  end
end

--! Walk the evil handyman to (x, y), then let him stand there.
local function walk_to(handyman, x, y)
  handyman:setNextAction(WalkAction(x, y))
  handyman:queueAction(IdleAction())
end

--! One game hour of an evil handyman's mischief (from Staff:tick).
function sabotage.tick(handyman)
  local s = handyman.mp_saboteur
  local world = handyman.world
  s.hours = s.hours + 1
  if s.hours >= sabotage.STAY_DAYS[s.level] * 50 then return sabotage.goHome(handyman) end
  local x, y = handyman.tile_x, handyman.tile_y
  local hospital = handyman.hospital
  local action = handyman:getCurrentAction()
  local standing = action and action.name == "idle"

  -- Level 2 and 3: litter on the corridor where he is.
  if s.level >= 2 and x and s.hours % sabotage.LITTER_EVERY == 0 and not handyman:getRoom() and
      not world:getObjects(x, y) and world.map.th:getCellFlags(x, y).buildable and
      hospital:isInHospital(x, y) then
    if world:newLitter(math.random(1, 4), x, y, math.random(0, 1)) then
      log(string.format("handyman #%d dropped litter at %d,%d", handyman.mp_id, x, y))
    end
  end

  -- Level 3: every few days he "repairs" a machine, like any handyman on a
  -- call: into its room, the repair at the machine, out again. It is worn
  -- down to nearly broken when he walks away.
  if s.level >= 3 then
    if s.machine then
      sabotage.fakeRepairTick(handyman, standing)
      return
    elseif s.hours >= (s.next_damage or sabotage.DAMAGE_EVERY) then
      local machine = sabotage.pickMachine(world, hospital)
      if machine then
        local ux, uy = machine:getRepairTile()
        s.machine, s.walk_started, s.repairing = machine.mp_id, s.hours, nil
        handyman:setDynamicInfoText(_S.dynamic_info.staff.actions.going_to_repair
            :format(machine.object_type.name))
        local room = handyman:getRoom()
        if room then
          handyman:setNextAction(room:createLeaveAction())
          handyman:queueAction(WalkAction(ux, uy):setIsEntering(true))
        else
          handyman:setNextAction(WalkAction(ux, uy):setIsEntering(true))
        end
        handyman:queueAction(IdleAction())
        return
      end
      s.next_damage = s.hours + sabotage.DAMAGE_EVERY
    end
  end

  -- Otherwise he strolls about their corridors, like a handyman on his round.
  if standing and s.hours >= (s.next_move or 0) then
    local tx, ty = sabotage.corridorTile(world, hospital)
    if tx then walk_to(handyman, tx, ty) end
    s.next_move = s.hours + math.random(20, 60)
  end
end

--! An evil handyman on his way to "repair" a machine (one game hour; level
--! 3). At its repair tile he keeps new patients out, as a real repair does,
--! waits until nobody uses it and plays the repair; when that is over the
--! machine is worn down and he walks out.
function sabotage.fakeRepairTick(handyman, standing)
  local s = handyman.mp_saboteur
  local world = handyman.world
  local machine = world:getEntityById(s.machine)
  local room = machine and not machine.to_destroy and machine:getRoom()
  if s.repairing and standing then
    -- The repair is over.
    if room then sabotage.damage(machine) end
    sabotage.unlockRoom(world, s)
    sabotage.leaveMachine(handyman)
    return
  end
  if not room or (not s.repairing and s.hours - s.walk_started > DAMAGE_GIVE_UP_HOURS) then
    log(string.format("handyman #%d gave up on machine #%d", handyman.mp_id, s.machine))
    sabotage.unlockRoom(world, s)
    sabotage.leaveMachine(handyman)
    return
  end
  local ux, uy = machine:getRepairTile()
  if s.repairing or not standing then return end
  if handyman.tile_x ~= ux or handyman.tile_y ~= uy then
    -- Not there (a blocked way, or a save from before): walk on.
    handyman:setNextAction(WalkAction(ux, uy):setIsEntering(true))
    handyman:queueAction(IdleAction())
    return
  end
  if not s.locked then
    s.locked = true
    room:lockRoomOnRepair()
  end
  local patient = room:getPatient()
  if machine.user or (patient and not patient:isLeaving()) then return end
  s.repairing = true
  local repair = UseObjectAction(machine):setProlongedUsage(false)
  repair.min_length = 20
  handyman:setNextAction(repair)
  handyman:queueAction(IdleAction())
  log(string.format("handyman #%d repairing machine #%d", handyman.mp_id, machine.mp_id))
end

--! Done with a machine (or given up): out of its room, back to his round.
function sabotage.leaveMachine(handyman)
  local s = handyman.mp_saboteur
  s.machine, s.repairing, s.locked = nil, nil, nil
  s.next_damage = s.hours + sabotage.DAMAGE_EVERY
  s.next_move = s.hours + math.random(10, 30)
  handyman:setDynamicInfoText("")
  local room = handyman:getRoom()
  if room then
    handyman:setNextAction(room:createLeaveAction())
    handyman:queueAction(IdleAction())
  end
end

--! His time is up: he leaves the hospital and goes home (out of the game).
--! Only the player who sent him is told.
function sabotage.goHome(handyman)
  local s = handyman.mp_saboteur
  local world = handyman.world
  log(string.format("handyman #%d's time is up in hospital %d", handyman.mp_id, s.target))
  sabotage.unlockRoom(world, s)
  handyman:setDynamicInfoText("")
  handyman.fired = true
  handyman.going_home = true
  handyman.hover_cursor = nil
  handyman:despawn()
  MultiplayerSession.tellPlayer(world, world.hospitals[s.owner],
      S().sabotage_went_home:format(world.hospitals[s.target].name))
end

--! At a machine for a "repair": the room lets patients in again.
function sabotage.unlockRoom(world, s)
  local machine = s.locked and s.machine and world:getEntityById(s.machine)
  local room = machine and machine:getRoom()
  if room then
    room:unlockRoomOnRepair()
    room:tryAdvanceQueue()
  end
end

--! The machine of `hospital` the evil handyman goes for: the one with the most
--! uses left (the first in game order if several), not in a crashed room or
--! one being repaired.
function sabotage.pickMachine(world, hospital)
  local best, best_left
  for _, entity in ipairs(world.entities) do
    if class.is(entity, Machine) and not entity.to_destroy and entity.mp_id then
      local room = entity:getRoom()
      local left = entity.strength and entity:getRemainingUses()
      if room and room.hospital == hospital and not room.crashed and not room.needs_repair and
          not room.manual_repair and
          left and left > 3 and (not best_left or left > best_left) then
        best, best_left = entity, left
      end
    end
  end
  return best
end

--! Wear a machine down to two uses left: it smokes and calls for a handyman;
--! more use or an earthquake destroys it.
function sabotage.damage(machine)
  local room = machine:getRoom()
  if not machine.strength then return end
  machine.times_used = math.max(machine.times_used or 0, machine.strength - 2)
  log(string.format("machine #%d worn down to %d uses", machine.mp_id or 0, machine:getRemainingUses()))
  if machine.updateDynamicInfo then machine:updateDynamicInfo() end
  if room then
    machine:callHandymanForRepairIfNecessary(room)
    machine:updateSmokeDisplay(room)
  end
end

--! Thrown out (the sack button of his staff window, by the hospital he is in):
--! he walks back to the player who sent him and works there as an ordinary
--! handyman from then on.
function sabotage.throwOut(world, handyman, by)
  local s = handyman.mp_saboteur
  local owner = world.hospitals[s.owner]
  log(string.format("handyman #%d thrown out of hospital %d", handyman.mp_id, world:getHospitalIndex(by)))
  sabotage.unlockRoom(world, s)
  handyman:setDynamicInfoText("")
  handyman.mp_saboteur = nil
  local ok, why = MultiplayerSession.transferStaff(world, by, owner, handyman)
  if not ok then
    -- Nowhere to go back to: he just leaves the hospital (no severance).
    handyman.mp_saboteur = s
    handyman:despawn()
    handyman.fired = true
  end
  MultiplayerSession.tellPlayer(world, by, S().sabotage_caught:format(owner.name))
  MultiplayerSession.tellPlayer(world, owner, S().sabotage_caught_owner:format(by.name))
  return true, ok and nil or why
end

--! An epidemic: contagious patients of one disease arrive at the rival's
--! hospital (by its helipad, or else a map edge).
function sabotage.startEpidemic(world, target, level)
  local contagious = {}
  for _, disease in ipairs(world.available_diseases) do
    if disease.contagious then contagious[#contagious + 1] = disease end
  end
  if #contagious == 0 then return false, "no contagious diseases on this level" end
  local disease = contagious[math.random(1, #contagious)]
  local x, y = target:getHeliportSpawnPosition()
  if not x then
    local spawn_point = world.spawn_points[math.random(1, #world.spawn_points)]
    x, y = spawn_point.x, spawn_point.y
  end
  for _ = 1, EPIDEMIC_PATIENTS[level] do
    local patient = world:newEntity("Patient", 2, 1)
    patient:setDisease(disease)
    patient:setTile(x, y)
    patient:setHospital(target)
    target:addToEpidemic(patient)
  end
  return true
end

--! An emergency the rival cannot refuse: the helicopter just comes, and the
--! rival gets a fax that says so (accepted like UIFax:choice "accept_emergency").
function sabotage.sendEmergency(world, target, level)
  local candidates = {}
  for _, available in ipairs(world.available_diseases) do
    local disease = TheApp.diseases[available.id]
    local known = target.disease_casebook[available.id] and target.disease_casebook[available.id].discovered
    -- Level 3 may bring a disease they have not discovered (they cannot cure it).
    if disease and disease.emergency_number and (known or level >= 3) then
      candidates[#candidates + 1] = disease
    end
  end
  if #candidates == 0 then return false, "no disease for an emergency" end
  local disease = candidates[math.random(1, #candidates)]
  target.emergency = {
    disease = disease,
    victims = EMERGENCY_PATIENTS[level],
    bonus = 1000,
    percentage = 0.75,
    killed_emergency_patients = 0,
    cured_emergency_patients = 0,
    mp_forced = true,
  }
  world:newObject("helicopter", "north", nil, nil, nil, target)
  target.mp_emergency_timer = World.newCountdown(52)
  local ui = world.ui
  if ui and ui.hospital == target then
    ui:addWindow(UIWatch(ui, "emergency", target))
  end
  local message = {
    {text = S().sabotage_emergency_fax[1]},
    {text = S().sabotage_emergency_fax[2]:format(EMERGENCY_PATIENTS[level], disease.name)},
    {text = S().sabotage_emergency_fax[3]},
    choices = {{text = _S.fax.emergency_result.close_text, choice = "close"}},
  }
  if ui and ui.bottom_panel then
    ui.bottom_panel:queueMessage("information", message, nil, nil, nil, nil, target)
  end
  return true
end

--! Attack rats (from a rival) alive in `hospital`.
function sabotage.countRats(world, hospital)
  local count = 0
  for _, entity in ipairs(world.entities) do
    if entity.mp_attack_rat and entity.hospital == hospital and not entity.shot and not entity.to_destroy then
      count = count + 1
    end
  end
  return count
end

--! A rat attack: new holes in the rival's corridor walls and rats out of
--! them, running from hole to hole like any rat.
function sabotage.ratAttack(world, target, level)
  target:mpAddRatholes(2 + level)
  if #target.ratholes < 2 then return false, "no walls for rat holes" end
  local spawned = 0
  for _ = 1, RATS[level] do
    local rat = target:spawnRat()
    if rat then
      rat.mp_attack_rat = true
      spawned = spawned + 1
    end
  end
  if spawned == 0 then return false, "no walls for rat holes" end
  log(string.format("%d rats let loose in hospital %d", spawned, world:getHospitalIndex(target)))
  MultiplayerSession.tellPlayer(world, target, S().sabotage_rats_notice)
  return true
end

-- Days an attack rat keeps running before it goes back into a hole for good.
local RAT_DAYS = 30
-- Reputation lost a day: a point for every few attack rats alive, at most a
-- few points (a point per rat was up to 1200 for one level 3 attack).
local RATS_PER_POINT = 5
local MAX_RAT_POINTS = 3

--! Each day: the attack rats still alive cost their hospital a reputation
--! point for every RATS_PER_POINT of them, at most MAX_RAT_POINTS (from
--! Hospital:onEndDay). After RAT_DAYS the attack wears off.
--! The reputation `count` attack rats cost in a day.
function sabotage.ratPoints(count)
  if count <= 0 then return 0 end
  return math.min(MAX_RAT_POINTS, math.ceil(count / RATS_PER_POINT))
end

function sabotage.dailyRats(hospital)
  for _, entity in ipairs(hospital.world.entities) do
    if entity.mp_attack_rat and entity.hospital == hospital then
      entity.mp_attack_days = (entity.mp_attack_days or 0) + 1
      if entity.mp_attack_days > RAT_DAYS then entity.mp_attack_rat = nil end
    end
  end
  local count = sabotage.countRats(hospital.world, hospital)
  if count > 0 then
    hospital:unconditionalChangeReputation(-sabotage.ratPoints(count))
    if hospital.world.game_date:dayOfMonth() == 1 then
      MultiplayerSession.tellPlayer(hospital.world, hospital, S().sabotage_rats_reminder:format(count))
    end
  end
end

--------------------------------------------------------------------------------
-- Headhunter
--------------------------------------------------------------------------------

--! Whether `staff` is of the kind a headhunter of `level` goes for: level 1 a
--! junior doctor or a nurse, level 2 a doctor (not a junior or consultant),
--! level 3 a consultant or a specialist (surgeon, psychiatrist, researcher).
local function headhuntKind(staff, level)
  local profile = staff.profile
  if profile.humanoid_class == "Nurse" then return level == 1 end
  if profile.humanoid_class ~= "Doctor" then return false end
  if level == 1 then return profile.is_junior == 1 end
  if level == 2 then return profile.is_junior ~= 1 and profile.is_consultant ~= 1 end
  return profile.is_consultant == 1 or profile.is_surgeon == 1 or
      profile.is_psychiatrist == 1 or profile.is_researcher == 1
end

--! The member of staff of `hospital` a headhunter of `level` goes for: the
--! most skilled one of that kind who is not busy with another request.
function sabotage.headhuntTarget(hospital, level)
  local best
  for _, staff in ipairs(hospital.staff) do
    if not staff.fired and not staff.quitting_in and not staff.mp_in_transit and
        not staff.mp_saboteur and not staff.mp_headhunted and staff.profile and
        headhuntKind(staff, level) and
        (not best or staff.profile.skill > best.profile.skill) then
      best = staff
    end
  end
  return best
end

--! A headhunter: the rival's doctor asks for a big pay rise (as a pay rise
--! request, answered in the usual window), or else leaves.
function sabotage.headhunt(world, buyer, target, level)
  local staff = sabotage.headhuntTarget(target, level)
  if not staff then return false, "they have nobody of that kind to poach" end
  local amount = math.max(1, math.floor(staff.profile.wage * HEADHUNT_RISE[level]))
  staff.mp_headhunted = {by = world:getHospitalIndex(buyer)}
  target:makeRaiseRequest(amount, staff)
  staff.quitting_in = HEADHUNT_TICKS
  staff:setMood("pay_rise", "activate")
  log(string.format("headhunter after %s #%s of hospital %d (rise $%d)", staff.profile.humanoid_class,
      tostring(staff.mp_id), world:getHospitalIndex(target), amount))
  MultiplayerSession.tellPlayer(world, target,
      S().sabotage_headhunter_notice:format(staff.profile:getFullName(), amount))
  return true
end

--! A headhunted member of staff who was not given the rise leaves (no
--! severance, no reputation lost) and goes on the hiring list, kept for the
--! hospital that sent the headhunter for a while.
function sabotage.poached(staff)
  local world, hospital = staff.world, staff.hospital
  local by = staff.mp_headhunted and staff.mp_headhunted.by
  staff.mp_headhunted = nil
  staff.quitting_in = nil
  hospital:removeMessage(staff)
  staff.message_callback = nil
  local staff_window = world.ui and world.ui:getWindow(UIStaff)
  if staff_window and staff_window.staff == staff then staff_window:close() end
  staff:removeQueuedStaffMessage()
  staff:setMood("pay_rise", "deactivate")
  staff:setMood("exit", "activate")
  staff:setDynamicInfoText(_S.dynamic_info.staff.actions.fired)
  staff.fired = true
  staff.going_home = true
  staff:despawn()
  staff.hover_cursor = nil
  staff:unregisterCallbacks()
  local window = world.ui and world.ui:getWindow(UIStaffManagement)
  if window then window:updateStaffList(staff) end
  -- On the hiring list again, at the top.
  local profile = staff.profile
  local pool = world.available_staff[profile.humanoid_class]
  if pool then
    profile.mp_reserved = by and {hospital = by, days = HEADHUNT_RESERVED_DAYS} or nil
    table.insert(pool, 1, profile)
  end
  log(string.format("%s #%s left hospital %d for the hiring list", profile.humanoid_class,
      tostring(staff.mp_id), world:getHospitalIndex(hospital)))
  MultiplayerSession.tellPlayer(world, hospital, S().sabotage_headhunter_left:format(profile:getFullName()))
  local buyer = by and world.hospitals[by]
  if buyer then
    MultiplayerSession.tellPlayer(world, buyer,
        S().sabotage_headhunter_won:format(profile:getFullName(), HEADHUNT_RESERVED_DAYS))
  end
end

--! Why `hospital` cannot hire `profile` now (nil: it can): a poached doctor
--! is kept for the hospital that sent the headhunter for a while.
function sabotage.hireRefusal(world, hospital, profile)
  local reserved = profile.mp_reserved
  if reserved and reserved.days > 0 and world.hospitals[reserved.hospital] ~= hospital then
    return "promised to another hospital for a few days"
  end
  return nil
end

--! Each day: poached doctors on the hiring list are kept a day less, and
--! smear campaigns end when their time is up.
function sabotage.daily(world)
  for _, hospital in ipairs(world.hospitals) do
    local smear = hospital.mp_smear
    if smear and world.game_date:monthOfGame() >= smear.until_month then
      hospital.mp_smear = nil
      log(string.format("smear campaign against hospital %d over: %d patients went elsewhere",
          world:getHospitalIndex(hospital), smear.sent or 0))
      MultiplayerSession.tellPlayer(world, hospital, S().sabotage_smear_over)
    end
  end
  for _, pool in pairs(world.available_staff) do
    for _, profile in ipairs(pool) do
      local reserved = profile.mp_reserved
      if reserved then
        reserved.days = reserved.days - 1
        if reserved.days <= 0 then profile.mp_reserved = nil end
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Broken boiler
--------------------------------------------------------------------------------

--! The rival's heating breaks down: cold in the winter months (October to
--! March), hot otherwise, until their handymen have repaired it
--! (Hospital:_fixBoiler, the original game's boiler breakdown, which more
--! handymen repair sooner).
function sabotage.breakBoiler(world, target, level)
  local heat = target.heating
  if heat.heating_broke then return false, "their heating is broken already" end
  if target:countRadiators() == 0 then return false, "they have no radiators" end
  local month = world.game_date:monthOfYear()
  local broken_heat = (month >= 10 or month <= 3) and 0 or 1
  heat.saved_radiator_heat = heat.radiator_heat
  heat.radiator_heat = broken_heat
  heat.boiler_repair_count = BOILER_REPAIR[level]
  heat.heating_broke = true
  target:adviseBoilerBreakdown(broken_heat)
  log(string.format("boiler of hospital %d broken (%s, repair %d)", world:getHospitalIndex(target),
      broken_heat == 0 and "cold" or "hot", BOILER_REPAIR[level]))
  MultiplayerSession.tellPlayer(world, target, S().sabotage_boiler_notice)
  return true
end

--------------------------------------------------------------------------------
-- Smear campaign
--------------------------------------------------------------------------------

--! A smear campaign: for a few months a share of the patients who would come
--! to the rival go to the other hospitals (World:_coopPatientHospital).
function sabotage.smear(world, target, level)
  if target.mp_smear then return false, "a smear campaign against them is running already" end
  -- (sabotage.daily ends it.)
  target.mp_smear = {share = SMEAR_SHARE[level],
      until_month = world.game_date:monthOfGame() + SMEAR_MONTHS[level]}
  log(string.format("smear campaign against hospital %d until month %d", world:getHospitalIndex(target),
      target.mp_smear.until_month))
  MultiplayerSession.tellPlayer(world, target, S().sabotage_smear_notice:format(SMEAR_MONTHS[level]))
  return true
end

--! The hospital a new patient goes to instead of `hospital`, if a smear
--! campaign against it turns them away (nil: they come). Draws a shared
--! random number only while a campaign runs, the same on every peer.
function sabotage.smearRedirect(world, hospital)
  local smear = hospital.mp_smear
  if not smear or math.random() >= smear.share then return nil end
  local players = world.mp_coop.players
  local start = world:getHospitalIndex(hospital) or 1
  for step = 1, players - 1 do
    local other = world.hospitals[(start - 1 + step) % players + 1]
    if other and other ~= hospital and other.opened and not other.mp_place then
      smear.sent = (smear.sent or 0) + 1
      return other
    end
  end
  return nil
end

--------------------------------------------------------------------------------
-- Espionage
--------------------------------------------------------------------------------

--! What a spy of `level` can take from `from` for `to`: improvements (drugs
--! and machines) at level 1, discoveries at level 2, either at level 3.
function sabotage.stealable(from, to, level)
  local items = {}
  for _, item in ipairs(MultiplayerSession.shareableResearch(from, to)) do
    local discovery = item.kind == "e"
    if level == 3 or (level == 2) == discovery then items[#items + 1] = item end
  end
  return items
end

--! How many research results a spy of `level` brings back.
function sabotage.spyItems(level)
  return level == 3 and 2 or 1
end

--! Espionage: the buyer gets one (two at level 3) of the rival's research
--! results they lack, those picked (`keys`, ";"-separated, see
--! UIMultiplayerSpy) or else at random (bots); at level 3 the rival loses
--! half the progress towards what they research now.
function sabotage.spy(world, buyer, target, level, keys)
  local items = sabotage.stealable(target, buyer, level)
  if #items == 0 then return false, "they know nothing that you do not" end
  local chosen = {}
  if keys and keys ~= "" then
    local by_key = {}
    for _, item in ipairs(items) do by_key[item.key] = item end
    for key in tostring(keys):gmatch("[^;]+") do
      if by_key[key] and #chosen < sabotage.spyItems(level) then
        chosen[#chosen + 1] = by_key[key]
        by_key[key] = nil
      end
    end
    if #chosen == 0 then return false, "they no longer have what you picked, or you have it" end
  else
    for _ = 1, sabotage.spyItems(level) do
      if #items == 0 then break end
      chosen[#chosen + 1] = table.remove(items, math.random(1, #items))
    end
  end
  local names = {}
  for _, item in ipairs(chosen) do
    MultiplayerSession.applyResearchItem(world, target, buyer, item)
    names[#names + 1] = item.name
  end
  if level == 3 then
    local research = target.research
    for _, info in pairs(research.research_policy) do
      local progress = type(info) == "table" and info.current and research.research_progress[info.current]
      if progress and progress.points then progress.points = math.floor(progress.points / 2) end
    end
  end
  log(string.format("hospital %d spied on hospital %d: %s", world:getHospitalIndex(buyer),
      world:getHospitalIndex(target), table.concat(names, ", ")))
  MultiplayerSession.tellPlayer(world, buyer, S().sabotage_espionage_got:format(table.concat(names, ", ")))
  MultiplayerSession.tellPlayer(world, target,
      level == 3 and S().sabotage_espionage_notice_3 or S().sabotage_espionage_notice)
  return true
end

return sabotage
