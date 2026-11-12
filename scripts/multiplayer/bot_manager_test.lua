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

-- An ally asks a bot for one of its plots (M:plotRequest). A map of 30 x 10
-- indoor tiles in columns: plot 1 (x 1-6, the asker's start), plot 2 (x 7-12,
-- the bot's start), plot 5 (x 13-18, 60 tiles), plot 6 (x 19-26, 80 tiles),
-- plot 7 (x 27-30, the asker's). Plot 6 touches plot 7. Rooms fill the
-- first `room_rows` rows of a plot. The level wants a hospital worth $100,000.
do
  local function plot_of(x)
    if x <= 6 then return 1 elseif x <= 12 then return 2 elseif x <= 18 then return 5 elseif x <= 26 then return 6 end
    return 7
  end
  local owner = {[1] = 1, [2] = 2, [5] = 2, [6] = 2, [7] = 1}
  local room_rows = {[2] = 3}
  local paid = {[5] = 7875, [6] = 9000}
  local touch = {[5] = {[2] = true, [6] = true}, [6] = {[5] = true, [7] = true}, [7] = {[6] = true}}
  local blocked, far, icons = {}, {}, {}
  local th = {
    size = function() return 30, 10 end,
    getCellFlags = function(_, x, y, flags)
      flags = flags or {}
      local p = plot_of(x)
      flags.parcelId, flags.owner, flags.hospital = p, owner[p] or 0, true
      flags.roomId = y <= (room_rows[p] or 0) and 1 or 0
      return flags
    end,
    getPlotCount = function() return 7 end,
    getPlotOwner = function(_, p) return owner[p] or 0 end,
  }
  MultiplayerSession = {
    BOT_LAND_FILL = 0.70, PLOT_PRICE_STEP = 500, PLOT_MAX_PRICE = 50000,
    plotTiles = function(_, p)
      local t = {}
      for y = 1, 10 do
        for x = 1, 30 do
          if plot_of(x) == p then t[#t + 1] = x t[#t + 1] = y end
        end
      end
      return t
    end,
    plotPaid = function(_, p) return paid[p] or 0 end,
    plotsTouching = function(_, p) return touch[p] or {} end,
    isStartingPlot = function(_, p) return p <= 2 end,
    plotRefusal = function(_, h, p)
      if p < 1 or p > 7 then return "no such plot" end
      if owner[p] ~= h:getPlayerIndex() then return "not your plot" end
      if p <= 2 then return "starting plot" end
      return blocked[p]
    end,
    -- (The released game's rule: the plot must touch the asker's land.)
    plotHandoverRefusal = function(_, _, p) return far[p] end,
  }
  local asker = {getPlayerIndex = function() return 1 end}
  local mine = hospital({balance = 50000, value = 150000})
  mine.getPlayerIndex = function() return 2 end
  local tworld = {map = {th = th}, hospitals = {asker, mine}, endconditions = ec, mp_plot_offers = {},
      ui = {hospital = mine, bottom_panel = {findMessageIcon = function(_, id) return icons[id] end}}}
  local today, free_floor = 100, 400
  local bot = {world = tworld, gameDay = function() return today end, freeFloor = function() return free_floor end,
      freeTile = function(_, x, y) local p = plot_of(x) return owner[p] == 2 and y > (room_rows[p] or 0) end}
  local m = setmetatable({bot = bot, log = function() end, pick = function(l) return l[1] end, fill_in = fill,
      no_space = {}, plot_bought = {}, plot_sent = {}}, M)
  local function ask(plot, asker_index) return m:plotRequest(asker_index or 1, plot, 15000, "ann") end
  local function gives(v, plot, price, what)
    eq(v.give, true, what .. ": given")
    eq(v.plot, plot, what .. ": the plot")
    eq(v.price, price, what .. ": the price")
  end
  local function keeps(v, why, what)
    eq(v.give, nil, what .. ": kept")
    eq(v.why, why, what .. ": why")
  end
  -- An empty plot it does not need: free (its bank holds $15,000 or more).
  local v = ask(5)
  gives(v, 5, 0, "empty plot")
  eq(v.why, "free", "free")
  eq(v.line, "Plot 5 is yours, ann, free of charge. Just accept the fax.", "the line")
  -- Short of cash: what it cost, rounded to $500, at least $500, at most $50,000.
  mine.balance = 9000
  gives(ask(5), 5, 8000, "short of cash: $7,875 asks $8,000")
  eq(ask(5).why, "price", "a price")
  eq(ask(5).line:find("$8,000", 1, true) ~= nil, true, "the price in the line")
  paid[5], mine.value = 120000, 300000
  gives(ask(5), 5, 50000, "never more than $50,000")
  paid[5] = 100
  gives(ask(5), 5, 500, "at least one step")
  paid[5], mine.balance, mine.value = 7875, 50000, 150000
  -- Kept: rooms or things on it.
  blocked[5] = "plot not empty"
  keeps(ask(5), "in_use", "in use")
  -- Somebody walking on it: given, once nobody is (Bot:plotWaitTick).
  blocked[5] = "people on the plot"
  v = ask(5)
  gives(v, 5, 0, "people on it")
  eq(v.wait, "people", "offered once nobody is on it")
  blocked[5] = nil
  -- Kept: it needs the land. Without plot 5, rooms would take 124 of 140 tiles
  -- (less than 35% free).
  room_rows = {[2] = 10, [6] = 8}
  keeps(ask(5), "land", "too little floor left without it")
  room_rows = {[2] = 3}
  -- A room found no floor lately, and without the plot's 60 free tiles only 70
  -- would be left (under 120): it is about to build there.
  m.no_space["room:psych"] = today - 5
  free_floor = 130
  keeps(ask(5), "land", "a room waits for floor")
  free_floor = 400
  gives(ask(5), 5, 0, "plenty of floor besides it")
  m.no_space = {}
  -- Kept: it bought the plot itself a few days ago (for rooms to come).
  m:notePlotBought(5)
  today = today + 10
  keeps(ask(5), "fresh", "just bought")
  today = today + 30
  gives(ask(5), 5, 0, "bought more than 30 days ago")
  -- Kept: the value goal ($100,000). Worth $105,000, without the plot's $7,875
  -- it would be under it.
  mine.value = 105000
  v = ask(5)
  keeps(v, "value", "the value goal would fail")
  eq(v.line, "Sorry ann, without plot 5 my hospital value would be under the $100k the level asks for.", "value line")
  mine.value = 50000
  keeps(ask(5), "value", "the value goal not met yet")
  mine.mp_goals_reached = true
  gives(ask(5), 5, 0, "the requirements reached: the value no longer matters")
  mine.mp_goals_reached, mine.value = nil, 150000
  -- No plot named: the one touching the asker's land first (plot 6, though
  -- bigger), then the smallest; one with nobody on it first.
  gives(ask(nil), 6, 0, "any: the one touching the asker's land")
  owner[7] = 0
  gives(ask(nil), 5, 0, "any: the smallest")
  blocked[5] = "people on the plot"
  v = ask(nil)
  gives(v, 6, 0, "any: one nobody is on")
  eq(v.wait, nil, "offered at once")
  blocked[5] = nil
  -- None to spare: the reason of the best kept, or none at all.
  mine.value = 105000
  v = ask(nil)
  keeps(v, "value", "all kept for the value goal")
  eq(v.plot, 5, "the best of the rest named")
  mine.value = 150000
  owner[5], blocked[6] = 0, "plot not empty"
  keeps(ask(nil), "none", "none to spare")
  owner[5], blocked[6] = 2, nil
  -- Plots it cannot give.
  keeps(ask(7), "not_mine", "not its plot")
  keeps(ask(99), "no_such", "no such plot")
  keeps(ask(2), "start", "its starting plot")
  blocked[5] = "joins your land"
  keeps(ask(5), "joins", "joins its land")
  blocked[5] = nil
  far[5] = "does not touch their land"
  keeps(ask(5), "far", "the released game: must touch the asker's land")
  far[5] = nil
  -- Offered already: a fax waiting, or an offer just sent.
  tworld.mp_plot_offers[5], icons[77] = 77, {}
  keeps(ask(5), "offered", "a fax waiting")
  icons[77] = nil
  gives(ask(5), 5, 0, "the fax answered")
  m:notePlotOffered(5)
  keeps(ask(5), "offered", "an offer just sent")
  today = today + 2
  gives(ask(5), 5, 0, "the offer long gone")
  -- The same hospital, an auction on.
  keeps(ask(5, 2), "same", "a person sharing its hospital")
  tworld.mp_auction = {}
  keeps(ask(5), "auction", "during an auction")
  tworld.mp_auction = nil
  MultiplayerSession = nil
end
print("plot requests ok")

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

-- Dealing with rivals (2026-11-12): research is worth what its machine
-- costs (an X-ray more than a slack tongue clinic), only when patients need
-- the room; another bot's ask is read back from the chat line.
do
  local saved = rawget(_G, "TheApp")
  TheApp = {objects = {x_ray = {id = "x_ray", thob = 27}, slicer = {id = "slicer", thob = 26}},
    rooms = {{id = "x_ray", objects_needed = {x_ray = 1, radiation_shield = 1}, categories = {diagnosis = 7}},
      {id = "slack_tongue", objects_needed = {slicer = 1}, categories = {clinics = 1}}}}
  local w = {map = {level_config = {objects = {[26] = {StartCost = 1500}, [27] = {StartCost = 4000}}}}, rooms = {}}
  local mine = {disease_casebook = {}}
  local need = {x_ray = true, slack_tongue = true}
  eq(M.researchValue(w, mine, "e:x_ray", need), 4000, "an X-ray: $4,000")
  eq(M.researchValue(w, mine, "e:slicer", need), 1000, "a slack tongue clinic: $1,000")
  eq(M.researchValue(w, mine, "e:x_ray", {}), 0, "no patient needs it: nothing")
  eq(M.researchValue(w, mine, "m:x_ray", need), 0, "a better X-ray without one: nothing")
  w.rooms = {{hospital = mine, room_info = TheApp.rooms[1]}}
  eq(M.researchValue(w, mine, "m:x_ray", need), 1000, "a better X-ray it has: $1,000")
  mine.disease_casebook.bloaty_head = {recoveries = 3}
  eq(M.researchValue(w, mine, "d:bloaty_head", need), 500, "a better drug it uses: $500")
  eq(M.researchValue(w, mine, "d:baldness", need), 0, "a drug for a disease it never saw: nothing")
  eq(M.priceText(4000), "$4,000", "price 4000")
  eq(M.priceText(500), "$500", "price 500")
  eq(M.priceText(12500), "$12,500", "price 12500")
  TheApp = saved

  local bf = assert(io.open((arg[1]:gsub("bot_manager%.lua$", "bot.lua"))))
  local bsrc = bf:read("*a")
  bf:close()
  local a = assert(bsrc:find("  research_please = {", 1, true))
  local b = assert(bsrc:find("  -- Its answers to another bot's ask", a, true))
  local lines = assert((loadstring or load)("return {" .. bsrc:sub(a, b - 1) .. "}"))()
  for _, set in ipairs({"research_buy", "research_please", "staff_ask_rival"}) do
    for _, t in ipairs(lines[set]) do
      local text = t:gsub("{name}", "Bot Clive and ann"):gsub("{item}", "X-Ray"):gsub("{price}", "$3,500")
          :gsub("{room}", "X-ray"):gsub("{kind}", "surgeon")
      local got = M.readAsk(lines, text)
      eq(got and got.set, set, "read back: " .. text)
      if set ~= "staff_ask_rival" then eq(got.item, "X-Ray", "item: " .. text) end
      if set == "research_buy" then eq(got.price, 3500, "price: " .. text) end
      if set == "staff_ask_rival" then eq(got.kind, "surgeon", "kind: " .. text) end
    end
  end
  eq(M.readAsk(lines, "Deal, Bot Clive: my X-Ray research for $3,500. Accept it in your messages."), nil,
      "an answer is no ask")
  eq(M.readAsk(lines, "Hello everybody!"), nil, "small talk is no ask")
  -- Rivals only in a race where everyone plays alone.
  eq(M.dealsWithRivals({mp_coop = {competitive = true}}), true, "a race of all against all")
  eq(M.dealsWithRivals({mp_coop = {competitive = true, teams = {1, 2, 1, 2}}}), false, "a race of teams")
end
print("rivals ok")
