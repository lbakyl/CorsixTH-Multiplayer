-- A quick check of the manager's judgements on made-up hospitals: who meets
-- the level's requirements to win, what a bot says it still lacks, when it
-- counts as failing its objectives, and who goes to the training room.
-- Usage: lua scripts/multiplayer/bot_manager_test.lua scripts/multiplayer/bot_manager.lua
-- (any Lua 5.1 to 5.5; the manager is loaded without the game).
local M = assert(loadfile(arg[1]))()

local function eq(a, b, what)
  if a ~= b then
    print("FAIL", what, tostring(a), tostring(b))
    os.exit(1)
  end
end

-- A level: win with $20,000, a hospital worth $100,000 and under 10% deaths
-- (one group); lose when the reputation is below 200 (warned at 400).
local ec = {
  win_goals = {[1] = {
    balance = {win_value = 20000, max_min = 1},
    value = {win_value = 100000, max_min = 1},
    percentage_killed = {win_value = 10, max_min = 0},
  }},
  lose_goals = {[1] = {
    reputation = {boundary = 400, lose_value = 200, max_min = 0},
  }},
}
function ec.getAttribute(_, hospital, name) return hospital[name] end
local world = {endconditions = ec}

local function hospital(fields)
  local h = {balance = 0, value = 0, percentage_killed = 0, reputation = 500, loan = 0}
  for k, v in pairs(fields) do h[k] = v end
  return h
end

