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
--! Every purchase is the lockstep command `sabotage` {trick, level, to}; the
--! rival is not told who sent an epidemic or an emergency.

local sabotage = {}

--! Prices by kind and level.
sabotage.PRICES = {
  handyman = {5000, 12500, 20000},
  epidemic = {6000, 12000, 20000},
  emergency = {5000, 10000, 18000},
  rats = {4000, 9000, 15000},
}
sabotage.KINDS = {"handyman", "epidemic", "emergency", "rats"}

-- Evil handymen at once in one hospital, at most.
local MAX_HANDYMEN = 3
-- Contagious patients sent, and emergency patients, by level.
local EPIDEMIC_PATIENTS = {2, 4, 7}
local EMERGENCY_PATIENTS = {3, 6, 10}
local RATS = {5, 10, 20}
local MAX_RATS = 30 -- attack rats alive in one hospital, at most
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
local RAT_DAYS = 60

--! Each day: every attack rat still alive costs its hospital a reputation
--! point (from Hospital:onEndDay). After RAT_DAYS the attack wears off.
function sabotage.dailyRats(hospital)
  for _, entity in ipairs(hospital.world.entities) do
    if entity.mp_attack_rat and entity.hospital == hospital then
      entity.mp_attack_days = (entity.mp_attack_days or 0) + 1
      if entity.mp_attack_days > RAT_DAYS then entity.mp_attack_rat = nil end
    end
  end
  local count = sabotage.countRats(hospital.world, hospital)
  if count > 0 then
    hospital:unconditionalChangeReputation(-count)
    if hospital.world.game_date:dayOfMonth() == 1 then
      MultiplayerSession.tellPlayer(hospital.world, hospital, S().sabotage_rats_reminder:format(count))
    end
  end
end

return sabotage
