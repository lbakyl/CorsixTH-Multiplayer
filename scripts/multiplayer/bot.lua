-- A computer player (bot) for one multiplayer room. The server (mp_server)
-- starts it when the room's owner clicks an empty place in the lobby:
--   corsix-th --interpreter=<this file> --config-file=<generated>
-- It joins the room like a player (ready at once), and once the game starts
-- it plays its own hospital through the same game windows and commands as a
-- person: it builds the rooms the level has one after the other, hires the
-- staff they need and opens the hospital, so that for the first year or so
-- it looks like somebody playing. It also talks: a greeting in the second to
-- fourth month, answers to the chat, and a word when somebody sends it
-- something. In co-op it accepts what the others offer (staff, patients,
-- research, money requests); in a competitive race it refuses all of it and
-- plays a dirty trick now and then (the first one in months 7 to 12).
--
-- It never uses the game's random numbers (that would change its game and
-- desync it); its choices come from its own generator below.
--
-- Environment (set by the server):
--   CORSIXTH_SOURCE      checkout root
--   MP_SERVER            server address host:port
--   MP_BOT_ROOM          room to join
--   MP_BOT_TOKEN         token the server gave this bot
--   MP_BOT_NAME          its name (also the name of its hospital)
--   MP_BOT_MODE          the room's mode (shared, coop, competitive)
--   MP_LUA_CPATH, MP_LUA_PATH  where to find LuaSocket (if not standard)
-- Tests only:
--   MP_BOT_SEED          seed for its choices (default: from the clock)
--   MP_BOT_PACE          game days between its building steps are divided
--                        by this (default 1: like a person)
--   MP_BOT_FAST          1: run the game as fast as the others allow and
--                        answer at once (scripted tests)
local args = {...}
local unpack_args = table.unpack or unpack
local source_dir = assert(os.getenv("CORSIXTH_SOURCE"), "Missing CORSIXTH_SOURCE")
local server = assert(os.getenv("MP_SERVER"), "Missing MP_SERVER")
local room = assert(os.getenv("MP_BOT_ROOM"), "Missing MP_BOT_ROOM")
local token = assert(os.getenv("MP_BOT_TOKEN"), "Missing MP_BOT_TOKEN")
local my_name = os.getenv("MP_BOT_NAME") or "Bot"
local pace = math.max(1, tonumber(os.getenv("MP_BOT_PACE") or "1") or 1)
local fast = os.getenv("MP_BOT_FAST") == "1"

if os.getenv("MP_LUA_CPATH") then package.cpath = os.getenv("MP_LUA_CPATH") .. ";" .. package.cpath end
if os.getenv("MP_LUA_PATH") then package.path = os.getenv("MP_LUA_PATH") .. ";" .. package.path end

local function log(msg)
  io.stdout:write("[" .. my_name .. "] " .. msg .. "\n")
  io.stdout:flush()
end

-- Its own random numbers (a linear congruential generator): never the
-- game's math.random.
-- (Its name goes into the seed, so that bots started together differ.)
local seed = tonumber(os.getenv("MP_BOT_SEED") or "") or os.time()
for i = 1, #my_name do seed = (seed * 31 + my_name:byte(i)) % 2147483647 end
local rng_state = seed % 2147483647
local function rand(a, b)
  rng_state = (rng_state * 1103515245 + 12345) % 2147483648
  local r = math.floor(rng_state / 65536) / 32768 -- 0 <= r < 1
  if not a then return r end
  return a + math.floor(r * (b - a + 1))
