-- The bot's hospital manager (scripts/multiplayer/bot.lua): instead of a
-- fixed building order it looks at its hospital every game day, as a player
-- looks at the screen, and does what is needed most.
--
--  * It reads the hospital (Manager:assess): patients and the rooms their
--    diseases need (built or not), queues per room type, staff and their
--    tiredness, reception, litter, worn machines, thirst, warmth, toilets,
--    money, loan, reputation and how far it is from the level's goals.
--  * Every possible project (a room, a second room of a busy type, a member
--    of staff, a desk, benches, a drinks machine, radiators, land) gets a
--    score from those needs (Manager:projects); the best one it can afford
--    is done, one every one to three game days, like a person would.
--  * Smaller things happen on their own: a handyman to a machine half worn,
--    heating, prices once a month, loans, research aimed at a disease it
--    cannot treat, the faxes about patients, VIPs and epidemics.
--  * Machines are looked after: a new machine for one worn down by its
--    repairs, a room destroyed by an exploding machine built again where it
--    stands, land bought (borrowing for it) when there is no floor left.
--  * In a race it throws out evil handymen and shoots attack rats (after
--    a week or two, as a busy player would), more handymen for a broken
--    boiler, a word to whoever
--    played the trick; it aims its own dirty tricks at whoever leads.
--  * A research room with two desks, a researcher placed in it, and its
--    research shared for free with its allies when they lack it.
--  * A plan from a language model (Manager:applyPlan, through the server)
--    can raise the scores of some projects (never prices: bots keep them);
--    the manager still checks everything and plays on without it. The
--    report for it starts with the hospital's problems (Manager:problems),
--    and its most urgent choices come before the manager's own ideas.
--
-- Like the rest of the bot it never uses the game's random numbers.

local M = {}
M.__index = M

-- Rooms it leaves alone (none: the training room is run by M:training).
local SKIP_ROOMS = {}
-- Doctors with a skill a room needs.
local SPECIALISTS = {Psychiatrist = true, Surgeon = true, Researcher = true}
-- Kept in the bank for wages and repairs.
local RESERVE = 3000
-- A patient it has no room for (and cannot build one now): this share is
-- referred to a team mate with the rooms, the rest sent home; and at most one
-- referral to the same hospital in this many game days (the person there
-- gets a fax for each one, Jan on eu2).
local REFER_SHARE = 0.5
local REFER_GAP_DAYS = 3
-- A room nobody has used for this many game days (about 5 months) is taken
-- down for its floor (Jan, eu2), and none of the kind is built again for
-- REMOVED_REBUILD_DAYS unless patients keep asking for it. While the level's
-- hospital value is a goal not met yet: only after VACANT_DAYS_VALUE (a
-- year) and with no space left (M:projects, M:outOfSpace).
local VACANT_DAYS, VACANT_DAYS_VALUE = 150, 360
local REMOVED_REBUILD_DAYS = 180
-- Rooms used by staff, not patients: used while staff are in them.
local STAFF_ROOMS = {staff_room = true, training = true, research = true}
-- Never taken down for being empty (a hospital without them is no hospital).
local KEEP_ROOMS = {gp = true}
-- Rooms worth a second (third) copy when their queues grow.
local COPIES = {gp = 6, pharmacy = 2, general_diag = 3, psych = 2, ward = 2, toilets = 3, staff_room = 2,
    cardiogram = 2, scanner = 2, ultrascan = 2, blood_machine = 2, x_ray = 2, inflation = 2,
    fracture_clinic = 2, hair_restoration = 2, slack_tongue = 2, electrolysis = 2, dna_fixer = 1,
    jelly_vat = 1, decontamination = 1, operating_theatre = 2, research = 1}
-- Queue per room above which another room of the type helps.
local BUSY_QUEUE = 5
-- The model's plan names a room the hospital has: another one only while at
-- least this many patients per room wait for those (M.planRoomWanted).
local PLAN_COPY_QUEUE = 2
-- With this much in the bank, shorter queues are worth another room and one
-- more copy of a type is allowed (the money is no use in the bank: the bots
-- of 2026-11-03 ended two years with $100k-150k and a falling reputation).
local RICH = 40000
-- A project this urgent may be paid with a loan (a repair, land, a machine).
local URGENT = 20
-- Game days before it deals with a dirty trick (an evil handyman, rats): a
-- player notices them only after a while.
local NOTICE_DAYS = {10, 18}
-- Game days between research offers to the same ally.
local SHARE_DAYS = 21
-- Game days between specialists sent to the same ally (of one kind), and
-- between asking the allies for one (an emergency: sooner).
-- (Asks: the same kind at most once in 3 months, Jan 2026-11-12; an
-- emergency sooner, it is over in days.)
local GIVE_DAYS, ASK_DAYS, ASK_DAYS_EMERGENCY = 20, 90, 7
-- Game days a specialist must be missing (a room waits for one, or cannot work
-- without one) before the allies are asked for one (an emergency: sooner), and
-- before an allied bot lends one although the ally could hire (Jan, 2026-11-07:
-- no bot ever asked).
local LACK_DAYS, LACK_EMERGENCY_DAYS = 10, 3
-- Money left after a plot bought for the hospital's value (not for room).
local VALUE_LAND_SPARE = 15000
-- Game days between warnings that an opponent can win (4 months).
local RIVAL_WARN_DAYS = 120
-- A failing hospital is looked at from the second game year (Jan, 2026-11-08:
-- the thresholds stay, "with the exception of year 1": no review by the
-- advisor and no ask to the allies before month 13 of the game), and at most
-- every RESCUE_DAYS (3 months).
local RESCUE_FROM_MONTH, RESCUE_DAYS = 13, 90
-- Waiting areas (Jan, 2026-11-03): by each room's door and the reception
-- benches for the queue, a plant and a radiator, and a drinks machine by
-- every third, within WAITING_R tiles. Not by rooms nobody queues for.
local WAITING = {bench = true, plant = true, radiator = true, drinks_machine = true}
-- A drinks machine serves the waiting places this many tiles around it.
local DRINKS_R = 8
local WAITING_R = 4
local NO_WAITING = {staff_room = true, research = true, training = true}
-- Rooms that earn the most: repaired and looked after first.
local EARNERS = {operating_theatre = 25, scanner = 10, x_ray = 8, cardiogram = 8, ultrascan = 8,
    fracture_clinic = 8, inflation = 8, dna_fixer = 8, hair_restoration = 6, slack_tongue = 6, electrolysis = 6,
    jelly_vat = 6, decontamination = 6, blood_machine = 6}
-- The score a team mate's wish adds: before the bot's own ideas, after the
-- basics of an opening hospital (90 and more).
local WISH = 50
-- The size a bot gives a room (square). A room for one doctor or one machine
-- gets the game's smallest (Jan, 2026-11-11: bots' rooms were too large and
-- the land was gone early; a GP's office of 4x4 instead of 5x5 is a third
-- less floor). One more than the smallest only where more floor serves more
-- people: beds, seats, loos, desks, lecture chairs. Bot:layoutSpot puts a
-- room snugly against walls and other rooms, so floor is left for the GP's
-- offices a busy hospital needs later (a 3-year level 7 race: land gone by
-- month 7, GP queues of 60 to 80). Extras that do not fit are sold.
-- An X-ray room one more too: at its smallest, 6 x 6, the radiation shield
-- found no place beside the machine in 12 of 16 rooms (a 2-year race on
-- level 6, 2026-11-12).
local SIZES = {ward = 7, staff_room = 6, toilets = 5, research = 6, training = 5, x_ray = 7}
-- The training room: lecture chairs (3 to 6 in all, chosen once per bot; a chair
-- is one student at a time, and more than 3 students at once learn slower
-- each: 2/(n-1) of the rate), the days between reviews of the teacher (a
-- year, first in the 2nd month) and, from the 3rd year, of the staff. Until
-- the 3rd year its chairs are kept full, with students hired while the bank
-- holds TRAIN_HIRE_FLOOR; from then on new doctors are juniors trained first
-- (M:training).
local CHAIRS_MIN, CHAIRS_MAX = 3, 6
local TEACHER_REVIEW_DAYS, FIRST_TEACHER_REVIEW = 360, 31
local STAFF_REVIEW_FROM, STAFF_REVIEW_DAYS = tonumber(os.getenv("MP_BOT_STAFF_REVIEW_FROM") or "") or 720, 30
local TRAIN_HIRE_FLOOR = 10000
-- What a player puts into a new room besides what it needs: warmth, a
-- plant, a bin; comfort in the staff room; more toilets and beds.
local EXTRAS = {
  staff_room = {sofa = 1, tv = 1, pool_table = 1, radiator = 1, plant = 1},
  toilets = {loo = 1, sink = 1, radiator = 1},
  -- (Four beds in all: Jan, 2026-11-11.)
  ward = {bed = 3, radiator = 1, plant = 1},
  psych = {radiator = 1, plant = 1, bookcase = 1},
  -- (A second desk: room for a second researcher.)
  research = {desk = 1, radiator = 1, plant = 1},
  -- (Three students at a time.)
  training = {lecture_chair = 2, radiator = 1},
}
local DEFAULT_EXTRAS = {radiator = 1, plant = 1, bin = 1}

--! The smallest size of a room type (the game's minimum, the staff room's 5).
local function smallest_size(id)
  for _, rt in ipairs(TheApp.rooms) do
    if rt.id == id then return math.max(rt.minimum_size or 4, id == "staff_room" and 5 or 0) end
  end
end

