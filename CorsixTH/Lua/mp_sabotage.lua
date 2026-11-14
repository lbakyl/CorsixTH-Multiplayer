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
--!  * a litter bomb (the original's network game had them): the buyer plants
--!    it on a corridor of a rival's hospital (the cursor carries it there);
--!    its fuse burns for 16 days, then it throws 15, 25 or 40 pieces of
--!    litter about. The players of that hospital may click it first to pick
--!    it up, but then they must throw it into another rival's hospital: it
--!    cannot be sold, and its fuse burns on in their hands.
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
  litter_bomb = {1000, 2000, 3000}, -- (cheap, it is only a mess: Jan, 2026-11-14)
}
sabotage.KINDS = {"handyman", "epidemic", "emergency", "rats", "headhunter", "boiler", "smear", "espionage",
  "litter_bomb"}

--! The month of the game (1 = the first January) from which each level of
--! each trick can be bought, in every race (Jan, 2026-11-06): the mild ones
--! first, the worst late, all of them by the last month of the first year.
--! No emergency in the first two months. A level with its own schedule
--! (level 7's mp_tricks) can only make a trick wait longer.
sabotage.SCHEDULE = {
  rats = {2, 4, 7},        -- 5, 10, 20 rats
  boiler = {2, 4, 7},      -- shorter or longer repairs
  smear = {3, 5, 8},       -- one to three months of fewer patients
  handyman = {3, 5, 9},    -- idle, litters, wears machines down
  espionage = {3, 6, 9},   -- level 3: the rival loses half its research
  headhunter = {4, 6, 10}, -- a junior, a doctor, a consultant or specialist
  emergency = {3, 6, 11},  -- 3, 6, 10 patients (level 3: maybe undiscovered)
  epidemic = {4, 7, 12},   -- 2, 4, 7 contagious patients
  -- (The litter bomb has no months: every level from the start. Jan,
  -- 2026-11-14, to test all three; level 7 still holds it back to June.)
}

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
-- Litter bomb: the fuse in game hours (ticks; 50 in a day), 16 days, about
-- 45 seconds at Normal speed, shown in the 8 stages of the original's art;
-- the pieces of litter it throws about and how far (tiles), by level.
sabotage.BOMB_FUSE = 800
sabotage.BOMB_LITTER = {15, 25, 40}
sabotage.BOMB_RADIUS = {2, 3, 4}
local MAX_BOMBS = 2       -- ticking in one hospital at once, at most
local BOMB_UNHAPPY = 0.1  -- happiness lost by people right by it (2 tiles)
local FUSE_HISS_EVERY = 25 -- game hours between the hisses of its fuse

local handlers = MultiplayerSession.default_handlers

local function S() return _S.multiplayer_window end

--! The n-th of a list of texts, round and round (a string table: counted
--! with ipairs, as its length may not be what # says).
local function nth_text(list, n)
  local texts = {}
  for _, text in ipairs(list) do texts[#texts + 1] = text end
  if #texts == 0 then return "" end
  return texts[(n - 1) % #texts + 1]
end

local function log(text)
  local session = TheApp and TheApp.mp_session
  if session then session.log(string.format("sabotage (step %d): %s", session.step, text)) end
end

--! What a trick costs `buyer` now: its price, changed on a level with its
--! own trick rules (level 7: the trick of the month, the last and the
--! leader of the race, mp_levels.trickPriceFactor), in whole $100.
function sabotage.price(world, buyer, kind, level)
  local price = sabotage.PRICES[kind][level]
  local factor = corsixth.require("mp_levels").trickPriceFactor(world, buyer, kind)
  if factor == 1 then return price end
  return math.floor(price * factor / 100 + 0.5) * 100
end

--! The month of the game from which a trick of `kind` at `level` can be
--! bought (nil: from the start): sabotage.SCHEDULE, or later on a level
--! with its own trick rules. (A room with tricks=2, the test rooms: every
--! trick from the start, but for the level's own rules.)
function sabotage.unlockMonth(world, kind, level)
  local anytime = world.mp_coop and world.mp_coop.tricks_anytime
  local month = not anytime and (sabotage.SCHEDULE[kind] or {})[level] or nil
  local rules = world.map.level_config.mp_tricks
  if rules then
    local own = rules.unlock and rules.unlock[kind]
    if level == 3 and rules.top_level_month then own = math.max(own or 0, rules.top_level_month) end
    if own then month = math.max(month or 0, own) end
  end
  if month and month <= 1 then return nil end
  return month
end

--! Does this game allow this kind of trick at all (the room's game options)?
--! The rat attack only when the host allowed it (Argus: rats should cost
--! nothing; Jan: an option, off by default, 2026-11-08). (Level 7's trick of
--! the month follows the same rules: levels.trickOfTheMonth, mp_levels.lua.)
function sabotage.allowed(world, kind)
  local coop = world.mp_coop
  if not coop or coop.tricks_off then return false end
  if kind == "rats" and not coop.rats_on then return false end
  return true
end

--! Why the buyer's hospital cannot play this trick on `target` now (nil: it can).
function sabotage.refusal(world, buyer, target, kind, level)
  if not (world.mp_coop and world.mp_coop.competitive) then return "only in a competitive game" end
  if world.mp_coop.tricks_off then return "dirty tricks are off in this game" end
  if not sabotage.allowed(world, kind) then return "that trick is off in this game" end
  local prices = sabotage.PRICES[kind]
  if not prices or not prices[level] then return "no such trick" end
  if not target or target == buyer then return "no such hospital" end
  if not world:mpRivals(buyer, target) then return "they are on your team" end
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
  elseif kind == "litter_bomb" then
    if sabotage.countBombs(world, target) >= MAX_BOMBS then return "they have enough litter bombs already" end
  elseif kind == "emergency" then
    if target.emergency or target.mp_emergency_timer then return "they have an emergency on" end
    if target.epidemic then return "they have an epidemic on" end
    if not target:hasReceptionDesk(true) then return "they have no staffed reception desk" end
    if not target:getHeliportSpawnPosition() then return "they have no helipad" end
  end
  local from = sabotage.unlockMonth(world, kind, level)
  if from and world.game_date:monthOfGame() < from then
    return string.format("not before month %d", from)
  end
  if buyer.balance < sabotage.price(world, buyer, kind, level) then return "not enough money" end
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
  elseif kind == "litter_bomb" then
    -- (Where the cursor put it down: a corridor of that rival.)
    local spot
    spot, why = sabotage.bombSpot(world, buyer, cmd.x, cmd.y)
    if spot and spot ~= target then spot, why = nil, "not that rival's hospital" end
    ok = spot and sabotage.plantBomb(world, buyer, target, tonumber(cmd.x), tonumber(cmd.y), level) and true
  else
    ok, why = sabotage.sendEmergency(world, target, level)
  end
  if not ok then return false, why end
  local price = sabotage.price(world, buyer, kind, level)
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
--! Days an evil handyman works in a hospital before its adviser wonders
--! aloud about him (and again after as many more), so that a player who
--! never looks at their handymen gets a hint (Jan: Argus had no idea).
sabotage.HINT_DAYS = 30

--! An evil handyman's hint is due (every HINT_DAYS he works in a hospital):
--! its adviser wonders aloud, for twice as long as usual, but at most once
--! in HINT_DAYS however many of them are there (Jan: two of them, from two
--! rivals, made it twice a month). The words: the next of a few, the same
--! on every peer.
function sabotage.hint(world, handyman)
  local s = handyman.mp_saboteur
  local hospital = handyman.hospital
  local now = world.game_date
  if hospital.mp_handyman_hint and now < hospital.mp_handyman_hint then return end
  -- (A day short: the same handyman's next hint is HINT_DAYS on, to the hour.)
  hospital.mp_handyman_hint = now:plusDays(sabotage.HINT_DAYS - 1)
  s.hints = (s.hints or 0) + 1
  MultiplayerSession.tellPlayer(world, hospital, nth_text(S().sabotage_handyman_hint, s.hints), 2)
end

function sabotage.tick(handyman)
  local s = handyman.mp_saboteur
  local world = handyman.world
  s.hours = s.hours + 1
  if s.hours >= sabotage.STAY_DAYS[s.level] * 50 then return sabotage.goHome(handyman) end
  if s.hours % (sabotage.HINT_DAYS * 50) == 0 and handyman.hospital then
    sabotage.hint(world, handyman)
  end
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
  target.mp_rat_days = 0
  return true
end

-- Days between reminders while attack rats run about.
sabotage.RAT_REMINDER_DAYS = 14

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
    -- Every two weeks the adviser reminds the player (the attack's notice is
    -- easy to miss: Jan and Argus never saw one), each time in other words.
    local days = (hospital.mp_rat_days or 0) + 1
    hospital.mp_rat_days = days
    if days % sabotage.RAT_REMINDER_DAYS == 0 then
      local n = math.floor(days / sabotage.RAT_REMINDER_DAYS)
      MultiplayerSession.tellPlayer(hospital.world, hospital, nth_text(S().sabotage_rats_reminders, n):format(count))
    end
  else
    hospital.mp_rat_days = nil
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
  -- On the hiring list again, at the top: the list of the hospital that sent
  -- the headhunter (each hospital has its own, World:staffPool).
  local profile = staff.profile
  local to = world.hospitals[by] or hospital
  local pool = world:staffPool(to)[profile.humanoid_class]
  if pool then
    profile.mp_reserved = by and {hospital = by, days = HEADHUNT_RESERVED_DAYS} or nil
    table.insert(pool, 1, profile)
  end
  log(string.format("%s #%s left hospital %d for the hiring list of hospital %d", profile.humanoid_class,
      tostring(staff.mp_id), world:getHospitalIndex(hospital), world:getHospitalIndex(to)))
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
  -- (A poached doctor is on the list of a hospital that has made its list,
  -- the same on every peer; a list made later has none.)
  local pools = {world.available_staff}
  for _, h in ipairs(world.hospitals) do pools[#pools + 1] = h.available_staff end
  for _, lists in ipairs(pools) do
    for _, pool in pairs(lists) do
      for _, profile in ipairs(pool) do
        local reserved = profile.mp_reserved
        if reserved then
          reserved.days = reserved.days - 1
          if reserved.days <= 0 then profile.mp_reserved = nil end
        end
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
--! random number only while a campaign runs, the same on every peer. (In a
--! race of two teams they go to the other team, never to a team mate.)
function sabotage.smearRedirect(world, hospital)
  local smear = hospital.mp_smear
  if not smear or math.random() >= smear.share then return nil end
  local players = world.mp_coop.players
  local start = world:getHospitalIndex(hospital) or 1
  for step = 1, players - 1 do
    local other = world.hospitals[(start - 1 + step) % players + 1]
    if other and world:mpRivals(hospital, other) and other.opened and not other.mp_place then
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
    -- (A discovery copied earns no breakthrough bonus: mp_levels.lua.)
    if item.kind == "e" then
      buyer.mp_spied = buyer.mp_spied or {}
      buyer.mp_spied[item.object.id] = true
    end
    -- (Names are localised strings: table.concat takes plain ones only.)
    names[#names + 1] = tostring(item.name):gsub("^<LocalisedString> Current value:", "")
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

--------------------------------------------------------------------------------
-- Litter bomb
--------------------------------------------------------------------------------

--! The lit litter bombs on the floor of `hospital`.
function sabotage.countBombs(world, hospital)
  local n = 0
  for _, e in ipairs(world.entities) do
    local b = e.mp_bomb
    if b and not b.gone and e.tile_x and e.hospital == hospital then n = n + 1 end
  end
  return n
end

--! The bomb `hospital` holds (picked up, to be thrown on), or nil.
function sabotage.heldBomb(world, hospital)
  local index = world:getHospitalIndex(hospital)
  for _, e in ipairs(world.entities) do
    local b = e.mp_bomb
    if b and not b.gone and b.held == index then return e end
  end
end

--! The hospital that a bomb `thrower` plants (or throws) onto tile (x, y)
--! lands in, or nil and why not: a corridor inside a rival's building,
--! nothing standing there but litter, no other bomb on it, and not more
--! than MAX_BOMBS in that hospital.
function sabotage.bombSpot(world, thrower, x, y)
  x, y = tonumber(x), tonumber(y)
  if not x or not y or x % 1 ~= 0 or y % 1 ~= 0 or not world:isOnMap(x, y) then
    return nil, "no such spot"
  end
  local target
  for _, h in ipairs(world.hospitals) do
    if h:isInHospital(x, y) then
      target = h
      break
    end
  end
  if not target then return nil, "not inside a hospital" end
  if not world:mpRivals(thrower, target) then return nil, "not a rival's hospital" end
  if target.mp_place then return nil, "they are out of the race" end
  if not target.opened or target.mp_opening then return nil, "their hospital is not open yet" end
  if not world.map.th:getCellFlags(x, y).passable or world:getRoom(x, y) then return nil, "not on a corridor" end
  for _, obj in ipairs(world:getObjects(x, y) or {}) do
    if not (obj.object_type and obj.object_type.id == "litter") then return nil, "something stands there" end
  end
  for _, e in ipairs(world.entities) do
    local b = e.mp_bomb
    if b and not b.gone and e.tile_x == x and e.tile_y == y then return nil, "a bomb is there already" end
  end
  if sabotage.countBombs(world, target) >= MAX_BOMBS then return nil, "they have enough litter bombs already" end
  return target
end

--! The fuse stage of a bomb (1: all of the fuse left, 8: nearly none).
function sabotage.bombStage(bomb)
  local stages = #bomb.object_type.fuse_animations
  local burnt = sabotage.BOMB_FUSE - bomb.mp_bomb.fuse
  return math.max(1, math.min(stages, math.floor(burnt * stages / sabotage.BOMB_FUSE) + 1))
end

--! Put a lit bomb down at (x, y) in `target`: a new one of `level` (bought
--! by `thrower`), or `bomb`, picked up somewhere and thrown on (its fuse
--! burns on). The players of that hospital hear the warning; who it came
--! from they are not told.
function sabotage.plantBomb(world, thrower, target, x, y, level, bomb)
  if bomb then
    bomb.hospital = target
    bomb.mp_bomb.held = nil
    bomb:setTile(x, y)
  else
    bomb = world:newObject("litter_bomb", x, y, nil, nil, target)
    bomb.mp_bomb = {level = level, fuse = sabotage.BOMB_FUSE, hours = 0}
  end
  local b = bomb.mp_bomb
  b.from = world:getHospitalIndex(thrower)
  b.throws = (b.throws or 0) + 1
  bomb:showFuse(sabotage.bombStage(bomb))
  bomb:playSound("ignite2.wav")
  log(string.format("hospital %d put litter bomb #%d (level %d, %d hours left) at %d,%d in hospital %d",
      b.from, bomb.mp_id, b.level, b.fuse, x, y, world:getHospitalIndex(target)))
  MultiplayerSession.tellPlayer(world, target, S().sabotage_bomb_notice, true)
  local ui = world.ui
  if ui and ui.hospital == target and ui.playAnnouncement then
    ui:playAnnouncement("rand040.wav", _G["AnnouncementPriority"].High)
  end
  return bomb
end

--! The players of `hospital` pick up `bomb` from its floor: it is theirs to
--! throw on (sabotage.heldBomb; the window to throw it in opens by itself,
--! sabotage.syncBombWindow), and its fuse burns on.
function sabotage.pickBomb(world, bomb, hospital)
  local b = bomb.mp_bomb
  bomb:setTile(nil)
  bomb.hospital = hospital
  b.held = world:getHospitalIndex(hospital)
  log(string.format("hospital %d picked up litter bomb #%d (%d hours left)", b.held, bomb.mp_id, b.fuse))
  MultiplayerSession.tellPlayer(world, hospital, S().sabotage_bomb_picked, true)
  -- (Whoever put it there sees it gone, and is told why. Argus: it just
  -- vanished.)
  local from = world.hospitals[b.from or 0]
  if from and from ~= hospital then
    MultiplayerSession.tellPlayer(world, from, S().sabotage_bomb_found:format(hospital.name))
  end
end

--! Pick up a litter bomb from one's own floor: {bomb}.
function handlers.litter_bomb_pick(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local bomb = MultiplayerSession.entityOf(world, cmd.bomb, rawget(_G, "LitterBomb"))
  local b = bomb and bomb.mp_bomb
  if not b or b.gone or b.held or not bomb.tile_x then return false, "no such bomb" end
  if bomb.hospital ~= hospital then return false, "not in your hospital" end
  if sabotage.heldBomb(world, hospital) then return false, "you hold a bomb already" end
  sabotage.pickBomb(world, bomb, hospital)
  return true
end

--! Throw the bomb one holds onto a corridor of a rival's hospital: {bomb, x, y}.
function handlers.litter_bomb_throw(world, cmd)
  local hospital = world.hospitals[cmd.hospital or 1]
  local bomb = MultiplayerSession.entityOf(world, cmd.bomb, rawget(_G, "LitterBomb"))
  local b = bomb and bomb.mp_bomb
  if not b or b.gone or b.held ~= world:getHospitalIndex(hospital) then return false, "you hold no such bomb" end
  local target, why = sabotage.bombSpot(world, hospital, cmd.x, cmd.y)
  if not target then return false, why end
  sabotage.plantBomb(world, hospital, target, tonumber(cmd.x), tonumber(cmd.y), nil, bomb)
  return true
end

--! One game hour of a lit bomb (LitterBomb:tick): its fuse burns, on the
--! floor or in someone's hands; its floor taken from under it (a room built
--! there, the plot sold) sets it off at once.
function sabotage.bombTick(bomb)
  local b = bomb.mp_bomb
  if not b or b.gone then return end
  local world = bomb.world
  b.fuse = b.fuse - 1
  b.hours = (b.hours or 0) + 1
  local x, y = bomb.tile_x, bomb.tile_y
  if x then
    if not bomb.hospital:isInHospital(x, y) or world:getRoom(x, y) then b.fuse = 0 end
    if b.fuse > 0 and b.hours % FUSE_HISS_EVERY == 0 then bomb:playSound("fuse.wav") end
  end
  if b.fuse <= 0 then
    sabotage.bombGoesOff(world, bomb)
  else
    bomb:showFuse(sabotage.bombStage(bomb))
  end
end

--! Litter thrown about by a bomb of `level` gone off at (x, y): pieces on
--! corridor tiles of `hospital` around it (nothing standing on them), at
--! random (the game's random: the same on every peer). How many it threw.
function sabotage.scatterLitter(world, hospital, x, y, level)
  local radius = sabotage.BOMB_RADIUS[level] or 2
  local th = world.map.th
  local spots = {}
  for dy = -radius, radius do
    for dx = -radius, radius do
      local tx, ty = x + dx, y + dy
      if dx * dx + dy * dy <= radius * radius + radius and world:isOnMap(tx, ty) and
          hospital:isInHospital(tx, ty) and th:getCellFlags(tx, ty).passable and not world:getRoom(tx, ty) then
        local free = true
        for _, obj in ipairs(world:getObjects(tx, ty) or {}) do
          if not (obj.object_type and obj.object_type.id == "litter") then free = false end
        end
        if free then spots[#spots + 1] = {tx, ty} end
      end
    end
  end
  local count = 0
  for i = 1, math.min(sabotage.BOMB_LITTER[level] or 15, #spots) do
    local j = math.random(i, #spots)
    spots[i], spots[j] = spots[j], spots[i]
    if world:newLitter(math.random(1, 4), spots[i][1], spots[i][2], math.random(0, 1)) then count = count + 1 end
  end
  return count
end

--! The fuse has burnt down: litter all around where the bomb is (in the
--! hands of a hospital that held it too long: on a corridor of its own),
--! people right by it upset, and the word to that hospital and to whoever
--! put it there.
function sabotage.bombGoesOff(world, bomb)
  local b = bomb.mp_bomb
  b.gone = true
  local hospital = bomb.hospital
  local in_hands = not bomb.tile_x
  local x, y = bomb.tile_x, bomb.tile_y
  if in_hands then
    x, y = sabotage.corridorTile(world, hospital)
    if x then bomb:setTile(x, y) end
  end
  if x then bomb:playSound("explode.wav") end
  world:destroyEntity(bomb)
  local pieces = 0
  if x then
    pieces = sabotage.scatterLitter(world, hospital, x, y, b.level)
    local Humanoid = _G["Humanoid"]
    for _, e in ipairs(world.entities) do
      if class.is(e, Humanoid) and e.tile_x and e.hospital == hospital and
          math.abs(e.tile_x - x) <= 2 and math.abs(e.tile_y - y) <= 2 then
        e:changeAttribute("happiness", -BOMB_UNHAPPY)
      end
    end
  end
  local index = world:getHospitalIndex(hospital)
  log(string.format("litter bomb #%d went off in hospital %d%s at %s,%s: %d pieces of litter",
      bomb.mp_id, index, in_hands and " (in its hands)" or "", tostring(x), tostring(y), pieces))
  MultiplayerSession.tellPlayer(world, hospital, in_hands and S().sabotage_bomb_in_hands or S().sabotage_bomb_blast)
  local from = world.hospitals[b.from or 0]
  if from and from ~= hospital then
    MultiplayerSession.tellPlayer(world, from, S().sabotage_bomb_blast_rival:format(hospital.name))
  end
  local ui = world.ui
  if x and ui and ui.hospital == hospital and ui.shakeBriefly then ui:shakeBriefly(0.3, 700) end
end

--! This player's window to throw the bomb their hospital holds: open while
--! it holds one (again after a load or a repair), closed after (after every
--! step, MultiplayerSession:tickAuction's neighbour).
function sabotage.syncBombWindow(session, world)
  local ui = world and world.ui
  local class_ = rawget(_G, "UIMultiplayerLitterBomb")
  if session.observer or session.abstains or not ui or not class_ or not ui.hospital then return end
  local bomb = sabotage.heldBomb(world, ui.hospital)
  local window = ui:getWindow(class_)
  if bomb then
    if not window or window.bomb ~= bomb then
      if window then window:close() end
      ui:addWindow(class_(ui, {bomb = bomb}))
    end
  elseif window and window.bomb then
    window:close()
  end
end

return sabotage