end
local function pick(list) return list[rand(1, #list)] end

--------------------------------------------------------------------------------
-- What it says. %s is the other player's name.
--------------------------------------------------------------------------------

local LINES = {
  greet = {
    friendly = {
      "Hi everyone! Building my hospital nice and slowly over here.",
      "Hello, team! Shout if you need a hand. Or a doctor.",
      "Good morning, colleagues! The coffee machine is on me.",
      "Hi all! My first patients are on their way. Fingers crossed.",
      "Greetings from across town! Let me know if you need anything.",
      "Hello! My receptionist says hi too.",
    },
    fiery = {
      "Enjoy your lead while it lasts. My hospital is coming for yours.",
      "This town needs only one hospital. Guess which one.",
      "My doctors are sharper and my nurses faster. Good luck, everybody!",
      "Ready to lose? I have already ordered the trophy.",
      "I hope your patients like waiting. Mine won't have to.",
      "Watch out, %s. I play to win.",
    },
  },
  accept = {
    "Thank you, %s!",
    "Much appreciated, %s.",
    "Cheers, %s, that helps a lot!",
    "You're a star, %s.",
    "Got it, thanks %s!",
    "That's very kind of you, %s.",
  },
  refuse = {
    "Not on my watch, %s!",
    "Nice try, %s. No thanks.",
    "I don't take gifts from rivals, %s.",
    "Keep it, %s. I'll win on my own.",
    "Ha! What's the catch, %s?",
    "Do I look that gullible, %s?",
  },
  pay = {
    "Here you go, %s.",
    "Sent, %s. Spend it wisely!",
    "Of course, %s. That's what friends are for.",
  },
  broke = {
    "Sorry %s, I'm broke right now.",
    "I'd love to, %s, but my bank manager says no.",
  },
  money_thanks = {
    "Thanks for the cash, %s!",
    "Wow, thank you %s! Straight into new equipment.",
    "%s, you're too generous. Thanks!",
  },
  money_back = {
    "Keep your money, %s. You'll need it.",
    "I don't want your charity, %s. Sent it back.",
    "Return to sender, %s!",
  },
  trick = {
    "Is it just me, or does it smell funny over at %s's place?",
    "Hope your handymen are well rested, %s.",
    "Having a quiet day, %s? Not for long.",
    "Oh dear, %s. Busy, busy, busy.",
  },
}

local REPLIES = {
  bot = {
    friendly = {"Yes, I'm a bot, %s. Beep boop!", "Guilty, %s. Computer player, at your service."},
    fiery = {"A bot, %s, and a better manager than you.", "Beep boop, %s. Prepare to lose."},
  },
  greet = {
    friendly = {"Hi %s!", "Hello %s, how's the hospital?", "Hey %s! Busy day here.", "Hi %s, good to see you."},
    fiery = {"Hello, %s. Enjoy it while it lasts.", "Oh, it's you, %s.", "Hi %s. Ready to lose?"},
  },
  how = {
    friendly = {"Doing fine, %s! Short queues and watered plants.", "All good, %s. A bit of Bloaty Head, nothing serious.",
        "Busy but happy, %s. You?"},
    fiery = {"Better than you, %s.", "Never better, %s. Check the league table."},
  },
  thanks = {
    friendly = {"Any time, %s!", "No problem, %s.", "You're welcome, %s."},
    fiery = {"Don't get used to it, %s.", "Hmph. You're welcome, %s."},
  },
  insult = {
    friendly = {"Hey, be nice, %s!", "Ouch, %s. I have feelings. Probably."},
    fiery = {"Big words, %s. Let's see the scoreboard.", "Keep talking, %s. I'll keep winning."},
  },
  race = {
    friendly = {"We're in this together, %s!", "Teamwork, %s. That's how we win."},
    fiery = {"We'll see who's laughing at the year end, %s.", "First place is mine, %s.",
        "You'll be watching my victory from the waiting room, %s."},
  },
  money = {
    friendly = {"Money's tight here too, %s. Ask me later!", "I'd help, %s, but my budget says no today."},
    fiery = {"Money? From me? Dream on, %s.", "Not a penny, %s."},
  },
  bye = {
    friendly = {"Bye %s, see you soon!", "Take care, %s!"},
    fiery = {"Running away already, %s?", "Bye, %s. One less rival."},
  },
  question = {
    friendly = {"Good question, %s. I'm just a humble bot.", "No idea, %s, I'm busy curing Bloaty Head.",
        "Ask me again after my coffee break, %s.", "Hmm, let me think about it, %s."},
    fiery = {"Wouldn't you like to know, %s.", "That's classified, %s.", "Figure it out yourself, %s."},
  },
  other = {
    friendly = {"Ha, good one, %s.", "Agreed, %s.", "Busy here, %s, but I'm listening.", "Sure thing, %s!",
        "Interesting, %s. Tell me more.", "Right you are, %s."},
    fiery = {"Talk is cheap, %s.", "Keep chatting, %s, I'll keep building.", "Hmm. Suspicious, %s.",
        "Is that a threat, %s?", "Whatever you say, %s."},
  },
}

-- Words that choose the kind of answer (lower case; a few in Czech too).
local KEYWORDS = {
  {"bot", {"bot", "robot", "computer", "human", "real person"}},
  {"how", {"how are you", "how's it going", "how is it going", "how do you do", "jak se mas", "jak se máš"}},
  {"greet", {"hello", "hi", "hey", "hiya", "ahoj", "cau", "čau", "nazdar", "yo", "morning"}},
  {"thanks", {"thank", "thanks", "thx", "diky", "díky", "dekuji", "děkuji"}},
  {"bye", {"bye", "see you", "cya", "goodnight", "good night", "nashle"}},
  {"insult", {"stupid", "idiot", "noob", "loser", "dumb", "suck", "lame"}},
  {"race", {"win", "winning", "lose", "losing", "beat", "first place", "crush"}},
  {"money", {"money", "cash", "loan", "dollars", "penny", "broke"}},
}

local function has_word(text, word)
  if word:find(" ") then return text:find(word, 1, true) ~= nil end
  -- A whole word (so "hi" is not found in "this").
  for w in text:gmatch("[%w\128-\255']+") do
    if w == word then return true end
  end
  return false
end

local function reply_kind(text)
  text = text:lower()
  for _, entry in ipairs(KEYWORDS) do
    for _, word in ipairs(entry[2]) do
      if has_word(text, word) then return entry[1] end
    end
  end
  if text:find("?", 1, true) then return "question" end
  return "other"
end

--------------------------------------------------------------------------------
-- The bot
--------------------------------------------------------------------------------

local socket, builder, sabotage
local Bot = {}
Bot.__index = Bot

-- Rooms first, in this order; then the others the level has, by name.
local FIRST_ROOMS = {gp = 1, pharmacy = 2, general_diag = 3, ward = 4, psych = 5, staff_room = 6,
    toilets = 7, cardiogram = 8, scanner = 9, ultrascan = 10, blood_machine = 11, x_ray = 12}
-- Rooms a beginner leaves alone (a consultant to teach in it).
local SKIP_ROOMS = {training = true}
-- Doctors with a skill a room needs: how they are hired.
local SPECIALISTS = {Psychiatrist = "psychiatrist", Surgeon = "surgeon", Researcher = "researcher"}
-- Kept in the bank when building or buying.
local RESERVE = 3000
-- Corridor furniture once the hospital is open: id -> how many.
local EXTRAS = {{"bench", 3}, {"plant", 2}, {"drinks_machine", 1}, {"bench", 5}, {"extinguisher", 1},
    {"plant", 4}}

function Bot.new(lobby)
  local self = setmetatable({}, Bot)
  self.lobby = lobby
  self.mode = lobby.start_params and lobby.start_params.mode or os.getenv("MP_BOT_MODE") or "coop"
  self.fiery = self.mode == "competitive"
  self.outbox = {}         -- {at = real time, text =, to = peer or nil, fn = optional}
  self.offers_seen = {}    -- message number -> true
  self.last_reply = 0
  self.next_think = 0
  self.world = nil
  return self
end

function Bot:now() return socket.gettime() end

--! Say something (to everybody, or privately to one peer) after `delay` seconds.
function Bot:say(text, delay, to, fn)
  self.outbox[#self.outbox + 1] = {at = self:now() + (fast and 0 or (delay or 2)), text = text, to = to, fn = fn}
end

--! A person's typing time for a line: a pause to read, then some per letter.
local function typing(text)
  return 1.5 + #text * 0.06 + rand() * 2
end

function Bot:flushOutbox()
  local now = self:now()
  for i = #self.outbox, 1, -1 do
    local entry = self.outbox[i]
    if now >= entry.at then
      table.remove(self.outbox, i)
      if entry.fn then entry.fn() end
      if entry.text then
        self.lobby:send("CHAT", {text = entry.text, to = entry.to})
        log("CHAT: " .. entry.text)
      end
    end
  end
end

--! Peer -> name, and whether that player is a bot (from the room's list).
function Bot:playerName(peer)
  local p = self.lobby.players and self.lobby.players[peer]
  if p then return p.name, p.bot == "1" end
  for _, gp in ipairs(self.lobby.game_players or {}) do
    if gp.peer == peer then return gp.name, false end
  end
  return nil, false
end

--! The player of a hospital (index): their peer and name.
function Bot:playerOfHospital(index)
  for peer, h in pairs(self.lobby.peer_hospital or {}) do
    if h == index then
      local name, is_bot = self:playerName(peer)
      return peer, name, is_bot
    end
  end
end

function Bot:hospitalIndex()
  return TheApp.mp_session and TheApp.mp_session.hospital_index or 1
end

function Bot:gameDay()
  local d = self.world:date()
  return (d:monthOfGame() - 1) * 30 + d:dayOfMonth()
end

--! Days from now for the next step of a plan (shorter in a fast test).
function Bot:later(days)
  return self:gameDay() + math.max(1, math.floor(days / pace))
end

--------------------------------------------------------------------------------
-- Chat
--------------------------------------------------------------------------------

function Bot:onChat(f)
  local peer = tonumber(f.peer)
  local session = TheApp.mp_session
  if not session or not peer or peer == 0 or peer == session.peer_id then return end
  local name, is_bot = self:playerName(peer)
  if is_bot or not name then return end -- bots do not chat with each other
  local text = f.text or ""
  local private = f.to ~= nil
  local first = my_name:lower():match("(%a+)$") or my_name:lower()
  local named = text:lower():find(first, 1, true) ~= nil
  -- Several bots in a room: each answers a public line now and then.
  local bots = 0
  for _, p in pairs(self.lobby.players or {}) do
    if p.bot == "1" then bots = bots + 1 end
  end
  if not (private or named) then
    if rand() > 0.6 / math.max(1, bots) then return end
  end
  if self:now() - self.last_reply < 6 and not private then return end
  self.last_reply = self:now()
  local kind = reply_kind(text)
  local line = pick(REPLIES[kind][self.fiery and "fiery" or "friendly"]):format(name)
  self:say(line, typing(line), private and peer or nil)
end

--------------------------------------------------------------------------------
-- Offers, money and votes
--------------------------------------------------------------------------------

--! Answer the offers in this hospital's message bar (after a while, like
--! a person reading the fax).
function Bot:answerOffers()
  local panel = self.world.ui and self.world.ui.bottom_panel
  if not panel then return end
  local mine = self.world.ui.hospital
  for _, icon in ipairs(panel:allMessageIcons()) do
    local offer = type(icon.message) == "table" and icon.message.mp_offer
    if offer and icon.hospital == mine and icon.mp_id and not self.offers_seen[icon.mp_id] then
      self.offers_seen[icon.mp_id] = true
      local _, name = self:playerOfHospital(offer.from)
      name = name or "friend"
      local accept = not self.fiery
      local line
      if accept then
        local cost = offer.kind == "money" and offer.amount or offer.price or 0
        if cost > 0 and mine.balance - cost < RESERVE then
          accept = false
          line = pick(LINES.broke)
        elseif offer.kind == "money" then
          line = pick(LINES.pay)
        else
          line = pick(LINES.accept)
        end
      else
        line = pick(LINES.refuse)
      end
      line = line:format(name)
      local msg = icon.mp_id
      local delay = 3 + rand() * 5
      log(string.format("offer #%s (%s) from %s: %s in %.1f s", tostring(msg), tostring(offer.kind), name,
          accept and "accept" or "decline", delay))
      self:say(nil, delay, nil, function()
        local session = TheApp.mp_session
        if session and not session.held then
          session:issue({kind = "fax_choice", msg = msg, choice = accept and 1 or 2})
        end
      end)
      self:say(line, delay + typing(line))
    end
  end
end

--! Money arrived from another player (give_money, seen as it happens).
function Bot:moneyReceived(from_index, amount)
  local _, name = self:playerOfHospital(from_index)
  name = name or "friend"
  if self.fiery then
    -- Refused: it goes straight back.
    local line = pick(LINES.money_back):format(name)
    local delay = 3 + rand() * 4
    self:say(nil, delay, nil, function()
      local session = TheApp.mp_session
      if session and not session.held then
        session:issue({kind = "give_money", to = from_index, amount = amount})
      end
    end)
    self:say(line, delay + typing(line))
  else
    local line = pick(LINES.money_thanks):format(name)
    self:say(line, 2 + typing(line))
  end
end

--------------------------------------------------------------------------------
-- Building, hiring, opening
--------------------------------------------------------------------------------

--! The rooms this hospital can build now, most needed first.
function Bot:roomPlan()
  local hospital = self.world.ui.hospital
  local list = {}
  for _, room_type in ipairs(TheApp.rooms) do
    local discovery = hospital.room_discoveries[room_type.id]
    if discovery and discovery.is_discovered and hospital.research.research_progress[room_type] and
        not SKIP_ROOMS[room_type.id] then
      list[#list + 1] = room_type
    end
  end
  table.sort(list, function(a, b)
    local fa, fb = FIRST_ROOMS[a.id] or 99, FIRST_ROOMS[b.id] or 99
    if fa ~= fb then return fa < fb end
    return a.id < b.id
  end)
  return list
end

function Bot:roomCost(room_type)
  local hospital = self.world.ui.hospital
  local progress = hospital.research.research_progress[room_type]
  local cost = progress and progress.build_cost or 0
  for object, count in pairs(room_type.objects_needed or {}) do
    local ok, each = pcall(hospital.getObjectBuildCost, hospital, object)
    if ok and each then cost = cost + each * count end
  end
  return cost
end

--! Is this tile free floor of this hospital (no room, no object on it)?
function Bot:freeTile(x, y)
  local world = self.world
  local th = world.map.th
  local mw, mh = th:size()
  if x < 1 or y < 1 or x > mw or y > mh then return false end
  if not world.ui.hospital:isInHospital(x, y) or world:getRoom(x, y) or world:getObject(x, y) then return false end
  local flags = th:getCellFlags(x, y)
  return flags.buildable and flags.passable
end

--! Would a w x h room fit at x, y with free floor below it and to its
--! right (where its door goes)? It may stand against other walls.
function Bot:roomFits(x, y, w, h)
  for tx = x, x + w do
    for ty = y, y + h do
      -- The room itself, the row below it and the column to its right.
      if not self:freeTile(tx, ty) then return false end
    end
  end
  return true
end

--! The nearest place for a packed w x h room (see Bot:roomFits).
function Bot:packedSpot(cx, cy, w, h)
  for r = 0, 40 do
    for dy = -r, r do
      for dx = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r and self:roomFits(cx + dx, cy + dy, w, h) then
          return cx + dx, cy + dy
        end
      end
    end
  end
end

--! Draw the next room (furnished automatically). Returns the type drawn,
--! or nil and why not ("money", "space": it needs more land, "done").
function Bot:buildNextRoom()
  local hospital = self.world.ui.hospital
  for _, room_type in ipairs(self:roomPlan()) do
    local tries = self.room_tries[room_type.id] or 0
    if hospital:countRoomOfType(room_type.id, 1) == 0 and tries < 3 then
      if hospital.balance - self:roomCost(room_type) < RESERVE then return nil, "money" end
      self.room_tries[room_type.id] = tries + 1
      local min = room_type.minimum_size or 4
      local ax, ay = self:anchor()
      local size = math.min(7, math.max(5, min + 1))
      -- The size it would like with room around it, then smaller, then
      -- packed against other walls.
      local x, y, w
      for s = size, min, -1 do
        if not x then
          x, y = builder.find_free_rect(self.world, ax, ay, s, s, 40)
          w = s
        end
      end
      for s = size, min, -1 do
        if not x then
          x, y = self:packedSpot(ax, ay, s, s)
          w = s
        end
      end
      if x then
        local ok, res = pcall(builder.ui_room, self.world, ax, ay, room_type.id, w, w, true, log, {x, y})
        if not ok then log("could not draw " .. room_type.id .. ": " .. tostring(res)) end
        if ok and res then return room_type end
      else
        log(string.format("no space for a %s (%dx%d)", room_type.id, min, min))
        return nil, "space"
      end
    end
  end
  return nil, "done"
end

--! Buy the cheapest plot of land it may buy (on its side of the map) if it
--! can afford it and still keep money for a room.
function Bot:buyPlot()
  local world = self.world
  local th, hospital = world.map.th, world.ui.hospital
  local me = world:getHospitalIndex(hospital)
  local best, best_price
  for plot = 1, th:getPlotCount() do
    local side = world.mp_coop and MultiplayerSession.plotSide(world, plot)
    if (not side or side == me) and th:isParcelPurchasable(plot, hospital:getPlayerIndex()) then
      local price = world.map:getParcelPrice(plot)
      if not best or price < best_price then best, best_price = plot, price end
    end
  end
  if not best then
    log("no land left to buy")
    return false
  end
  if hospital.balance - best_price < 3 * RESERVE then
    log(string.format("plot %d costs $%d: not enough money yet", best, best_price))
    return false
  end
  log(string.format("buying plot %d for $%d", best, best_price))
  TheApp.mp_session:issue({kind = "buy_plot", plot = best})
  return true
end

--! Where to build from: the reception desk, or the middle of the hospital.
function Bot:anchor()
  return builder.anchor(self.world)
end

--! Buy a corridor object and put it on a free tile near the desk (the first
--! tile, nearest first, where the placement window allows it).
function Bot:buyCorridor(object_id)
  local world, ui = self.world, self.world.ui
  local hospital = ui.hospital
  local ok_cost, cost = pcall(hospital.getObjectBuildCost, hospital, object_id)
  if not ok_cost or hospital.balance - (cost or 0) < RESERVE then return false end
  local shop = UIFurnishCorridor(ui)
  ui:addWindow(shop)
  local found
  for _, o in ipairs(shop.objects) do
    if o.object.id == object_id then o.qty = o.qty + 1 found = true end
  end
  if not found then shop:close() return false end
  shop:confirm()
  local place = ui:getWindow(UIPlaceObjects)
  if not place then return false end
  local facings = {}
  for name in pairs(place.objects[1].object.orientations) do facings[#facings + 1] = name end
  table.sort(facings)
  local ax, ay = self:anchor()
  local placed
  -- Tiles with free floor all around (so nothing blocks a corridor).
  local x, y = builder.find_free_rect(world, ax, ay, 1, 1, 40, function(tx, ty)
    if world:anyHumanoidObscuringArea(tx, ty) then return false end
    for _, facing in ipairs(facings) do
      place:setOrientation(facing)
      place:setBlueprintCell(tx, ty)
      if place.object_blueprint_good then return true end
    end
    return false
  end)
  if x then
    place.object_cell_x, place.object_cell_y = x, y
    place:onMouseUp("left", 100000, 100000) -- a click outside the window
    placed = true
    log(string.format("bought a %s at %d,%d", object_id, x, y))
  else
    log("no place for a " .. object_id)
  end
  if ui:getWindow(UIPlaceObjects) then ui:getWindow(UIPlaceObjects):close() end
  return placed
end

--! The staff this hospital wants now: category -> count.
function Bot:staffWanted()
  local hospital = self.world.ui.hospital
  local want = {Receptionist = math.min(2, #hospital:getReceptionDesks()), Doctor = 0, Nurse = 0, Handyman = 0}
  local rooms = 0
  for _, r in pairs(self.world.rooms) do
    if r.hospital == hospital and r.is_active then
      rooms = rooms + 1
      for category, n in pairs(r.room_info.required_staff or {}) do
        if SPECIALISTS[category] then
          want[category] = (want[category] or 0) + n
          want.Doctor = want.Doctor + n
        else
          want[category] = (want[category] or 0) + n
        end
      end
    end
  end
  want.Handyman = rooms >= 8 and 2 or (rooms >= 3 and 1 or 0)
  return want
end

--! Hire one member of staff the hospital lacks (specialists first).
function Bot:hireOne()
  local world = self.world
  local hospital = world.ui.hospital
  if hospital.balance < RESERVE then return false end
  local want = self:staffWanted()
  local order = {"Receptionist", "Psychiatrist", "Surgeon", "Researcher", "Doctor", "Nurse", "Handyman"}
  for _, category in ipairs(order) do
    local need = want[category] or 0
    if need > 0 and hospital:countStaffOfCategory(category, need) < need then
      local class, skill = category, SPECIALISTS[category]
      if skill then class = "Doctor" end
      local pool = world.available_staff[class]
      local has = pool and #pool > 0
      if has and skill then
        has = false
        for _, profile in ipairs(pool) do
          if profile["is_" .. skill] == 1 then has = true end
        end
      end
      if has then
        local dx, dy = self:anchor()
        local ok, err = pcall(builder.ui_hire, world, dx, dy, skill and (class .. ":" .. skill) or class, log)
        if not ok then log("could not hire a " .. category .. ": " .. tostring(err)) end
        return ok
      end
    end
  end
  return false
end

--! Open the hospital (the button of the opening countdown).
function Bot:openHospital()
  for _, win in ipairs(self.world.ui.windows) do
    if class.is(win, UIWatch) and win.count_type == "initial_opening" and win.hospital == self.world.ui.hospital then
      log("opening the hospital")
      win:buttonEndCountdown()
      return true
    end
  end
  return false
end

function Bot:readyToOpen()
  local hospital = self.world.ui.hospital
  return #hospital:getReceptionDesks(true) > 0 and hospital:countRoomOfType("gp", 1) > 0 and
      hospital:countStaffOfCategory("Doctor", 1) > 0
end

--------------------------------------------------------------------------------
-- Dirty tricks (competitive)
--------------------------------------------------------------------------------

function Bot:playTrick()
  local world = self.world
  local mine = world.ui.hospital
  local targets = {}
  for index, hospital in ipairs(world.hospitals) do
    local peer, name, is_bot = self:playerOfHospital(index)
    if hospital ~= mine and peer and not is_bot then targets[#targets + 1] = {hospital, name} end
  end
  if #targets == 0 then return false end
  local target = pick(targets)
  local kinds = self.tricks_played == 0 and {"handyman"} or sabotage.KINDS
  local kind = pick(kinds)
  -- The highest level it can afford with something left over, at most a
  -- random one.
  local level = rand(1, 3)
  while level > 1 and mine.balance - sabotage.PRICES[kind][level] < 2 * RESERVE do level = level - 1 end
  if mine.balance - sabotage.PRICES[kind][level] < 2 * RESERVE then
    log(string.format("no %s trick: not enough money ($%d)", kind, math.floor(mine.balance)))
    return false
  end
  local why = sabotage.refusal(world, mine, target[1], kind, level)
  if why then
    log(string.format("no %s trick (level %d) on %s: %s", kind, level, target[2], why))
    return false
  end
  log(string.format("dirty trick: %s level %d on %s", kind, level, target[2]))
  TheApp.mp_session:issue({kind = "sabotage", trick = kind, level = level, to = world:getHospitalIndex(target[1])})
  if rand() < 0.5 then
    local line = pick(LINES.trick):format(target[2])
    self:say(line, 20 + rand() * 40)
  end
  return true
end

--------------------------------------------------------------------------------
-- Every tick
--------------------------------------------------------------------------------

--! A (new) game world: the start, a continued game's save, or a repair.
function Bot:attach(world)
  self.world = world
  builder.hospital = world.ui.hospital
  if not self.plan then
    local day = self:gameDay()
    local month = world:date():monthOfGame()
    self.start_day = day
    self.plan = {
      desk = self:later(rand(2, 5)),
      room = self:later(rand(5, 9)),
      staff = day,
      extras = 1,
      extra_day = day,
      -- The greeting some time in the second to fourth month of the game (or
      -- of its time in a continued game).
      greet = (month - 1) * 30 + rand(31, 119),
      -- The first dirty trick in months 7 to 12.
      trick = (month - 1) * 30 + rand(181, 359),
    }
    if pace > 1 then self.plan.greet = day + math.floor((self.plan.greet - day) / pace) end
    if pace > 1 then self.plan.trick = day + math.floor((self.plan.trick - day) / pace) end
    self.room_tries = {}
    self.tricks_played = 0
    log(string.format("playing hospital %d (%s), %s; greeting on day %d%s", self:hospitalIndex(),
        tostring(world.ui.hospital.name), self.mode, self.plan.greet,
        self.fiery and (", first trick on day " .. self.plan.trick) or ""))
  end
end

--! Close the windows a person would close (they would pause this game).
local CLOSE_WINDOWS = {"UIAnnualReport", "UIInformation", "UIStaffRise"}
function Bot:closeWindows()
  local ui = TheApp.ui
  for i = #ui.windows, 1, -1 do
    local win = ui.windows[i]
    for _, name in ipairs(CLOSE_WINDOWS) do
      local cls = rawget(_G, name)
      if cls and class.is(win, cls) then
        win:close()
        break
      end
    end
  end
end

function Bot:think()
  local world = self.world
  local hospital = world.ui.hospital
  local plan = self.plan
  local day = self:gameDay()
  self:answerOffers()

  if day >= plan.greet and not plan.greeted then
    plan.greeted = true
    local others = {}
    for peer, p in pairs(self.lobby.players or {}) do
      if p.bot ~= "1" and peer ~= TheApp.mp_session.peer_id then others[#others + 1] = p.name end
    end
    table.sort(others)
    local line = pick(LINES.greet[self.fiery and "fiery" or "friendly"]):format(others[1] and pick(others) or "everybody")
    self:say(line, typing(line))
  end

  -- A placed (won or out) racer does no more.
  if hospital.mp_place then return end

  if day >= plan.desk and #hospital:getReceptionDesks() == 0 then
    plan.desk = self:later(3)
    local ok, err = pcall(self.buyCorridor, self, "reception_desk")
    if not ok then log("could not buy a desk: " .. tostring(err)) end
    return
  end
  if #hospital:getReceptionDesks() == 0 then return end

  if day >= plan.staff then
    if self:hireOne() then
      plan.staff = self:later(rand(1, 3))
      return
    end
    plan.staff = self:later(2)
  end

  if not hospital.opened and self:readyToOpen() and not plan.opened then
    if self:openHospital() then plan.opened = true end
  end

  -- A room drawn a moment ago: wait until it stands (or was refused).
  local pending = plan.pending
  if pending and (hospital:countRoomOfType(pending.id, 1) > 0 or day >= pending.until_day) then
    plan.pending = nil
  end
  if day >= plan.room and not plan.pending then
    local built, why = self:buildNextRoom()
    if built then
      log(string.format("drawing a %s on day %d (balance $%d)", built.id, day, math.floor(hospital.balance)))
      plan.pending = {id = built.id, until_day = day + 5}
      plan.room = self:later(rand(10, 20))
    elseif why == "money" then
      plan.room = self:later(5)
    elseif why == "space" then
      -- More land, as a person would buy when the building is full.
      plan.room = self:later(self:buyPlot() and 3 or 15)
    else
      plan.rooms_done = true
      plan.room = self:later(30)
    end
  end

  -- Benches and plants once the main rooms stand (they would take a small
  -- plot's room space otherwise).
  local rooms = 0
  for _, r in pairs(world.rooms) do
    if r.hospital == hospital and r.is_active then rooms = rooms + 1 end
  end
  if hospital.opened and (rooms >= 4 or plan.rooms_done) and day >= plan.extra_day and EXTRAS[plan.extras] then
    local id, upto = EXTRAS[plan.extras][1], EXTRAS[plan.extras][2]
    local have = 0
    for _, e in ipairs(world.entities) do
      if e.object_type and e.object_type.id == id and hospital:isInHospital(e.tile_x, e.tile_y) and
          not world:getRoom(e.tile_x, e.tile_y) then
        have = have + 1
      end
    end
    if have >= upto then
      plan.extras = plan.extras + 1
    else
      local ok, err = pcall(self.buyCorridor, self, id)
      if not ok then log("could not buy a " .. id .. ": " .. tostring(err)) end
      if not ok or not err then plan.extras = plan.extras + 1 end
    end
    plan.extra_day = self:later(rand(4, 10))
  end

  if self.fiery and day >= plan.trick and hospital.opened then
    if self:playTrick() then
      self.tricks_played = self.tricks_played + 1
      plan.trick = self:later(rand(60, 120))
    else
      plan.trick = self:later(7)
    end
  end
end

function Bot:update()
  local session = TheApp.mp_session
  local world = TheApp.world
  self:flushOutbox()
  if not session or not world or session.held then return end
  if world ~= self.world then self:attach(world) end
  self:closeWindows()
  local now = self:now()
  if now < self.next_think then return end
  self.next_think = now + (fast and 0.05 or 0.5)
  local ok, err = xpcall(function() self:think() end, debug.traceback)
  if not ok then
    log("ERROR: " .. tostring(err))
    self.next_think = now + 5
  end
end

--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

local function run()
  assert(loadfile(source_dir .. "/CorsixTH/CorsixTH.lua"))(unpack_args(args))
  assert(TheApp.good_install_folder, "Game data was not accepted")
  socket = require("socket")
  corsixth.require("mp_lobby")
  corsixth.require("mp_session")
  builder = assert(loadfile(source_dir .. "/scripts/multiplayer/probe_builder.lua"))()
  sabotage = MultiplayerSession.sabotage

  local bot
  -- Money sent to it: seen when the command runs here (the game itself
  -- does the same on every computer).
  local handlers = MultiplayerSession.default_handlers
  local give_money = handlers.give_money
  handlers.give_money = function(world, cmd)
    local ok, why = give_money(world, cmd)
    local session = TheApp.mp_session
    if ok and bot and session and tonumber(cmd.to) == session.hospital_index and
        tonumber(cmd.peer) ~= session.peer_id then
      bot:moneyReceived(tonumber(cmd.hospital), tonumber(cmd.amount))
    end
    return ok, why
  end
  -- The game ends for everybody (lost, or all back to the lobby): stop.
  local finished = false
  MultiplayerSession.finishGame = function(self)
    self.finish_request = nil
    finished = true
  end

  local lobby, err = MultiplayerLobby.connect(server, my_name, 10,
      {role = "bot", room = room, token = token})
  assert(lobby, "cannot connect: " .. tostring(err))
  lobby.log = log
  log("connected as " .. lobby.build)
  while lobby.state ~= "in_game" do
    lobby:poll()
    if lobby.state == "closed" then
      log("the server closed the connection: " .. tostring(lobby.error and lobby.error.text))
      return
    end
    socket.sleep(0.05)
  end
  log("game started")
  bot = Bot.new(lobby)
  lobby:addListener(function(_, event, f)
    if event == "chat" then bot:onChat(f) end
  end)
  local session = TheApp.mp_session
  -- It agrees to every speed vote.
  if session then session.auto_agree = "yes" end

  local next_tick
  while not finished and lobby.state == "in_game" and not lobby.transport.closed do
    session = TheApp.mp_session
    if not session then break end
    if not TheApp.world and not session.held then break end
    local before = session.step
    if fast then
      -- Tests: one step per tick, as fast as the others allow.
      session.unpaced, session.steps_per_tick = true, 1
    else
      -- One tick every 18 ms, like the game's own timer.
      local now = socket.gettime()
      if next_tick and now < next_tick then socket.sleep(next_tick - now) end
      next_tick = math.max(now, next_tick or now) + 0.018
    end
    TheApp:onTick()
    bot:update()
    if fast and session.step == before then socket.sleep(0.002) end
  end
  log("game over (" .. tostring(lobby.state) .. ")")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  io.stderr:flush()
  os.exit(1)
end
os.exit(0)
