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
--  * Smaller things happen on their own: a handyman to a worn machine,
--    heating, prices once a month, loans, research aimed at a disease it
--    cannot treat, the faxes about patients, VIPs and epidemics.
--  * In a race it throws out evil handymen, shoots attack rats, and aims its
--    dirty tricks at whoever leads.
--  * A plan from a language model (Manager:applyPlan, through the server)
--    can raise the scores of some projects and change prices or the loan;
--    the manager still checks everything and plays on without it.
--
-- Like the rest of the bot it never uses the game's random numbers.

local M = {}
M.__index = M

-- Rooms a beginner leaves alone (a consultant to teach in it).
local SKIP_ROOMS = {training = true}
-- Doctors with a skill a room needs.
local SPECIALISTS = {Psychiatrist = true, Surgeon = true, Researcher = true}
-- Kept in the bank for wages and repairs.
local RESERVE = 3000
-- Rooms worth a second (third) copy when their queues grow.
local COPIES = {gp = 3, pharmacy = 2, general_diag = 2, psych = 2, ward = 2, toilets = 3, staff_room = 2,
    cardiogram = 2, scanner = 2, ultrascan = 2, blood_machine = 2, x_ray = 2, inflation = 2,
    fracture_clinic = 2, hair_restoration = 2, tongue_clinic = 2, electrolysis = 2, dna_fixer = 1,
    jelly_vat = 1, decontamination = 1, operating_theatre = 2, research = 1}
-- Queue per room above which another room of the type helps.
local BUSY_QUEUE = 5
-- The score a team mate's wish adds: before the bot's own ideas, after the
-- basics of an opening hospital (90 and more).
local WISH = 50
-- The size a player gives a room (square), when there is space.
local SIZES = {gp = 5, pharmacy = 5, general_diag = 5, psych = 6, ward = 7, staff_room = 6, toilets = 5,
    research = 6, operating_theatre = 7, x_ray = 6, scanner = 6, decontamination = 6, dna_fixer = 6,
    electrolysis = 6, training = 6}
-- What a player puts into a new room besides what it needs: warmth, a
-- plant, a bin; comfort in the staff room; more toilets and beds.
local EXTRAS = {
  staff_room = {sofa = 1, tv = 1, pool_table = 1, radiator = 1, plant = 1},
  toilets = {loo = 1, sink = 1, radiator = 1},
  ward = {bed = 2, radiator = 1, plant = 1},
  psych = {radiator = 1, plant = 1, bookcase = 1},
  research = {},
}
local DEFAULT_EXTRAS = {radiator = 1, plant = 1, bin = 1}

--! The size and extras for a new room of this type.
function M.roomPlan(id)
  local extras = EXTRAS[id] or DEFAULT_EXTRAS
  local copy = {}
  for k, v in pairs(extras) do copy[k] = v end
  return SIZES[id], copy
end