-- Requirements: all met, no loan: ready.
local r = M.requirements(world, hospital({balance = 25000, value = 120000, percentage_killed = 5}))
eq(r.ready, true, "ready")
eq(r.met, 3, "met")
-- The loan stops the win (the game's rule), the goals are met.
r = M.requirements(world, hospital({balance = 25000, value = 120000, percentage_killed = 5, loan = 5000}))
eq(r.complete, true, "complete with a loan")
eq(r.ready, false, "a loan is no win")
-- A death rate is met below its value; progress counts the way there.
r = M.requirements(world, hospital({balance = 10000, value = 50000, percentage_killed = 20}))
eq(r.met, 0, "none met")
eq(r.complete, false, "not complete")
for _, c in ipairs(r.list) do
  if c.name == "balance" then eq(c.progress, 0.5, "balance progress") end
  if c.name == "value" then eq(c.progress, 0.5, "value progress") end
  if c.name == "percentage_killed" then eq(c.progress, 0.5, "deaths progress") end
end
-- The game's own flag (a hospital that once reached the goals in co-op) counts.
eq(M.meets(world, hospital({mp_goals_reached = true})), true, "reached flag")
eq(M.meets(world, hospital({mp_place = 1, mp_place_how = "won"})), true, "a place won")
eq(M.meets(world, hospital({mp_place = 3, mp_place_how = "out"})), false, "a place lost")
-- No goals at all: nothing to tell.
eq(M.requirements({endconditions = {win_goals = {}, getAttribute = ec.getAttribute}}, hospital({})), nil, "no goals")

-- What a bot says it lacks: one requirement, the furthest away first, and a
-- different one the next time.
local fill = function(line, vars) return (line:gsub("{(%w+)}", function(k) return vars[k] end)) end
local manager = setmetatable({
  fill_in = fill, pick = function(list) return list[1] end,
  lines = {win_need = {
    balance = {"short {short}"}, value = {"worth {now} of {want}"}, percentage_killed = {"dead {now}% of {want}%"},
    loan = {"loan {loan}"},
  }},
}, M)
r = M.requirements(world, hospital({balance = 5000, value = 90000, percentage_killed = 20}))
-- (balance: 25% of the way; deaths 50%; value 90%)
eq(manager:needLine(r), "short $15k", "first the furthest")
eq(manager:needLine(r), "dead 20% of 10%", "then another")
eq(manager:needLine(r), "worth $90k of $100k", "then the third")
eq(manager:needLine(r), "short $15k", "and round again")
r = M.requirements(world, hospital({balance = 25000, value = 120000, percentage_killed = 5, loan = 15000}))
eq(manager:needLine(r), "loan $15k", "only the loan left")
r = M.requirements(world, hospital({balance = 25000, value = 120000, percentage_killed = 5}))
eq(manager:needLine(r), nil, "nothing left to say")

-- Failing: close to losing, and a year in far from the goals.
local function failing(h, month, extra)
  local self = setmetatable({bot = {world = {endconditions = ec, date = function() end}}}, M)
  local s = {hosp = h, day = month * 30, month = month, balance = h.balance, loan = h.loan, max_loan = 20000,
      reputation = h.reputation}
  for k, v in pairs(extra or {}) do s[k] = v end
  return self:failing(s)
end
eq(#failing(hospital({balance = 20000, value = 100000, reputation = 500}), 6), 0, "healthy")
-- Reputation 250: past the warning (400), 75% of the way to 200: close to losing.
eq(#failing(hospital({reputation = 250}), 6), 1, "close to losing")
-- A year in with less than 30% of the way on average.
eq(#failing(hospital({balance = 1000, value = 10000, percentage_killed = 40}), 12), 1, "far behind")
eq(#failing(hospital({balance = 1000, value = 10000, percentage_killed = 40}), 6), 0, "too early to say")
-- The game's own mark.
eq(#failing(hospital({balance = 20000, value = 100000, mp_failing_since = 1}), 6), 1, "failed at the year end")
-- Out of money and loans for 20 days.
local broke = hospital({balance = 500, loan = 20000, opened = true, value = 90000, percentage_killed = 5})
local self = setmetatable({bot = {world = {endconditions = ec}}}, M)
local s = {hosp = broke, day = 100, month = 4, balance = 500, loan = 20000, max_loan = 20000, reputation = 500}
eq(#self:failing(s), 0, "broke, but not for long")
s.day = 121
eq(#self:failing(s), 1, "broke for 20 days")
-- A failing bot asks the advisor and its allies, but never in the first game
-- year (months 1 to 12), and then at most every 3 months.
do
  local reviews, asks = 0, 0
  local m = setmetatable({bot = {now = function() return 0 end,
      askRescue = function() reviews = reviews + 1 return false end},
      log = function() end, history = {}, failing = function() return {"(a test) failing"} end,
      report = function() return "" end, planMenu = function() return {} end,
      askForHelp = function() asks = asks + 1 end}, M)
  local function day(d) local st = {day = d, month = math.floor((d - 1) / 30) + 1, hosp = {}} m:rescue(st) m:rescue(st) end
  day(200)
  day(360)
  eq(reviews + asks, 0, "no rescue in the first year")
  day(361)
  eq(reviews, 1, "a review in month 13")
  eq(asks, 1, "and an ask to the allies")
  day(400)
  eq(reviews, 1, "not again within 3 months")
  day(452)
  eq(reviews, 2, "again after 3 months")
end
print("manager judgements ok")

-- Where its money went (said to an ally it gives less than asked, or nothing):
-- its last big spending, in words, for three months.
do
  local today = 100
  local m = setmetatable({bot = {gameDay = function() return today end}, log = function() end, history = {}}, M)
  eq(m:spentWords(today), nil, "nothing spent yet")
  m:noteSpent("buy:bench", 150)
  eq(m:spentWords(today), nil, "a bench is no big spending")
  m:noteSpent("room:x_ray", 12000)
  eq(m:spentWords(today), "the new x ray room ($12,000)", "a room")
  m:noteSpent("gift:Ann", 5000)
  eq(m:spentWords(today), "the money I sent to Ann ($5,000)", "a gift")
  m:noteSpent("buy:land", 30000)
  eq(m:spentWords(today + 10), "a new plot of land ($30,000)", "land")
  eq(m:spentWords(today + 91), nil, "too long ago")
end
print("spending ok")

-- Rooms taken down: one nobody used for 5 months; while the level's value goal
-- is not met, only one unused for a year and only with no space left (a room
-- found no floor lately and no land can be got), the cheapest first.
do
  local hosp = {}
  local function room(id, kind, cost)
    return {id = id, hospital = hosp, built = true, is_active = true, room_info = {id = kind, cost = cost}}
  end
  local plot_price
  local m = setmetatable({bot = {world = {rooms = {room(1, "gp", 5000), room(2, "x_ray", 12000),
      room(3, "training", 3000)}}, roomCost = function(_, rt) return rt.cost end,
      cheapestPlot = function() return plot_price and 1, plot_price end},
      room_used = {[1] = 0, [2] = 0, [3] = 10}, no_space = {}}, M)
  local st = {hosp = hosp, day = 200, balance = 5000, loan = 0, max_loan = 20000}
  eq(m:vacantRoom(st).id, 2, "five months unused: the one empty longest (never the GP's office)")
  eq(m:vacantRoom(st, 360, true), nil, "the value goal: not before a year")
  st.day = 400
  eq(m:vacantRoom(st, 360, true).id, 3, "a year unused: the cheapest")
  eq(m:outOfSpace(st), false, "not without a room that found no floor")
  m.no_space["room:psych"] = 390
  plot_price = 10000
  eq(m:outOfSpace(st), false, "land it can get (with a loan)")
  plot_price = 40000
  eq(m:outOfSpace(st), true, "land too dear: out of space")
  plot_price = nil
  eq(m:outOfSpace(st), true, "no land left: out of space")
  st.day = 430
  eq(m:outOfSpace(st), false, "the last room without floor was a month ago")
end
print("rooms taken down ok")

-- The floor in one piece: a corridor 7 tiles long and 3 wide, the entrance at
-- its west end, a room's door at its east end. A bench or drinks machine
-- (a whole tile) or a radiator (one side of a tile) that would cut it in two
-- is refused (Bot:floorKept: more parts than before); one that already does
-- is found and taken away (M.floorBlocker).
do
  local W = M.FLOOR_W
  local function key(x, y) return y * W + x end
  local walk, held = {}, {}
  for y = 1, 3 do
    for x = 1, 7 do
      walk[key(x, y)] = (y > 1 and 1 or 0) + (x < 7 and 2 or 0) + (y < 3 and 4 or 0) + (x > 1 and 8 or 0)
    end
  end
  local floor = {walk = walk, held = held, targets = {key(1, 2), key(7, 2)}}
  local function parts(change) return (M.floorParts(floor, change)) end
  local function put(x, y) walk[key(x, y)], held[key(x, y)] = nil, walk[key(x, y)] end
  local bench = {orientations = {north = {footprint = {{0, 0, complete_cell = true},
      {0, -1, only_passable = true, invisible = true, shareable = true}}}}}
  local radiator = {orientations = {east = {footprint = {{0, 0, only_side = true}}},
      south = {footprint = {{0, 0, only_side = true}}}}}
  eq(parts(), 1, "one piece")
  eq(parts(M.objectChange(bench, 4, 3, "north")), 1, "a bench by the wall is fine")
  local across = {}
  for y = 1, 3 do M.objectChange(bench, 4, y, "north", across) end
  eq(parts(across), 2, "a row of benches across the corridor would split it")
  -- Two benches stand (as a bot put them down); the third would close the gap.
  put(4, 1)
  put(4, 2)
  local before = parts()
  eq(before, 1, "two benches leave a gap")
  eq(parts(M.objectChange(bench, 4, 3, "north")) > before, true, "the third is refused: it splits the floor")
  eq(parts(M.objectChange(bench, 2, 3, "north")) > before, false, "elsewhere a bench is fine")
  eq(parts(M.objectChange(radiator, 4, 3, "east")) > before, true, "a radiator closing the gap's side is refused")
  eq(parts(M.objectChange(radiator, 4, 3, "south")) > before, false, "against the wall it is fine")
  eq(parts(M.objectChange(bench, 7, 2, "north")) > before, true, "nothing on the tile before a door")
  -- A floor already in two (three benches across): the bench in the way is
  -- the one the bot sells, and without it the floor is one piece again.
  put(4, 3)
  eq(parts(), 2, "three benches split it")
  local away = {}
  for y = 1, 3 do M.objectChange(bench, 4, y, "north", away, true) end
  local kind, k = M.floorBlocker(floor, away)
  eq(kind, "tile", "an object is in the way")
  eq(k % W, 4, "one of the three benches")
  eq(parts(M.objectChange(bench, k % W, math.floor(k / W), "north", nil, true)), 1, "taken away, the floor is whole")
  -- A floor parted by walls (nothing to take away): no object is blamed.
  eq(M.floorBlocker({walk = {[key(1, 1)] = 0, [key(3, 1)] = 0}, held = {}, targets = {key(1, 1), key(3, 1)}}, {}),
      nil, "walls: nothing to sell")
end
print("floor ok")

-- The training room: students fill the chairs from the doctors who can be
-- spared; a doctor with a patient, or the only surgeon of an operating
-- theatre, stays at work.
do
  class = {is = function(x, c) return x and x.is_a == c end} -- (the game's class library, for Patient)
  Patient = "Patient"
  local moved = {}
  local theatre = {id = 2, is_active = true, room_info = {id = "operating_theatre", required_staff = {Surgeon = 1}},
      humanoids = {}, x = 10, y = 10, width = 5, height = 5}
  local gp = {id = 3, is_active = true, room_info = {id = "gp", required_staff = {Doctor = 1}},
      humanoids = {}, x = 20, y = 10, width = 5, height = 5}
  local chair = {object_type = {id = "lecture_chair"}}
  local teacher
  local training = {id = 1, is_active = true, room_info = {id = "training", required_staff = {Consultant = 1}},
      objects = {[chair] = true, [{object_type = {id = "lecture_chair"}}] = true, [{object_type = {id = "lecture_chair"}}] = true},
      humanoids = {}, x = 1, y = 1, width = 5, height = 5}
  local clinic = {staff = {}}
  for _, rm in ipairs({training, theatre, gp}) do rm.hospital = clinic end
  local rooms_at = {} -- "x,y" -> room
  local function doctor(name, tile_x, room, fields)
    local st = {humanoid_class = "Doctor", tile_x = tile_x, tile_y = 1, mp_id = #clinic.staff + 1, name = name,
        profile = {skill = 0.5, getFullName = function() return name end},
        fulfillsCriterion = function(_, cat) return cat == "Doctor" end}
    for k, v in pairs(fields or {}) do st[k] = v end
    st.profile.is_junior, st.profile.is_consultant = fields and fields.junior, fields and fields.consultant
    rooms_at[tile_x .. ",1"] = room
    clinic.staff[#clinic.staff + 1] = st
    if room then room.humanoids[st] = true end
    return st
  end
  teacher = doctor("Teacher", 2, training, {consultant = true})
  training.staff_member = teacher
  local junior = doctor("Junior", 30, nil, {junior = true})
  local gp_doc = doctor("GPdoc", 31, gp, {})
  gp.humanoids[{is_a = "Patient"}] = true          -- (a patient in his room)
  local surgeon = doctor("Surgeon", 32, theatre, {})
  surgeon.fulfillsCriterion = function(_, cat) return cat == "Surgeon" or cat == "Doctor" end
  local plain = doctor("Plain", 33, nil, {skill = 0.2})
  plain.profile.skill = 0.2
  function clinic.countStaffOfCategory(_, cat) return cat == "Surgeon" and 1 or 0 end
  local tworld = {ui = {hospital = clinic}, rooms = {training, theatre, gp}, available_staff = {Doctor = {}},
      getRoom = function(_, x, y) return rooms_at[x .. "," .. y] end}
  local wanted, hired, can_hire = 2, 0, true
  local bot = {world = tworld, flag = function(p, name) return p[name] ~= nil and p[name] ~= false end,
      teacherScore = function() return 0 end, specialisms = function() return 0 end,
      staffWanted = function() return {Doctor = wanted} end,
      canHire = function() return can_hire end,
      hireStudent = function() hired = hired + 1 return true end,
      moveStaffInto = function(_, st) moved[#moved + 1] = st.name return true end}
  local m = setmetatable({bot = bot, log = function() end, history = {}, rand = function(_, b) return b or 1 end}, M)
  local first = {day = 40, balance = 50000}
  m:training(first)
  eq(moved[1], "Junior", "a junior first")
  m:training({day = 41, balance = 50000})
  eq(#moved, 1, "not again within 3 days")
  -- (the junior sits in the room now)
  junior.tile_x = 4
  rooms_at["4,1"] = training
  training.humanoids[junior] = true
  m:training({day = 45, balance = 50000})
  eq(moved[2], "Plain", "then the doctor who can be spared, not the one with a patient or the only surgeon")
  eq(m:canSpareDoctor(gp_doc), false, "a doctor with a patient stays")
  eq(m:canSpareDoctor(surgeon), false, "the only surgeon of a theatre stays")
  eq(m:canSpareDoctor(plain), true, "a plain doctor can go")
  -- Three chairs, two students: the third is no doctor who must stay at work,
  -- but (until the 3rd year the chairs are kept full) one hired as a student.
  local second = moved[2]
  plain.tile_x = 5
  rooms_at["5,1"] = training
  training.humanoids[plain] = true
  m:training({day = 50, balance = 50000})
  eq(#moved, 2, "no third student for a doctor who must stay (" .. tostring(moved[3]) .. ", " .. second .. ")")
  eq(hired, 1, "a student hired for the third chair")
  m:training({day = 52, balance = 50000})
  eq(hired, 1, "one every 3 days")
  m:training({day = 53, balance = 5000})
  eq(hired, 1, "not without the money for it")
  -- The hospital lacks a doctor (the GP's office stands empty and fewer
  -- doctors work than its rooms need). Until the 3rd year a student goes back
  -- only when no doctor can be hired (the students do not count as staff, so
  -- a doctor is hired for the room); then the most skilled one.
  wanted = 4
  gp.humanoids[gp_doc] = nil
  m:training({day = 600, balance = 50000})
  eq(#moved, 2, "a doctor can be hired: the students stay")
  eq(m:studentsAway(600), 2, "both students are away from work")
  can_hire = false
  m:training({day = 603, balance = 50000})
  eq(moved[3], "Junior", "none to hire: the most skilled student goes back")
  -- From the 3rd year nobody is hired to fill a chair, a junior learns until
  -- he is a doctor (and counts as staff for the need he was hired for), and
  -- a student who is not a junior goes back when a doctor is lacking.
  local before = hired
  m:training({day = 800, balance = 50000})
  eq(moved[4], "Plain", "the student who is not a junior goes back")
  eq(hired, before, "no student hired from the 3rd year")
  eq(m:studentsAway(800), 1, "the junior counts as staff")
  eq(m:traineeChair({day = 800}) ~= nil, true, "a free chair for a junior hired for a need")
  eq(m:traineeChair({day = 700}), nil, "not before the 3rd year")
  -- Chairs: 3 to 6, chosen once.
  local n1 = m:trainingPlan()
  local _, extra = m:trainingPlan()
  eq(extra >= 2 and extra <= 5, true, "3 to 6 chairs")
  eq(m.training_chairs - 1, extra, "the same number every time")
  eq(n1 == 6 or n1 == 5, true, "its size (5 or 6)")
end
print("training ok")