--! The planned size of a room type (SIZES, else the smallest).
-- (A bot set to research hard, Bot.research_heavy: a bigger room with four
-- desks, a researcher at each. Jan's test of 2026-11-12.)
local function SIZES_OF(id)
  if id == "research" and M.research_heavy then return 8 end
  -- (A hard bot: three desks, three researchers; a 7 x 7 room holds them.)
  if id == "research" and M.hard then return 7 end
  return SIZES[id] or smallest_size(id)
end

-- A hard bot's research in its first two years (Jan, 2026-11-12): mostly
-- cures (the machines that earn), then diagnosis, a share each for the rest;
-- once every cure machine is found, or after two years, the game's even
-- split again. (Percent of the research; the areas are the game's.)
local HARD_RESEARCH = {cure = 70, diagnosis = 27, drugs = 1, improvements = 1, specialisation = 1}
local EVEN_RESEARCH = {cure = 20, diagnosis = 20, drugs = 20, improvements = 20, specialisation = 20}
local HARD_RESEARCH_DAYS = 720
M.HARD_RESEARCH, M.EVEN_RESEARCH, M.HARD_RESEARCH_DAYS = HARD_RESEARCH, EVEN_RESEARCH, HARD_RESEARCH_DAYS

--! The research shares a bot wants now (area -> percent), or nil: leave them.
--!param policy the hospital's research_policy; day: game day; hard: a hard bot
function M.researchWanted(policy, day, hard)
  if not hard or not policy then return nil end
  local cure_left = policy.cure and policy.cure.current
  if day < HARD_RESEARCH_DAYS and cure_left then return HARD_RESEARCH end
  return EVEN_RESEARCH
end

--! Set the research shares (lowered ones first, so the raised ones have
--! room), a few days apart at most once.
function M:researchPolicy(s)
  local policy = s.hosp.research and s.hosp.research.research_policy
  local want = M.researchWanted(policy, s.day, M.hard)
  if not want or (self.research_set_day and s.day - self.research_set_day < 7) then return end
  local lower, raise = {}, {}
  for _, area in ipairs({"cure", "diagnosis", "drugs", "improvements", "specialisation"}) do
    local now = policy[area] and policy[area].frac
    local target = want[area]
    -- (An area with nothing left to research stays as the game has it.)
    if now and target and now ~= target and (target < now or policy[area].current) then
      if target < now then lower[#lower + 1] = {area, target} else raise[#raise + 1] = {area, target} end
    end
  end
  if #lower + #raise == 0 then return end
  self.research_set_day = s.day
  local parts = {}
  for _, list in ipairs({lower, raise}) do
    for _, a in ipairs(list) do
      self:issue({kind = "research_frac", area = a[1], frac = a[2]})
      parts[#parts + 1] = a[1] .. " " .. a[2] .. "%"
    end
  end
  self:note(string.format("day %d: research %s", s.day, table.concat(parts, ", ")))
end

--! The size and extras for a new room of this type.
--! May the model's plan add a room of type `id` (n built, q patients
--! waiting for them)? The first one; another one within COPIES only while
--! patients wait for those there are (Jan, 2026-11-12: Bot Edna built a
--! second ward nobody waited for, because her plans kept naming one).
function M.planRoomWanted(id, n, q)
  if n == 0 then return true end
  return n < (COPIES[id] or 1) and q / n >= PLAN_COPY_QUEUE
end

function M.roomPlan(id)
  -- What an expert player builds (bot_learned.lua, learnt from their saved
  -- games): their size, and what they put in besides what the room needs
  -- (Argus: radiators by the room's size, no plants or bins).
  local recipe = M.learned and M.Learned and M.Learned.recipe(M.learned, id, SIZES_OF(id))
  if recipe then
    local rt = TheApp and TheApp.rooms and TheApp.rooms[id]
    return math.max(recipe.w, recipe.d), M.Learned.extras(recipe.objects, rt and rt.objects_needed)
  end
  local extras = EXTRAS[id] or DEFAULT_EXTRAS
  local copy = {}
  for k, v in pairs(extras) do copy[k] = v end
  -- (No plant: the floor is for desks.)
  if id == "research" and M.research_heavy then copy.desk, copy.plant = 3, nil end
  if id == "research" and M.hard and not M.research_heavy then copy.desk, copy.plant = 2, nil end
  return SIZES_OF(id), copy
end

--! A manager for the bot `bot` (its helpers: drawRoom, hireCategory,
--! buyCorridor, buyPlot, canHire, roomPlan, roomCost, playerOfHospital,
--! say, later, gameDay) and `ctx` = {log, rand, pick, sabotage, lines, typing}.
function M.new(bot, ctx)
  local self = setmetatable({}, M)
  self.bot, self.log, self.rand, self.pick = bot, ctx.log, ctx.rand, ctx.pick
  self.sabotage, self.lines, self.typing = ctx.sabotage, ctx.lines, ctx.typing
  self.fill_in = ctx.fill
  self.demand = {}         -- room id -> patients who needed it lately (decaying)
  self.next_project = 0    -- game day of the next project
  self.next_daily = -1
  self.next_monthly = -1
  self.called = {}         -- machine entity id -> day a handyman was sent
  self.answered = {}       -- message number -> true
  self.referred_day = {}   -- hospital index -> game day this hospital last referred a patient there
  self.room_used = {}      -- room id -> last game day somebody used it (a patient; staff in staff-only rooms)
  self.removed_type = {}   -- room type id -> game day a room of it was removed for being empty
  self.noticed = {}        -- saboteur entity id -> day it was noticed
  self.boost = {}          -- project key -> extra score from the model's plan
  self.wishes = {}         -- project key -> {until = last game day, had = how many then} (a team mate's wish)
  self.sent_to_lab = {}    -- staff mp_id -> game day it was sent into the research room
  self.hands_off = {}      -- project key -> last game day a team mate keeps it for themselves
  self.failed = {}         -- project key -> day it failed (try again later)
  self.history = {}        -- what it did lately (for the model's report and chat)
  self.left = {}           -- why patients left: cured, kicked, fed_up, over_priced
  self.lost = {}           -- disease id -> patients who left uncured
  self.no_space = {}       -- project key -> last game day it found no floor for it
  self.tricks = {}         -- kind of dirty trick -> game day noticed (from the adviser)
  self.shared = {}         -- ally hospital index -> {item key -> game day offered}
  self.gave = {}           -- "<ally index>:<category>" -> game day a specialist was sent
  self.asked_for = {}      -- category -> game day the allies were asked for one
  self.lacking = {}        -- specialist category -> game day it was first missing for a room
  self.ally_lack = {}      -- "<ally index>:<category>" -> game day an ally was first missing one
  self.blocked_spec = {}   -- category -> {day, room}: a room patients need waits for this specialist
  self.spent = nil         -- its last big spending, {key, cost, day} (M:noteSpent)
  self.plot_bought = {}    -- plot -> game day it asked to buy it itself (Bot:buyPlot)
  self.plot_sent = {}      -- plot -> game day it offered it to an ally (M:plotRequest)
  self.research_need = {}  -- room id -> game day a patient needed it and it was not discovered
  self.player_asked = {}   -- hospital index -> game day it asked them for help (M:askForNeeds)
  self.rival_bought = {}   -- rival hospital index -> game day it bought research from them
  self.rival_staff_asked = {} -- category -> game day a rival was asked for one
  self.s = nil             -- the last assessment (M:assess), for answers between days
  M.research_heavy = bot.research_heavy or false
  -- (What it learnt from experts, bot_learned.lua, while it is a hard bot:
  -- Bot:applyLevel sets M.learned.)
  M.learned, M.Learned = bot.expert_data, ctx.learned_module
  return self
end

function M:note(text)
  self.log(text)
  self.history[#self.history + 1] = text
  if #self.history > 12 then table.remove(self.history, 1) end
end

-- Spending worth telling an ally who asks for money where it went (Jan,
-- 2026-11-08): this much or more, within SPENT_DAYS game days.
local SPENT_NOTE, SPENT_DAYS = 2000, 90

--! Note what the bot spent money on (`key`: a project key, "loan" for a
--! repayment, "gift:<name>" for money sent to an ally, "trick"), if it was
--! big enough to be worth a word (M:spentWords).
function M:noteSpent(key, cost)
  if (cost or 0) >= SPENT_NOTE then
    self.spent = {key = key, cost = math.floor(cost), day = self.bot:gameDay()}
  end
end

--------------------------------------------------------------------------------
-- Reading the hospital
--------------------------------------------------------------------------------

local function avg(sum, n) return n > 0 and sum / n or 0 end

--! What a player would see on the screen and in the reports, as numbers.
function M:assess()
  local bot, world = self.bot, self.bot.world
  local hosp = world.ui.hospital
  local s = {hosp = hosp, day = bot:gameDay(), month = world:date():monthOfGame()}

  -- Rooms: built per type, queues, unstaffed.
  s.rooms, s.queue, s.unstaffed, s.room_count, s.crashed, s.building = {}, {}, {}, 0, {}, {}
  s.doors = {} -- where patients wait: {key, x, y, queue, max benches}
  for _, r in pairs(world.rooms) do
    -- (A room destroyed by an exploding machine: out of use, still there.)
    if r.hospital == hosp and r.crashed then s.crashed[#s.crashed + 1] = r end
    -- (Drawn, being furnished or finished but not open yet: no second one.)
    if r.hospital == hosp and not r.crashed and not r.is_active then
      s.building[r.room_info.id] = (s.building[r.room_info.id] or 0) + 1
    end
    if r.hospital == hosp and r.is_active then
      local id = r.room_info.id
      s.rooms[id] = (s.rooms[id] or 0) + 1
      s.room_count = s.room_count + 1
      local q = r.door and r.door.queue
      s.queue[id] = (s.queue[id] or 0) + (q and q:reportedSize() or 0)
      if r.door and r.door.tile_x and not NO_WAITING[id] then
        s.doors[#s.doors + 1] = {key = "room" .. r.id, x = r.door.tile_x, y = r.door.tile_y,
            queue = q and q:reportedSize() or 0, max = 4}
      end
      local crit = r.getRequiredStaffCriteria and r:getRequiredStaffCriteria()
      if crit and next(crit) and not r:testStaffCriteria(crit) then
        s.unstaffed[id] = (s.unstaffed[id] or 0) + 1
      end
    end
  end

  -- Patients: what their diseases need, comfort.
  local need = {}
  -- Diagnosed patients in the hospital now, by the treatment room they wait
  -- for and it does not have (M:projects builds it soon).
  s.waiting_for = {}
  local thirst, warm, toilet, happy, n = 0, 0, 0, 0, 0
  s.patients, s.cold, s.hot = 0, 0, 0
  for _, p in ipairs(hosp.patients or {}) do
    if p.tile_x and not p.going_home and not p.dead and p.disease then
      s.patients = s.patients + 1
      local a = p.attributes or {}
      thirst, toilet, happy = thirst + (a.thirst or 0), toilet + (a.toilet_need or 0), happy + (a.happiness or 0.5)
      local w = a.warmth or 0.5
      warm = warm + w
      if w < 0.25 then s.cold = s.cold + 1 elseif w > 0.75 then s.hot = s.hot + 1 end
      n = n + 1
      local d = p.disease
      if p.diagnosed then
        for _, room in ipairs(d.treatment_rooms or {}) do
          if not s.rooms[room] then
            need[room] = (need[room] or 0) + 1
            s.waiting_for[room] = (s.waiting_for[room] or 0) + 1
          end
        end
      else
        for _, room in ipairs(d.diagnosis_rooms or {}) do
          if not s.rooms[room] then need[room] = (need[room] or 0) + 0.25 end
        end
        -- (Undiagnosed patients will need the treatment room too.)
        for _, room in ipairs(d.treatment_rooms or {}) do
          if not s.rooms[room] then need[room] = (need[room] or 0) + 0.4 end
        end
      end
    end
  end
  s.thirst, s.warmth, s.toilet, s.happiness = avg(thirst, n), avg(warm, n), avg(toilet, n), avg(happy, n)
  -- Demand decays, so a room asked for long ago counts less than today's.
  for room, v in pairs(self.demand) do self.demand[room] = v * 0.9 end
  for room, v in pairs(need) do self.demand[room] = (self.demand[room] or 0) + v end
  for room in pairs(s.rooms) do self.demand[room] = nil end

  -- Staff.
  s.staff, s.fatigue, s.staff_happy = {}, 0, 0
  local sn = 0
  for _, st in ipairs(hosp.staff) do
    if not st.fired then
      local c = st.humanoid_class
      s.staff[c] = (s.staff[c] or 0) + 1
      if c ~= "Receptionist" and c ~= "Handyman" then
        s.fatigue = s.fatigue + ((st.attributes and st.attributes.fatigue) or 0)
        s.staff_happy = s.staff_happy + ((st.attributes and st.attributes.happiness) or 0.5)
        sn = sn + 1
      end
    end
  end
  s.fatigue, s.staff_happy = avg(s.fatigue, sn), avg(s.staff_happy, sn)

  -- An emergency on (accepted, or one a rival sent): its disease, the rooms
  -- that cure it and the days left (Agnes, 2026-11-06, took 30 days to hire
  -- the second surgeon for her emergency: nothing told her it was missing).
  s.emergency = nil
  local em = hosp.emergency
  local em_rooms = M.emergencyRooms(world, hosp)
  if em_rooms then
    local t = hosp.mp_emergency_timer
    local days
    if t and t.tick_rate and Date and Date.hoursPerDay then
      days = math.max(0, math.floor((t.open_timer + 1) * t.tick_rate / Date.hoursPerDay()))
    end
    s.emergency = {disease = em.disease.id, name = em.disease.name, victims = em.victims or 0,
        cured = em.cured_emergency_patients or 0, killed = em.killed_emergency_patients or 0,
        rooms = em_rooms, days = days}
    if self.noted_emergency ~= em then
      self.noted_emergency = em
      self:note(string.format("day %d: emergency on: %d %s, cured in %s", s.day, s.emergency.victims,
          s.emergency.disease, table.concat(em.disease.treatment_rooms or {}, ", ")))
    end
  end

  -- Rooms that cannot work at all for want of staff (M.shortStaff).
  s.short = M.shortStaff(world, hosp, em_rooms)

  -- Desks, corridor objects, litter, machines, rats and saboteurs.
  s.desks = #hosp:getReceptionDesks()
  s.staffed_desks = #hosp:getReceptionDesks(true)
  s.reception_queue = 0
  for _, desk in ipairs(hosp:getReceptionDesks()) do
    local q = desk.queue and desk.queue:reportedSize() or 0
    s.reception_queue = s.reception_queue + q
    if desk.tile_x then
      s.doors[#s.doors + 1] = {key = "desk" .. desk.tile_x .. "," .. desk.tile_y, x = desk.tile_x, y = desk.tile_y,
          queue = q, max = 6}
    end
  end
  local comfort = {} -- corridor benches, plants, radiators, drinks machines

  s.objects, s.litter, s.worn, s.rats, s.saboteurs, s.machines = {}, 0, {}, {}, {}, {}
  local me = world:getHospitalIndex(hosp)
  for _, e in ipairs(world.entities) do
    if e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) then
      local t = e.object_type and e.object_type.id
      if t == "litter" then
        s.litter = s.litter + 1
      elseif t and not world:getRoom(e.tile_x, e.tile_y) then
        s.objects[t] = (s.objects[t] or 0) + 1
        if WAITING[t] then comfort[#comfort + 1] = {t, e.tile_x, e.tile_y} end
      end
      -- (A machine's second part, like the operating table's, has no strength.)
      if class.is(e, Machine) and e.hospital == hosp and e.strength and e.getRemainingUses then
        local left = e:getRemainingUses()
        if left <= 3 then s.worn[#s.worn + 1] = e end
        local rm = world:getRoom(e.tile_x, e.tile_y)
        local progress = hosp.research.research_progress[e.object_type]
        if rm and rm.is_active and progress then
          s.machines[#s.machines + 1] = {e = e, room = rm.room_info.id, left = left, strength = e.strength,
              new = progress.start_strength or e.strength, cost = progress.cost or 0}
        end
      end
      if class.is(e, Rat) and e.mp_attack_rat and not e.shot then s.rats[#s.rats + 1] = e end
    end
    if e.mp_saboteur and e.mp_saboteur.target == me and not e.mp_in_transit then
      s.saboteurs[#s.saboteurs + 1] = e
    end
  end

  -- What already stands by each waiting place.
  s.comfort = comfort
  for _, d in ipairs(s.doors) do
    d.near = {bench = 0, plant = 0, radiator = 0, drinks_machine = 0}
    for _, c in ipairs(comfort) do
      if math.abs(c[2] - d.x) <= WAITING_R and math.abs(c[3] - d.y) <= WAITING_R then
        d.near[c[1]] = d.near[c[1]] + 1
      end
    end
  end

  -- Money and goals.
  s.balance, s.loan, s.reputation = hosp.balance, hosp.loan or 0, hosp.reputation or 0
  s.max_loan = math.floor((hosp.value or 0) * 0.33 / 5000) * 5000 + 10000
  s.goals = {}
  local ec = world.endconditions
  -- (The first group of goals: the levels here have one.)
  local group = ec and ec.win_goals and (ec.win_goals[1] or select(2, next(ec.win_goals)))
  for name, g in pairs(group or {}) do
    if g.win_value then
      local ok, now = pcall(ec.getAttribute, ec, hosp, name)
      s.goals[name] = {now = ok and tonumber(now) or 0, want = g.win_value}
    end
  end
  -- How far each goal is (1 = met; a death rate is met below its value).
  s.goal_progress, s.goals_left = {}, 0
  for name, g in pairs(s.goals) do
    local p
    if name == "percentage_killed" then
      p = g.now <= g.want and 1 or g.want / math.max(g.now, 1)
    else
      p = g.want > 0 and math.min(1, g.now / g.want) or 1
    end
    s.goal_progress[name] = p
    if p < 1 then s.goals_left = s.goals_left + 1 end
  end
  s.heat = hosp.heating and math.floor((hosp.heating.radiator_heat or 0.5) * 10 + 0.5) or 5
  self.state = s
  return s
end

--------------------------------------------------------------------------------
-- Projects: what to build, hire or buy next
--------------------------------------------------------------------------------

local function room_types()
  local types = {}
  for _, rt in ipairs(TheApp.rooms) do types[rt.id] = rt end
  return types
end

--! The rooms that cure the emergency `hosp` has on (room id -> true), or
--! nil. (In multiplayer the emergency is set while its fax waits for an
--! answer too; it is on once accepted, when its countdown runs.)
function M.emergencyRooms(world, hosp)
  local em = hosp.emergency
  if not (em and em.disease and (hosp.mp_emergency_timer or not world.mp_coop)) then return nil end
  local rooms = {}
  for _, id in ipairs(em.disease.treatment_rooms or {}) do rooms[id] = true end
  return rooms
end

--! Rooms of `hosp` (built, being built, or wanted by its emergency) that
--! cannot work at all: one needs more staff of a kind than the whole
--! hospital has, like an operating theatre with one surgeon. (Any doctor or
--! nurse is called over from another room; a missing surgeon is missing.)
--! Staff walking over from another hospital count as there.
--!param emergency_rooms (table or nil) M.emergencyRooms
--!return {{room, cat, need, have, built, building, emergency}, ...}, the
--! emergency's first
function M.shortStaff(world, hosp, emergency_rooms)
  local types = room_types()
  local built, building = {}, {}
  for _, r in pairs(world.rooms) do
    if r.hospital == hosp and not r.crashed then
      local id = r.room_info.id
      if r.is_active then built[id] = true else building[id] = true end
    end
  end
  local index = world:getHospitalIndex(hosp)
  local function coming(cat)
    local n = 0
    for _, st in ipairs(world.mp_transfers or {}) do
      local t = st.mp_in_transit
      if t and t.to == index and st.fulfillsCriterion and st.humanoid_class ~= "Patient" and
          st:fulfillsCriterion(cat) then
        n = n + 1
      end
    end
    return n
  end
  local out, checked = {}, {}
  local function check(id)
    if checked[id] or not types[id] then return end
    checked[id] = true
    for cat, k in pairs(types[id].required_staff or {}) do
      local have = hosp:countStaffOfCategory(cat, k)
      if have < k then have = have + coming(cat) end
      if have < k then
        out[#out + 1] = {room = id, cat = cat, need = k, have = have, built = built[id] or false,
            building = building[id] or false, emergency = emergency_rooms and emergency_rooms[id] or false}
      end
    end
  end
  for id in pairs(emergency_rooms or {}) do check(id) end
  for id in pairs(built) do check(id) end
  for id in pairs(building) do check(id) end
  table.sort(out, function(a, b)
    if a.emergency ~= b.emergency then return a.emergency end
    return a.room .. a.cat < b.room .. b.cat
  end)
  return out
end

--! How many specialists of kind `cat` `hosp` can spare: those beyond what
--! its rooms need (every room, built, being built or destroyed, and the
--! rooms its emergency wants).
function M.spareStaff(world, hosp, cat, emergency_rooms)
  local types = room_types()
  local need, counted = 0, {}
  for _, r in pairs(world.rooms) do
    if r.hospital == hosp then
      local rt = types[r.room_info.id]
      need = need + (rt and rt.required_staff and rt.required_staff[cat] or 0)
      counted[r.room_info.id] = true
    end
  end
  for id in pairs(emergency_rooms or {}) do
    local rt = types[id]
    if not counted[id] and rt and rt.required_staff then need = need + (rt.required_staff[cat] or 0) end
  end
  return math.max(0, hosp:countStaffOfCategory(cat) - need)
end

function M:available(room_id)
  local hosp = self.bot.world.ui.hospital
  local d = hosp.room_discoveries[room_id]
  return d and d.is_discovered and not SKIP_ROOMS[room_id]
end

--! Every project worth doing now with its score (higher is more urgent).
function M:projects(s)
  local bot, hosp = self.bot, s.hosp
  local world = bot.world
  local list = {}
  local listed = {}
  -- (The room's owner chose that bots sharing a person's hospital leave the
  -- rooms and the corridors to the person: no rooms, nothing bought for
  -- the corridors or rooms, no room taken in; land, staff and the rest
  -- still. What the person asks for is still done.)
  local builds = not bot:leavesBuilding()
  if not builds and not self.said_hands_off then
    self.said_hands_off = true
    self:note(string.format("day %d: leaves the rooms and corridors to the person (game option)", s.day))
  end
  local function add(key, score, run, cost)
    if not builds and not self.wishes[key] and key ~= "buy:land" and
        (key:find("^room:") or key:find("^buy:") or key:find("^edit:")) then
      return
    end
    -- (Not what a team mate said they would do themselves.)
    if self.hands_off[key] and s.day <= self.hands_off[key] then return end
    -- (Not a room just taken down for standing empty, unless patients ask
    -- for it now or a team mate wants it.)
    local room_kind = key:match("^room:(.+)$")
    if room_kind and self.removed_type[room_kind] and s.day - self.removed_type[room_kind] < REMOVED_REBUILD_DAYS and
        (self.demand[room_kind] or 0) < 3 and not self.wishes[key] then
      return
    end
    -- (Only the basics of an opening hospital are done without the money
    -- for them; not what a plan or a wish lifted that high.)
    local basic = score >= 90
    score = score + (self.boost[key] or 0) + (self.wishes[key] and WISH or 0) + self:goalBonus(key, s)
    listed[key] = true
    if self.failed[key] and s.day < self.failed[key] then return end
    if score > 0.5 then list[#list + 1] = {key = key, score = score, run = run, cost = cost or 0, basic = basic} end
  end
  local rooms_by_id = {}
  for _, rt in ipairs(TheApp.rooms) do rooms_by_id[rt.id] = rt end
  local function room(id, score, size)
    local rt = rooms_by_id[id]
    if not rt or not self:available(id) or s.building[id] then return end
    -- A room for a specialist (a psychiatrist, surgeons, a researcher) waits
    -- until one is on the staff or on the hiring list: an empty room helps
    -- nobody.
    for cat in pairs(rt.required_staff or {}) do
      if SPECIALISTS[cat] and hosp:countStaffOfCategory(cat, 1) == 0 and not bot:canHire(cat) then
        -- (Patients ask for the room, or an ally wished for it: the allies are asked, M:askAllies.)
        if (self.demand[id] or 0) >= 2 or self.wishes["room:" .. id] then self.blocked_spec[cat] = {day = s.day, room = id} end
        return
      end
    end
    local want, extras = M.roomPlan(id)
    if id == "training" then
      want, extras.lecture_chair = self:trainingPlan()
    end
    add("room:" .. id, score, function()
      -- (A team mate may have asked for it beside something: "a toilet next
      -- to the GP's office".)
      local wish = self.wishes["room:" .. id]
      local near = wish and wish.near
      local ok, why = bot:drawRoom(rt, size or want, extras, near)
      if ok and near and bot.near_missed then wish.near_missed = near end
      return ok, why
    end, bot:roomCost(rt))
  end
  -- (From the 3rd year a doctor hired for a need is a junior hired into a
  -- free chair of the training room, trained before he works: M:training.)
  local trainee_chair = self:traineeChair(s)
  local function hire(cat, score)
    if not bot:canHire(cat) then return end
    add("hire:" .. cat, score, function()
      if cat == "Doctor" and trainee_chair and bot:hireStudent(true) then
        self:note(string.format("day %d: a junior for a need, trained first", s.day))
        return true
      end
      return bot:hireCategory(cat)
    end, 0)
  end
  -- (Students in the training room are not at work: the hiring rules do not
  -- count them, but for the juniors hired for a need from the 3rd year.)
  local away = self:studentsAway(s.day)
  local function staff(cat)
    return hosp:countStaffOfCategory(cat) - (cat == "Doctor" and away or 0)
  end
  local function buy(id, score)
    local ok, cost = pcall(hosp.getObjectBuildCost, hosp, id)
    if ok then add("buy:" .. id, score, function() return bot:buyCorridor(id) end, cost or 0) end
  end

  -- The basics of an opening hospital.
  -- (A receptionist for a desk there is, not before: staff only for a need.)
  if s.desks > 0 and s.staffed_desks == 0 and (s.staff.Receptionist or 0) == 0 then hire("Receptionist", 100) end
  if not s.rooms.gp then room("gp", 90) end
  if s.rooms.gp and (s.staff.Doctor or 0) == 0 then hire("Doctor", 95) end
  -- Then as a person opens a hospital: a pharmacy and a general diagnosis
  -- next, before toilets and a staff room (they come once patients and staff
  -- need them). Jan, 2026-11-12: the bots built a GP's office, then toilets
  -- and a staff room (the model's plan named those first).
  local opening = not (s.rooms.gp and (s.rooms.pharmacy or not self:available("pharmacy")) and
      (s.rooms.general_diag or not self:available("general_diag")))
  if s.rooms.gp and not s.rooms.pharmacy then room("pharmacy", 85) end
  if s.rooms.gp and not s.rooms.general_diag then room("general_diag", 80) end

  -- Rooms the patients need (treatment first), by the decaying demand; a
  -- pharmacy and a general diagnosis are always worth it.
  -- (Not one more of a type that stands destroyed: that one is repaired.)
  local destroyed = {}
  for _, r in ipairs(s.crashed) do destroyed[r.room_info.id] = true end
  for id, v in pairs(self.demand) do
    if not s.rooms[id] and not destroyed[id] and not s.waiting_for[id] then room(id, 1 + v * 1.5) end
  end
  -- A treatment room diagnosed patients in the hospital wait for now: soon,
  -- before comfort, with a loan if need be (its fees go otherwise). Jan,
  -- 2026-11-12: a patient waited for an operating theatre while the bot
  -- bought radiators; it came only when the model's plan named it.
  for id, n in pairs(s.waiting_for) do
    if not destroyed[id] then room(id, 55 + 5 * math.min(n, 5) + (self.demand[id] or 0) * 0.5) end
  end
  if not s.rooms.pharmacy then room("pharmacy", 6) end
  if not s.rooms.general_diag then room("general_diag", 5) end
  -- Tired staff need a staff room; patients need toilets.
  if not s.rooms.staff_room and s.room_count >= 3 then room("staff_room", 5 + s.fatigue * 12) end
  if not s.rooms.toilets and s.patients >= 6 then room("toilets", 2 + s.toilet * 8) end
  if s.rooms.staff_room and s.fatigue > 0.6 and (s.rooms.staff_room or 0) < COPIES.staff_room then
    room("staff_room", (s.fatigue - 0.5) * 12)
  end
  -- A research room once the basics stand, if diseases wait for rooms it
  -- has not discovered.
  local undiscovered = 0
  for id, v in pairs(self.demand) do
    if not self:available(id) then undiscovered = undiscovered + v end
  end
  if not s.rooms.research and s.room_count >= 4 then room("research", 6 + undiscovered * 0.4) end
  if M.research_heavy and not s.rooms.research and s.room_count >= 3 then room("research", 30 + undiscovered * 0.4) end
  -- Training: a lecture room once doctors want teaching (juniors, or doctors
  -- not yet consultants) and a consultant can teach them (on the staff or
  -- the hiring list), when money allows.
  local learners = self:doctorsWhere(function(p) return not bot.flag(p, "is_consultant") end)
  local consultants = self:doctorsWhere(function(p) return bot.flag(p, "is_consultant") end)
  if not s.rooms.training and #learners >= 2 and (#consultants > 0 or bot:canHire("Consultant")) and
      (s.staff.Doctor or 0) >= 5 and s.balance > 20000 then
    room("training", 4 + #learners)
  end
  -- A researcher for each desk in it (two at most).
  local lab = s.rooms.research and self:roomOf("research")
  if lab then
    local desks = 0
    for o in pairs(lab.objects or {}) do
      if o.object_type and o.object_type.id == "desk" then desks = desks + 1 end
    end
    -- (Researchers elsewhere in the hospital do not count: the game never
    -- calls staff into a research room, nobody queues at its door. One on
    -- the staff goes over; else one more is hired straight into it.)
    local working, spare, spare_rank = 0, nil, 9
    for _, st in ipairs(hosp.staff) do
      if not st.fired and st.tile_x and st:fulfillsCriterion("Researcher") then
        local where = world:getRoom(st.tile_x, st.tile_y)
        if where == lab then
          working = working + 1
        elseif not st.pickup and st.mp_id and s.day - (self.sent_to_lab[st.mp_id] or -99) > 10 then
          -- (From the corridor first, then a staff room, then another room;
          -- never the training room's teacher or students.)
          local rank = not where and 1 or where.room_info.id == "staff_room" and 2 or
              where.room_info.id == "training" and 9 or 3
          if rank < spare_rank then spare, spare_rank = st, rank end
        end
      end
    end
    -- (At least two researchers, a hard bot three: Jan, 2026-11-12.)
    local wanted = math.min(M.research_heavy and 4 or M.hard and 3 or 2, math.max(1, desks))
    if working < wanted then
      if spare then
        add("staff:research", working == 0 and 14 or 6, function()
          self.sent_to_lab[spare.mp_id] = s.day
          return bot:moveStaffInto(spare, lab)
        end, 0)
      else
        hire("Researcher", working == 0 and 12 or 5)
      end
    end
  end
  -- Full GP's offices send patients on to diagnosis rooms: more of those.
  local busy_q, more = BUSY_QUEUE, 0
  if s.balance > RICH then busy_q, more = BUSY_QUEUE - 2, 1 end
  local gp_per = s.rooms.gp and s.queue.gp / s.rooms.gp or 0
  if gp_per > busy_q and s.rooms.general_diag and s.rooms.general_diag < COPIES.general_diag + more then
    room("general_diag", gp_per - busy_q + 1)
  end
  -- Busy rooms: another one of the type. (A room without its doctor at
  -- this moment is no reason not to: the doctor may be on a break.)
  for id, n in pairs(s.rooms) do
    local per = s.queue[id] / n
    -- (GP's offices: at most COPIES.gp (6), rich or not, and only for a queue.)
    if per > busy_q and n < (COPIES[id] or 1) + (COPIES[id] and id ~= "gp" and more or 0) then
      room(id, (per - busy_q + 1) * 1.2)
    end
  end
  -- A second operating theatre once the first works and somebody waits for
  -- it, or the bank is full: surgery earns the most (Jan, 2026-11-11: the
  -- people in a game built two each, the bots one, its queue never long).
  local surgery_q = s.queue.operating_theatre or 0
  if s.rooms.operating_theatre == 1 and (surgery_q >= 1 or s.balance > RICH) then
    room("operating_theatre", 6 + surgery_q * 2)
  end

  -- Staff: rooms that nobody works in, then busy ones.
  local want = {Doctor = 0, Nurse = 0}
  for id, n in pairs(s.rooms) do
    for cat, k in pairs(rooms_by_id[id] and rooms_by_id[id].required_staff or {}) do
      want[cat] = (want[cat] or 0) + k * n
      if SPECIALISTS[cat] then want.Doctor = want.Doctor + k * n end
    end
  end
  -- (A room without its doctor for a moment is not short of staff: the
  -- doctor is in another room. Only fewer people than rooms, or long
  -- queues, call for more; and never more than the patients need.)
  local cap = {Doctor = want.Doctor + 1 + math.floor(s.patients / 12), Nurse = want.Nurse + 1 + math.floor(s.patients / 20)}
  for cat, k in pairs(want) do
    local have = staff(cat)
    if have < k then hire(cat, 8 + (k - have) * 2) end
  end
  -- A room that cannot work for want of a specialist (or of anybody of a
  -- kind) comes before new rooms, and an emergency's rooms before all but
  -- the basics: its patients die while the room waits. (A research room
  -- treats nobody: less urgent. A room the emergency wants that it cannot
  -- build gets nobody.)
  for _, sh in ipairs(s.short) do
    if sh.built or s.building[sh.room] or self:available(sh.room) then
      local score = (sh.room == "research" and 15 or 45) + math.min(20, (s.queue[sh.room] or 0) * 2)
      if sh.emergency then score = score + 35 end
      hire(sh.cat, score)
    end
  end
  -- The emergency's rooms it lacks, built at once (room() waits for a
  -- specialist on the staff or the hiring list).
  if s.emergency then
    for id in pairs(s.emergency.rooms) do
      if not s.rooms[id] and not destroyed[id] then room(id, 70) end
    end
  end
  for id, n in pairs(s.rooms) do
    local per = s.queue[id] / n
    if per > BUSY_QUEUE then
      for cat in pairs(rooms_by_id[id] and rooms_by_id[id].required_staff or {}) do
        local have = staff(cat)
        local base = SPECIALISTS[cat] and "Doctor" or cat
        if have < (want[cat] or 0) + 2 and staff(base) < (cap[base] or 99) then
          hire(cat, per - BUSY_QUEUE)
        end
      end
    end
  end
  -- A room destroyed by an exploding machine: built again where it stands
  -- (it still takes up the floor), or cleared away if it cannot be.
  local builder = corsixth.require("mp_room_builder")
  for _, r in ipairs(s.crashed) do
    local id = r.room_info.id
    local repair = builder.repairCommand(bot.world, r) ~= nil
    local progress = hosp.research.research_progress[r.room_info]
    local cost = repair and (progress and progress.build_cost or 0) or r:calculateRemovalCost()
    add("repair:" .. id, 30 + (EARNERS[id] or 0) + (self.demand[id] or 0) * 1.5, function()
      return self:issue({kind = "remove_crashed_room", room = r.id, repair = repair and 1 or nil,
          hospital = bot.world:getHospitalIndex(hosp)})
    end, cost)
  end
  -- A machine worn down by its repairs (each takes some strength): a new
  -- one before it explodes; urgent once it is nearly done for.
  for _, m in ipairs(s.machines) do
    if m.new > m.strength + 1 and m.strength <= math.max(3, math.floor(m.new / 2)) then
      add("replace:" .. m.room, (m.strength <= 3 and 25 or 6) + (EARNERS[m.room] or 0) * 0.5, function()
        return self:issue({kind = "replace_machine", machine = m.e.mp_id})
      end, m.cost)
    end
  end
  -- No floor for what it wants: first a room that is bigger than it needs
  -- taken in by a row (no cost, and the land may be gone), then land.
  -- With no land left to buy, rooms go down to their smallest size (the
  -- plant and radiator may not fit any more).
  local wanted = self:landWanted(s)
  local _, land_price
  if wanted then _, land_price = bot:cheapestPlot() end
  local size_of = land_price and SIZES_OF or smallest_size
  -- (One room at a time, a month apart: each edit closes the room a while.)
  -- (Never in a hospital a person plays in too: the rooms are theirs as well.)
  if wanted and #bot:hospitalMates() == 0 and
      s.day - (self.shrink_day or -99) > 30 and bot:oversizedRoom(size_of) then
    add("edit:shrink", 12 + wanted * 6, function()
      local ok, why = bot:shrinkRoom(size_of)
      if ok then self.shrink_day = s.day end
      return ok, why
    end, 0)
  end
  if wanted and land_price then
    add("buy:land", 10 + wanted * 6, function() return bot:buyPlot() end, land_price)
  end
  -- The hospital's value is a goal still to reach: land counts in full, so a
  -- plot is bought when the money is there, needed or not (GOAL_LEVERS
  -- raises it further).
  local value_left = s.goal_progress.value
  -- (Only with money to spare and no loan: Jan, 2026-11-12, Bertie bought
  -- two plots with $14,000 in the bank and $20,000 owed, its land a quarter
  -- full.)
  if not wanted and value_left and value_left < 1 and (value_left >= 0.8 or s.goals_left == 1) and
      s.balance > 3 * RESERVE and (hosp.loan or 0) == 0 then
    local _, price = bot:cheapestPlot()
    if price and price < s.balance - VALUE_LAND_SPARE then
      add("buy:land", 6, function() return bot:buyPlot() end, price)
    end
  end
  -- A room nobody has used for about five months: taken down for its floor.
  -- While the level's hospital value is a goal not reached yet, a room is
  -- sold only as a last resort (it takes the room's whole price off the value,
  -- for half of it back: Argus, Jan 2026-11-08): unused for a year, and only
  -- when it has no space for what it needs and no land it can get
  -- (M:outOfSpace); the cheapest such room, after a room bigger than it needs
  -- was taken in (edit:shrink scores higher).
  -- (Not in a hospital a person plays in too: the rooms are theirs as well.)
  if #bot:hospitalMates() == 0 then
    local value_goal = s.goal_progress.value ~= nil and s.goal_progress.value < 1
    local days = value_goal and VACANT_DAYS_VALUE or VACANT_DAYS
    local rm = (not value_goal or self:outOfSpace(s)) and self:vacantRoom(s, days, value_goal)
    if rm then
      local kind = rm.room_info.id
      add("edit:remove", (value_goal and 8 or 14) + (wanted or 0) * 6, function()
        local ok, why = bot:editRoom(rm, {"delete"})
        if ok then
          self.removed_type[kind] = s.day
          self.room_used[rm.id] = nil
          self:note(string.format("day %d: removing %s #%d: nobody used it for %d days%s", s.day, kind, rm.id, days,
              value_goal and " and there is no space left (the value goal is not met)" or ""))
        end
        return ok, why
      end, 0)
    end
  end

  -- Reception: another desk and receptionist when the queue grows.
  if s.desks < 2 and s.reception_queue > 10 then buy("reception_desk", (s.reception_queue - 8) * 0.6) end
  if (s.staff.Receptionist or 0) < s.desks then hire("Receptionist", 12) end
  -- Handymen: litter, machines, plants.
  local machines = 0
  for id, n in pairs(s.rooms) do
    if rooms_by_id[id] and rooms_by_id[id].objects_needed then
      for obj in pairs(rooms_by_id[id].objects_needed) do
        if TheApp.objects[obj] and TheApp.objects[obj].default_strength then machines = machines + n end
      end
    end
  end
  local handymen = math.min(5, (s.room_count >= 3 and 1 or 0) + math.floor(s.litter / 12) + math.floor(machines / 4))
  -- A broken boiler: the more handymen, the sooner it is repaired.
  if hosp.heating and hosp.heating.heating_broke then handymen = math.max(handymen, 3) end
  -- (Litter piling up makes it urgent: Bots Agnes and Bertie had 2 and 3
  -- handymen and 90 to 100 pieces of litter in the corridors, 2026-11-11.)
  if (s.staff.Handyman or 0) < handymen then
    hire("Handyman", 3 + (handymen - (s.staff.Handyman or 0)) * 2 + math.min(20, math.floor(s.litter / 5)))
  end

  -- Corridor comfort, once the hospital is open and has a few rooms.
  if hosp.opened and s.room_count >= 3 then
    local waiting = s.reception_queue
    for _, q in pairs(s.queue) do waiting = waiting + q end
    -- Waiting areas, the busiest first (standing patients get fed up).
    table.sort(s.doors, function(a, b) return a.queue > b.queue or (a.queue == b.queue and a.key < b.key) end)
    local function place(id, d, score)
      local ok, cost = pcall(hosp.getObjectBuildCost, hosp, id)
      if ok then
        add("buy:" .. id .. "@" .. d.key, score, function() return bot:buyCorridor(id, d.x, d.y) end, cost or 0)
      end
    end
    for i, d in ipairs(s.doors) do
      local benches_wanted = math.min(d.max, 1 + math.ceil(d.queue * 0.6))
      -- (Patients standing in a queue: before radiators and plants. Jan,
      -- 2026-11-12: standing patients and no benches at Bertie's.)
      if d.near.bench < benches_wanted then
        local missing = benches_wanted - d.near.bench
        -- (A hard bot: a bench by every door soon, before anybody stands.)
        place("bench", d, ((d.queue >= 2 or M.hard) and 8 or 3) + missing * 2 + d.queue * 0.5)
      end
      if d.near.plant < 1 then place("plant", d, 2 + (1 - s.happiness)) end
      if d.near.radiator < 1 then place("radiator", d, 2 + s.cold * 0.5) end
    end
    -- Drinks machines: one per 25 patients (one at least), each by the
    -- busiest waiting place with none within DRINKS_R tiles. (Before, every
    -- third place wanted one within 4 tiles, and which places were third
    -- changed with the queues: machines everywhere, side by side.) A plan
    -- naming buy:drinks_machine only raises this rule's score: before, it
    -- bought one by the reception every week (Matroftt, 2026-11-07: 76
    -- machines in eight hospitals of about 30 patients, in rows).
    local drinks_now = s.objects.drinks_machine or 0
    local drinks_boost = self.boost["buy:drinks_machine"] or 0
    if s.patients >= 8 and drinks_now < 1 + s.patients / 25 then
      local covered = false
      for _, d in ipairs(s.doors) do
        if not covered then
          local near = 0
          for _, c in ipairs(s.comfort or {}) do
            if c[1] == "drinks_machine" and math.abs(c[2] - d.x) <= DRINKS_R and math.abs(c[3] - d.y) <= DRINKS_R then
              near = near + 1
            end
          end
          if near == 0 then
            -- (The plan never makes it urgent: no loan for it. The first
            -- machine goes anywhere if nothing fits by the door.)
            local score = math.min(URGENT - 5, 2 + s.thirst * 4 + drinks_boost)
            local ok, cost = pcall(hosp.getObjectBuildCost, hosp, "drinks_machine")
            if ok then
              add("buy:drinks_machine@" .. d.key, score, function()
                return bot:buyCorridor("drinks_machine", d.x, d.y) or (drinks_now == 0 and bot:buyCorridor("drinks_machine"))
              end, cost or 0)
            end
            covered = true
          end
        end
      end
    end
    local benches = s.objects.bench or 0
    if benches < waiting * 0.6 and benches < 40 then buy("bench", 1 + (waiting * 0.6 - benches) * 0.5) end
    local radiators = s.objects.radiator or 0
    if radiators < 2 + s.room_count / 3 and (s.cold > 2 or radiators == 0) then buy("radiator", 2 + s.cold * 0.5) end
    if (s.objects.bin or 0) < 2 and s.litter > 8 then buy("bin", 1.5) end
    if (s.objects.plant or 0) < 2 + s.room_count / 4 then buy("plant", 0.8 + (1 - s.happiness)) end
    if (s.objects.extinguisher or 0) < 1 and s.room_count >= 6 then buy("extinguisher", 0.7) end
  end
  -- What a team mate asked for in the chat, if nothing above wanted it. A
  -- wish somebody has done meanwhile (the team mate built the room
  -- themselves, say) is over.
  for key, w in pairs(self.wishes) do
    if s.day > w.until_day or self:howMany(key) > w.had then
      self.wishes[key] = nil
      self:note("wish over: " .. key)
    elseif not listed[key] then
      local kind, what = key:match("^(%a+):(.+)$")
      if key == "buy:land" then
        local _, price = bot:cheapestPlot()
        if price then add(key, 0, function() return bot:buyPlot() end, price) end
      elseif kind == "room" then
        room(what, 0)
      elseif kind == "hire" then
        hire(what, 0)
      elseif kind == "buy" then
        buy(what, 0)
      elseif kind == "remove" then
        -- A team mate asks for a room to go (its floor for something else).
        local rm = self:roomOf(what)
        if rm then
          add(key, 0, function()
            local ok, why = bot:editRoom(rm, {"delete"})
            if ok then self.removed_type[what] = s.day end
            return ok, why
          end, 0)
        end
      elseif kind == "add" or kind == "bigger" then
        -- An object more in a room, or the room bigger: edit it as a person
        -- would (Bot:editRoom).
        local room_id, obj = what:match("^([%w_]+):?([%w_]*)$")
        local rm = self:roomOf(room_id)
        if rm then
          local steps = kind == "add" and {"buy:" .. obj, "place", "done"} or {"resize:1:1", "place", "done"}
          local ok, cost = pcall(hosp.getObjectBuildCost, hosp, obj ~= "" and obj or "radiator")
          add(key, 0, function() return bot:editRoom(rm, steps) end, kind == "add" and ok and cost or 1000)
        end
      end
    end
  end
  -- What the model's plan named that no rule above listed (one nurse more,
  -- say): tried, within the copies of a room, and never urgent (no loan for
  -- it). (Before, such a plan item was dropped without a word; tried without
  -- those limits, the bots built six pharmacies on loans.) Staff only for a
  -- need: a desk or a room without its staff (Jan: a second receptionist
  -- and a doctor came before there was a desk or a room for them).
  local need = {Receptionist = s.desks, Doctor = want.Doctor, Nurse = want.Nurse, Handyman = handymen}
  for key, b in pairs(self.boost) do
    if b > 0 and not listed[key] then
      local kind, what = key:match("^(%a+):(.+)$")
      local score = math.min(0, URGENT - 5 - b)
      if kind == "hire" then
        local base = SPECIALISTS[what] and "Doctor" or what
        if staff(base) < math.min(cap[base] or 99, need[base] or 0) then hire(what, score) end
      elseif kind == "room" then
        -- (Not while the opening rooms are still to come.)
        if not opening and M.planRoomWanted(what, s.rooms[what] or 0, s.queue[what] or 0) then room(what, score) end
      elseif kind == "buy" and what ~= "drinks_machine" then -- (drinks: the rule above)
        buy(what, score)
      end
    end
  end
  table.sort(list, function(a, b) return a.score > b.score end)
  return list
end

--! The doctors on the staff whose profile passes `test`.
function M:doctorsWhere(test)
  local out = {}
  for _, st in ipairs(self.bot.world.ui.hospital.staff) do
    if not st.fired and st.humanoid_class == "Doctor" and st.profile and test(st.profile) then out[#out + 1] = st end
  end
  return out
end

--! The size and the extra chairs of a new training room: this bot's number of
--! lecture chairs (3 to 6 in all, picked once from its own random numbers)
--! less the one the room needs. Six chairs want a bigger room.
function M:trainingPlan()
  self.training_chairs = self.training_chairs or self.rand(CHAIRS_MIN, CHAIRS_MAX)
  return self.training_chairs >= 5 and 6 or SIZES.training, self.training_chairs - 1
end

--! Can this doctor be taken from his work to the training room? Not from a
--! room with a patient in it or in its queue (a GP's office with patients),
--! and never the last of a specialism a room needs (the only surgeon of an
--! operating theatre).
function M:canSpareDoctor(st)
  local world, hosp = self.bot.world, self.bot.world.ui.hospital
  local room = st.tile_x and world:getRoom(st.tile_x, st.tile_y)
  if room then
    for h in pairs(room.humanoids or {}) do
      if class.is(h, Patient) then return false end
    end
    local q = room.door and room.door.queue
    if q and q:reportedSize() > 0 then return false end
  end
  for cat in pairs(SPECIALISTS) do
    if st:fulfillsCriterion(cat) then
      local need = 0
      for _, rm in pairs(world.rooms) do
        if rm.hospital == hosp and rm.is_active and not rm.crashed then
          need = need + ((rm.room_info.required_staff or {})[cat] or 0)
        end
      end
      if need > 0 and hosp:countStaffOfCategory(cat) - 1 < need then return false end
    end
  end
  return true
end

--! The training room as it is now: {room, teacher (the one at the projector,
--! or a consultant of the room away on a break: he comes back by himself,
--! last_room), chairs (lecture chairs), students (the doctors inside but the
--! teacher)}, or nil when it has no working training room.
function M:trainingRoom()
  local bot = self.bot
  local room = self:roomOf("training")
  if not room or not room.is_active then return nil end
  local world = bot.world
  local teacher = room.staff_member
  if not teacher then
    for _, st in ipairs(self:doctorsWhere(function(p) return bot.flag(p, "is_consultant") end)) do
      if st.last_room == room then teacher = st end
    end
  end
  local chairs, students = 0, {}
  for o in pairs(room.objects or {}) do
    if o.object_type and o.object_type.id == "lecture_chair" then chairs = chairs + 1 end
  end
  for _, st in ipairs(self:doctorsWhere(function() return true end)) do
    if st ~= teacher and st.tile_x and world:getRoom(st.tile_x, st.tile_y) == room then
      students[#students + 1] = st
    end
  end
  return {room = room, teacher = teacher, chairs = chairs, students = students}
end

--! Is this student in the training room a trainee: from the 3rd year
--! (STAFF_REVIEW_FROM) a junior, hired for a need and trained to a doctor
--! before he works (Jan, 2026-11-08)? A trainee counts as staff for that need
--! (M:projects), other students do not.
function M:isTrainee(st, day)
  return day >= STAFF_REVIEW_FROM and self.bot.flag(st.profile, "is_junior")
end

--! Doctors in the training room who are not at work and not hired for a need
--! (M:isTrainee): the hiring rules do not count them (M:projects).
function M:studentsAway(day)
  local t = self:trainingRoom()
  local n = 0
  for _, st in ipairs(t and t.students or {}) do
    if not self:isTrainee(st, day) then n = n + 1 end
  end
  return n
end

--! From the 3rd year: a training room with its teacher and a free chair, for a
--! junior hired for a need (M:projects), or nil.
function M:traineeChair(s)
  if s.day < STAFF_REVIEW_FROM then return nil end
  local t = self:trainingRoom()
  if t and t.teacher and #t.students < t.chairs then return t end
  return nil
end

--! The training room: its teacher and students.
--! How training works (rooms/training.lua, Doctor:trainSkills): a doctor
--! who is not yet a consultant learns only while he sits in a lecture chair
--! of the training room and a consultant stands at the projector; he does
--! no work for patients meanwhile, and his pay keeps going. A student gains
--! general skill every day (juniors become doctors, doctors consultants);
--! a special skill (surgeon, psychiatrist, researcher) only if the teacher
--! has it and he has not. More chairs than 3 are filled but slow each
--! student (2/(n-1) of the rate). The room holds the chairs plus the teacher.
--!
--! The teacher is chosen again every TEACHER_REVIEW_DAYS (a year, the first
--! time in the 2nd month, or when there is none for a month): the
--! consultant with the most special skills (then the most skill), from the
--! staff or, if one there is better, from the hiring list (hired straight
--! into the room). Students fill the chairs: juniors first, then other
--! doctors not yet consultants, while the other rooms keep their doctors
--! (M:canSpareDoctor).
--!
--! Until the 3rd year (STAFF_REVIEW_FROM) the chairs are kept full from the
--! day the room has its teacher (Jan, 2026-11-08): with no doctor to spare,
--! a junior (else a doctor not yet a consultant) is hired straight into the
--! room as a student, one every 3 days, while the bank holds TRAIN_HIRE_FLOOR.
--! Those students do not count as staff, so the rooms still get their
--! doctors (M:projects); one goes back to work only when the hospital has
--! fewer doctors at work than its rooms need and none can be hired.
--!
--! From the 3rd year doctors are hired only for a need, and such a doctor is
--! a junior hired into a free chair (M:projects, M:traineeChair): he is
--! trained first and goes to work once he is a doctor and more staff is
--! needed. The staff are reviewed every STAFF_REVIEW_DAYS and the doctors the
--! hospital can spare (a room with no patient, the others still enough) go in
--! without the margin kept before. A student who is not a junior goes back to
--! work when the hospital has fewer doctors at work than its rooms need.
--!
--! A student who became a consultant goes back to work at once (to a room
--! short of one, else the staff room: he learns nothing more).
function M:training(s)
  local bot = self.bot
  local t = self:trainingRoom()
  if not t then return end
  local room, teacher = t.room, t.teacher
  local world = bot.world
  if s.day >= (self.teacher_review or FIRST_TEACHER_REVIEW) or
      (not teacher and s.day - (self.teacher_sent or -99) > 30) then
    self.teacher_review = s.day + TEACHER_REVIEW_DAYS
    self.student_day = nil -- (the chairs are filled again now)
    local best, best_v
    for _, st in ipairs(self:doctorsWhere(function(p) return bot.flag(p, "is_consultant") end)) do
      local v = bot.teacherScore(st.profile)
      if not st.pickup and st.mp_id and (not best_v or v > best_v) then best, best_v = st, v end
    end
    local pool = (world.staffPool and world:staffPool() or world.available_staff).Doctor or {}
    local hire_v
    for _, p in ipairs(pool) do
      if bot.flag(p, "is_consultant") then
        local v = bot.teacherScore(p)
        if not hire_v or v > hire_v then hire_v = v end
      end
    end
    -- (One more special skill than the best on the staff is worth a wage.)
    if hire_v and hire_v >= (best_v or -1) + 1 and s.balance > 20000 then
      if bot:hireTeacher() then
        self.teacher_sent = s.day
        self:note(string.format("day %d: hired a teacher (%d special skills) for the training room",
            s.day, math.floor(hire_v)))
        return
      end
    end
    if best and best ~= teacher then
      if bot:moveStaffInto(best, room) then
        self.teacher_sent = s.day
        self:note(string.format("day %d: %s teaches (%d special skills)", s.day,
            tostring(best.profile:getFullName()), bot.specialisms(best.profile)))
        return
      end
    end
  end
  -- Students: one change every 3 days at most.
  if s.day - (self.student_day or -99) < 3 then return end
  local chairs, students = t.chairs, t.students
  local full = s.day < STAFF_REVIEW_FROM
  local short = self:roomShortOf("Doctor")
  local doctors = #self:doctorsWhere(function() return true end)
  local needed = bot:staffWanted().Doctor
  -- (A room without its doctor at this moment may have him on a break: the
  -- hospital lacks one when fewer doctors are at work than its rooms need.)
  local lacking = short and doctors - #students < needed
  -- Back to work, one at a time: a student now a consultant; or, when the
  -- hospital lacks a doctor, the most skilled student (until the 3rd year
  -- only when none can be hired; from then on never a junior in training).
  local leaving, leaving_skill
  for _, st in ipairs(students) do
    if not st.pickup and st.mp_id then
      if bot.flag(st.profile, "is_consultant") then
        leaving, leaving_skill = st, 99
      elseif lacking and (not full or not bot:canHire("Doctor")) and not self:isTrainee(st, s.day) and
          (st.profile.skill or 0) > (leaving_skill or -1) then
        leaving, leaving_skill = st, st.profile.skill or 0
      end
    end
  end
  if leaving then
    local target = short or self:roomShortOf("Consultant")
    if not target and bot.flag(leaving.profile, "is_consultant") then target = self:roomOf("staff_room") end
    if target and bot:moveStaffInto(leaving, target) then
      self.student_day = s.day
      self:note(string.format("day %d: %s trained, back to the %s", s.day,
          tostring(leaving.profile:getFullName()), target.room_info.id))
      return
    end
  end
  -- A room with fewer chairs than the 3 it should have (an older game's):
  -- one more, as a person would add it.
  if chairs < CHAIRS_MIN and s.balance > 8000 and s.day - (self.chair_day or -99) > 30 and
      bot:extraAllowed(room, "lecture_chair") then
    self.chair_day = s.day
    if bot:editRoom(room, {"buy:lecture_chair", "place", "done"}) then
      self:note(string.format("day %d: one more lecture chair (%d)", s.day, chairs))
      return
    end
  end
  -- From the 3rd year the staff are reviewed (every STAFF_REVIEW_DAYS):
  -- nothing is kept back but the doctors the rooms need.
  local review = s.day >= STAFF_REVIEW_FROM and s.day - (self.staff_review or -99) >= STAFF_REVIEW_DAYS
  local margin = full and 1 or 0
  local filled = false
  if #students < chairs and not short and doctors - #students - (teacher and 1 or 0) - margin >= needed then
    -- Juniors first, then the least skilled doctor not yet a consultant,
    -- among those who can be spared from their work.
    local pick, pick_v
    for _, st in ipairs(self:doctorsWhere(function(p) return not bot.flag(p, "is_consultant") end)) do
      local inside = st.tile_x and world:getRoom(st.tile_x, st.tile_y) == room
      if not inside and not st.pickup and st.mp_id and self:canSpareDoctor(st) then
        local v = (bot.flag(st.profile, "is_junior") and 0 or 1) + (st.profile.skill or 0)
        if not pick_v or v < pick_v then pick, pick_v = st, v end
      end
    end
    if pick and bot:moveStaffInto(pick, room) then
      filled = true
      self.student_day = s.day
      self:note(string.format("day %d: %s to the training room%s", s.day, tostring(pick.profile:getFullName()),
          review and " (staff review)" or ""))
    end
  end
  -- Until the 3rd year the chairs are kept full: nobody to spare, so a
  -- student is hired (never while the room has no teacher: nobody would learn).
  if full and not filled and #students < chairs and teacher and s.balance > TRAIN_HIRE_FLOOR and
      bot:hireStudent() then
    self.student_day = s.day
    self:note(string.format("day %d: hired a student for the training room (%d of %d chairs taken)", s.day,
        #students, chairs))
  end
  if review and #students >= chairs then self.staff_review = s.day end
end

--! A room of this hospital with fewer staff of `category` than it needs
--! (the first by id), or nil.
function M:roomShortOf(category)
  local world, hosp = self.bot.world, self.bot.world.ui.hospital
  local best
  for _, rm in pairs(world.rooms) do
    local need = rm.hospital == hosp and rm.is_active and rm.room_info.id ~= "training" and
        (rm.room_info.required_staff or {})[category]
    if need and not best or (need and rm.id < best.id) then
      local have = 0
      for h in pairs(rm.humanoids or {}) do
        if h.humanoid_class == "Doctor" and h:fulfillsCriterion(category) then have = have + 1 end
      end
      if have < need then best = rm end
    end
  end
  return best
end

--! How full its land is (MultiplayerSession.landFill), worked out once a day.
function M:landFill(s)
  if self.fill_day ~= s.day then
    self.fill_day = s.day
    self.fill = MultiplayerSession.landFill(self.bot.world, s.hosp)
  end
  return self.fill
end

--! Does it need land: how many kinds of room found no floor in the last 30
--! days, or nil. Not while plenty of floor is free (then the rooms were
--! badly placed, more land would not help), unless three kinds failed.
--! Once rooms take BOT_LAND_FILL of its floor it looks for a plot anyway
--! (2: urgent enough to borrow for), before a rival buys up the land.
--!param free_floor (number) optional: its free floor tiles (Bot:freeFloor)
--!param fill (number) optional: how full its land is (M:landFill); both
--! as they would be without a plot it is asked for (M:plotRequest)
function M:landWanted(s, free_floor, fill)
  local wanted = 0
  for _, day in pairs(self.no_space) do
    if s.day - day <= 30 then wanted = wanted + 1 end
  end
  if wanted < 3 and wanted > 0 and (free_floor or self.bot:freeFloor()) >= 120 then wanted = 0 end
  if (fill or self:landFill(s)) >= MultiplayerSession.BOT_LAND_FILL then wanted = math.max(wanted, 2) end
  if wanted == 0 then return nil end
  return wanted
end

-- A plot an ally offers is taken when less than this much of its own land is
-- free (its rooms take more than 65% of the indoor floor).
local PLOT_TAKE_FREE = 0.35
local PLOT_LINES = {
  take = {"Thanks, %s, I'll take the plot. I was running out of room.",
      "A plot, %s? Yes please, my hospital is getting cramped."},
  roomy = {"Thanks, %s, but I still have plenty of room.", "No thanks, %s, my land is mostly empty still."},
  broke = {"Sorry %s, I cannot afford that plot right now.", "I'd love it, %s, but I cannot pay for the plot."},
}

--! An ally offers a plot (offer.plot, offer.price): take it when little of
--! its own land is free (under PLOT_TAKE_FREE, by MultiplayerSession.landFill)
--! and it can pay, with a loan if need be (the loan is taken when the plot
--! changes hands: MultiplayerSession.botBorrow). (An ally asking for one of
--! its plots: M:plotRequest.)
--!return (bool, string) accept, and the line to say (%s: the other player's name)
function M:plotAnswer(offer)
  local world = self.bot.world
  local hosp = world.ui.hospital
  local free = 1 - MultiplayerSession.landFill(world, hosp)
  local price = offer.price or 0
  local borrow = math.max(0, MultiplayerSession.maxLoan(world, hosp) - (hosp.loan or 0))
  local verdict, why = true, "take"
  if free >= PLOT_TAKE_FREE then
    verdict, why = false, "roomy"
  elseif price > 0 and hosp.balance + borrow - price < MultiplayerSession.BOT_AUCTION_RESERVE then
    verdict, why = false, "broke"
  end
  self.log(string.format("plot %s offered for $%d: %d%% of its land free, balance $%d, may borrow $%d: %s",
      tostring(offer.plot), price, math.floor(free * 100 + 0.5), math.floor(hosp.balance), borrow,
      verdict and "accepts" or ("declines (" .. why .. ")")))
  return verdict, self.pick(PLOT_LINES[why])
end

--! Do the most urgent project it can afford (one at a time, like a person).
function M:doProject(s)
  local bot = self.bot
  if s.day < self.next_project then return end
  local list = self:projects(s)
  for i = 1, math.min(#list, 6) do
    local p = list[i]
    -- (Something urgent it cannot pay: a loan, then it is done.)
    local short = p.cost + RESERVE - s.balance
    -- (Once in a few days: the bank may say no.)
    if short > 0 and p.score >= URGENT and not p.basic and s.day - (self.loan_day or -99) > 5 then
      local amount = math.ceil(short / 5000) * 5000
      if s.loan + amount <= s.max_loan and s.hosp.opened and self:issue({kind = "loan", amount = amount}) then
        self.loan_day = s.day
        self:note(string.format("day %d: loan of $%d for %s", s.day, amount, p.key))
        self.next_project = bot:later(1)
        return
      end
    end
    if s.balance - p.cost >= RESERVE or p.basic then
      local ok, why = p.run()
      if ok then
        self:note(string.format("day %d: %s (score %.1f, $%d)", s.day, p.key, p.score, math.floor(s.balance)))
        self:noteSpent(p.key, p.cost)
        if p.key == "buy:land" or p.key == "edit:shrink" then self.no_space = {} end
        self.no_space[p.key] = nil
        self.boost[p.key] = nil
        self.boost[(p.key:gsub("@.*$", ""))] = nil -- (buy:bench@desk... was the plan's buy:bench)
        if self.wishes[p.key] then self:tellWisher(self.wishes[p.key], "wish_done", p.key) end
        self.wishes[p.key] = nil
        -- Rooms take a few days to build; staff and objects less.
        self.next_project = bot:later(p.key:find("^room:") and self.rand(2, 4) or self.rand(1, 2))
        return
      end
      if why == "busy" then
        self.next_project = s.day
        return
      end
      if why == "space" then
        -- Out of floor: buy land, then try again.
        self:note(string.format("day %d: no space for %s", s.day, p.key))
        local w = self.wishes[p.key]
        if w and not w.told_space then
          w.told_space = true
          self:tellWisher(w, "wish_no_space", p.key)
        end
        self.no_space[p.key] = s.day
        self.failed[p.key] = s.day + 5
        self.next_project = bot:later(2)
        return
      end
      self.failed[p.key] = s.day + (why == "money" and 3 or 10)
      self:note(string.format("day %d: %s failed (%s)", s.day, p.key, tostring(why or "?")))
    elseif self.wishes[p.key] and not self.wishes[p.key].told_money then
      self.wishes[p.key].told_money = true
      self:tellWisher(self.wishes[p.key], "wish_no_money", p.key)
    end
  end
  self.next_project = bot:later(1)
end

--------------------------------------------------------------------------------
-- Every day and every month
--------------------------------------------------------------------------------

function M:issue(cmd)
  local session = TheApp.mp_session
  if session and not session.held then session:issue(cmd) return true end
  return false
end

--! Small things a player does every day: handymen to worn machines, the
--! heating, a loan when money runs out, faxes, rats and evil handymen. A
--! helper (a person runs the hospital too) only sends the handymen.
function M:daily(s)
  local bot = self.bot
  local hosp = s.hosp
  local helper = bot:sharesWithPerson()
  self:noteRoomUse(s)
  if not helper then self:researchPolicy(s) end
  -- Machines half worn: a handyman to each (once in a while per machine).
  -- Repaired early, a machine seldom loses strength (the game takes it
  -- with the share used up) and does not explode while the handyman walks.
  if (s.staff.Handyman or 0) > 0 then
    for _, m in ipairs(s.machines) do
      local id, used = m.e.mp_id, m.strength - m.left
      if id and used >= math.max(2, math.ceil(m.strength / 2)) and
          (not self.called[id] or s.day - self.called[id] > 3) then
        self.called[id] = s.day
        self:issue({kind = "call_handyman", machine = id})
      end
    end
  end
  -- Dirty tricks (in a race), also when a person shares the hospital: they
  -- have had the time to deal with them first.
  self:defend(s)
  if helper then return end
  self:training(s)
  -- Its floor in pieces (Bot:repairFloor): looked at once a game week, every
  -- 2 days while it is being mended. (Not when it leaves the building to the
  -- person it shares with: those are their things.)
  if s.day >= (self.floor_check or 0) and not bot:leavesBuilding() then
    local sold = bot:repairFloor()
    self.floor_check = s.day + (sold and 2 or 7)
    if sold then self:note(string.format("day %d: %s", s.day, sold)) end
  end
  -- Heating: warmer when patients are cold, cooler when they are hot.
  -- (Not while the boiler is broken: the heating cannot be set then.)
  if hosp.opened and s.patients >= 4 and (s.objects.radiator or 0) > 0 and
      not (hosp.heating and hosp.heating.heating_broke) then
    if s.cold > s.patients / 4 and s.heat < 8 then
      self:issue({kind = "set_heat", level = s.heat + 1})
    elseif s.hot > s.patients / 4 and s.heat > 3 then
      self:issue({kind = "set_heat", level = s.heat - 1})
    end
  end
  -- Money: a loan before the bank account runs dry.
  if s.balance < 1500 and s.loan + 5000 <= s.max_loan and hosp.opened then
    if self:issue({kind = "loan", amount = 5000}) then self:note(string.format("day %d: loan of $5,000", s.day)) end
  end
  self:answerFaxes(s)
end

--! The month in one line for the log: why patients left, which diseases
--! it lost most, specialists.
function M:monthLine(s)
  local left = {}
  for k, v in pairs(self.left) do left[#left + 1] = k .. "=" .. v end
  table.sort(left)
  local lost = {}
  for d, n in pairs(self.lost) do lost[#lost + 1] = {d, n} end
  table.sort(lost, function(a, b) return a[2] > b[2] end)
  local top = {}
  for i = 1, math.min(5, #lost) do top[#top + 1] = lost[i][1] .. "=" .. lost[i][2] end
  local hosp = s.hosp
  local queues = {}
  for id, n in pairs(s.rooms) do queues[#queues + 1] = string.format("%s:%d/%d", id, s.queue[id] or 0, n) end
  table.sort(queues)
  local staff, n = {}, 0
  for c, k in pairs(s.staff) do staff[#staff + 1] = c .. "=" .. k; n = n + k end
  table.sort(staff)
  local juniors = #self:doctorsWhere(function(p) return self.bot.flag(p, "is_junior") end)
  local consultants = #self:doctorsWhere(function(p) return self.bot.flag(p, "is_consultant") end)
  local goals = {}
  for name, g in pairs(s.goals or {}) do
    goals[#goals + 1] = string.format("%s %d/%d", name, math.floor(g.now), g.want)
  end
  table.sort(goals)
  -- (Its floor, Bot:floorReport: in how many parts, with and without its
  -- corridor objects, and what must be reached.)
  local ok, floor_text = pcall(self.bot.floorReport, self.bot)
  if not ok then floor_text = "?" end
  return string.format("month %d: left %s; lost most: %s; in hospital %d; queues %s, reception %d; psychiatrists %d,"
      .. " surgeons %d; prices %d%%; reputation %d, $%d; loan $%d; staff %d (%s), juniors %d, consultants %d;"
      .. " staff happy %d%%, tired %d%%; patients happy %d%%; land %d%% full; goals %s; floor %s", s.month,
      table.concat(left, " "), table.concat(top, " "),
      s.patients, table.concat(queues, " "), s.reception_queue, hosp:countStaffOfCategory("Psychiatrist"),
      hosp:countStaffOfCategory("Surgeon"), 100, s.reputation, math.floor(s.balance),
      math.floor(s.loan or 0), n, table.concat(staff, ","), juniors, consultants, math.floor(s.staff_happy * 100 + 0.5),
      math.floor(s.fatigue * 100 + 0.5), math.floor((s.happiness or 0) * 100 + 0.5),
      math.floor(self:landFill(s) * 100 + 0.5), #goals > 0 and table.concat(goals, " ") or "none", floor_text)
end

--! Once a month: prices, repaying the loan, research.
function M:monthly(s)
  local hosp = s.hosp
  self.log(self:monthLine(s))
  -- Prices: a bot never changes them (Argus, 2026-11-07: its patients
  -- walked out over prices, and that is the person's business, not a
  -- computer player's). It sets back to normal what an older bot changed
  -- (a game continued from a save), once.
  if not self.prices_normal then
    self.prices_normal = true
    local changed = false
    for id, entry in pairs(hosp.disease_casebook) do
      if entry.price and entry.discovered ~= false and not entry.pseudo and math.floor(entry.price * 100 + 0.5) ~= 100 then
        changed = self:issue({kind = "set_price", disease = id, percent = 100}) or changed
      end
    end
    if changed then self:note(string.format("day %d: prices back to 100%%", s.day)) end
  end
  -- Loan: repay it once the money flows in again (the balance up since a
  -- month ago), keeping $12,000; or what it can spare above $25,000.
  local flowing = self.last_balance and s.balance > self.last_balance
  self.last_balance = s.balance
  if s.loan > 0 and (s.balance > 25000 or (flowing and s.balance > 17000)) then
    local keep = s.balance > 25000 and 20000 or 12000
    local amount = math.min(s.loan, math.floor((s.balance - keep) / 1000) * 1000)
    if amount > 0 and self:issue({kind = "loan", amount = -amount}) then
      self:noteSpent("loan", amount)
      self:note(string.format("day %d: repaid $%d of the loan ($%d left)", s.day, amount, s.loan - amount))
    end
  end
  -- Research: aim it at the disease whose treatment room it lacks most.
  if s.rooms.research then
    local best, best_v
    for room_id, v in pairs(self.demand) do
      if not self:available(room_id) and (not best_v or v > best_v) then best, best_v = room_id, v end
    end
    -- (Not a room this level does not have at all: canConcentrateResearch
    -- fails on it.)
    if best and best_v > 1 and best ~= self.research_room and hosp.world.available_rooms[best] then
      -- (A diagnosis room's machine is researched as its "diag_" entry.)
      local diag = "diag_" .. best
      if hosp.disease_casebook[diag] and hosp:canConcentrateResearch(diag) then
        if self:issue({kind = "concentrate_research", disease = diag}) then
          self.research_room = best
          self:note(string.format("day %d: research on %s (for a %s)", s.day, diag, best))
        end
      end
      for id, entry in pairs(best ~= self.research_room and hosp.disease_casebook or {}) do
        local d = entry.disease
        local rooms = d and d.treatment_rooms
        if rooms and rooms[#rooms] == best and hosp:canConcentrateResearch(id) then
          if self:issue({kind = "concentrate_research", disease = id}) then
            self.research_room = best
            self:note(string.format("day %d: research on %s (for a %s)", s.day, id, best))
          end
          break
        end
      end
    end
  end
end

--! Answer the faxes a player answers: a patient it cannot help yet, a VIP,
--! an epidemic. (Offers and emergencies: bot.lua.)
function M:answerFaxes(s)
  local world, hosp = self.bot.world, s.hosp
  local panel = world.ui and world.ui.bottom_panel
  if not panel then return end
  for _, icon in ipairs(panel:allMessageIcons()) do
    local msg = type(icon.message) == "table" and icon.message
    local choices = msg and msg.choices
    if choices and icon.hospital == hosp and icon.mp_id and not self.answered[icon.mp_id] and not msg.mp_offer and
        icon.type ~= "emergency" then
      local index = {}
      for i, c in ipairs(choices) do
        if c.enabled ~= false then index[c.choice] = i end
      end
      local pick, why, refer_to
      local diagnosis = false
      for _, c in ipairs(choices) do
        if c.choice == "guess_cure" then diagnosis = true end
      end
      if diagnosis then
        -- A patient who has been to every diagnosis room it has and is
        -- still not sure: a guess (a waiting patient stands in the corridor
        -- for two months, then leaves or dies), or a diagnosis room more.
        local patient = icon.owner
        local missing = false
        for _, r in ipairs(patient and patient.disease and patient.disease.diagnosis_rooms or {}) do
          if not s.rooms[r] and self:available(r) then
            missing = true
            self.demand[r] = (self.demand[r] or 0) + 1
          elseif not s.rooms[r] and hosp.room_discoveries[r] and not SKIP_ROOMS[r] then
            -- (Not discovered yet: research to ask for, M:askForNeeds.)
            self.research_need[r] = s.day
          end
        end
        -- (A diagnosis room it can build beats a guess: a guessed cure
        -- kills more often.)
        if missing and s.balance > 15000 and index.wait then
          pick, why = index.wait, "building a diagnosis room"
        elseif index.guess_cure then
          pick, why = index.guess_cure, "a good guess"
        else
          pick, why = index.send_home, "cannot diagnose it"
        end
      elseif index.send_home or index.wait then
        -- A patient whose room it does not have (or cannot diagnose).
        local patient = icon.owner
        local rooms = patient and patient.disease and patient.disease.treatment_rooms or {}
        local missing, buildable = false, true
        for _, r in ipairs(rooms) do
          if not s.rooms[r] then
            missing = true
            self.demand[r] = (self.demand[r] or 0) + 2
            if not self:available(r) then
              buildable = false
              if hosp.room_discoveries[r] then self.research_need[r] = s.day end
            end
          end
        end
        -- (Never "research": that is an autopsy, and it costs the hospital
        -- a lot of reputation when it comes out.)
        if not missing then
          pick, why = index.wait, "the room is there"
        elseif buildable and s.balance > 15000 then
          pick, why = index.wait, "building the room"
        else
          -- About half go to a team mate whose hospital has the rooms (not
          -- every one: the person there gets a fax for each), the rest home.
          local mate, mate_index = self:referTarget(patient, rooms, s.day)
          if mate and index.wait and self.rand() < REFER_SHARE then
            pick, why = index.wait, "referred to " .. tostring(mate.name)
            refer_to = mate_index
            self.referred_day[mate_index] = s.day
          else
            pick, why = index.send_home, "no room for it"
          end
        end
      elseif index.accept_vip or index.refuse_vip then
        local good = s.reputation >= 450 and s.room_count >= 5 and s.litter < 10
        pick, why = good and index.accept_vip or index.refuse_vip, good and "a good day for a VIP" or "not ready"
      elseif index.declare_epidemic then
        pick, why = index.declare_epidemic, "safer"
      end
      if pick then
        self.answered[icon.mp_id] = true
        local id = icon.mp_id
        local choice_name = choices[pick].choice
        local patient_id = refer_to and icon.owner and icon.owner.mp_id
        self.bot:say(nil, 2 + self.rand() * 4, nil, function()
          -- (A referral as a person makes it: the offer, then "wait" so the
          -- patient stays until the team mate answers, UIMultiplayerChooseHospital.)
          if patient_id then self:issue({kind = "offer_patient", to = refer_to, patient = patient_id}) end
          self:issue({kind = "fax_choice", msg = id, choice = pick})
        end)
        self:note(string.format("day %d: fax #%d (%s): %s, %s", s.day, id, tostring(icon.type), choice_name, why))
      end
    end
  end
end

--! What raises each of the level's goals (Jan: a bot should know them and
--! work towards them; Bertie won by his value only by the way). Keys are a
--! project key or its kind ("room", "buy", "hire").
-- How far a goal must be (its share of the way) before the bot works at it.
local GOAL_REACH = 0.7
local GOAL_LEVERS = {
  -- (The value is land, rooms and what is in them: cash does not count.)
  value = {["buy:land"] = 8, room = 3, buy = 1},
  num_cured = {room = 2, hire = 2},
  percentage_cured = {room = 2, hire = 2},
  reputation = {["room:toilets"] = 3, ["room:staff_room"] = 2, ["buy:plant"] = 2, ["buy:bench"] = 2,
      ["buy:radiator"] = 2, ["buy:bin"] = 2, ["hire:Handyman"] = 2},
  patient_happiness = {["room:toilets"] = 3, ["buy:bench"] = 3, ["buy:plant"] = 2, ["buy:radiator"] = 2,
      ["buy:drinks_machine"] = 1, ["buy:bin"] = 1},
  staff_happiness = {["room:staff_room"] = 5, ["buy:plant"] = 1, ["buy:radiator"] = 1},
}

--! Extra score for a project from the goals not met yet but within reach
--! (GOAL_REACH of the way there): more the nearer, double when it is the
--! last one. Early on every goal is far and nothing changes: the hospital
--! is built as usual first (with pushes from the start, a bot bought land
--! before anything else and had no money for tricks or auctions). A money
--! goal within reach, with at most one other left, makes spending wait (not
--! what is urgent: repairs, a loan for those).
function M:goalBonus(key, s)
  local left = s.goals_left or 0
  if left == 0 then return 0 end
  local kind = key:match("^(%a+):")
  local push = left == 1 and 2 or 1
  local bonus = 0
  for name, p in pairs(s.goal_progress) do
    local levers = p < 1 and p >= GOAL_REACH and GOAL_LEVERS[name]
    local b = levers and (levers[key] or levers[kind])
    if b then bonus = bonus + b * p * push end
  end
  local money = s.goal_progress.balance
  if money and money < 1 and money >= GOAL_REACH and left <= 2 and
      (kind == "room" or kind == "buy" or kind == "edit") then
    bonus = bonus - 4 * push * money
  end
  return bonus
end

--! Once a day: the rooms in use (a patient inside; staff in a staff-only
--! room). A room first seen today counts as used today.
function M:noteRoomUse(s)
  local world = self.bot.world
  for _, rm in pairs(world.rooms) do
    if rm.hospital == s.hosp and rm.is_active then
      local used = not self.room_used[rm.id]
      for h in pairs(rm.humanoids or {}) do
        if class.is(h, Patient) or (STAFF_ROOMS[rm.room_info.id] and class.is(h, Staff)) then used = true end
      end
      if used then self.room_used[rm.id] = s.day end
    end
  end
end

--! A room of its own nobody has used for `days` game days (VACANT_DAYS by
--! default): the one empty longest, or with `cheapest` the one that costs
--! least (the least value lost); nil if none.
function M:vacantRoom(s, days, cheapest)
  days = days or VACANT_DAYS
  local world = self.bot.world
  local best, best_day, best_cost
  for _, rm in pairs(world.rooms) do
    local day = self.room_used[rm.id]
    if rm.hospital == s.hosp and rm.built and rm.is_active and not rm.crashed and day and
        not KEEP_ROOMS[rm.room_info.id] and s.day - day >= days then
      local cost = cheapest and self.bot:roomCost(rm.room_info) or 0
      if not best or cost < best_cost or
          (cost == best_cost and (day < best_day or (day == best_day and rm.id < best.id))) then
        best, best_day, best_cost = rm, day, cost
      end
    end
  end
  return best
end

--! No room to grow: something it wanted found no floor in the last 30 days
--! (M:doProject), and no plot is left that it may buy and pay for, with a
--! loan if need be.
function M:outOfSpace(s)
  local cramped = false
  for _, day in pairs(self.no_space) do
    if s.day - day <= 30 then cramped = true end
  end
  if not cramped then return false end
  local _, price = self.bot:cheapestPlot()
  return not price or s.balance + math.max(0, s.max_loan - s.loan) - price < RESERVE
end

--! A team mate's hospital to refer a patient to: one that has every room in
--! `rooms`, is still in the race and had no referral from this hospital in
--! the last REFER_GAP_DAYS game days. Its index, or nil.
function M:referTarget(patient, rooms, day)
  local world = self.bot.world
  local mine = world.ui.hospital
  if not (patient and patient.mp_id and MultiplayerSession.referable(patient)) then return nil end
  local n = world.mp_coop and world.mp_coop.players or 0
  for i = 1, n do
    local h = world.hospitals[i]
    local last = self.referred_day[i]
    -- (Allies only: in a race everyone for themselves the rivals may trade,
    -- but a bot does not hand its patients to them.)
    if h and h ~= mine and not h.mp_place and world:mpMayTrade(mine, h) and not world:mpRivals(mine, h) and
        not (last and day - last < REFER_GAP_DAYS) then
      local has = true
      for _, r in ipairs(rooms) do
        if h:countRoomOfType(r, 1) == 0 then has = false break end
      end
      if has then return h, i end
    end
  end
  return nil
end

--! A race: throw out evil handymen once noticed, shoot attack rats.
function M:defend(s)
  for _, e in ipairs(s.saboteurs) do
    local id = e.mp_id
    if id then
      self.noticed[id] = self.noticed[id] or (s.day + self.rand(NOTICE_DAYS[1], NOTICE_DAYS[2]))
      if s.day >= self.noticed[id] and not self.noticed[-id] then
        self.noticed[-id] = true
        self:issue({kind = "fire_staff", staff = id})
        self:note(string.format("day %d: threw out an evil handyman", s.day))
        -- (Throwing him out tells who sent him, as it tells a person.)
        local owner = e.mp_saboteur and e.mp_saboteur.owner
        if self.bot.fiery then self.bot:tellRival("handyman", owner) end
      end
    end
  end
  -- Rats: noticed after a while, then a few a day, like clicks (those out of
  -- their holes); a word once they are all gone. (Counted by the game: on a
  -- day when all are in their holes they are still there.)
  local count = self.sabotage and self.sabotage.countRats and self.sabotage.countRats(self.bot.world, s.hosp)
  if (count or #s.rats) > 0 then
    self.rats_from = self.rats_from or (s.day + self.rand(NOTICE_DAYS[1], NOTICE_DAYS[2]))
    if s.day >= self.rats_from then
      if not self.rats_shooting then
        self.rats_shooting = true
        self:note(string.format("day %d: shooting %d rats", s.day, #s.rats))
      end
      for i = 1, math.min(#s.rats, 4) do
        local rat = s.rats[i]
        if rat.mp_id then self:issue({kind = "shoot_rat", rat = rat.mp_id}) end
      end
    end
  elseif self.rats_from then
    if self.rats_shooting and self.bot.fiery then self.bot:tellRival("rats") end
    self.rats_from, self.rats_shooting = nil, nil
  end
end

-- The text of a game string (translatable strings are wrapped objects).
local function plain(text)
  if type(text) ~= "userdata" then return tostring(text) end
  return (require("TH").stringProxy._unwrap(text))
end

--! Does `text` read as the game string `format` (its %s and %d any text)?
local function says(format, text)
  if not format then return false end
  local pattern = plain(format):gsub("%%[sd]", ""):gsub("[%%%^%$%(%)%.%[%]%*%+%-%?]", "%%%0")
  pattern = "^" .. pattern:gsub("", ".-") .. "$"
  return plain(text):find(pattern) ~= nil
end

--! The adviser told the bot's player something: dirty tricks it can see
--! (a broken boiler, a smear campaign, a spy) get a word to the rivals. (An
--! epidemic or an emergency sent by a rival looks like any other; evil
--! handymen and rats are found in the hospital itself, M:defend.)
function M:notice(text)
  local S = _S.multiplayer_window
  local kind
  if says(S.sabotage_boiler_notice, text) then
    kind = "boiler"
  elseif says(S.sabotage_smear_notice, text) then
    kind = "smear"
  elseif says(S.sabotage_espionage_notice, text) or says(S.sabotage_espionage_notice_3, text) then
    kind = "espionage"
  end
  if not kind then return end
  local day = self.bot:gameDay()
  self.tricks[kind] = day
  self:note(string.format("day %d: dirty trick noticed: %s", day, kind))
  if self.bot.fiery then self.bot:tellRival(kind) end
end

--! The rival to play a dirty trick on: the one closest to winning (its
--! reputation and money), a person rather than a bot.
function M:trickTarget()
  local bot, world = self.bot, self.bot.world
  local mine = world.ui.hospital
  local best, best_score, best_name
  for index, hospital in ipairs(world.hospitals) do
    local peer, name, is_bot = bot:playerOfHospital(index)
    -- (Not a hospital that is closed or has nobody working in it: no
    -- patients to lose, money wasted.)
    if peer and world:mpRivals(mine, hospital) and not hospital.mp_place and hospital.opened and
        #hospital.staff > 0 then
      local score = (hospital.reputation or 0) + (hospital.balance or 0) / 500 + (is_bot and -200 or 0)
      if not best or score > best_score then best, best_score, best_name = hospital, score, name end
    end
  end
  return best, best_name
end

--! Which trick hurts this rival most: machines to wear down, a staffed
--! desk for an epidemic or emergency, else rats.
function M:trickKind(target)
  local world = self.bot.world
  local machines = 0
  for _, e in ipairs(world.entities) do
    if class.is(e, Machine) and e.hospital == target then machines = machines + 1 end
  end
  local kinds = {}
  if machines >= 3 then kinds[#kinds + 1] = "handyman" end
  if target:hasReceptionDesk(true) then kinds[#kinds + 1] = self.rand() < 0.5 and "epidemic" or "emergency" end
  kinds[#kinds + 1] = "rats"
  return kinds
end

--------------------------------------------------------------------------------
-- The model's plan (through the server) and the report for it
--------------------------------------------------------------------------------

--! The hospital in a few lines, for the language model.
function M:report()
  local s = self.state
  if not s then return nil end
  local lines = {}
  local function add(fmt, ...) lines[#lines + 1] = string.format(fmt, ...) end
  add("Month %d of the game, day %d. Mode: %s.", s.month, s.day, self.bot.mode)
  add("Money $%d, loan $%d (up to $%d), reputation %d, patients in the hospital %d, open: %s. Rooms take %d%% of its floor.",
      math.floor(s.balance), s.loan, s.max_loan, s.reputation, s.patients, tostring(s.hosp.opened or false),
      math.floor(self:landFill(s) * 100 + 0.5))
  local problems = self:problems(s)
  if #problems > 0 then
    add("PROBLEMS TO FIX FIRST (found from its numbers):")
    for _, p in ipairs(problems) do add("- %s", p) end
  end
  local goals = {}
  for name, g in pairs(s.goals) do goals[#goals + 1] = string.format("%s %d of %d", name, math.floor(g.now), g.want) end
  table.sort(goals)
  add("Goals to win the level: %s.", #goals > 0 and table.concat(goals, ", ") or "none")
  local rooms = {}
  for id, n in pairs(s.rooms) do
    rooms[#rooms + 1] = string.format("%s x%d (queue %d%s)", id, n, s.queue[id] or 0, s.unstaffed[id] and ", unstaffed" or "")
  end
  table.sort(rooms)
  add("Rooms: %s.", #rooms > 0 and table.concat(rooms, "; ") or "none")
  local needed = {}
  for id, v in pairs(self.demand) do
    if v >= 0.5 then needed[#needed + 1] = string.format("%s (%.1f%s)", id, v, self:available(id) and "" or ", not researched") end
  end
  table.sort(needed)
  add("Rooms patients needed lately but it does not have: %s.", #needed > 0 and table.concat(needed, ", ") or "none")
  local staff = {}
  for c, n in pairs(s.staff) do staff[#staff + 1] = c .. " " .. n end
  table.sort(staff)
  add("Staff: %s; tiredness %.0f%%, staff happiness %.0f%%.", table.concat(staff, ", "), s.fatigue * 100, s.staff_happy * 100)
  local machines = {}
  for _, m in ipairs(s.machines) do
    machines[#machines + 1] = string.format("%s strength %d of %d, %d uses left", m.room, m.strength, m.new, m.left)
  end
  table.sort(machines)
  add("Reception: %d desks (%d staffed), queue %d. Litter %d. Machines: %s.", s.desks, s.staffed_desks,
      s.reception_queue, s.litter, #machines > 0 and table.concat(machines, "; ") or "none")
  add("Patients: thirst %.0f%%, warmth %.0f%% (%d cold, %d hot), toilet need %.0f%%, happiness %.0f%%. Heating %d/10.",
      s.thirst * 100, s.warmth * 100, s.cold, s.hot, s.toilet * 100, s.happiness * 100, s.heat)
  if self.bot.fiery then
    local rivals = {}
    local world = self.bot.world
    for index, h in ipairs(world.hospitals) do
      local _, name = self.bot:playerOfHospital(index)
      if name and world:mpRivals(s.hosp, h) then
        rivals[#rivals + 1] = string.format("%s: reputation %d, money $%d%s", name, h.reputation or 0,
            math.floor(h.balance or 0), h.mp_place and (", placed " .. h.mp_place) or "")
      end
    end
    add("Rivals: %s. Evil handymen in its hospital: %d, attack rats: %d.", table.concat(rivals, "; "),
        #s.saboteurs, #s.rats)
  end
  local left = {}
  for k, v in pairs(self.left) do left[#left + 1] = k .. " " .. v end
  table.sort(left)
  local lost = {}
  for d, n in pairs(self.lost) do lost[#lost + 1] = string.format("%s %d", d, n) end
  table.sort(lost)
  add("Patients so far: %s. Left uncured, by disease: %s.", #left > 0 and table.concat(left, ", ") or "none",
      #lost > 0 and table.concat(lost, ", ") or "none")
  if #self.history > 0 then add("Recently: %s.", table.concat(self.history, "; ")) end
  return table.concat(lines, "\n")
end

--! What is going wrong, as a good player would see it, each with the
--! project that fixes it (for the top of the model's report).
function M:problems(s)
  local out = {}
  local function add(fmt, ...) out[#out + 1] = string.format(fmt, ...) end
  local hosp = s.hosp
  local e = s.emergency
  if e then
    local need = {}
    for id in pairs(e.rooms) do need[#need + 1] = id .. (s.rooms[id] and "" or " (MISSING: room:" .. id .. ")") end
    table.sort(need)
    add("EMERGENCY: %d %s patients by helicopter, %d cured, %d dead so far%s. They need: %s."
        .. " Every one of those rooms must work, with all its staff, before anything else.",
        e.victims, e.disease, e.cured, e.killed, e.days and string.format(", %d days left", e.days) or "",
        table.concat(need, ", "))
  end
  for _, sh in ipairs(s.short or {}) do
    local state = sh.built and "cannot work" or "will not work"
    if self.bot:canHire(sh.cat) then
      add("The %s %s%s: it needs %d %s, the hospital has %d. Hire one now: hire:%s.", sh.room, state,
          sh.emergency and " (the EMERGENCY needs it)" or "", sh.need, sh.cat, sh.have, sh.cat)
    else
      add("The %s %s%s: it needs %d %s, the hospital has %d, and none is on the hiring list now"
          .. " (wait for one, or train a doctor in the training room).", sh.room, state,
          sh.emergency and " (the EMERGENCY needs it)" or "", sh.need, sh.cat, sh.have)
    end
  end
  for _, r in ipairs(s.crashed) do
    local id = r.room_info.id
    local progress = hosp.research.research_progress[r.room_info]
    add("The %s was destroyed by an exploding machine: no patient can use it and it still takes up the floor."
        .. " Repair it: repair:%s ($%d).", id, id, progress and progress.build_cost or 0)
  end
  for _, m in ipairs(s.machines) do
    if m.new > m.strength + 1 and m.strength <= math.max(3, math.floor(m.new / 2)) then
      add("The machine in the %s is worn down (strength %d, a new one has %d) and will soon explode: replace:%s ($%d).",
          m.room, m.strength, m.new, m.room, m.cost)
    end
  end
  local blocked = {}
  for key, day in pairs(self.no_space) do
    if s.day - day <= 30 then blocked[#blocked + 1] = key end
  end
  table.sort(blocked)
  if #blocked > 0 and self:landWanted(s) then
    local _, price = self.bot:cheapestPlot()
    if price then
      add("No floor space left: it could not build %s. Buy land first: buy:land ($%d; a loan pays for it if needed).",
          table.concat(blocked, ", "), price)
    else
      add("No floor space left (and no land to buy): it could not build %s.", table.concat(blocked, ", "))
    end
  end
  for id, n in pairs(s.rooms) do
    local per = s.queue[id] / n
    if per > 2 * BUSY_QUEUE then
      add("Long queue at the %s: %d patients for %d room(s)%s. Another room:%s or more staff for it.", id,
          s.queue[id], n, s.unstaffed[id] and ", one without its staff" or "", id)
    end
  end
  if s.balance < 2 * RESERVE and s.loan < s.max_loan then
    add("Money is short ($%d); a loan of up to $%d more is possible.", math.floor(s.balance), s.max_loan - s.loan)
  end
  if s.reputation < 300 then
    add("Reputation is low (%d): cure patients (enough rooms and staff, short queues), lower prices.", s.reputation)
  end
  return out
end

--! The menu for a plan: every project (M.menu) and, for its rooms now, a
--! repair or a new machine.
function M:planMenu()
  local items = M.menu()
  local s = self.state
  if not s then return items end
  -- Land only once it has found no floor for a room (the model liked to buy
  -- it from the first day).
  if self:landWanted(s) then items[#items + 1] = "buy:land" end
  local seen = {}
  for _, r in ipairs(s.crashed) do
    local key = "repair:" .. r.room_info.id
    if not seen[key] then seen[key] = true items[#items + 1] = key end
  end
  for _, m in ipairs(s.machines) do
    local key = "replace:" .. m.room
    if not seen[key] then seen[key] = true items[#items + 1] = key end
  end
  return items
end

--! The projects a plan may name (for the model's menu).
function M.menu()
  local rooms = {}
  for _, rt in ipairs(TheApp.rooms) do
    if not SKIP_ROOMS[rt.id] then rooms[#rooms + 1] = "room:" .. rt.id end
  end
  local items = {"hire:Doctor", "hire:Nurse", "hire:Handyman", "hire:Receptionist", "hire:Psychiatrist",
      "hire:Surgeon", "hire:Researcher", "buy:bench", "buy:drinks_machine", "buy:radiator", "buy:plant",
      "buy:bin", "buy:reception_desk", "buy:extinguisher"}
  for _, r in ipairs(rooms) do items[#items + 1] = r end
  return items
end

--! The projects a team mate may ask for now: rooms it has discovered, and
--! for the rooms it has, an object more (add:<room>:<object>) or the room
--! bigger (bigger:<room>).
function M:wishMenu()
  local items = {}
  for _, k in ipairs(M.menu()) do
    local room_id = k:match("^room:(.+)$")
    if not room_id or self:available(room_id) then items[#items + 1] = k end
  end
  -- (A team mate may always ask for land.)
  items[#items + 1] = "buy:land"
  local world = self.bot.world
  local seen = {}
  for _, rm in pairs(world.rooms) do
    local id = rm.room_info.id
    if rm.hospital == world.ui.hospital and rm.is_active and not seen[id] then
      seen[id] = true
      items[#items + 1] = "bigger:" .. id
      items[#items + 1] = "remove:" .. id
      for _, obj in ipairs(rm.room_info.objects_additional or {}) do
        if self.bot:extraAllowed(rm, obj) then items[#items + 1] = "add:" .. id .. ":" .. obj end
      end
    end
  end
  return items
end

--! The first active room of a type in this hospital (the one a team mate
--! means), or nil.
function M:roomOf(id)
  local world = self.bot.world
  local found
  for _, rm in pairs(world.rooms) do
    if rm.hospital == world.ui.hospital and rm.is_active and rm.room_info.id == id and
        (not found or rm.id < found.id) then
      found = rm
    end
  end
  return found
end

--! How many of a project's thing this hospital has: rooms of the type (also
--! ones still being built), staff of the kind, or corridor objects.
function M:howMany(key)
  local world = self.bot.world
  local hosp = world.ui.hospital
  local kind, what = key:match("^(%a+):(.+)$")
  local n = 0
  if kind == "room" then
    for _, r in pairs(world.rooms) do
      if r.hospital == hosp and r.room_info.id == what and not r.crashed then n = n + 1 end
    end
  elseif kind == "hire" then
    n = hosp:countStaffOfCategory(what)
  elseif kind == "add" then
    local room_id, obj = what:match("^([%w_]+):([%w_]+)$")
    for _, rm in pairs(world.rooms) do
      if rm.hospital == hosp and rm.room_info.id == room_id then
        for o in pairs(rm.objects or {}) do
          if o.object_type and o.object_type.id == obj then n = n + 1 end
        end
      end
    end
  elseif kind == "remove" then
    -- (Counted down: one room fewer is one more, so the wish is over.)
    for _, r in pairs(world.rooms) do
      if r.hospital == hosp and r.room_info.id == what and not r.crashed then n = n - 1 end
    end
  elseif kind == "bigger" then
    for _, rm in pairs(world.rooms) do
      if rm.hospital == hosp and rm.room_info.id == what then n = n + rm.width * rm.height end
    end
  elseif kind == "buy" then
    for _, e in ipairs(world.entities) do
      if e.object_type and e.object_type.id == what and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) and
          not world:getRoom(e.tile_x, e.tile_y) then
        n = n + 1
      end
    end
  end
  return n
end

--! A team mate asked for this project in the chat: it comes next (for 60
--! game days: a request for every room takes a while; then it lapses, if it could not be done), unless somebody
--! does it first.
function M:wish(key, peer)
  -- A room may come with a place: "room:toilets@near:gp" (next to the GP's
  -- office), "@near:entrance", "@near:reception". Other places are ignored.
  local base, place = key:match("^([^@]+)@near:([%w_]+)$")
  if base then
    key = base
    local known = place == "entrance" or place == "reception"
    for _, rt in ipairs(TheApp.rooms) do known = known or rt.id == place end
    if not known or not key:find("^room:") then place = nil end
  end
  for _, k in ipairs(self:wishMenu()) do
    if k == key then
      self.wishes[key] = {until_day = self.bot:gameDay() + 60, had = self:howMany(key), peer = peer, near = place}
      self.next_project = math.min(self.next_project, self.bot:gameDay())
      self:note("wish: " .. key .. (place and (" next to the " .. place) or ""))
      return true
    end
  end
  return false
end

--! A wish's project in words ("an inflation room", "a nurse", "a bench").
local function wish_words(key)
  local kind, what = key:match("^(%a+):([^:]+)")
  local function room_name(id)
    local ok, name = pcall(function() return _S.rooms_short[id] end)
    return (ok and type(name) == "string" and name or id:gsub("_", " ")) .. " room"
  end
  if kind == "room" then
    return room_name(what)
  elseif kind == "add" then
    -- "add:gp:plant": the plant in the GP room
    local obj = key:match("^add:[^:]+:(.+)$") or "thing"
    return obj:gsub("_", " ") .. " in the " .. room_name(what)
  elseif kind == "bigger" then
    return "bigger " .. room_name(what)
  elseif kind == "remove" then
    return room_name(what)
  elseif kind == "hire" then
    return "a " .. what:lower()
  elseif key == "buy:land" then
    return "more land"
  end
  return (what or key):gsub("_", " ")
end

--! A place a room was asked to be built beside, in words.
local function near_words(place)
  if place == "reception" then return "reception desk" end
  if place == "entrance" then return "entrance" end
  return wish_words("room:" .. place)
end

--! Tell whoever wished for a project how it went (done, no space yet, no
--! money yet), so a "certainly!" in the chat is not the last word.
function M:tellWisher(w, kind, key)
  local bot = self.bot
  local peers = w.peer and {w.peer} or bot:hospitalMates()
  for _, peer in ipairs(peers) do
    local name = bot:playerName(peer)
    if name then
      -- (Something put into a room: "the plant in the GP room is in place".)
      local lines = (kind == "wish_done" and key:find("^add:") and self.lines.wish_done_add) or
          (kind == "wish_done" and key:find("^remove:") and self.lines.wish_done_remove) or
          (kind == "wish_done" and w.near_missed and self.lines.wish_done_far) or self.lines[kind]
      local line = self.fill_in(self.pick(lines), {name = name, what = wish_words(key),
          near = w.near_missed and near_words(w.near_missed) or ""})
      bot:say(line, self.typing(line), peer)
    end
  end
end

--! A team mate keeps this project for themselves (or took back their
--! wish): no wish for it, and the bot leaves it alone for 60 game days.
function M:leaveTo(key)
  self.wishes[key] = nil
  self.hands_off[key] = self.bot:gameDay() + 60
  self:note("left to a team mate: " .. key)
end

--! A plan from the model: {priorities = {{action, weight}}}. Raises those projects' scores until done: a
--! weight of 10 comes before the manager's own ideas (as a team mate's
--! wish), a weight of 3 only tips the balance.
function M:applyPlan(plan)
  if type(plan) ~= "table" then return end
  self.boost = {}
  local valid = {}
  for _, k in ipairs(self:planMenu()) do valid[k] = true end
  local taken = {}
  for i, p in ipairs(type(plan.priorities) == "table" and plan.priorities or {}) do
    if type(p) == "table" and valid[p.action] and i <= 6 then
      local w = math.max(0, math.min(10, tonumber(p.weight) or 3))
      self.boost[p.action] = w * w / 2
      taken[#taken + 1] = p.action
    end
  end
  -- (A plan to revive a failing hospital stays in force for a month, M:rescue.)
  if self.rescue_until and self.bot:gameDay() <= self.rescue_until then
    for key, b in pairs(self.rescue_boost or {}) do self.boost[key] = math.max(self.boost[key] or 0, b) end
  end
  -- (No price: bots keep the normal prices, M:monthly.)
  self:note("plan: " .. table.concat(taken, ", "))
end

--! Its research (discoveries, better drugs and machines) to every ally, a
--! hospital on its side that another player plays, who lacks it: for free,
--! once in SHARE_DAYS per ally, again only when there is something new.
function M:shareResearch(s)
  local bot, world = self.bot, self.bot.world
  local mine = s.hosp
  if not world.mp_coop or not world.mpMayTrade or not MultiplayerSession.shareableResearch then return end
  if world.mp_coop.sharing_off then return end -- (the room's owner switched it off)
  for index, h in ipairs(world.hospitals) do
    local peer = bot:playerOfHospital(index)
    -- (Never to a rival: in a race only to team mates.)
    if h ~= mine and peer and world:mpMayTrade(mine, h) and not world:mpRivals(mine, h) then
      local seen = self.shared[index] or {}
      self.shared[index] = seen
      local items = MultiplayerSession.shareableResearch(mine, h)
      local keys, names, new = {}, {}, false
      for _, item in ipairs(items) do
        keys[#keys + 1] = item.key
        names[#names + 1] = plain(item.name)
        if not seen[item.key] then new = true end
      end
      -- A person sharing this hospital decides: the bot asks them first and
      -- sends it when they say "share" (Bot:onChat sets bot.share_ok).
      local person = bot:sharesWithPerson()
      local allowed = not person or (bot.share_ok and s.day - bot.share_ok <= SHARE_DAYS)
      if new and person and not allowed and s.day - (seen.asked or -999) >= SHARE_DAYS then
        seen.asked = s.day
        local _, people = bot:peopleOfHospital(index)
        local list = table.concat(names, ", ", 1, math.min(#names, 4)) .. (#names > 4 and ", ..." or "")
        for _, mate in ipairs(bot:hospitalMates()) do
          local line = self.fill_in(self.pick(self.lines.research_ask), {name = bot:playerName(mate),
              ally = people[1] or world.hospitals[index].name, list = list})
          bot:say(line, self.typing(line), mate)
        end
      end
      if new and allowed and s.day - (seen.offered or -999) >= SHARE_DAYS and
          self:issue({kind = "offer_research", to = index, items = table.concat(keys, ";"), price = 0}) then
        seen.offered = s.day
        for _, key in ipairs(keys) do seen[key] = s.day end
        self:note(string.format("day %d: research for hospital %d: %s", s.day, index, table.concat(keys, ",")))
        -- (No chat line: the offer arrives as a fax in their messages.)
      end
    end
  end
end

--! Allied hospitals (not its own, played by somebody, on its side): index ->
--! hospital, in index order.
function M:allies()
  local bot, world = self.bot, self.bot.world
  local mine, out = world.ui.hospital, {}
  if not (world.mp_coop and world.mpMayTrade) then return out end
  for index, h in ipairs(world.hospitals) do
    if h ~= mine and bot:playerOfHospital(index) and world:mpMayTrade(mine, h) and not world:mpRivals(mine, h) then
      out[#out + 1] = {index = index, hosp = h}
    end
  end
  return out
end

-- (Specialists for the rooms patients use: a research room waits.)
-- (A consultant too, for the training room: Jan, 2026-11-12.)
local function lends(sh) return (SPECIALISTS[sh.cat] or sh.cat == "Consultant") and sh.room ~= "research" end

--! The name of a room type for the chat ("operating theatre").
local function room_name(id)
  local rt = room_types()[id]
  return rt and rt.name and plain(rt.name) or id:gsub("_", " ")
end

--! A specialist an ally needs and cannot get (an operating theatre with one
--! surgeon, none on their hiring list, or none hired for LACK_DAYS): one of
--! its own it can spare is offered for free (they accept in their messages,
--! as any offer of staff; a bot accepts an ally's), at most once in
--! GIVE_DAYS per ally and kind. (A bot sharing a person's hospital leaves
--! its staff to the person.)
function M:helpAllies(s)
  local bot, world = self.bot, self.bot.world
  local mine = s.hosp
  if bot:sharesWithPerson() then return end
  for _, ally in ipairs(self:allies()) do
    local h, index = ally.hosp, ally.index
    local short = M.shortStaff(world, h, M.emergencyRooms(world, h))
    -- How long each kind has been missing there (the same days they count).
    local missing = {}
    for _, sh in ipairs(short) do
      if lends(sh) and (sh.built or sh.building) then
        local key = index .. ":" .. sh.cat
        missing[key] = true
        self.ally_lack[key] = self.ally_lack[key] or s.day
      end
    end
    for key in pairs(self.ally_lack) do
      if key:find("^" .. index .. ":") and not missing[key] then self.ally_lack[key] = nil end
    end
    for _, sh in ipairs(short) do
      local key = index .. ":" .. sh.cat
      local lacking = self.ally_lack[key] and s.day - self.ally_lack[key] >= (sh.emergency and LACK_EMERGENCY_DAYS or LACK_DAYS)
      if lends(sh) and (sh.built or sh.building) and s.day - (self.gave[key] or -999) >= GIVE_DAYS and
          (lacking or not bot:canHire(sh.cat, h)) and
          M.spareStaff(world, mine, sh.cat, s.emergency and s.emergency.rooms) > 0 then
        -- (The least skilled of them: it keeps its best.)
        local pick
        for _, st in ipairs(mine.staff) do
          if not st.fired and not st.mp_saboteur and not st.mp_in_transit and not st.mp_offer and st.mp_id and
              st:fulfillsCriterion(sh.cat) and (not pick or (st.profile.skill or 0) < (pick.profile.skill or 0)) then
            pick = st
          end
        end
        if pick and self:issue({kind = "offer_staff", to = index, staff = pick.mp_id}) then
          self.gave[key] = s.day
          local who = plain(pick.profile:getFullName())
          self:note(string.format("day %d: offered %s (%s) to hospital %d for its %s", s.day, who, sh.cat, index, sh.room))
          local peers, people = bot:peopleOfHospital(index)
          if #peers > 0 then
            local line = self.fill_in(self.pick(self.lines.staff_sent), {names = table.concat(people, " and "),
                who = who, kind = sh.cat:lower(), room = room_name(sh.room),
                urgent = sh.emergency and self.pick(self.lines.staff_for_emergency) or ""})
            bot:say(line, self.typing(line), table.concat(peers, ","))
          end
          return -- (one at a time)
        end
      end
    end
  end
end

--! The specialists this hospital lacks for a room (it has, or is building,
--! or patients ask for): {room, cat, need, have, built, building, emergency}.
--! A room it cannot build for want of one (M:projects) counts when patients
--! need it, or an ally wished for it. (Tests: MP_BOT_TEST_LACK="day:Cat:room"
--! makes it lack one from that game day.)
function M:lackedStaff(s)
  local lacks = {}
  local have_cat = {}
  for _, sh in ipairs(s.short) do
    if lends(sh) and (sh.built or sh.building) then
      lacks[#lacks + 1] = sh
      have_cat[sh.cat] = true
    end
  end
  local cats = {}
  for cat in pairs(self.blocked_spec) do cats[#cats + 1] = cat end
  table.sort(cats)
  for _, cat in ipairs(cats) do
    local b = self.blocked_spec[cat]
    if s.day - b.day <= 5 and not have_cat[cat] and SPECIALISTS[cat] then
      local need = 1
      for _, rt in ipairs(TheApp.rooms) do
        if rt.id == b.room then need = (rt.required_staff or {})[cat] or 1 end
      end
      lacks[#lacks + 1] = {room = b.room, cat = cat, need = need, have = s.hosp:countStaffOfCategory(cat),
          built = false, building = false, emergency = false}
      have_cat[cat] = true
    end
  end
  local test_day, test_cat, test_room = (os.getenv("MP_BOT_TEST_LACK") or ""):match("^(%d+):(%a+):([%w_]+)$")
  if test_day and s.day >= tonumber(test_day) and not have_cat[test_cat] then
    lacks[#lacks + 1] = {room = test_room, cat = test_cat, need = 1, have = 0, built = false, building = false,
        emergency = false, test = true}
  end
  return lacks
end

--! A specialist its own room needs (or patients ask a room for) and it has
--! lacked for LACK_DAYS (an emergency: sooner), whether or not one is on the
--! hiring list: the allies are asked (at most once in ASK_DAYS per kind; an
--! emergency sooner). Before, it asked only when none was on the hiring
--! list, which hardly ever happens: a room waits for its specialist to be on
--! the list before it is built. An allied bot with one to spare sends one by
--! itself (M:helpAllies, an offer): no need to ask. People with one to spare
--! are asked by name, else the team's chat asks everybody on its side.
function M:askAllies(s)
  local bot, world = self.bot, self.bot.world
  local lacks = self:lackedStaff(s)
  -- Since when each kind is missing (and forgotten once it is not).
  local now = {}
  for _, sh in ipairs(lacks) do
    now[sh.cat] = true
    self.lacking[sh.cat] = self.lacking[sh.cat] or s.day
  end
  for cat in pairs(self.lacking) do
    if not now[cat] then self.lacking[cat] = nil end
  end
  for _, sh in ipairs(lacks) do
    local wait = sh.emergency and ASK_DAYS_EMERGENCY or ASK_DAYS
    local days = s.day - self.lacking[sh.cat]
    -- (Only while it cannot hire one: none on the hiring list, or no money
    -- for the wage: Jan, 2026-11-12.)
    local cannot_hire = sh.test or not bot:canHire(sh.cat) or s.balance < RESERVE
    -- (And still so the next day: a new month's hiring list comes on its
    -- first day, and Bertie asked Jan for a psychiatrist that very day,
    -- before his own list had the one Jan's had. Jan, 2026-11-12.)
    self.cannot_hire_since = self.cannot_hire_since or {}
    if not cannot_hire then
      self.cannot_hire_since[sh.cat] = nil
    elseif not self.cannot_hire_since[sh.cat] then
      self.cannot_hire_since[sh.cat] = s.day
    end
    local looked_twice = sh.test or (self.cannot_hire_since[sh.cat] and s.day > self.cannot_hire_since[sh.cat])
    if days >= (sh.emergency and LACK_EMERGENCY_DAYS or LACK_DAYS) and cannot_hire and looked_twice and
        s.day - (self.asked_for[sh.cat] or -999) >= wait then
      local bot_spares, spare_peers, spare_names, everybody = false, {}, {}, {}
      for _, ally in ipairs(self:allies()) do
        local spare = M.spareStaff(world, ally.hosp, sh.cat, M.emergencyRooms(world, ally.hosp)) > 0
        local peers, names = bot:peopleOfHospital(ally.index)
        local _, _, is_bot = bot:playerOfHospital(ally.index)
        -- (An allied bot lends one by itself only for a room that stands or is being built.)
        if spare and #peers == 0 and is_bot and (sh.built or sh.building) then bot_spares = true end
        for i, peer in ipairs(peers) do
          everybody[#everybody + 1] = peer
          if spare then spare_peers[#spare_peers + 1], spare_names[#spare_names + 1] = peer, names[i] end
        end
      end
      -- (Nobody to read it, or an allied bot sends one anyway.)
      if not bot_spares and #everybody > 0 then
        self.asked_for[sh.cat] = s.day
        local urgent = sh.emergency and self.pick(self.lines.staff_for_emergency) or ""
        local needs = sh.need .. " " .. sh.cat:lower() .. (sh.need > 1 and "s" or "")
        local line, to
        if #spare_peers > 0 then
          line = self.fill_in(self.pick(self.lines.staff_ask_one), {names = table.concat(spare_names, " or "),
              kind = sh.cat:lower(), room = room_name(sh.room), needs = needs, have = sh.have, urgent = urgent})
          to = table.concat(spare_peers, ",")
        else
          line = self.fill_in(self.pick(self.lines.staff_ask_all), {kind = sh.cat:lower(), room = room_name(sh.room),
              needs = needs, have = sh.have, urgent = urgent})
          to = "team"
        end
        self:note(string.format("day %d: asked the allies for a %s (%s), missing for %d days", s.day, sh.cat,
            sh.room, days))
        bot:say(line, self.typing(line), to)
        return
      end
    end
  end
end

--------------------------------------------------------------------------------
-- The level's requirements: who meets them, and what the bot still lacks
--------------------------------------------------------------------------------

local function sorted_keys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    if type(a) == type(b) then return a < b end
    return type(a) == "number"
  end)
  return keys
end

--! Dollars in the chat: $850, $20k.
local function money(n)
  n = math.max(0, math.ceil(n))
  if n >= 1000 then return string.format("$%dk", math.ceil(n / 1000)) end
  return string.format("$%d", n)
end

--! A value of requirement `name` in the chat (money for the bank and the value).
local function amount(name, v)
  if name == "balance" or name == "value" then return money(v) end
  return string.format("%d", math.floor(v + 0.5))
end

--! Game days from the first (tests, MP_BOT_TEST_WIN).
local function game_day(world)
  local d = world:date()
  return (d:monthOfGame() - 1) * 30 + d:dayOfMonth()
end

--! How a hospital stands to the level's requirements to win, as the game
--! counts them (EndConditions): the group of goals it comes closest to,
--! {group, list = {{name, now, want, ok, progress}}, met, complete (every goal
--! of the group), loan, ready (complete and no loan: what the game wants for a
--! win), reached (the game already said so: the flag co-op and teams keep, or a
--! place won in a race)}. nil if the level has no goals.
--! (Tests: MP_BOT_TEST_WIN="<hospital index>:<day>;..." makes those hospitals
--! meet them from that game day on; "<room>/<hospital index>:<day>" only in
--! that room, MP_BOT_ROOM.)
function M.requirements(world, hosp)
  local ec = world.endconditions
  if not (ec and type(ec.win_goals) == "table" and ec.getAttribute) then return nil end
  local best
  for _, g in ipairs(sorted_keys(ec.win_goals)) do
    local list, met = {}, 0
    local goals = ec.win_goals[g]
    for _, name in ipairs(sorted_keys(goals)) do
      local crit = goals[name]
      if crit.win_value then
        local ok, now = pcall(ec.getAttribute, ec, hosp, name)
        now = ok and tonumber(now) or 0
        -- (max_min 1: at least this much; else at most.)
        local atleast = crit.max_min == 1
        local good = atleast and now >= crit.win_value or (not atleast and now <= crit.win_value)
        local progress
        if atleast then
          progress = crit.win_value > 0 and math.min(1, now / crit.win_value) or 1
        else
          progress = good and 1 or crit.win_value / math.max(now, 1)
        end
        list[#list + 1] = {name = name, now = now, want = crit.win_value, ok = good, progress = progress}
        if good then met = met + 1 end
      end
    end
    if #list > 0 then
      local score = met / #list
      if not best or score > best.score then best = {group = g, list = list, score = score, met = met} end
    end
  end
  if not best then return nil end
  best.loan = hosp.loan or 0
  best.complete = best.met == #best.list
  best.ready = best.complete and best.loan == 0
  best.reached = hosp.mp_goals_reached == true or (hosp.mp_place ~= nil and hosp.mp_place_how == "won")
  local forced = os.getenv("MP_BOT_TEST_WIN")
  if forced then
    local index = world:getHospitalIndex(hosp)
    local room = os.getenv("MP_BOT_ROOM") or ""
    for entry in forced:gmatch("[^;]+") do
      local where, i, day = entry:match("^%s*([%w_]-)/?(%d+):(%d+)%s*$")
      if i and (where == "" or where == room) and tonumber(i) == index and game_day(world) >= tonumber(day) then
        best.ready, best.reached = true, true
      end
    end
  end
  return best
end

--! Does this hospital meet the requirements to win (now, or already said so)?
function M.meets(world, hosp)
  local r = M.requirements(world, hosp)
  return r ~= nil and (r.ready or r.reached) or false
end

--! How many people can read what the bot says to its team: the people who
--! share its hospital and those who play allied hospitals.
function M:sideReaders()
  local bot = self.bot
  local n = #bot:hospitalMates()
  for _, ally in ipairs(self:allies()) do
    n = n + #bot:peopleOfHospital(ally.index)
  end
  return n
end

--! Is this the bot that speaks for its side when only one should: the allied
--! bot (itself included) with the lowest hospital number?
function M:isCaller()
  local bot = self.bot
  local mine = bot:hospitalIndex()
  for _, ally in ipairs(self:allies()) do
    local _, _, is_bot = bot:playerOfHospital(ally.index)
    if is_bot and ally.index < mine then return false end
  end
  return true
end

--! Names for the chat: "Ann", "Ann and Bob", "Ann, Bob and Cleo".
local function join_names(names)
  if #names <= 1 then return names[1] or "" end
  return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

--! The one thing this bot still lacks for the win, in a chat line: the
--! requirement it has said least about, the furthest from it first.
function M:needLine(me)
  local cands = {}
  for _, c in ipairs(me.list) do
    if not c.ok then cands[#cands + 1] = c end
  end
  local name, c = "loan", nil
  if #cands > 0 then
    self.need_said = self.need_said or {}
    table.sort(cands, function(a, b)
      local sa, sb = self.need_said[a.name] or 0, self.need_said[b.name] or 0
      if sa ~= sb then return sa < sb end
      if a.progress ~= b.progress then return a.progress < b.progress end
      return a.name < b.name
    end)
    c = cands[1]
    name = c.name
    self.need_said[name] = (self.need_said[name] or 0) + 1
  elseif me.loan <= 0 then
    return nil
  end
  local lines = self.lines.win_need[name]
  if not lines then return nil end
  local vars = {loan = money(me.loan)}
  if c then
    local left = math.max(1, math.ceil(c.want - c.now))
    vars.now, vars.want, vars.left = amount(name, c.now), amount(name, c.want), tostring(left)
    vars.short = money(left)
  end
  return self.fill_in(self.pick(lines), vars)
end

--! Once a day: the level's requirements in the team chat (only when a person
--! on its side can read it). When a person on its side now meets them, the
--! allied bot with the lowest number says so ("Good job, ..."); a bot that
--! meets them too says that in a line of its own; and a bot that does not
--! says what it still needs, one requirement at a time, again every 6 months
--! while an ally meets them and it does not.
function M:winChat(s)
  local bot, world = self.bot, self.bot.world
  if not (world.mp_coop and world.endconditions) then return end
  local me = M.requirements(world, s.hosp)
  if not me then return end
  local mine = me.ready or me.reached
  local newly, human_met = {}, false
  self.ally_met = self.ally_met or {}
  for _, ally in ipairs(self:allies()) do
    local meets = M.meets(world, ally.hosp)
    local peers, names = bot:peopleOfHospital(ally.index)
    if meets and #peers > 0 then human_met = true end
    if meets and not self.ally_met[ally.index] then
      self.ally_met[ally.index] = s.day
      for _, n in ipairs(names) do newly[#newly + 1] = n end
    elseif not meets then
      self.ally_met[ally.index] = nil
    end
  end
  local i_newly = mine and not self.me_met
  self.me_met = mine
  local mates = {}
  for _, peer in ipairs(bot:hospitalMates()) do mates[#mates + 1] = bot:playerName(peer) or "friend" end
  if self:sideReaders() == 0 then return end
  local stagger = (bot:botRank() - 1) * 3 -- (several bots: not all at the same moment)
  local function say(line, extra)
    bot:say(line, self.typing(line) + stagger + (extra or 0), "team")
  end
  local first = 0
  -- Somebody on its side got there: a good word, from one bot.
  if #newly > 0 and self:isCaller() then
    say(self.fill_in(self.pick(self.lines.win_good), {names = join_names(newly)}))
    first = 3
  end
  -- The people who share its hospital got there with it.
  if i_newly and #mates > 0 then
    say(self.fill_in(self.pick(self.lines.win_own), {names = join_names(mates)}))
    first = 3
  elseif mine and (#newly > 0 or (i_newly and human_met)) then
    say(self.pick(self.lines.win_me_too), first + 3)
  end
  -- Not there yet while an ally is: what is missing, now and every 6 months.
  if not mine and (human_met or next(self.ally_met)) and (#newly > 0 or s.day >= (self.need_next or 0)) then
    local line = self:needLine(me)
    if line then
      self.need_next = s.day + 180
      self:note(string.format("day %d: tells the team what it still needs for the win", s.day))
      say(line, first + 6)
    end
  end
end

--! In a race: an opponent (a bot or a person) that meets all the
--! requirements to win gets a warning in the team chat, as soon as the bot
--! sees it and then every 4 months while it is still so. Only one allied bot
--! says it (M:isCaller), and only when a person on the bot's side can read
--! it.
function M:rivalWatch(s)
  local bot, world = self.bot, self.bot.world
  if not (world.mp_coop and world.mp_coop.competitive and world.endconditions) then return end
  local winners, names, fresh = {}, {}, false
  self.rival_seen = self.rival_seen or {}
  for index, h in ipairs(world.hospitals) do
    local _, name = bot:playerOfHospital(index)
    if h ~= s.hosp and name and world:mpRivals(s.hosp, h) and M.meets(world, h) then
      winners[#winners + 1] = index
      names[#names + 1] = name
      if not self.rival_seen[index] then fresh = true end
    end
  end
  -- (One that stops meeting them is news again when it meets them again.)
  local now = {}
  for _, index in ipairs(winners) do now[index] = true end
  for index in pairs(self.rival_seen) do
    if not now[index] then self.rival_seen[index] = nil end
  end
  if #winners == 0 or not (fresh or s.day >= (self.rival_next or 0)) then return end
  for _, index in ipairs(winners) do self.rival_seen[index] = true end
  self.rival_next = s.day + RIVAL_WARN_DAYS
  if not self:isCaller() or self:sideReaders() == 0 then return end
  local line = self.fill_in(self.pick(#names > 1 and self.lines.win_rivals or self.lines.win_rival),
      {names = join_names(names)})
  self:note(string.format("day %d: warns the team: %s meet the winning conditions", s.day, join_names(names)))
  bot:say(line, self.typing(line), "team")
end

--------------------------------------------------------------------------------
-- Dealing with rivals and asking for help (Jan, 2026-11-12): a race is no
-- reason to turn down a good deal. A bot takes a rival's referred patient it
-- can treat, buys research its patients need (by how big it is: an X-ray
-- is worth more than a slack tongue clinic, up to RIVAL_PAY_MAX) and a
-- specialist it lacks badly. From month ASK_FROM_MONTH it asks for them
-- itself: an ally to share research for free, a rival for a price, and a
-- rival for a specialist (allies: M:askAllies), at most one ask a month and
-- the same player at most once in ASK_PLAYER_DAYS. A bot asked by another
-- bot answers with an offer (M:botRequest); a person answers in the game.
--------------------------------------------------------------------------------

local RIVAL_PAY_MAX = 4000      -- the most it pays a rival for research
local RIVAL_STAFF_PAY = 3000    -- ... for a specialist it lacks
local RIVAL_STAFF_PRICE = 2000  -- what it asks a rival for a spare specialist
local RIVAL_QUEUE = 4           -- a rival's patient only to a queue this short (per room)
local ASK_FROM_MONTH = 4        -- the first month it asks (after the third)
local ASK_PLAYER_DAYS = 90      -- game days between asks to the same player
local RIVAL_BUY_DAYS = 90       -- game days between research bought from the same rival
local RIVAL_LACK_DAYS = 30      -- a specialist missing this long is missed badly
local NEED_DAYS = 60            -- a room patients needed this lately is still wanted
M.RIVAL_PAY_MAX, M.RIVAL_STAFF_PAY, M.RIVAL_STAFF_PRICE = RIVAL_PAY_MAX, RIVAL_STAFF_PAY, RIVAL_STAFF_PRICE

local function round500(n) return math.floor((n + 250) / 500) * 500 end

--! Dollars in a chat line: $4,000.
local function price_text(n)
  local text = string.format("%d", math.max(0, math.floor(n + 0.5)))
  local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return "$" .. (out:gsub("^,", ""))
end
M.priceText = price_text

--! What one piece of research (a key of MultiplayerSession.shareableResearch:
--! e:<object>, m:<object>, d:<disease>) is worth to `mine` in dollars. A
--! discovery that opens a room in `need` (room id -> true: its patients
--! needed it lately): three quarters of the machine's price, a diagnosis
--! room a quarter more (it serves many diseases), $1,000 to RIVAL_PAY_MAX.
--! A better machine it has in a room: a quarter of its price, $500 to
--! $1,000; a better drug for a disease it treats: $500. Anything else: 0.
function M.researchValue(world, mine, key, need)
  local kind, id = tostring(key):match("^(%a):([%w_]+)$")
  local config = world.map and world.map.level_config
  local function machine_cost(object)
    local o = config and config.objects and object.thob and config.objects[object.thob]
    return o and o.StartCost or 0
  end
  if kind == "e" or kind == "m" then
    local object = TheApp.objects[id]
    if not object then return 0 end
    if kind == "e" then
      local best = 0
      for _, rt in ipairs(TheApp.rooms) do
        if need[rt.id] and rt.objects_needed and rt.objects_needed[id] then
          local v = machine_cost(object) * 0.75 * (rt.categories and rt.categories.diagnosis and 1.25 or 1)
          best = math.max(best, math.min(RIVAL_PAY_MAX, math.max(1000, round500(v))))
        end
      end
      return best
    end
    for _, r in pairs(world.rooms or {}) do
      if r.hospital == mine and not r.crashed and r.room_info and r.room_info.objects_needed and
          r.room_info.objects_needed[id] then
        return math.min(1000, math.max(500, round500(machine_cost(object) * 0.25)))
      end
    end
    return 0
  elseif kind == "d" then
    local case = mine.disease_casebook and mine.disease_casebook[id]
    if case and (case.recoveries or 0) + (case.turned_away or 0) > 0 then return 500 end
  end
  return 0
end

--! Rooms its patients needed lately (noted from the faxes, M:answerFaxes)
--! that it has not discovered: room id -> true.
function M:neededRooms(s)
  local need = {}
  for id, day in pairs(self.research_need) do
    if s.day - day <= NEED_DAYS and not self:available(id) then need[id] = true end
  end
  return need
end

--! What an offer of research (";"-separated keys) is worth to it, capped at
--! RIVAL_PAY_MAX, and whether any of it is new knowledge it can use.
function M:offerValue(s, keys)
  local need = self:neededRooms(s)
  local world = self.bot.world
  local total, any = 0, false
  for key in tostring(keys or ""):gmatch("[^;]+") do
    local v = M.researchValue(world, s.hosp, key, need)
    total = total + v
    if v > 0 or key:sub(1, 2) == "e:" then any = true end
  end
  return math.min(RIVAL_PAY_MAX, total), any
end

--! How far `hosp` is on the level's goals (0 to 1; 0 without goals).
local function goal_progress(world, hosp)
  local r = M.requirements(world, hosp)
  if not r then return 0 end
  local sum = 0
  for _, c in ipairs(r.list) do sum = sum + c.progress end
  return #r.list > 0 and sum / #r.list or 0
end

--! Would it help rival `h` (sell it research or a specialist)? Not one
--! that meets the goals or is well ahead of it (a fifth of the way).
function M:helpsRival(s, h)
  local world = self.bot.world
  if M.meets(world, h) then return false end
  return goal_progress(world, h) <= goal_progress(world, s.hosp) + 0.2
end

--! The kind of specialist it lacks now that `staff` is, or nil.
function M:lackedKind(s, staff)
  if not (staff and staff.fulfillsCriterion) then return nil end
  for _, sh in ipairs(self:lackedStaff(s)) do
    if staff:fulfillsCriterion(sh.cat) then return sh.cat end
  end
end

--! Does it deal with rivals at all? Only in a race where everyone plays
--! alone: in a race of teams only with its team mates (Jan, 2026-11-12), also
--! where the game (build 25eb54cb) would let the other team trade.
local function deals_with_rivals(world)
  return not (world.mp_coop and world.mp_coop.teams)
end
M.dealsWithRivals = deals_with_rivals

--! A rival's offer (Bot:answerOffers): accept it?, and its answer (a line
--! filled in), or nil for the usual refusal.
function M:rivalOffer(offer, name)
  local s = self.s
  if not s or not deals_with_rivals(self.bot.world) then return false end
  local bot, world = self.bot, self.bot.world
  local L = self.lines
  local function say(set, vars)
    vars = vars or {}
    vars.name = name
    return self.fill_in(self.pick(set), vars)
  end
  local price = offer.price or 0
  if offer.kind == "patient" then
    local patient = world:getEntityById(offer.entity)
    if not bot:canTreat(patient) then return false, say(L.rival_cannot_treat) end
    local rooms = patient and patient.diagnosed and patient.disease and patient.disease.treatment_rooms
    local room = rooms and rooms[1] or "gp"
    if (s.queue[room] or 0) / math.max(1, s.rooms[room] or 1) > RIVAL_QUEUE then
      return false, say(L.rival_patient_busy)
    end
    self:note(string.format("day %d: takes a patient from %s (rival)", s.day, name))
    return true, say(L.rival_patient_yes)
  elseif offer.kind == "research" then
    local value, any = self:offerValue(s, offer.items)
    if price == 0 then
      if any then
        self:note(string.format("day %d: takes free research from %s (rival)", s.day, name))
        return true, say(L.rival_research_free)
      end
      return false, say(L.rival_research_useless)
    end
    if value <= 0 then return false, say(L.rival_research_useless) end
    if price > value then
      self:note(string.format("day %d: research from %s for $%d: too dear (worth $%d)", s.day, name, price, value))
      return false, say(L.rival_research_dear, {value = price_text(value)})
    end
    local last = self.rival_bought[offer.from]
    if last and s.day - last < RIVAL_BUY_DAYS then return false, say(L.rival_research_later) end
    if s.balance - price < RESERVE then return false, say(L.rival_broke) end
    self.rival_bought[offer.from] = s.day
    self:note(string.format("day %d: buys research from %s for $%d (worth $%d)", s.day, name, price, value))
    return true, say(L.rival_research_yes, {value = price_text(price)})
  elseif offer.kind == "staff" then
    local kind = self:lackedKind(s, world:getEntityById(offer.entity))
    if not kind then return false end
    if price > RIVAL_STAFF_PAY then
      return false, say(L.rival_staff_dear, {value = price_text(RIVAL_STAFF_PAY), kind = kind:lower()})
    end
    if s.balance - price < RESERVE then return false, say(L.rival_broke) end
    self:note(string.format("day %d: buys a %s from %s for $%d", s.day, kind, name, price))
    return true, say(L.rival_staff_yes, {kind = kind:lower()})
  end
  return false
end

--! The undiscovered machine of room `room_id` that hospital `from` could
--! give `to` (an item of MultiplayerSession.shareableResearch), or nil.
local function research_for_room(from, to, room_id)
  local rt = room_types()[room_id]
  if not (rt and rt.objects_needed and MultiplayerSession.shareableResearch) then return nil end
  for _, item in ipairs(MultiplayerSession.shareableResearch(from, to)) do
    if item.kind == "e" and rt.objects_needed[item.object.id] then return item end
  end
end

--! The players to ask in hospital `index`: its people, or its bot when
--! nobody else plays it ({peers, names, bot}); nil when there is none.
function M:contactsOf(index)
  local bot = self.bot
  local peers, names = bot:peopleOfHospital(index)
  if #peers > 0 then return {peers = peers, names = names, bot = false} end
  local peer, name, is_bot = bot:playerOfHospital(index)
  if peer and name and is_bot then return {peers = {peer}, names = {name}, bot = true} end
end

--! The hospitals it may ask now (allies or rivals): index, hosp, contacts;
--! not asked in ASK_PLAYER_DAYS.
function M:askable(s, rivals)
  local world = self.bot.world
  local out = {}
  if rivals and not deals_with_rivals(world) then return out end
  for index, h in ipairs(world.hospitals) do
    if h ~= s.hosp and not h.mp_place and world:mpMayTrade(s.hosp, h) and world:mpRivals(s.hosp, h) == rivals and
        s.day - (self.player_asked[index] or -999) >= ASK_PLAYER_DAYS then
      local who = self:contactsOf(index)
      if who then out[#out + 1] = {index = index, hosp = h, who = who} end
    end
  end
  return out
end

--! Once a month from ASK_FROM_MONTH: the research its patients need (an ally
--! who has it is asked to share it, else a rival is offered money for it),
--! or a specialist it has missed badly and cannot hire (a rival who can
--! spare one; the allies are asked in M:askAllies). Called every day.
function M:askForNeeds(s)
  local bot, world = self.bot, self.bot.world
  if not world.mp_coop or s.month < ASK_FROM_MONTH or self.asked_month == s.month then return end
  if bot:sharesWithPerson() or s.hosp.mp_place then return end
  local function ask(target, set, vars, what)
    vars.name = table.concat(target.who.names, " and ")
    local line = self.fill_in(self.pick(set), vars)
    self.player_asked[target.index] = s.day
    self.asked_month = s.month
    self:note(string.format("day %d: asks hospital %d (%s) for %s", s.day, target.index,
        target.who.bot and "a bot" or "a person", what))
    bot:say(line, self.typing(line), table.concat(target.who.peers, ","))
  end
  if not world.mp_coop.sharing_off then
    local need = self:neededRooms(s)
    -- (The room most patients asked for first.)
    local order = sorted_keys(need)
    table.sort(order, function(a, b)
      local da, db = self.demand[a] or 0, self.demand[b] or 0
      if da ~= db then return da > db end
      return a < b
    end)
    for _, rid in ipairs(order) do
      for _, rivals in ipairs({false, true}) do
        for _, target in ipairs(self:askable(s, rivals)) do
          local item = research_for_room(target.hosp, s.hosp, rid)
          if item then
            local vars = {item = plain(item.name), room = room_name(rid)}
            if rivals then
              vars.price = price_text(M.researchValue(world, s.hosp, item.key, need))
              ask(target, self.lines.research_buy, vars, item.key .. " for " .. vars.price)
            else
              ask(target, self.lines.research_please, vars, item.key .. " (free)")
            end
            return
          end
        end
      end
    end
  end
  for _, sh in ipairs(self:lackedStaff(s)) do
    local since = self.lacking[sh.cat]
    if sh.built and since and s.day - since >= RIVAL_LACK_DAYS and not bot:canHire(sh.cat) and
        s.day - (self.rival_staff_asked[sh.cat] or -999) >= ASK_PLAYER_DAYS then
      for _, target in ipairs(self:askable(s, true)) do
        if M.spareStaff(world, target.hosp, sh.cat, M.emergencyRooms(world, target.hosp)) > 0 then
          self.rival_staff_asked[sh.cat] = s.day
          ask(target, self.lines.staff_ask_rival, {kind = sh.cat:lower(), room = room_name(sh.room)},
              "a " .. sh.cat)
          return
        end
      end
    end
  end
end

--! Patterns that read the asks of M:askForNeeds back: {pattern, names (what
--! each capture is: item, kind, price), set}.
local ask_patterns
local function asks_of(lines)
  if ask_patterns then return ask_patterns end
  ask_patterns = {}
  for _, set in ipairs({"research_buy", "research_please", "staff_ask_rival"}) do
    for _, line in ipairs(lines[set] or {}) do
      local names = {}
      local pattern = line:gsub("[%%%^%$%(%)%.%[%]%*%+%-%?]", "%%%0"):gsub("{(%w+)}", function(k)
        if k == "item" or k == "kind" then
          names[#names + 1] = k
          return "(.-)"
        end
        if k == "price" then
          names[#names + 1] = k
          return "%$([%d,]+)"
        end
        return ".-"
      end)
      ask_patterns[#ask_patterns + 1] = {pattern = "^" .. pattern .. "$", names = names, set = set}
    end
  end
  return ask_patterns
end

--! Read an ask of M:askForNeeds: {set, item, kind, price}, or nil.
function M.readAsk(lines, text)
  for _, a in ipairs(asks_of(lines)) do
    local caps = {text:match(a.pattern)}
    if caps[1] then
      local out = {set = a.set}
      for i, k in ipairs(a.names) do out[k] = caps[i] end
      if out.price then out.price = tonumber((out.price:gsub(",", ""))) end
      return out
    end
  end
end

--! Another bot asked it (privately) for research or a specialist
--! (M:askForNeeds): it answers with an offer, an ally for free, a rival for
--! the price named (research) or RIVAL_STAFF_PRICE (a specialist), unless
--! that rival is ahead (M:helpsRival). People decide for themselves.
function M:botRequest(peer, name, text)
  local s = self.s
  local bot, world = self.bot, self.bot.world
  if not s or not world.mp_coop or bot:sharesWithPerson() then return end
  local ask = M.readAsk(self.lines, text)
  if not ask then return end
  local index = (bot.lobby.peer_hospital or {})[peer]
  local h = index and world.hospitals[index]
  if not h or h == s.hosp or not world:mpMayTrade(s.hosp, h) then return end
  local rival = world:mpRivals(s.hosp, h)
  if rival and not deals_with_rivals(world) then return end
  local L = self.lines
  local function reply(set, vars)
    vars = vars or {}
    vars.name = name
    local line = self.fill_in(self.pick(set), vars)
    bot:say(line, 3 + self.typing(line), tostring(peer))
  end
  if ask.set == "research_buy" or ask.set == "research_please" then
    local item
    local shareable = MultiplayerSession.shareableResearch and MultiplayerSession.shareableResearch(s.hosp, h) or {}
    for _, it in ipairs(shareable) do
      if plain(it.name) == ask.item then item = it end
    end
    if not item or world.mp_coop.sharing_off then
      self:note(string.format("day %d: %s asked for %s research: none to give", s.day, name, tostring(ask.item)))
      return reply(L.ask_research_none, {item = ask.item})
    end
    local price = rival and math.max(MultiplayerSession.RIVAL_MIN_PRICE or 1000, ask.price or 0) or 0
    if rival and not self:helpsRival(s, h) then
      self:note(string.format("day %d: %s (ahead) asked for %s research: refused", s.day, name, item.key))
      return reply(L.ask_rival_ahead)
    end
    if self:issue({kind = "offer_research", to = index, items = item.key, price = price}) then
      self:note(string.format("day %d: offers %s research to %s for $%d (asked)", s.day, item.key, name, price))
      reply(rival and L.ask_research_sold or L.ask_research_shared, {item = ask.item, price = price_text(price)})
    end
  elseif ask.set == "staff_ask_rival" then
    local cat
    for _, c in ipairs({"Surgeon", "Psychiatrist", "Researcher", "Consultant"}) do
      if c:lower() == ask.kind then cat = c end
    end
    if not cat then return end
    if rival and not self:helpsRival(s, h) then
      self:note(string.format("day %d: %s (ahead) asked for a %s: refused", s.day, name, cat))
      return reply(L.ask_rival_ahead)
    end
    if M.spareStaff(world, s.hosp, cat, s.emergency and s.emergency.rooms) < 1 then
      self:note(string.format("day %d: %s asked for a %s: none to spare", s.day, name, cat))
      return reply(L.ask_staff_none, {kind = ask.kind})
    end
    local pick
    for _, st in ipairs(s.hosp.staff) do
      if not st.fired and not st.mp_saboteur and not st.mp_in_transit and not st.mp_offer and st.mp_id and
          st:fulfillsCriterion(cat) and (not pick or (st.profile.skill or 0) < (pick.profile.skill or 0)) then
        pick = st
      end
    end
    local price = rival and RIVAL_STAFF_PRICE or 0
    if pick and self:issue({kind = "offer_staff", to = index, staff = pick.mp_id, price = price > 0 and price or nil}) then
      local who = plain(pick.profile:getFullName())
      self:note(string.format("day %d: offers %s (%s) to %s for $%d (asked)", s.day, who, cat, name, price))
      reply(L.ask_staff_sold, {who = who, kind = ask.kind, price = price_text(price)})
    end
  end
end

--------------------------------------------------------------------------------
-- A hospital that is failing its objectives: review with the model, ask the allies
--------------------------------------------------------------------------------

--! Dollars with thousands separators: 20,000.
local function dollars(n)
  local text = string.format("%d", math.max(0, math.floor(n + 0.5)))
  local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
  return (out:gsub("^,", ""))
end

--! Why this hospital is failing its objectives, as a list of reasons (empty:
--! it is not): close to a way of losing the level, failing at the last year
--! end (a race, or co-op), far behind the goals a year in, out of money and
--! loans, or a low reputation that keeps falling. (Tests: MP_BOT_TEST_FAIL
--! makes it fail from that game day.)
function M:failing(s)
  local world, hosp = self.bot.world, s.hosp
  local reasons = {}
  local forced = tonumber(os.getenv("MP_BOT_TEST_FAIL") or "")
  if forced and s.day >= forced then reasons[#reasons + 1] = "(a test) the objectives are not met" end
  -- A group of lose goals all past the point where the game warns, and half
  -- the way to the limit or more (as EndConditions:generateReportTable counts it).
  local ec = world.endconditions
  if ec and type(ec.lose_goals) == "table" and ec.getAttribute then
    for _, g in ipairs(sorted_keys(ec.lose_goals)) do
      local total, near, worst, names = 0, 0, 1, {}
      for _, name in ipairs(sorted_keys(ec.lose_goals[g])) do
        local crit = ec.lose_goals[g][name]
        total = total + 1
        local ok, now = pcall(ec.getAttribute, ec, hosp, name)
        local mm = crit.max_min == 1 and 1 or -1
        if ok and tonumber(now) and crit.boundary and crit.lose_value and crit.boundary ~= crit.lose_value and
            (tonumber(now) - crit.boundary) * mm > 0 then
          near = near + 1
          names[#names + 1] = name
          worst = math.min(worst, 1 - (tonumber(now) - crit.lose_value) / (crit.boundary - crit.lose_value))
        end
      end
      if total > 0 and near == total and worst >= 0.5 then
        reasons[#reasons + 1] = "close to losing the level (" .. table.concat(names, ", ") .. ")"
      end
    end
  end
  if hosp.mp_failing_since then
    reasons[#reasons + 1] = "it failed the goals at the last year end and fails the level at the next"
  end
  -- A year in and far from the goals.
  local me = s.month >= 12 and M.requirements(world, hosp)
  if me and not (me.ready or me.reached) then
    local sum, n = 0, 0
    for _, c in ipairs(me.list) do
      if c.name ~= "months_played" then sum, n = sum + c.progress, n + 1 end
    end
    if n > 0 and sum / n < 0.3 then
      reasons[#reasons + 1] = string.format("far behind on the goals after %d months (%d%% of the way)", s.month,
          math.floor(100 * sum / n + 0.5))
    end
  end
  -- No money, no loan left.
  if hosp.opened and s.balance < 2000 and s.loan >= s.max_loan - 5000 then
    self.broke_since = self.broke_since or s.day
    if s.day - self.broke_since >= 20 then reasons[#reasons + 1] = "out of money with the loan used up" end
  else
    self.broke_since = nil
  end
  -- A low reputation that fell by 50 or more in the last 3 months.
  self.rep_hist = self.rep_hist or {}
  if self.rep_hist.month ~= s.month then
    self.rep_hist.month = s.month
    table.insert(self.rep_hist, s.reputation)
    if #self.rep_hist > 4 then table.remove(self.rep_hist, 1) end
  end
  if #self.rep_hist >= 4 and s.reputation < 250 and s.reputation <= self.rep_hist[1] - 50 then
    reasons[#reasons + 1] = string.format("reputation %d and falling (it was %d three months ago)",
        math.floor(s.reputation), math.floor(self.rep_hist[1]))
  end
  return reasons
end

--! What the weakest of the level's goals needs, in words after "to": raise the
--! value of my hospital, cure more patients...
function M:goalWords(s)
  local me = M.requirements(self.bot.world, s.hosp)
  local worst
  for _, c in ipairs(me and me.list or {}) do
    if not c.ok and c.name ~= "months_played" and (not worst or c.progress < worst.progress) then worst = c end
  end
  local words = {value = "raise the value of my hospital", reputation = "improve my reputation",
      num_cured = "cure more patients", percentage_cured = "cure more patients",
      percentage_killed = "keep more patients alive", staff_happiness = "make my staff happier",
      patient_happiness = "make my patients happier", balance = "get my finances back in order"}
  return words[worst and worst.name or ""] or "get back on track"
end

--! A project in words after "to": build a new X-Ray room, hire a surgeon...
local function purpose_words(key)
  local kind, what = key:match("^(%a+):([^:@]+)")
  if kind == "room" then
    return "build a new " .. wish_words(key)
  elseif kind == "hire" then
    return "hire " .. wish_words(key)
  elseif key == "buy:land" then
    return "buy more land"
  elseif kind == "buy" then
    return "buy a " .. what:gsub("_", " ")
  elseif kind == "repair" then
    return "repair the " .. wish_words("room:" .. what)
  elseif kind == "replace" then
    return "replace the machine in the " .. wish_words("room:" .. what)
  end
  return nil
end

--! The bot's last big spending (M:noteSpent) in words for the chat: "the new
--! X-Ray room ($12,000)", if it was within SPENT_DAYS game days of `day`;
--! else nil.
function M:spentWords(day)
  local sp = self.spent
  if not sp or day - sp.day > SPENT_DAYS then return nil end
  local kind, what = sp.key:match("^(%a+):([^:@]+)")
  local words
  if kind == "room" then
    words = "the new " .. wish_words(sp.key)
  elseif sp.key == "buy:land" then
    words = "a new plot of land"
  elseif kind == "repair" then
    words = "repairing the " .. wish_words("room:" .. what)
  elseif kind == "replace" then
    words = "a new machine for the " .. wish_words("room:" .. what)
  elseif kind == "add" then
    words = "the " .. wish_words(sp.key)
  elseif kind == "bigger" then
    words = "making the " .. wish_words("room:" .. what) .. " bigger"
  elseif kind == "gift" then
    words = "the money I sent to " .. what
  elseif sp.key == "loan" then
    words = "paying back my loan"
  elseif sp.key == "trick" then
    words = "a dirty trick"
  elseif kind == "buy" then
    words = "a new " .. what:gsub("_", " ")
  else
    return nil
  end
  return string.format("%s ($%s)", words, dollars(sp.cost))
end

--------------------------------------------------------------------------------
-- An ally asks for one of its plots (Bot:answerPlotRequest; the other way
-- round, a plot an ally offers it, is M:plotAnswer)
--------------------------------------------------------------------------------

-- An ally may ask a bot in the chat for one of its plots (Jan, 2026-11-08).
-- It hands over an empty plot that the game lets it give
-- (MultiplayerSession.plotRefusal: its own, not the starting plot, empty,
-- nobody on it, not the plot that joins the rest of its land to the
-- hospital) unless it needs it:
--  * the land: without the plot less than PLOT_TAKE_FREE of its indoor floor
--    would be free (it would take that plot back if it were offered,
--    M:plotAnswer), or it would be looking for land (M:landWanted, counted
--    without the plot: rooms that found no floor lately while too little
--    floor is left, or BOT_LAND_FILL full);
--  * rooms to come: it bought the plot itself in the last PLOT_FRESH_DAYS
--    game days (it buys land for rooms that found no floor);
--  * the level's hospital value goal: without what the plot cost it
--    (MultiplayerSession.plotPaid; the plot is empty, nothing else on it
--    counts) its value would be under the goal, and the hospital has not
--    reached the level's requirements yet (the game's flag, M.requirements).
-- A bank under the floor it keeps when an ally asks for money (Bot GIVE_KEEP,
-- $15,000) is short of cash: then it asks what the plot cost it, rounded to
-- PLOT_PRICE_STEP (at least one step, at most PLOT_MAX_PRICE); else the
-- plot is free.
local PLOT_FRESH_DAYS = 30
-- An offer it sent counts as waiting for an answer this long before the game
-- shows it (the command runs a few steps later).
local PLOT_SENT_DAYS = 1
-- What it says: {name}, {plot}, {price}, {terms} ("for free", "for $8,000"),
-- {want} (the value goal).
local PLOT_ASK_LINES = {
  free = {"Plot {plot} is yours, {name}, free of charge. Just accept the fax.",
      "You can have plot {plot} for nothing, {name}. The offer is in your faxes.",
      "Sure, {name}: plot {plot}, free. Accept the fax and it's yours."},
  price = {"You can have plot {plot} for ${price}, {name}: what it cost me. My bank is low, sorry.",
      "Plot {plot} is yours for ${price}, {name}. That's what I paid, and I'm short of cash right now.",
      "{name}, I'm low on money, so plot {plot} is ${price}, what it cost me. The offer is in your faxes."},
  wait = {"Plot {plot} is yours {terms}, {name}. Somebody is on it right now: the fax comes once they're off.",
      "You can have plot {plot} {terms}, {name}. I'll send the offer as soon as nobody is on it.",
      "{name}, plot {plot} is yours {terms} once the people on it have walked off. The fax follows."},
  in_use = {"Sorry {name}, I use plot {plot}: there are rooms or things of mine on it.",
      "Plot {plot} is in use, {name}. My rooms and things stand on it.",
      "I can't give you plot {plot}, {name}, my rooms and things are on it."},
  land = {"Sorry {name}, I need plot {plot} myself: my hospital would be short of floor without it.",
      "I'd be too cramped without plot {plot}, {name}. I need the space.",
      "{name}, plot {plot} stays with me: I need the land for my rooms."},
  fresh = {"Sorry {name}, I only just bought plot {plot} for my next rooms.",
      "Plot {plot} is for my next rooms, {name}. I bought it for them.",
      "{name}, I bought plot {plot} a few days ago to build on. It stays with me."},
  value = {"Sorry {name}, without plot {plot} my hospital value would be under the {want} the level asks for.",
      "I need plot {plot} for the hospital value goal ({want}), {name}.",
      "{name}, plot {plot} counts towards my hospital value, and I need it for the level's goal of {want}."},
  none = {"Sorry {name}, I have no plot to spare right now.",
      "I have no land to spare, {name}. My plots are all in use.",
      "Nothing to spare, {name}: I use all my land or need it."},
  not_mine = {"Plot {plot} isn't mine, {name}.", "I don't own plot {plot}, {name}.",
      "{name}, plot {plot} belongs to somebody else, not me."},
  no_such = {"There is no plot {plot}, {name}.", "Plot {plot}? There's no such plot, {name}."},
  start = {"Plot {plot} is my starting plot, {name}. That one stays with me.",
      "I can't give away plot {plot}, {name}: my hospital started there."},
  joins = {"Plot {plot} joins the rest of my land to my hospital, {name}. I can't give it away.",
      "Without plot {plot} the rest of my land would be cut off, {name}. Sorry."},
  far = {"Plot {plot} doesn't touch your land, {name}, so I can't hand it over.",
      "{name}, plot {plot} would have to touch your land for me to give it to you."},
  offered = {"I've already offered plot {plot}, {name}. Check the faxes.",
      "Plot {plot} is already on offer, {name}."},
  auction = {"Ask me again after the auction, {name}.", "Not during the auction, {name}. Ask me again after it."},
  same = {"We share this hospital, {name}: its land is yours as much as mine.",
      "No need, {name}: we run the same hospital and its land."},
  -- (A plot promised once nobody is on it, Bot:plotWaitTick: people kept
  -- walking over it.)
  busy = {"Sorry {name}, people keep walking over plot {plot}. Ask me again later.",
      "{name}, plot {plot} is never empty of people for long. Try asking me again later."},
}
M.PLOT_ASK_LINES = PLOT_ASK_LINES
-- plotRefusal's reasons -> the line it says.
local PLOT_REFUSED = {["no such plot"] = "no_such", ["not your plot"] = "not_mine", ["starting plot"] = "start",
    ["an auction is on"] = "auction", ["plot not empty"] = "in_use", ["joins your land"] = "joins",
    ["does not touch their land"] = "far", ["already offered"] = "offered"}
M.PLOT_REFUSED = PLOT_REFUSED

--! Note a plot it asks to buy itself (Bot:buyPlot): it is kept for the
--! rooms to come (PLOT_FRESH_DAYS).
function M:notePlotBought(plot)
  if plot then self.plot_bought[plot] = self.bot:gameDay() end
end

--! Note a plot it offered to an ally (until the game shows the offer).
function M:notePlotOffered(plot)
  self.plot_sent[plot] = self.bot:gameDay()
end

--! Is a fax offering `plot` waiting for an answer (the check the game's own
--! offer_plot makes)?
function M.plotOnOffer(world, plot)
  local id = world.mp_plot_offers and world.mp_plot_offers[plot]
  local panel = world.ui and world.ui.bottom_panel
  return id ~= nil and panel ~= nil and panel.findMessageIcon ~= nil and panel:findMessageIcon(id) ~= nil
end

--! Its indoor floor as MultiplayerSession.landFill counts it: {inside =
--! tiles, rooms = tiles with a room, per_plot = plot -> tiles}.
local function indoor_floor(world, hosp)
  local th = world.map.th
  local player = hosp:getPlayerIndex()
  local w, h = th:size()
  local flags = {}
  local land = {inside = 0, rooms = 0, per_plot = {}}
  for y = 1, h do
    for x = 1, w do
      th:getCellFlags(x, y, flags)
      if flags.hospital and flags.owner == player then
        land.inside = land.inside + 1
        if (flags.roomId or 0) ~= 0 then land.rooms = land.rooms + 1 end
        local p = flags.parcelId or 0
        land.per_plot[p] = (land.per_plot[p] or 0) + 1
      end
    end
  end
  return land
end

--! What it asks for `plot`: nothing, or, short of cash (a bank under
--! `keep`), what the plot cost it, rounded to PLOT_PRICE_STEP, from one step
--! to PLOT_MAX_PRICE.
function M.plotPrice(world, hosp, plot, keep)
  local paid = MultiplayerSession.plotPaid(world, plot)
  if hosp.balance >= keep or paid <= 0 then return 0 end
  local step = MultiplayerSession.PLOT_PRICE_STEP
  return math.max(step, math.min(MultiplayerSession.PLOT_MAX_PRICE, math.floor(paid / step + 0.5) * step))
end

--! Why it keeps `plot` (one the game would let it hand over): "land",
--! "fresh", "value" or nil (it can spare it); and what it worked out, for
--! the log: {fill = how full its land would be without it, want = the value goal}.
function M:plotNeed(s, plot, land)
  local bot, world = self.bot, self.bot.world
  local left = land.inside - (land.per_plot[plot] or 0)
  local info = {fill = left > 0 and land.rooms / left or 1}
  -- Its free floor without the plot's.
  local tiles = MultiplayerSession.plotTiles(world.map.th, plot)
  local free_on = 0
  for i = 1, #tiles, 2 do
    if bot:freeTile(tiles[i], tiles[i + 1]) then free_on = free_on + 1 end
  end
  land.free_floor = land.free_floor or bot:freeFloor()
  if 1 - info.fill < PLOT_TAKE_FREE or self:landWanted(s, land.free_floor - free_on, info.fill) then
    return "land", info
  end
  local bought = self.plot_bought[plot]
  if bought and s.day - bought <= PLOT_FRESH_DAYS then return "fresh", info end
  local r = M.requirements(world, s.hosp)
  if r and not r.reached then
    for _, c in ipairs(r.list) do
      if c.name == "value" and c.now - MultiplayerSession.plotPaid(world, plot) < c.want then
        info.want = c.want
        return "value", info
      end
    end
  end
  return nil, info
end

--! An ally (hospital `asker`, called `name`) asks for one of its plots:
--! `plot`, or any it can spare (nil). `keep`: the bank's floor for gifts to
--! allies (Bot GIVE_KEEP). Without a number it picks, among its plots the
--! game would let go and it does not need, one that touches the asker's land
--! first (MultiplayerSession.plotsTouching), then the smallest, then the
--! lowest number; with none, it says why it keeps the best of the rest.
--!return {give = true: offer `plot` for `price` (wait = "people": once nobody
--! is on it), why = the kind of answer (a key of PLOT_ASK_LINES), line = what
--! it says}
function M:plotRequest(asker, plot, keep, name)
  local bot, world = self.bot, self.bot.world
  local hosp, to = world.ui.hospital, world.hospitals[asker or 0]
  local th = world.map.th
  local today = bot:gameDay()
  local s = self.state and self.state.day == today and self.state or {hosp = hosp, day = today}
  local v = {plot = plot, price = 0}
  local function answer(why, detail, want)
    v.why = why
    local price = v.price > 0 and dollars(v.price)
    v.line = self.fill_in(self.pick(PLOT_ASK_LINES[why]), {name = name, plot = v.plot or "", price = price or "",
        terms = price and ("for $" .. price .. ", what it cost me") or "for free", want = want and money(want) or ""})
    self.log(string.format("plot request from %s (plot %s): %s%s", tostring(name), tostring(plot or "any"),
        v.give and string.format("offers plot %d for $%d", v.plot, v.price) or ("keeps it: " .. why),
        detail and (" (" .. detail .. ")") or ""))
    return v
  end
  if not to then return answer("none") end
  if to == hosp then return answer("same") end
  if world.mp_auction then return answer("auction") end
  -- Why the game would not let it hand `p` to the asker now (nil: it would).
  local function refusal(p)
    local why = MultiplayerSession.plotRefusal(world, hosp, p)
    -- (The released game wants the plot to touch the asker's land: guarded.)
    if not why and MultiplayerSession.plotHandoverRefusal then
      why = MultiplayerSession.plotHandoverRefusal(world, to, p)
    end
    -- (Offered, about to be, or promised once nobody is on it: Bot:plotWaitTick.)
    if not why and (M.plotOnOffer(world, p) or today - (self.plot_sent[p] or -99) <= PLOT_SENT_DAYS or
        (bot.plot_wait and bot.plot_wait.plot == p)) then
      why = "already offered"
    end
    return why
  end
  local land = indoor_floor(world, hosp)
  local function detail(info, p)
    return string.format("land %d%% full without it, bank $%d, it cost $%d", math.floor(info.fill * 100 + 0.5),
        math.floor(hosp.balance), math.floor(MultiplayerSession.plotPaid(world, p)))
  end
  local function offer(p, wait, info)
    v.give, v.plot, v.wait = true, p, wait or nil
    v.price = M.plotPrice(world, hosp, p, keep)
    return answer(wait and "wait" or (v.price > 0 and "price" or "free"), detail(info, p))
  end
  if plot then
    local why = refusal(plot)
    if why and why ~= "people on the plot" then return answer(PLOT_REFUSED[why] or "none", why) end
    local need, info = self:plotNeed(s, plot, land)
    if need then return answer(need, detail(info, plot), info.want) end
    return offer(plot, why and "people", info)
  end
  -- Any plot: the ones it may give, the best first.
  local mine = hosp:getPlayerIndex()
  local theirs = to:getPlayerIndex()
  local spare, kept, offered = {}, {}, nil
  for p = 1, th:getPlotCount() do
    if th:getPlotOwner(p) == mine and not MultiplayerSession.isStartingPlot(world, p) then
      local why = refusal(p)
      if not why or why == "people on the plot" then
        local touches = false
        for q in pairs(MultiplayerSession.plotsTouching(world, p)) do
          if th:getPlotOwner(q) == theirs then touches = true end
        end
        local need, info = self:plotNeed(s, p, land)
        local entry = {plot = p, busy = why ~= nil, touches = touches, need = need, info = info,
            tiles = #MultiplayerSession.plotTiles(th, p)}
        if need then kept[#kept + 1] = entry else spare[#spare + 1] = entry end
      elseif why == "already offered" then
        offered = offered or p
      end
    end
  end
  local function better(a, b)
    if a.busy ~= b.busy then return not a.busy end
    if a.touches ~= b.touches then return a.touches end
    if a.tiles ~= b.tiles then return a.tiles < b.tiles end
    return a.plot < b.plot
  end
  table.sort(spare, better)
  table.sort(kept, better)
  if spare[1] then return offer(spare[1].plot, spare[1].busy and "people", spare[1].info) end
  if kept[1] then
    v.plot = kept[1].plot
    return answer(kept[1].need, detail(kept[1].info, kept[1].plot), kept[1].info.want)
  end
  if offered then
    v.plot = offered
    return answer("offered")
  end
  return answer("none")
end

--! The bot is failing its objectives: it asks its allies, in the team chat,
--! for one concrete thing: money for the project it cannot afford that now
--! matters most (the top of its list that the bank cannot pay), and what for.
function M:askForHelp(s, reasons)
  if self:sideReaders() == 0 then return end
  local list = self:projects(s)
  local pick
  -- The top project the bank cannot pay, else the top one that costs anything.
  for i = 1, math.min(#list, 8) do
    local p = list[i]
    if not pick and p.cost > 0 and s.balance - p.cost < RESERVE and purpose_words(p.key) then pick = p end
  end
  for i = 1, math.min(#list, 8) do
    local p = list[i]
    if not pick and p.cost > 0 and purpose_words(p.key) then pick = p end
  end
  local vars = {goal = self:goalWords(s)}
  local line
  if pick then
    local need = pick.cost + RESERVE - s.balance
    vars.amount = dollars(math.min(30000, math.max(2000, math.ceil(math.max(need, pick.cost) / 1000) * 1000)))
    vars.purpose = purpose_words(pick.key)
    line = self.fill_in(self.pick(self.lines.rescue_ask), vars)
    -- (The server cuts a chat line at 200 letters: a long room name takes the short form.)
    if #line > 195 then pick = nil end
  end
  if not pick then
    vars.amount = dollars(math.min(30000, math.max(5000, math.ceil((2 * RESERVE - s.balance) / 1000) * 1000)))
    line = self.fill_in(self.pick(self.lines.rescue_ask_plain), vars)
  end
  self:note(string.format("day %d: asked the team for $%s (%s)", s.day, vars.amount, pick and pick.key or "no project"))
  self.bot:say(line, self.typing(line), "team")
end

--! Once a day: is the hospital failing its objectives (M:failing)? Then, at
--! most every RESCUE_DAYS, the model reviews it (a "rescue" question to the
--! server, its answer a plan like the weekly one that stays in force for a
--! month) and the allies are asked for help (M:askForHelp), after the answer
--! or a minute without one. Never in the first game year (RESCUE_FROM_MONTH;
--! the check still runs, so the reputation it remembers is there in month
--! 13). (Tests: MP_BOT_TEST_FAIL=<day> from that game day instead.)
function M:rescue(s)
  local bot = self.bot
  if s.hosp.mp_place or bot.standin then
    self.rescue_wait = nil
    return
  end
  local wait = self.rescue_wait
  if wait then
    if wait.done or bot:now() - wait.at > 70 then
      self.rescue_wait = nil
      self:askForHelp(s, wait.reasons)
    end
    return
  end
  local reasons = self:failing(s)
  local test_from = tonumber(os.getenv("MP_BOT_TEST_FAIL") or "")
  local too_early
  if test_from then too_early = s.day < test_from else too_early = (s.month or 0) < RESCUE_FROM_MONTH end
  if #reasons == 0 or too_early or s.day < (self.rescue_next or 0) then return end
  self.rescue_next = s.day + RESCUE_DAYS
  self:note(string.format("day %d: failing its objectives: %s", s.day, table.concat(reasons, "; ")))
  wait = {at = bot:now(), reasons = reasons}
  self.rescue_wait = wait
  local text = (self:report() or "") .. "\nFAILING ITS OBJECTIVES: " .. table.concat(reasons, "; ") .. "."
  local asked = bot:askRescue(text, table.concat(self:planMenu(), ","), function(plan)
    if plan then
      self:applyPlan(plan)
      self.rescue_boost, self.rescue_until = {}, s.day + 30
      for key, b in pairs(self.boost) do self.rescue_boost[key] = b end
    end
    wait.done = true
  end)
  if not asked then wait.done = true end
end

--------------------------------------------------------------------------------
-- The hospital's floor in one piece (Argus, 2026-11-08: a bot's benches and
-- drinks machines cut its floor apart, and its patients walked outside and
-- through three other hospitals to get from one part to the other. The
-- game's own rule only asks that some way exists, even one outside.)
--------------------------------------------------------------------------------

-- Tiles are keyed y * FLOOR_W + x. The sides of a tile one may cross (the
-- game's travel flags) are bits, north 1, east 2, south 4, west 8, and a side
-- is keyed tile key * 16 + its bit.
local FLOOR_W = 1000
M.FLOOR_W = FLOOR_W
local SIDES = {{bit = 1, step = -FLOOR_W, back = 4}, {bit = 2, step = 1, back = 8},
    {bit = 4, step = FLOOR_W, back = 1}, {bit = 8, step = -1, back = 2}}
local SIDE_OF = {north = SIDES[1], east = SIDES[2], south = SIDES[3], west = SIDES[4]}

local function has_bit(bits, bit) return math.floor(bits / bit) % 2 == 1 end

--! In how many separate parts of the floor are the places that must be
--! reached? `floor` (Bot:floorMap) = {walk = {[tile] = side bits} (the
--! hospital's corridor tiles, in no room, one can walk on), held = {[tile] =
--! side bits} (those an object stands on), targets = {tile, ...} (its
--! entrances, the front of each reception desk, the tile before each room's
--! door)}. `change` (optional, M.objectChange) is what an object or a room
--! would do: {block = {[tile] = true}, cut = {[side] = true}} put down, or
--! {open = {[tile] = true}, join = {[side] = true}} taken away. A target on a
--! tile nobody can walk on is a part of its own.
--!return the number of parts, and the part of each tile reached from a target
function M.floorParts(floor, change)
  change = change or {}
  local block, cut, open, join = change.block or {}, change.cut or {}, change.open or {}, change.join or {}
  local walk, held = floor.walk, floor.held
  local function walkable(k)
    return not block[k] and (walk[k] ~= nil or (open[k] ~= nil and held[k] ~= nil))
  end
  local part, parts = {}, 0
  for _, t in ipairs(floor.targets) do
    if not walkable(t) then
      parts = parts + 1
    elseif not part[t] then
      parts = parts + 1
      part[t] = parts
      local queue, head = {t}, 1
      while head <= #queue do
        local k = queue[head]
        head = head + 1
        local bits = walk[k] or held[k] or 0
        for _, d in ipairs(SIDES) do
          local n = k + d.step
          if not part[n] and walkable(n) and not cut[k * 16 + d.bit] and not cut[n * 16 + d.back] and
              (has_bit(bits, d.bit) or join[k * 16 + d.bit] or join[n * 16 + d.back]) then
            part[n] = parts
            queue[#queue + 1] = n
          end
        end
      end
    end
  end
  return parts, part
end

--! What an object of type `object` (with its orientations and footprints)
--! does to the floor (M.floorParts) at x, y facing `direction`, added to
--! `change` (a new table if nil): the tiles it takes (`block`) and the sides
--! it closes (`cut`: a radiator, a bin, an extinguisher stand against one
--! side of a tile); with `away`, what taking it away does (`open`, `join`).
function M.objectChange(object, x, y, direction, change, away)
  change = change or {}
  local o = object.orientations and object.orientations[direction]
  if not o then return change end
  -- (A bin facing east stands on its tile's west side, as the game has it:
  -- Object:occupyTilesByObjectFootprintAt.)
  if object.thob == 50 and direction == "east" then direction = "west" end
  local side = SIDE_OF[direction]
  local tiles, sides = away and "open" or "block", away and "join" or "cut"
  for _, t in ipairs(o.footprint or {}) do
    local k = (y + t[2]) * FLOOR_W + x + t[1]
    if t.only_side then
      if side then
        change[sides] = change[sides] or {}
        change[sides][k * 16 + side.bit] = true
      end
    elseif not t.only_passable then
      change[tiles] = change[tiles] or {}
      change[tiles][k] = true
    end
  end
  return change
end

--! The first thing in the way between two parts of the floor (M.floorParts),
--! with every object of `away` (M.objectChange of them all, taken away): the
--! shortest way from one part to another (or to a target an object stands
--! on), and the first tile on it that an object stands on, or side one
--! closes.
--!return "tile", tile key or "side", side key; nil when no object is in the way
function M.floorBlocker(floor, away)
  local parts, part = M.floorParts(floor)
  local walk, held = floor.walk, floor.held
  local open, join = away.open or {}, away.join or {}
  local held_target = {}
  for _, t in ipairs(floor.targets) do
    if walk[t] == nil then held_target[t] = true end
  end
  local function walkable(k) return walk[k] ~= nil or (open[k] ~= nil and held[k] ~= nil) end
  for p = 1, parts do
    local prev, queue, head = {}, {}, 1
    for k, q in pairs(part) do
      if q == p then
        prev[k] = false
        queue[#queue + 1] = k
      end
    end
    table.sort(queue) -- (the same way every time)
    while head <= #queue do
      local k = queue[head]
      head = head + 1
      local bits = walk[k] or held[k] or 0
      for _, d in ipairs(SIDES) do
        local n = k + d.step
        local through = has_bit(bits, d.bit) or join[k * 16 + d.bit] or join[n * 16 + d.back]
        if prev[n] == nil and walkable(n) and through then
          prev[n] = k
          if (part[n] and part[n] ~= p) or held_target[n] then
            -- Back along the way to part p: its first step out of the part is
            -- through an object (else the two would be one part).
            local a, b = k, n
            while prev[a] do a, b = prev[a], a end
            if walk[b] == nil then return "tile", b end
            for _, e in ipairs(SIDES) do
              if a + e.step == b then
                return "side", join[a * 16 + e.bit] and a * 16 + e.bit or b * 16 + e.back
              end
            end
            return nil
          end
          queue[#queue + 1] = n
        end
      end
    end
  end
  return nil
end

--! (MP_BOT_DIAG) Where the GP's offices, their doctors, the patients and
--! the doctors are, in the log once a month.
function M:diagnose(s)
  local world, hosp = self.bot.world, s.hosp
  local function act(h)
    local a = h.action_queue and h.action_queue[1]
    return a and a.name or "-"
  end
  local function where(h)
    local r = h.tile_x and world:getRoom(h.tile_x, h.tile_y)
    return r and (r.room_info.id .. "#" .. r.id) or (h.tile_x and "corridor" or "nowhere")
  end
  for _, r in pairs(world.rooms) do
    if r.hospital == hosp and r.room_info.id == "gp" then
      local q = r.door and r.door.queue
      local st = r.staff_member
      local inside = 0
      for _ in pairs(r.humanoids or {}) do inside = inside + 1 end
      self.log(string.format("diag gp#%d door %s,%s active %s: doctor %s, inside %d, queue %d (size %d, expected %d,"
          .. " max %s)", r.id, tostring(r.door and r.door.tile_x), tostring(r.door and r.door.tile_y),
          tostring(r.is_active), st and (act(st) .. " fatigue " .. string.format("%.2f", st.attributes.fatigue or 0)) or "none",
          inside, q and q:reportedSize() or -1, q and q:size() or -1, q and q:expectedSize() or -1,
          tostring(q and q.max_size)))
    end
  end
  local pat, gpv, prog, diag, n = {}, {}, 0, 0, 0
  local gp_name
  for _, rt in ipairs(TheApp.rooms) do
    if rt.id == "gp" then gp_name = tostring(rt.name) end
  end
  for _, p in ipairs(hosp.patients or {}) do
    if p.tile_x and not p.dead then
      n = n + 1
      local k = act(p) .. "@" .. where(p):gsub("#%d+", "")
      pat[k] = (pat[k] or 0) + 1
      prog = prog + (p.diagnosis_progress or 0)
      if p.diagnosed then diag = diag + 1 end
      local visits = 0
      for _, room in ipairs(p.treatment_history or {}) do
        if tostring(room) == gp_name then visits = visits + 1 end
      end
      local vk = visits >= 4 and "4+" or tostring(visits)
      gpv[vk] = (gpv[vk] or 0) + 1
    end
  end
  local list = {}
  for k, v in pairs(pat) do list[#list + 1] = k .. "=" .. v end
  table.sort(list)
  local vl = {}
  for k, v in pairs(gpv) do vl[#vl + 1] = k .. ":" .. v end
  table.sort(vl)
  self.log(string.format("diag patients %d, diagnosed %d, progress %.2f; gp visits %s; %s", n, diag,
      n > 0 and prog / n or 0, table.concat(vl, " "), table.concat(list, " ")))
  local docs = {}
  for _, st in ipairs(hosp.staff) do
    if st.humanoid_class == "Doctor" and not st.fired then
      local k = act(st) .. "@" .. where(st):gsub("#%d+", "")
      docs[k] = (docs[k] or 0) + 1
    end
  end
  list = {}
  for k, v in pairs(docs) do list[#list + 1] = k .. "=" .. v end
  table.sort(list)
  self.log("diag doctors: " .. table.concat(list, " "))
end

--------------------------------------------------------------------------------

--! Called from Bot:think twice a second.
function M:think()
  local bot = self.bot
  local day = bot:gameDay()
  if day < self.next_daily then
    return
  end
  self.next_daily = day + 1
  local s = self:assess()
  self.s = s
  self:daily(s)
  -- Specialists: lent to allies who cannot hire one (a hospital out of the
  -- race or done still helps its team), asked for when it cannot hire one.
  if bot.world.mp_coop then
    self:helpAllies(s)
    -- (Not a bot playing for a person who left: their name asks nobody.)
    if not s.hosp.mp_place and not bot.standin then
      self:askAllies(s)
      self:askForNeeds(s)
    end
    -- The level's requirements, in the team chat.
    self:winChat(s)
    self:rivalWatch(s)
  end
  -- Failing its objectives: a review by the model, and a word to the allies.
  self:rescue(s)
  if s.hosp.mp_place then return end -- out of the race (or won): no more building
  if not s.hosp.opened and s.staffed_desks > 0 and s.rooms.gp and (s.staff.Doctor or 0) > 0 and
      not bot:sharesWithPerson() then
    bot:openHospital()
  end
  if s.month ~= self.last_month then
    self.last_month = s.month
    -- (Prices, the loan and research belong to a person sharing the hospital.)
    if bot:sharesWithPerson() then self.log(self:monthLine(s)) else self:monthly(s) end
    for _, p in ipairs(self:problems(s)) do self.log("problem: " .. p) end
    if (os.getenv("MP_BOT_DIAG") or "") ~= "" then self:diagnose(s) end
    self.next_plan = s.day
  end
  -- Research its allies lack, for free, once in a while.
  if s.day >= (self.next_share or 0) then
    self.next_share = s.day + 7
    self:shareResearch(s)
  end
  -- A fresh plan once a game week (and at each month's start).
  if s.day >= (self.next_plan or 0) and bot:askPlan() then self.next_plan = s.day + 7 end
  self:doProject(s)
end

return M