--! A manager for the bot `bot` (its helpers: drawRoom, hireCategory,
--! buyCorridor, buyPlot, canHire, roomPlan, roomCost, playerOfHospital,
--! say, later, gameDay) and `ctx` = {log, rand, pick, sabotage, lines, typing}.
function M.new(bot, ctx)
  local self = setmetatable({}, M)
  self.bot, self.log, self.rand, self.pick = bot, ctx.log, ctx.rand, ctx.pick
  self.sabotage, self.lines, self.typing = ctx.sabotage, ctx.lines, ctx.typing
  self.demand = {}         -- room id -> patients who needed it lately (decaying)
  self.next_project = 0    -- game day of the next project
  self.next_daily = -1
  self.next_monthly = -1
  self.called = {}         -- machine entity id -> day a handyman was sent
  self.answered = {}       -- message number -> true
  self.noticed = {}        -- saboteur entity id -> day it was noticed
  self.boost = {}          -- project key -> extra score from the model's plan
  self.wishes = {}         -- project key -> last game day of a team mate's wish
  self.failed = {}         -- project key -> day it failed (try again later)
  self.history = {}        -- what it did lately (for the model's report and chat)
  self.left = {}           -- why patients left: cured, kicked, fed_up, over_priced
  self.lost = {}           -- disease id -> patients who left uncured
  return self
end

function M:note(text)
  self.log(text)
  self.history[#self.history + 1] = text
  if #self.history > 12 then table.remove(self.history, 1) end
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
  s.rooms, s.queue, s.unstaffed, s.room_count = {}, {}, {}, 0
  for _, r in pairs(world.rooms) do
    if r.hospital == hosp and r.is_active then
      local id = r.room_info.id
      s.rooms[id] = (s.rooms[id] or 0) + 1
      s.room_count = s.room_count + 1
      local q = r.door and r.door.queue
      s.queue[id] = (s.queue[id] or 0) + (q and q:reportedSize() or 0)
      local crit = r.getRequiredStaffCriteria and r:getRequiredStaffCriteria()
      if crit and next(crit) and not r:testStaffCriteria(crit) then
        s.unstaffed[id] = (s.unstaffed[id] or 0) + 1
      end
    end
  end

  -- Patients: what their diseases need, comfort.
  local need = {}
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
          if not s.rooms[room] then need[room] = (need[room] or 0) + 1 end
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

  -- Desks, corridor objects, litter, machines, rats and saboteurs.
  s.desks = #hosp:getReceptionDesks()
  s.staffed_desks = #hosp:getReceptionDesks(true)
  s.reception_queue = 0
  for _, desk in ipairs(hosp:getReceptionDesks()) do
    s.reception_queue = s.reception_queue + (desk.queue and desk.queue:reportedSize() or 0)
  end
  s.objects, s.litter, s.worn, s.rats, s.saboteurs = {}, 0, {}, {}, {}
  local me = world:getHospitalIndex(hosp)
  for _, e in ipairs(world.entities) do
    if e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) then
      local t = e.object_type and e.object_type.id
      if t == "litter" then
        s.litter = s.litter + 1
      elseif t and not world:getRoom(e.tile_x, e.tile_y) then
        s.objects[t] = (s.objects[t] or 0) + 1
      end
      if class.is(e, Machine) and e.hospital == hosp and e.getRemainingUses then
        local left = e:getRemainingUses()
        if left <= 3 then s.worn[#s.worn + 1] = e end
      end
      if class.is(e, Rat) and e.mp_attack_rat and not e.shot then s.rats[#s.rats + 1] = e end
    end
    if e.mp_saboteur and e.mp_saboteur.target == me and not e.mp_in_transit then
      s.saboteurs[#s.saboteurs + 1] = e
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
  s.heat = hosp.heating and math.floor((hosp.heating.radiator_heat or 0.5) * 10 + 0.5) or 5
  self.state = s
  return s
end

--------------------------------------------------------------------------------
-- Projects: what to build, hire or buy next
--------------------------------------------------------------------------------

function M:available(room_id)
  local hosp = self.bot.world.ui.hospital
  local d = hosp.room_discoveries[room_id]
  return d and d.is_discovered and not SKIP_ROOMS[room_id]
end

--! Every project worth doing now with its score (higher is more urgent).
function M:projects(s)
  local bot, hosp = self.bot, s.hosp
  local list = {}
  local listed = {}
  local function add(key, score, run, cost)
    score = score + (self.boost[key] or 0) + (self.wishes[key] and WISH or 0)
    listed[key] = true
    if self.failed[key] and s.day < self.failed[key] then return end
    if score > 0.5 then list[#list + 1] = {key = key, score = score, run = run, cost = cost or 0} end
  end
  local rooms_by_id = {}
  for _, rt in ipairs(TheApp.rooms) do rooms_by_id[rt.id] = rt end
  local function room(id, score, size)
    local rt = rooms_by_id[id]
    if not rt or not self:available(id) then return end
    -- A room for a specialist (a psychiatrist, surgeons, a researcher) waits
    -- until one is on the staff or on the hiring list: an empty room helps
    -- nobody.
    for cat in pairs(rt.required_staff or {}) do
      if SPECIALISTS[cat] and hosp:countStaffOfCategory(cat, 1) == 0 and not bot:canHire(cat) then return end
    end
    local want, extras = M.roomPlan(id)
    add("room:" .. id, score, function() return bot:drawRoom(rt, size or want, extras) end, bot:roomCost(rt))
  end
  local function hire(cat, score)
    if bot:canHire(cat) then add("hire:" .. cat, score, function() return bot:hireCategory(cat) end, 0) end
  end
  local function buy(id, score)
    local ok, cost = pcall(hosp.getObjectBuildCost, hosp, id)
    if ok then add("buy:" .. id, score, function() return bot:buyCorridor(id) end, cost or 0) end
  end

  -- The basics of an opening hospital.
  if s.staffed_desks == 0 and (s.staff.Receptionist or 0) == 0 then hire("Receptionist", 100) end
  if not s.rooms.gp then room("gp", 90) end
  if s.rooms.gp and (s.staff.Doctor or 0) == 0 then hire("Doctor", 95) end

  -- Rooms the patients need (treatment first), by the decaying demand; a
  -- pharmacy and a general diagnosis are always worth it.
  for id, v in pairs(self.demand) do
    if not s.rooms[id] then room(id, 1 + v * 1.5) end
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
  if not s.rooms.research and s.room_count >= 5 then room("research", 1 + undiscovered * 0.4) end
  -- Full GP's offices send patients on to diagnosis rooms: more of those.
  local gp_per = s.rooms.gp and s.queue.gp / s.rooms.gp or 0
  if gp_per > BUSY_QUEUE and s.rooms.general_diag and s.rooms.general_diag < COPIES.general_diag then
    room("general_diag", gp_per - BUSY_QUEUE + 1)
  end
  -- Busy rooms: another one of the type. (A room without its doctor at
  -- this moment is no reason not to: the doctor may be on a break.)
  for id, n in pairs(s.rooms) do
    local per = s.queue[id] / n
    if per > BUSY_QUEUE and n < (COPIES[id] or 1) then
      room(id, (per - BUSY_QUEUE + 1) * 1.2, id == "ward" and 7 or nil)
    end
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
    local have = hosp:countStaffOfCategory(cat)
    if have < k then hire(cat, 8 + (k - have) * 2) end
  end
  for id, n in pairs(s.rooms) do
    local per = s.queue[id] / n
    if per > BUSY_QUEUE then
      for cat in pairs(rooms_by_id[id] and rooms_by_id[id].required_staff or {}) do
        local have = hosp:countStaffOfCategory(cat)
        local base = SPECIALISTS[cat] and "Doctor" or cat
        if have < (want[cat] or 0) + 2 and hosp:countStaffOfCategory(base) < (cap[base] or 99) then
          hire(cat, per - BUSY_QUEUE)
        end
      end
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
  if (s.staff.Handyman or 0) < handymen then hire("Handyman", 3 + (handymen - (s.staff.Handyman or 0)) * 2) end

  -- Corridor comfort, once the hospital is open and has a few rooms.
  if hosp.opened and s.room_count >= 3 then
    local waiting = s.reception_queue
    for _, q in pairs(s.queue) do waiting = waiting + q end
    local benches = s.objects.bench or 0
    if benches < waiting * 0.6 and benches < 16 then buy("bench", 1 + (waiting * 0.6 - benches) * 0.5) end
    local drinks = s.objects.drinks_machine or 0
    if s.patients >= 8 and drinks < 1 + s.patients / 25 then buy("drinks_machine", 1 + s.thirst * 6) end
    local radiators = s.objects.radiator or 0
    if radiators < 2 + s.room_count / 3 and (s.cold > 2 or radiators == 0) then buy("radiator", 2 + s.cold * 0.5) end
    if (s.objects.bin or 0) < 2 and s.litter > 8 then buy("bin", 1.5) end
    if (s.objects.plant or 0) < 2 + s.room_count / 4 then buy("plant", 0.8 + (1 - s.happiness)) end
    if (s.objects.extinguisher or 0) < 1 and s.room_count >= 6 then buy("extinguisher", 0.7) end
  end
  -- What a team mate asked for in the chat, if nothing above wanted it.
  for key, until_day in pairs(self.wishes) do
    if s.day > until_day then
      self.wishes[key] = nil
    elseif not listed[key] then
      local kind, what = key:match("^(%a+):(.+)$")
      if kind == "room" then room(what, 0) elseif kind == "hire" then hire(what, 0) elseif kind == "buy" then buy(what, 0) end
    end
  end
  table.sort(list, function(a, b) return a.score > b.score end)
  return list
end

--! Do the most urgent project it can afford (one at a time, like a person).
function M:doProject(s)
  local bot = self.bot
  if s.day < self.next_project then return end
  local list = self:projects(s)
  for i = 1, math.min(#list, 6) do
    local p = list[i]
    if s.balance - p.cost >= RESERVE or p.score >= 90 then
      local ok, why = p.run()
      if ok then
        self:note(string.format("day %d: %s (score %.1f, $%d)", s.day, p.key, p.score, math.floor(s.balance)))
        self.boost[p.key] = nil
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
        bot:buyPlot()
        self.failed[p.key] = s.day + 5
        self.next_project = bot:later(2)
        return
      end
      self.failed[p.key] = s.day + (why == "money" and 3 or 10)
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
  -- Worn machines: a handyman to each (once in a while per machine).
  if (s.staff.Handyman or 0) > 0 then
    for _, m in ipairs(s.worn) do
      local id = m.mp_id
      if id and (not self.called[id] or s.day - self.called[id] > 3) then
        self.called[id] = s.day
        self:issue({kind = "call_handyman", machine = id})
      end
    end
  end
  if helper then return end
  -- Heating: warmer when patients are cold, cooler when they are hot.
  if hosp.opened and s.patients >= 4 and (s.objects.radiator or 0) > 0 then
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
  if bot.fiery then self:defend(s) end
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
  return string.format("month %d: left %s; lost most: %s; in hospital %d; queues %s, reception %d; psychiatrists %d,"
      .. " surgeons %d; prices %d%%; reputation %d, $%d", s.month, table.concat(left, " "), table.concat(top, " "),
      s.patients, table.concat(queues, " "), s.reception_queue, hosp:countStaffOfCategory("Psychiatrist"),
      hosp:countStaffOfCategory("Surgeon"), self.price_target or 100, s.reputation, math.floor(s.balance))
end

--! Once a month: prices, repaying the loan, research.
function M:monthly(s)
  local hosp = s.hosp
  self.log(self:monthLine(s))
  -- Prices: dearer with a good reputation and full queues, cheaper when the
  -- reputation suffers.
  local waiting = 0
  for _, q in pairs(s.queue) do waiting = waiting + q end
  local target = self.price_target or 100
  local dear = (self.left.over_priced or 0) - (self.dear_seen or 0)
  self.dear_seen = self.left.over_priced or 0
  if dear >= 2 then
    -- Patients walked out over the prices this month: cheaper, whatever else.
    target = math.max(70, target - 10)
    self.model_price = nil
  elseif self.model_price then
    -- The model's price, unless the reputation is already suffering.
    target = s.reputation < 300 and math.min(100, self.model_price) or self.model_price
    self.model_price = nil
  elseif s.reputation >= 600 and waiting > s.room_count * 2 then
    target = math.min(150, target + 10)
  elseif s.reputation < 350 or s.happiness < 0.35 then
    target = math.max(80, target - 10)
  elseif s.reputation >= 450 then
    target = math.min(120, target + 5)
  end
  if target ~= self.price_target then
    self.price_target = target
    for id, entry in pairs(hosp.disease_casebook) do
      if entry.price and entry.discovered ~= false and not entry.pseudo then
        local now = math.floor(entry.price * 100 + 0.5)
        if now ~= target then self:issue({kind = "set_price", disease = id, percent = target}) end
      end
    end
    self:note(string.format("day %d: prices to %d%%", s.day, target))
  end
  -- Loan: repay what it can spare.
  if s.loan > 0 and s.balance > 25000 then
    local amount = math.min(s.loan, math.floor((s.balance - 20000) / 1000) * 1000)
    if amount > 0 and self:issue({kind = "loan", amount = -amount}) then
      self:note(string.format("day %d: repaid $%d of the loan", s.day, amount))
    end
  end
  -- Research: aim it at the disease whose treatment room it lacks most.
  if s.rooms.research then
    local best, best_v
    for room_id, v in pairs(self.demand) do
      if not self:available(room_id) and (not best_v or v > best_v) then best, best_v = room_id, v end
    end
    if best and best_v > 1 and best ~= self.research_room then
      for id, entry in pairs(hosp.disease_casebook) do
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
      local pick, why
      if index.send_home or index.wait then
        -- A patient whose room it does not have (or cannot diagnose).
        local patient = icon.owner
        local rooms = patient and patient.disease and patient.disease.treatment_rooms or {}
        local missing, buildable = false, true
        for _, r in ipairs(rooms) do
          if not s.rooms[r] then
            missing = true
            self.demand[r] = (self.demand[r] or 0) + 2
            if not self:available(r) then buildable = false end
          end
        end
        -- (Never "research": that is an autopsy, and it costs the hospital
        -- a lot of reputation when it comes out.)
        if not missing then
          pick, why = index.wait, "the room is there"
        elseif buildable and s.balance > 15000 then
          pick, why = index.wait, "building the room"
        else
          pick, why = index.send_home, "no room for it"
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
        self.bot:say(nil, 2 + self.rand() * 4, nil, function()
          self:issue({kind = "fax_choice", msg = id, choice = pick})
        end)
        self:note(string.format("day %d: fax #%d (%s): %s, %s", s.day, id, tostring(icon.type), choice_name, why))
      end
    end
  end
end

--! A race: throw out evil handymen once noticed, shoot attack rats.
function M:defend(s)
  for _, e in ipairs(s.saboteurs) do
    local id = e.mp_id
    if id then
      self.noticed[id] = self.noticed[id] or (s.day + self.rand(1, 3))
      if s.day >= self.noticed[id] and not self.noticed[-id] then
        self.noticed[-id] = true
        self:issue({kind = "fire_staff", staff = id})
        self:note(string.format("day %d: threw out an evil handyman", s.day))
      end
    end
  end
  -- A few rats a day, like clicks.
  for i = 1, math.min(#s.rats, 3) do
    local rat = s.rats[i]
    if rat.mp_id then self:issue({kind = "shoot_rat", rat = rat.mp_id}) end
  end
end

--! The rival to play a dirty trick on: the one closest to winning (its
--! reputation and money), a person rather than a bot.
function M:trickTarget()
  local bot, world = self.bot, self.bot.world
  local mine = world.ui.hospital
  local best, best_score, best_name
  for index, hospital in ipairs(world.hospitals) do
    local peer, name, is_bot = bot:playerOfHospital(index)
    if peer and world:mpRivals(mine, hospital) and not hospital.mp_place then
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
  add("Money $%d, loan $%d (up to $%d), reputation %d, patients in the hospital %d, open: %s.",
      math.floor(s.balance), s.loan, s.max_loan, s.reputation, s.patients, tostring(s.hosp.opened or false))
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
  add("Reception: %d desks (%d staffed), queue %d. Litter %d, worn machines %d.", s.desks, s.staffed_desks,
      s.reception_queue, s.litter, #s.worn)
  add("Patients: thirst %.0f%%, warmth %.0f%% (%d cold, %d hot), toilet need %.0f%%, happiness %.0f%%. Heating %d/10.",
      s.thirst * 100, s.warmth * 100, s.cold, s.hot, s.toilet * 100, s.happiness * 100, s.heat)
  add("Prices at %d%% of normal.", self.price_target or 100)
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

--! The projects a team mate may ask for now (rooms it has discovered).
function M:wishMenu()
  local items = {}
  for _, k in ipairs(M.menu()) do
    local room_id = k:match("^room:(.+)$")
    if not room_id or self:available(room_id) then items[#items + 1] = k end
  end
  return items
end

--! A team mate asked for this project in the chat: it comes next (for 30
--! game days; then it lapses, if it could not be done).
function M:wish(key)
  for _, k in ipairs(self:wishMenu()) do
    if k == key then
      self.wishes[key] = self.bot:gameDay() + 30
      self.next_project = math.min(self.next_project, self.bot:gameDay())
      self:note("wish: " .. key)
      return true
    end
  end
  return false
end

--! A plan from the model: {priorities = {{action, weight}}, price = percent,
--! loan = amount, say = text}. Raises those projects' scores until done.
function M:applyPlan(plan)
  if type(plan) ~= "table" then return end
  self.boost = {}
  local valid = {}
  for _, k in ipairs(M.menu()) do valid[k] = true end
  local taken = {}
  for i, p in ipairs(type(plan.priorities) == "table" and plan.priorities or {}) do
    if type(p) == "table" and valid[p.action] and i <= 6 then
      local w = math.max(0, math.min(10, tonumber(p.weight) or 3))
      self.boost[p.action] = w
      taken[#taken + 1] = p.action
    end
  end
  local price = tonumber(plan.price)
  if price and price >= 70 and price <= 160 then
    -- (Set at the next monthly round.)
    self.model_price = math.floor(price / 5 + 0.5) * 5
  end
  self:note(string.format("plan: %s%s", table.concat(taken, ", "), price and (", prices " .. price .. "%") or ""))
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
  self:daily(s)
  if s.hosp.mp_place then return end -- out of the race (or won): no more building
  if not s.hosp.opened and s.staffed_desks > 0 and s.rooms.gp and (s.staff.Doctor or 0) > 0 and
      not bot:sharesWithPerson() then
    bot:openHospital()
  end
  if s.month ~= self.last_month then
    self.last_month = s.month
    -- (Prices, the loan and research belong to a person sharing the hospital.)
    if bot:sharesWithPerson() then self.log(self:monthLine(s)) else self:monthly(s) end
    self.next_plan = s.day
  end
  -- A fresh plan once a game week (and at each month's start).
  if s.day >= (self.next_plan or 0) and bot:askPlan() then self.next_plan = s.day + 7 end
  self:doProject(s)
end

return M
