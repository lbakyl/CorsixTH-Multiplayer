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
print("manager judgements ok")

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
  local bot = {world = tworld, flag = function(p, name) return p[name] ~= nil and p[name] ~= false end,
      teacherScore = function() return 0 end, specialisms = function() return 0 end,
      staffWanted = function() return {Doctor = 2} end,
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
  -- Three chairs: the teacher and two students fill the room, no third.
  local second = moved[2]
  plain.tile_x = 5
  rooms_at["5,1"] = training
  training.humanoids[plain] = true
  m:training({day = 50, balance = 50000})
  eq(#moved, 2, "no third student for a doctor who must stay (" .. tostring(moved[3]) .. ", " .. second .. ")")
  -- Chairs: 3 to 6, chosen once.
  local n1 = m:trainingPlan()
  local _, extra = m:trainingPlan()
  eq(extra >= 2 and extra <= 5, true, "3 to 6 chairs")
  eq(m.training_chairs - 1, extra, "the same number every time")
  eq(n1 == 6 or n1 == 5, true, "its size (5 or 6)")
end
print("training ok")
