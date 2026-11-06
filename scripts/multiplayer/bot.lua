-- A computer player (bot) for one multiplayer room. The server (mp_server)
-- starts it when the room's owner clicks an empty place in the lobby:
--   corsix-th --interpreter=<this file> --config-file=<generated>
-- It joins the room like a player (ready at once), and once the game starts
-- it plays its own hospital through the same game windows and commands as a
-- person: it builds the rooms the level has one after the other, hires the
-- staff they need and opens the hospital, so that for the first year or so
-- it looks like somebody playing. It also talks: a greeting in the second to
-- fourth month, answers when spoken to (and seldom otherwise), and a word
-- when somebody sends it something. In co-op it accepts what the others offer (staff, patients,
-- research, money requests); in a competitive race it refuses all of it and
-- plays a dirty trick now and then (the first one in months 7 to 12). In a
-- race of two teams it takes what its team mates offer and plays its tricks
-- on the other team.
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
--   MP_BOT_MODE          the room's mode (shared, coop, competitive, teams, ...)
--   MP_LUA_CPATH, MP_LUA_PATH  where to find LuaSocket (if not standard)
-- Tests only:
--   MP_BOT_SEED          seed for its choices (default: from the clock)
--   MP_BOT_AWAY_SECONDS  tests: seconds without a command before a team mate sharing the
--                        hospital counts as away (default 30; and 7 game days)
--   MP_BOT_TESTS         tests: 1 registers the probes' test commands (as every peer
--                        of a test game must)
--   MP_BOT_LEARN         tests: on this game day the bot discovers something
--                        (test command probe_learn), research to share
--   MP_BOT_WISHES        tests: "<day>:<project>;..." a team mate's wishes on those game
--                        days, as if asked in the chat (add:psych:skeleton, bigger:gp)
--   MP_BOT_PACE          game days between its building steps are divided
--                        by this (default 1: like a person)
--   MP_BOT_FAST          1: run the game as fast as the others allow and
--                        answer at once (scripted tests)
--   MP_BOT_BRAIN         "smart" (default: scripts/multiplayer/bot_manager.lua
--                        decides from the hospital's needs, with the server's
--                        advice if it has any), "manager" (the same without
--                        advice) or "script" (the fixed plan below);
--                        "Name=script;Other=smart" per bot
--                        or per room
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
  -- A dirty trick dealt with, to whoever sent it (Bot:tellRival): with their
  -- name when it is known or there is only one rival, else to everybody.
  tricked = {
    handyman = {"Nice try, %s. Your handyman is on his way back to you.",
        "Caught your handyman, %s. He's all yours again."},
    rats = {"Pest control is done, %s. Were those your rats?", "All the rats are shot, %s. Very funny."},
    boiler = {"Somebody broke my boiler. Very funny, %s. My handymen are on it.",
        "A broken boiler, %s? We have blankets."},
    smear = {"Bad press, %s? My patients will be back.", "Nice smear campaign, %s. Mine will be better."},
    espionage = {"Enjoy my research files, %s.", "A spy in my research department, %s? Cheeky."},
    headhunter_kept = {"You wanted my doctor, %s? They're staying with me.",
        "Hands off my staff, %s. They got their pay rise."},
    headhunter_lost = {"Take them, %s. I'll find somebody better.", "Fine, %s, keep them. Good luck with that one."},
  },
  tricked_unknown = {
    rats = {"The rats are gone. Whoever sent them: nice try.", "All rats shot. Next time send cheese."},
    boiler = {"Somebody broke my boiler. Whoever it was: we have blankets."},
    smear = {"Somebody is spreading lies about my hospital. Patients will see the truth."},
    espionage = {"Somebody copied my research. I hope you can read my handwriting."},
    headhunter_kept = {"Somebody tried to poach my doctor. They're staying."},
    headhunter_lost = {"Somebody poached my doctor. Fine, I'll train another."},
  },
  -- Specialists lent to an ally and asked for (Manager:helpAllies,
  -- Manager:askAllies): names, who, kind, room, then the emergency's words.
  staff_sent = {"%s, you can have %s, a %s, for your %s: free, accept my offer in your messages.%s",
      "%s: I'm offering you %s, a %s for your %s. No charge, just accept the fax.%s"},
  staff_for_emergency = {" It's for the emergency!", " Hurry, the emergency won't wait."},
  -- (names, kind, room, how many it needs ("2 surgeons"), has, emergency)
  staff_ask_one = {"%s, could you spare me a %s? My %s needs %s and I have %d, and there are none to hire.%s"},
  staff_ask_all = {"Has anybody got a %s to spare, or one on their hiring list? My %s needs %s and I have %d.%s"},
  -- To an ally it sent its research (Manager:shareResearch).
  research_sent = {"I've sent you my research for free, %s: %s.", "Some research for you, %s: %s. On the house."},
  -- To a person sharing the hospital, before sharing its research.
  -- To whoever asked for a project in the chat (Manager:tellWisher).
  wish_done = {"%s, your %s is ready.", "Done, %s: the %s is up and running."},
  wish_done_add = {"%s, the %s is in place.", "Done, %s: I put the %s in."},
  wish_no_space = {"Sorry %s, there is no space for the %s yet. I'll buy more land first."},
  wish_no_money = {"%s, the %s has to wait a little: not enough money yet."},
  research_ask = {"%s, shall I send %s our research for free (%s)? Say \"share\" and I will."},
  -- To a person sharing the hospital (Bot:sharesWithPerson).
  mate_away = {"You seem to be away, %s. I'll run the whole hospital until you're back."},
  mate_back = {"Welcome back, %s! Prices, loans and the faxes are yours again."},
  -- To a person sharing the hospital: what the weekly bonuses cost.
  bonuses = {"I gave %d unhappy staff a double bonus ($%d), %s."},
  greet = {
    friendly = {
      "Hi everyone! Building my hospital nice and slowly over here.",
      "Hello, team! Shout if you need a hand. Or a doctor.",
      "Good morning, colleagues! The coffee machine is on me.",
      "Hi all! My first patients are on their way. Fingers crossed.",
      "Greetings from across town! Let me know if you need anything.",
      "Hello! My receptionist says hi too.",
      "Hi there! Plenty of patients for all of us, I hope.",
      "Morning, neighbours! I've put the kettle on.",
    },
    fiery = {
      "Enjoy your lead while it lasts. My hospital is coming for yours.",
      "This town needs only one hospital. Guess which one.",
      "My doctors are sharper and my nurses faster. Good luck, everybody!",
      "Ready to lose? I have already ordered the trophy.",
      "I hope your patients like waiting. Mine won't have to.",
      "Watch out, %s. I play to win.",
      "Nice hospitals, everyone. Shame about the competition.",
      "I've already hired the best doctors in town. Sorry!",
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

local socket, builder, sabotage, Manager
local Bot = {}

--! Which brain this bot uses (MP_BOT_BRAIN, see the top; a key may also
--! name the room).
local function brain_of(name)
  local spec = os.getenv("MP_BOT_BRAIN") or "smart"
  if not spec:find("=", 1, true) then return spec end
  local first = name:lower():match("(%a+)$") or name:lower()
  for who, b in spec:gmatch("([^;=]+)=([^;]+)") do
    local w = who:lower()
    if w == name:lower() or w == first or w == room:lower() then return b end
  end
  return "smart"
end
Bot.__index = Bot

-- Rooms first, in this order; then the others the level has, by name.
local FIRST_ROOMS = {gp = 1, pharmacy = 2, general_diag = 3, ward = 4, psych = 5, staff_room = 6,
    toilets = 7, cardiogram = 8, scanner = 9, ultrascan = 10, blood_machine = 11, x_ray = 12}
-- Rooms a beginner leaves alone (a consultant to teach in it).
local SKIP_ROOMS = {}
-- Doctors with a skill a room needs: how they are hired.
local SPECIALISTS = {Psychiatrist = "psychiatrist", Surgeon = "surgeon", Researcher = "researcher",
    Consultant = "consultant"}

--! Is this staff profile flag set (1, true; not 0 or nil)?
local function flag(profile, name)
  local v = profile[name]
  return v ~= nil and v ~= 0 and v ~= false
end

--! How many of the three special skills (surgeon, psychiatrist, researcher)
--! a doctor has.
local function specialisms(profile)
  local n = 0
  for _, k in ipairs({"is_surgeon", "is_psychiatrist", "is_researcher"}) do
    if flag(profile, k) then n = n + 1 end
  end
  return n
end
Bot.specialisms = specialisms
Bot.flag = flag

--! A teacher's worth: special skills first (each one the students can
--! learn), then skill.
function Bot.teacherScore(profile)
  return specialisms(profile) + (profile.skill or 0)
end
-- Kept in the bank when building or buying.
local RESERVE = 3000
-- Staff care (Bot:careForStaff): once a game week everybody under half
-- happiness gets two bonuses (each 10% of their wage and +50% happiness),
-- while the balance stays above BONUS_FLOOR (Jan, 2026-11-03).
local BONUS_DAYS, BONUS_BELOW, BONUS_FLOOR = 7, 0.5, 2000
-- A person sharing the hospital answers pay rises; the bot steps in when
-- they have not and the member of staff would quit within this many hours.
local RISE_LAST_HOURS = 5 * 24
-- Corridor furniture once the hospital is open: id -> how many.
local EXTRAS = {{"bench", 3}, {"plant", 2}, {"drinks_machine", 1}, {"bench", 5}, {"extinguisher", 1},
    {"plant", 4}}

function Bot.new(lobby)
  local self = setmetatable({}, Bot)
  self.lobby = lobby
  -- A bot keeps no saves of its own (the people and the server do); its
  -- monthly autosave sometimes failed on its own windows.
  lobby._writeLocalSave = function() end
  self.mode = lobby.start_params and lobby.start_params.mode or os.getenv("MP_BOT_MODE") or "coop"
  -- (A race, of teams too: tricks, and rivals' offers refused.)
  self.fiery = self.mode == "competitive" or self.mode == "teams" or self.mode == "teamshared" or
      self.mode == "mixed"
  self.outbox = {}         -- {at = real time, text =, to = peer or nil, fn = optional}
  self.offers_seen = {}    -- message number -> true
  self.last_reply = -1000
  self.next_think = 0
  self.world = nil
  self.brain = brain_of(my_name)
  if self.brain ~= "script" then
    self.manager = Manager.new(self, {log = log, rand = rand, pick = pick, sabotage = sabotage, lines = LINES,
        typing = function(text) return 1.5 + #text * 0.06 + rand() * 2 end})
  end
  -- "manager": the same brain, without the language model's advice.
  if self.brain == "manager" then self.ai = "off" end
  log("brain: " .. self.brain)
  return self
end

function Bot:now() return socket.gettime() end

--! Say something after `delay` seconds: to everybody, privately to one peer,
--! or to = "team": to its team mates only in a race of teams, its allies in
--! co-op (to everybody when it has none). `banter`: small talk (greetings, taunts, remarks
--! nobody asked for), which players can hide (MULTIPLAYER > BOT CHAT), unlike
--! what a bot answers or tells its team mates.
function Bot:say(text, delay, to, fn, banter)
  self.outbox[#self.outbox + 1] = {at = self:now() + (fast and 0 or (delay or 2)), text = text, to = to, fn = fn,
      banter = banter and 1 or nil}
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
      if entry.text and entry.to == "team" then
        local mates = self.lobby:teamMates(self.world, TheApp.mp_session.peer_id)
        if #mates > 0 then
          self.lobby:send("CHAT", {text = entry.text, to = table.concat(mates, ","), team = 1, banter = entry.banter})
        else
          self.lobby:send("CHAT", {text = entry.text, banter = entry.banter})
        end
        log("CHAT" .. (#mates > 0 and " (team): " or ": ") .. entry.text)
      elseif entry.text then
        self.lobby:send("CHAT", {text = entry.text, to = entry.to, banter = entry.banter})
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

--! The people (not bots) playing hospital `index`: peers and names, in peer
--! order.
function Bot:peopleOfHospital(index)
  local peers, names = {}, {}
  for peer, h in pairs(self.lobby.peer_hospital or {}) do
    local name, is_bot = self:playerName(peer)
    if h == index and name and not is_bot and peer ~= TheApp.mp_session.peer_id then
      peers[#peers + 1] = peer
    end
  end
  table.sort(peers)
  for i, peer in ipairs(peers) do names[i] = self:playerName(peer) end
  return peers, names
end

--! A dirty trick dealt with (`kind`, a key of LINES.tricked): a word to the
--! people who sent it. `from` is the sender's hospital when the game said
--! who it was (a caught handyman); else, as a person would, it can only
--! guess: one rival hospital is named, with several it speaks to everybody.
function Bot:tellRival(kind, from)
  local world = self.world
  local mine = world.ui.hospital
  local hospitals = {}
  if from then
    hospitals[1] = from
  else
    for index, h in ipairs(world.hospitals) do
      if h ~= mine and world:mpRivals(mine, h) and self:playerOfHospital(index) ~= nil then
        hospitals[#hospitals + 1] = index
      end
    end
  end
  if #hospitals == 1 then
    local peers, names = self:peopleOfHospital(hospitals[1])
    if #peers == 0 then return end -- a bot: bots do not chat with each other
    local line = pick(LINES.tricked[kind]):format(table.concat(names, " and "))
    self:say(line, typing(line), table.concat(peers, ","), nil, true)
  elseif #hospitals > 1 and LINES.tricked_unknown[kind] then
    local line = pick(LINES.tricked_unknown[kind])
    self:say(line, typing(line), nil, nil, true)
  end
end

--! Does a person run this hospital too (one shared hospital, or a team
--! hospital)? Then the bot only helps: it builds and staffs, and leaves the
--! hospital's decisions (prices, loans, heating, research, faxes) to them.
-- A person sharing the hospital counts as away after this long without a
-- command (both: real seconds and game days); the bot then runs everything
-- until they give a command again.
local AWAY_SECONDS, AWAY_DAYS = tonumber(os.getenv("MP_BOT_AWAY_SECONDS") or "") or 30, 7

--! The people (not bots) who share this bot's hospital: their peers.
function Bot:hospitalMates()
  local session = TheApp.mp_session
  local mine = self:hospitalIndex()
  local mates = {}
  for peer, h in pairs(self.lobby.peer_hospital or {}) do
    if h == mine and peer ~= (session and session.peer_id) then
      local _, is_bot = self:playerName(peer)
      if not is_bot then mates[#mates + 1] = peer end
    end
  end
  return mates
end

--! Does it leave building to the person it shares the hospital with (the
--! room's "helpers" game option off: no rooms, nothing for the corridors)?
--! (From the room's options: one shared hospital has no world.mp_coop.)
function Bot:leavesBuilding()
  local off = (self.lobby and self.lobby.optionValue and self.lobby:optionValue("helpers") == "0") or
      (self.world and self.world.mp_coop and self.world.mp_coop.helpers_off)
  return off and #self:hospitalMates() > 0 or false
end

--! Note who gives commands (every command, just before it runs): a person
--! sharing the hospital is there while they play.
function Bot:watchCommands()
  local session = TheApp.mp_session
  if not session or self.watched_session == session then return end
  self.watched_session = session
  local bot = self
  local before = session.beforeStep
  session.beforeStep = function(s)
    local n = s.step + 1
    for _, cmd in ipairs(s.pending) do
      if cmd.step == n and cmd.peer then
        bot.last_command = bot.last_command or {}
        bot.last_command[cmd.peer] = {time = bot:now(), day = bot.world and bot:gameDay() or 0}
      end
    end
    return before(s)
  end
end

--! Does a person run this hospital with the bot now? Then the bot only
--! helps (builds, hires, buys) and leaves the hospital's decisions (prices,
--! loans, heating, research, faxes, opening) to them. A person who has given
--! no command for AWAY_SECONDS and AWAY_DAYS is away: the bot runs it all
--! until they are back (any command), and says so in the chat.
function Bot:sharesWithPerson()
  local mates = self:hospitalMates()
  if #mates == 0 then return false end
  local now, day = self:now(), self:gameDay()
  self.since = self.since or {time = now, day = day} -- (the start counts as their last command)
  local here = false
  for _, peer in ipairs(mates) do
    local last = self.last_command and self.last_command[peer] or self.since
    if now - last.time < AWAY_SECONDS or day - last.day < AWAY_DAYS then here = true end
  end
  if here ~= (self.mates_here ~= false) then
    self.mates_here = here
    local line = here and LINES.mate_back[1] or LINES.mate_away[1]
    log(here and "a team mate is back: they run the hospital's decisions again" or
        "the team mates are away: running the whole hospital")
    for _, peer in ipairs(mates) do
      local name = self:playerName(peer)
      self:say(line:format(name or "friend"), typing(line), peer)
    end
  end
  return here
end

--! This bot's place among the game's bots (1, 2, ...: by peer, the same
--! for every bot of the room), and how many there are.
function Bot:botRank()
  local peers = {}
  for peer, p in pairs(self.lobby.players or {}) do
    if p.bot == "1" then peers[#peers + 1] = peer end
  end
  table.sort(peers)
  local me = TheApp.mp_session.peer_id
  for i, peer in ipairs(peers) do
    if peer == me then return i, #peers end
  end
  return 1, math.max(1, #peers)
end

--! A line of `list` for this bot that no other bot of the game picks the
--! same way: the bots take turns through the list from a place the room's
--! name sets. (Three bots once all greeted with the trophy line.)
function Bot:ownLine(list)
  local rank = self:botRank()
  local base = 0
  for i = 1, #room do base = (base * 31 + room:byte(i)) % 1000003 end
  return list[(base + rank - 1) % #list + 1]
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
-- Advice from a language model, through the server (mp_server advisor.py)
--------------------------------------------------------------------------------

--! Ask the server (ASK kind=plan|chat); `done(fields)` gets the ANSWER, or
--! nil if none came within `wait` seconds.
function Bot:ask(kind, fields, wait, done)
  if self.ai == "off" then return false end
  self.asks = self.asks or {}
  self.ask_id = (self.ask_id or 0) + 1
  fields.id, fields.kind = self.ask_id, kind
  self.asks[self.ask_id] = {done = done, until_time = self:now() + wait}
  self.lobby:send("ASK", fields)
  return true
end

function Bot:onAnswer(f)
  local id = tonumber(f.id)
  local entry = id and self.asks and self.asks[id]
  if not entry then return end
  self.asks[id] = nil
  if f.error == "off" then
    if self.ai ~= "off" then log("advice: off on this server") end
    self.ai = "off"
  end
  entry.done(not f.error and f or nil)
end

--! Questions nobody answered in time: their fallback.
function Bot:expireAsks()
  local now = self:now()
  for id, entry in pairs(self.asks or {}) do
    if now > entry.until_time then
      self.asks[id] = nil
      entry.done(nil)
    end
  end
end

--! Once a game week (at most every 25 seconds): the hospital's report, and
--! what its team mates said lately, to the model, whose plan the manager
--! follows (it still checks everything itself). False if it did not ask.
function Bot:askPlan()
  local manager = self.manager
  local report = manager and manager:report()
  if not report then return false end
  if self.last_plan and self:now() - self.last_plan < 25 then return false end
  local said = {}
  for _, l in ipairs(self.mate_lines or {}) do
    if self:gameDay() - l.day <= 30 then said[#said + 1] = string.format("day %d, %s", l.day, l.text) end
  end
  if #said > 0 then
    report = report .. "\nTeam mates said lately (today is day " .. self:gameDay() .. "):\n" .. table.concat(said, "\n")
  end
  self.last_plan = self:now()
  return self:ask("plan", {text = report, menu = table.concat(manager:planMenu(), ",")}, 60, function(f)
    if not f then return end
    local plan = {priorities = {}, price = tonumber(f.price)}
    for action, weight in (f.actions or ""):gmatch("([%w_:]+):(%d+)") do
      plan.priorities[#plan.priorities + 1] = {action = action, weight = tonumber(weight)}
    end
    manager:applyPlan(plan)
    -- A team mate now and then says what it is up to (a rival keeps quiet).
    if f.note and f.note ~= "" and not self.fiery and rand() < 0.3 then
      self:say(f.note, typing(f.note), "team")
    end
  end)
end

--------------------------------------------------------------------------------
-- Chat
--------------------------------------------------------------------------------

function Bot:onChat(f)
  local peer = tonumber(f.peer)
  -- The chat so far (for the model's answers).
  self.chat_lines = self.chat_lines or {}
  if f.text and f.name and f.name ~= "server" then
    self.chat_lines[#self.chat_lines + 1] = f.name .. ": " .. f.text
    if #self.chat_lines > 8 then table.remove(self.chat_lines, 1) end
  end
  local session = TheApp.mp_session
  if not session or not peer or peer == 0 or peer == session.peer_id then return end
  local name, is_bot = self:playerName(peer)
  if is_bot or not name then return end -- bots do not chat with each other
  local text = f.text or ""
  -- (In a race of two teams: friendly to its team mate.)
  local world, hosp = self.world, self.lobby.peer_hospital and self.lobby.peer_hospital[peer]
  local mine = world and world.ui and world.ui.hospital
  local mate = hosp and mine and world:mpTeam(mine) and not world:mpRivals(world.hospitals[hosp], mine)
  local rival = self.fiery and not mate
  -- A person sharing the hospital says "share": its research may go to
  -- the allies (Manager:shareResearch asks first).
  for _, p in ipairs(self:hospitalMates()) do
    local low = text:lower()
    if p == peer and (low:find("share", 1, true) or low:find("sd95{l", 1, true) or low:find("teil", 1, true)) then
      self.share_ok = self:gameDay()
      log("a team mate allows sharing the research")
    end
  end
  -- What people on its side say goes into its next plan (wishes, worries).
  if not rival and text ~= "" then
    self.mate_lines = self.mate_lines or {}
    table.insert(self.mate_lines, {day = self:gameDay(), text = name .. ": " .. text:sub(1, 200)})
    if #self.mate_lines > 8 then table.remove(self.mate_lines, 1) end
  end
  local private = f.to ~= nil
  local first = my_name:lower():match("(%a+)$") or my_name:lower()
  local named = text:lower():find(first, 1, true) ~= nil
  -- A line to the bot (private, or with its name in it) gets an answer;
  -- other lines only seldom, so the people's own chat stays readable. Several
  -- bots in a room share that.
  local bots = 0
  for _, p in pairs(self.lobby.players or {}) do
    if p.bot == "1" then bots = bots + 1 end
  end
  if private or named then
    if self:now() - self.last_reply < 10 then return end
  else
    if self:now() - self.last_reply < 180 or rand() > 0.15 / math.max(1, bots) then return end
  end
  self.last_reply = self:now()
  local kind = reply_kind(text)
  local line = pick(REPLIES[kind][rival and "fiery" or "friendly"]):format(name)
  -- Spoken to: the model answers if the server has one (the stock line if
  -- it does not answer within a few seconds). The answer goes where the line
  -- came from: the team, that person, or everybody.
  local to = f.team == "1" and "team" or private and peer or nil
  if (private or named) and self.ai ~= "off" then
    local report = self.manager and self.manager:report() or ""
    local brief = report:match("^[^\n]*\n[^\n]*") or report
    -- (On the person's side it may also do what it is asked: the projects
    -- it can do now go along.)
    local menu = not rival and self.manager and table.concat(self.manager:wishMenu(), ",") or nil
    local asked = self:ask("chat", {text = brief, lines = table.concat(self.chat_lines, "\n"),
        rival = rival and 1 or nil, menu = menu}, 10, function(answer)
      local reply = answer and answer.text or line
      -- (Several at once: "a plant and a radiator in every room".)
      if answer and self.manager then
        for key in (answer.wish or ""):gmatch("[^,]+") do self.manager:wish(key, peer) end
        for key in (answer.leave or ""):gmatch("[^,]+") do self.manager:leaveTo(key) end
      end
      self:say(reply, typing(reply), to)
    end)
    if asked then return end
  end
  self:say(line, typing(line), to, nil, not (private or named))
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
      -- (From a team mate in a race of two teams: welcome.)
      local accept = not self.world:mpRivals(self.world.hospitals[offer.from], mine)
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
      -- (A team mate's offer: the thanks go to the team, not to the rivals.)
      self:say(line, delay + typing(line), not self.world:mpRivals(self.world.hospitals[offer.from], mine) and "team" or nil)
    end
  end
end

--! Answer this hospital's emergency faxes: accept if it has the treatment
--! room and somebody to work in it, else refuse (a fax left alone refuses
--! itself after 16 days, which some levels punish).
function Bot:answerEmergencies()
  local panel = self.world.ui and self.world.ui.bottom_panel
  if not panel then return end
  local mine = self.world.ui.hospital
  for _, icon in ipairs(panel:allMessageIcons()) do
    if icon.type == "emergency" and icon.hospital == mine and icon.mp_id and not self.offers_seen[icon.mp_id]
        and mine.emergency then
      self.offers_seen[icon.mp_id] = true
      -- Every room that cures it stands, with its staff complete or on the
      -- hiring list (two surgeons for an operating theatre: the second is
      -- hired at once, see BotManager:projects).
      local rooms = mine.emergency.disease.treatment_rooms or {}
      local can = #rooms > 0
      for _, id in ipairs(rooms) do
        local rt
        for _, r in ipairs(TheApp.rooms) do if r.id == id then rt = r end end
        if not rt or mine:countRoomOfType(id, 1) == 0 then can = false break end
        for cat, k in pairs(rt.required_staff or {}) do
          if mine:countStaffOfCategory(cat, k) < k and not self:canHire(cat) then can = false end
        end
      end
      local msg = icon.mp_id
      local delay = 2 + rand() * 4
      log(string.format("emergency fax #%s (%s): %s in %.1f s", tostring(msg), tostring(mine.emergency.disease.id),
          can and "accept" or "refuse", delay))
      self:say(nil, delay, nil, function()
        local session = TheApp.mp_session
        if session and not session.held then
          session:issue({kind = "fax_choice", msg = msg, choice = can and 1 or 2})
        end
      end)
    end
  end
end

--! Money arrived from another player (give_money, seen as it happens).
function Bot:moneyReceived(from_index, amount)
  local _, name = self:playerOfHospital(from_index)
  name = name or "friend"
  if self.world:mpRivals(self.world.hospitals[from_index], self.world.ui.hospital) then
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
    self:say(line, 2 + typing(line), "team")
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

--! The tiles nobody may build on now although they look free: a room being
--! furnished or edited (by anybody; while a person edits a room its walls
--! are down, but it is coming back), and the outline another player is
--! drawing; a tile of margin around each. Kept for one drawRoom.
function Bot:reservedTiles()
  local reserved = {}
  local function mark(r)
    for y = r.y - 1, r.y + r.h do
      for x = r.x - 1, r.x + r.w do reserved[y * 1000 + x] = true end
    end
  end
  for _, entry in pairs(self.world.mp_furnishing or {}) do
    if entry.x and entry.w then mark(entry) end
  end
  local session = TheApp.mp_session
  for _, r in pairs(session and session.remote_blueprints or {}) do
    if (r.w or 0) > 0 then mark(r) end
  end
  return reserved
end

--! How many tiles of free floor the hospital has (Bot:freeTile).
function Bot:freeFloor()
  local world = self.world
  local hosp = world.ui.hospital
  local th = world.map.th
  local mw, mh = th:size()
  local n = 0
  for y = 1, mh do
    for x = 1, mw do
      if hosp:isInHospital(x, y) and self:freeTile(x, y) then n = n + 1 end
    end
  end
  return n
end

--! Is this tile free floor of this hospital (no room, no object on it)?
function Bot:freeTile(x, y)
  local world = self.world
  local th = world.map.th
  local mw, mh = th:size()
  if x < 1 or y < 1 or x > mw or y > mh then return false end
  if self.reserved and self.reserved[y * 1000 + x] then return false end
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

--! Where a player would put a w x h room (squares from `size` down to
--! `min`, and one tile shorter): against the building's walls and the other
--! rooms, in rows, with a corridor in front of the door (the row below it;
--! two rows if possible), without thin gaps that nothing fits into, near the
--! reception, and never on the reception's or the entrances' floor.
--!return x, y, w, h or nil
function Bot:layoutSpot(min, size)
  local world = self.world
  local hosp = world.ui.hospital
  local th = world.map.th
  local mw, mh = th:size()
  -- Free floor, once (a table lookup is much cheaper than the map).
  local free = {}
  local x0, y0, x1, y1 = mw, mh, 1, 1
  for y = 1, mh do
    for x = 1, mw do
      if hosp:isInHospital(x, y) then
        x0, y0, x1, y1 = math.min(x0, x), math.min(y0, y), math.max(x1, x), math.max(y1, y)
        if self:freeTile(x, y) then free[y * 1000 + x] = true end
      end
    end
  end
  -- Keep the reception's queue and the entrances clear.
  local keep = {}
  local function protect(cx, cy, r)
    for y = cy - r, cy + r do
      for x = cx - r, cx + r do free[y * 1000 + x] = nil keep[y * 1000 + x] = true end
    end
  end
  for _, desk in ipairs(hosp:getReceptionDesks()) do
    if desk.tile_x then protect(desk.tile_x, desk.tile_y, 2) end
  end
  for _, e in ipairs(world.entities) do
    local id = e.object_type and e.object_type.id
    if id and id:find("entrance", 1, true) and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) then
      protect(e.tile_x, e.tile_y, 2)
    end
  end
  local function f(x, y) return free[y * 1000 + x] end
  -- A wall, a room, or the outside: not floor, and not floor kept clear.
  local function solid(x, y) return not f(x, y) and not keep[y * 1000 + x] end
  local ax, ay = self:anchor()
  local spots = {} -- {score, x, y, w, h}
  local shapes = {}
  for s = size, min, -1 do
    shapes[#shapes + 1] = {s, s}
    if s - 1 >= min then shapes[#shapes + 1] = {s, s - 1} end
  end
  for _, shape in ipairs(shapes) do
    local w, h = shape[1], shape[2]
    for y = y0, y1 - h do
      for x = x0, x1 - w + 1 do
        local ok = true
        -- The room, and the row below it (the corridor at its door; that
        -- may be floor kept clear, it is corridor anyway).
        for ty = y, y + h do
          for tx = x, x + w - 1 do
            if not f(tx, ty) and not (ty == y + h and keep[ty * 1000 + tx]) then ok = false break end
          end
          if not ok then break end
        end
        if ok then
          -- (Against walls and other rooms, and the size asked: the
          -- smallest only where nothing bigger fits snugly.)
          local score = w * h * 0.5
          for tx = x, x + w - 1 do
            if solid(tx, y - 1) then score = score + 1.5 end
            -- (A one tile gap above: nothing will ever fit in it.)
            if f(tx, y - 1) and solid(tx, y - 2) then score = score - 1.5 end
            if f(tx, y + h + 1) then score = score + 0.3 end
          end
          for ty = y, y + h - 1 do
            if solid(x - 1, ty) then score = score + 1.5 end
            if solid(x + w, ty) then score = score + 1.5 end
            if f(x - 1, ty) and solid(x - 2, ty) then score = score - 1.5 end
            if f(x + w, ty) and solid(x + w + 1, ty) then score = score - 1.5 end
          end
          score = score - 0.12 * (math.abs(x + w / 2 - ax) + math.abs(y + h / 2 - ay))
          spots[#spots + 1] = {score, x, y, w, h}
        end
      end
    end
  end
  -- The best that leaves the corridor in one piece.
  table.sort(spots, function(a, b) return a[1] > b[1] end)
  if (os.getenv("MP_BOT_DIAG") or "") ~= "" then
    local top = {}
    for i = 1, math.min(5, #spots) do
      local sp = spots[i]
      top[#top + 1] = string.format("%.1f@%d,%d %dx%d%s", sp[1], sp[2], sp[3], sp[4], sp[5],
          self:keepsCorridor(sp[2], sp[3], sp[4], sp[5]) and "" or " cuts")
    end
    local n_in, n_free, n_res, n_room, n_obj, n_flag = 0, 0, 0, 0, 0, 0
    for y = y0, y1 do
      for x = x0, x1 do
        if hosp:isInHospital(x, y) then
          n_in = n_in + 1
          if free[y * 1000 + x] then n_free = n_free + 1 end
          if self.reserved and self.reserved[y * 1000 + x] then n_res = n_res + 1 end
          if world:getRoom(x, y) then n_room = n_room + 1 end
          if world:getObject(x, y) then n_obj = n_obj + 1 end
          local fl = th:getCellFlags(x, y)
          if not (fl.buildable and fl.passable) then n_flag = n_flag + 1 end
        end
      end
    end
    log(string.format("layout diag %d-%d: area %d,%d-%d,%d, %d spots; best %s; tiles in %d free %d reserved %d room %d object %d not buildable %d",
        min, size, x0, y0, x1, y1, #spots, table.concat(top, ", "), n_in, n_free, n_res, n_room, n_obj, n_flag))
  end
  for i, spot in ipairs(spots) do
    if self:keepsCorridor(spot[2], spot[3], spot[4], spot[5]) then
      if i > 1 then log(string.format("layout: %d better spots would cut the corridor in two", i - 1)) end
      return spot[2], spot[3], spot[4], spot[5]
    end
  end
end

--! Would a w x h room at x, y leave the hospital's corridor in one piece?
--! The room editor only asks that the floor around a new room stays
--! connected, and a way out at one entrance and in at another counts: a room
--! from wall to wall could cut the reception off from the rooms. Here the
--! corridor around the room must still connect inside the building.
function Bot:keepsCorridor(x, y, w, h)
  local world, hosp = self.world, self.world.ui.hospital
  local th = world.map.th
  local mw, mh = th:size()
  local function corridor(tx, ty)
    if tx < 1 or ty < 1 or tx > mw or ty > mh then return false end
    if tx >= x and tx < x + w and ty >= y and ty < y + h then return false end
    if not hosp:isInHospital(tx, ty) or world:getRoom(tx, ty) then return false end
    return th:getCellFlags(tx, ty).passable
  end
  local around = {}
  for tx = x, x + w - 1 do
    if corridor(tx, y - 1) then around[#around + 1] = {tx, y - 1} end
    if corridor(tx, y + h) then around[#around + 1] = {tx, y + h} end
  end
  for ty = y, y + h - 1 do
    if corridor(x - 1, ty) then around[#around + 1] = {x - 1, ty} end
    if corridor(x + w, ty) then around[#around + 1] = {x + w, ty} end
  end
  if #around < 2 then return true end
  local seen, queue, head = {[around[1][2] * 1000 + around[1][1]] = true}, {around[1]}, 1
  while head <= #queue do
    local cx, cy = queue[head][1], queue[head][2]
    head = head + 1
    for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
      local nx, ny = cx + d[1], cy + d[2]
      local k = ny * 1000 + nx
      if not seen[k] and corridor(nx, ny) then
        seen[k] = true
        queue[#queue + 1] = {nx, ny}
      end
    end
  end
  for _, t in ipairs(around) do
    if not seen[t[2] * 1000 + t[1]] then return false end
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

--! Draw a room of this type (furnished automatically): with free floor
--! around it if possible, else smaller, else packed against other walls.
--!param size (integer) optional: the size it would like (a bigger ward, say)
--!return true, or nil and why not ("money", "space": it needs more land,
--! "refused": the room editor did not take it)
-- Rooms whose furniture does not fit in the game's smallest size: a 4x4
-- staff room has no place for the sofa beside the pool table and TV (Bot
-- Agnes drew one four times in a game, and pulled each down again).
local SMALLEST = {staff_room = 5}

function Bot:drawRoom(room_type, size, extras)
  local hospital = self.world.ui.hospital
  if self.furnishing then return nil, "busy" end
  if hospital.balance - self:roomCost(room_type) < RESERVE then return nil, "money" end
  local min = math.max(room_type.minimum_size or 4, SMALLEST[room_type.id] or 0)
  local ax, ay = self:anchor()
  size = math.max(min, size or min + 1) -- (one more than the smallest: room for a plant)
  self.reserved = self:reservedTiles()
  local x, y, w, h
  -- Where a player would put it (against walls and rooms, in rows).
  local ok_layout, lx, ly, lw, lh = pcall(self.layoutSpot, self, min, size)
  if ok_layout and lx then
    x, y, w, h = lx, ly, lw, lh
  elseif not ok_layout then
    log("layout: " .. tostring(lx))
  end
  -- Else a free tile more below and to the right (where the door goes), so
  -- the corridor in front of it is two tiles wide.
  -- (Each only if it leaves the corridor in one piece.)
  local function try(s, fx, fy)
    if x or not fx then return end
    for ty = fy, fy + s - 1 do
      for tx = fx, fx + s - 1 do
        if self.reserved[ty * 1000 + tx] then return end -- (a room being edited, an outline)
      end
    end
    if self:keepsCorridor(fx, fy, s, s) then x, y, w = fx, fy, s end
  end
  for s = size, min, -1 do
    if not x then try(s, builder.find_free_rect(self.world, ax, ay, s + 1, s + 1, 40)) end
  end
  for s = size, min, -1 do
    if not x then try(s, builder.find_free_rect(self.world, ax, ay, s, s, 40)) end
  end
  for s = size, min, -1 do
    if not x then try(s, self:packedSpot(ax, ay, s, s)) end
  end
  self.reserved = nil
  if not x then
    log(string.format("no space for a %s (%dx%d)", room_type.id, min, min))
    self.no_space_day = self:gameDay() -- (then it looks for land anywhere, cheapestPlot)
    return nil, "space"
  end
  local by_hand = extras and next(extras) ~= nil
  local ok, res = pcall(builder.ui_room, self.world, ax, ay, room_type.id, w, h or w, true, log, {x, y}, by_hand,
      {ax, ay})
  if not ok then log("could not draw " .. room_type.id .. ": " .. tostring(res)) end
  if ok and res then
    if by_hand then self.furnishing = {extras = extras, room_id = room_type.id} end
    return true
  end
  return nil, "refused"
end

--! Can this room take one more of this object (the level has it, it is
--! researched, and the room type lists it)?
local function extra_allowed(world, rm, id)
  local object = TheApp.objects[id]
  if not object then return false end
  local listed = false
  for _, o in ipairs(rm.room_info.objects_additional or {}) do
    if o == id then listed = true end
  end
  local cfg = world.map.level_config.objects
  local progress = world.ui.hospital.research.research_progress[object]
  return listed and cfg[object.thob] and cfg[object.thob].AvailableForLevel == 1 and
      (not progress or progress.discovered) and true or false
end

--! Can a room of this hospital take one more of this object? (For the
--! manager: what a team mate may ask to have added.)
function Bot:extraAllowed(rm, id)
  return extra_allowed(self.world, rm, id)
end

--! Edit one of this hospital's rooms like a person would (a team mate asked
--! for it): steps as in builder.edit_tick ("buy:skeleton", "place", "done";
--! "resize:1:1", "place", "done"). False if another edit is going on.
function Bot:editRoom(rm, steps)
  if self.editing or self.furnishing then return false, "busy" end
  self.editing = {room_type = rm.room_info.id, room_id = rm.id, steps = steps}
  log(string.format("editing %s #%d: %s", rm.room_info.id, rm.id, table.concat(steps, ", ")))
  return true
end

--! A room of its own bigger than it needs, and the side of it to take in:
--! the room with the most floor over `size_of(room id)` (its planned size,
--! the smallest plus one); the side whose last row or column has the fewest
--! things in it (they are put back elsewhere in the room). Returns room,
--! side or nil.
function Bot:oversizedRoom(size_of)
  local world, hospital = self.world, self.world.ui.hospital
  local best, best_side, best_excess
  for _, rm in pairs(world.rooms) do
    local id = rm.room_info.id
    local want = size_of(id) or (rm.room_info.minimum_size or 4) + 1
    if rm.hospital == hospital and rm.built and rm.is_active and not rm.crashed and
        (rm.width > want or rm.height > want) then
      local function things(x0, y0, x1, y1)
        local n = 0
        for ty = y0, y1 do
          for tx = x0, x1 do
            if world:getObject(tx, ty) then n = n + 1 end
          end
        end
        return n
      end
      local x0, y0, x1, y1 = rm.x, rm.y, rm.x + rm.width - 1, rm.y + rm.height - 1
      local side, fewest
      local function consider(name, n)
        if not fewest or n < fewest then side, fewest = name, n end
      end
      if rm.width > want then
        consider("right", things(x1, y0, x1, y1))
        consider("left", things(x0, y0, x0, y1))
      end
      if rm.height > want then consider("top", things(x0, y0, x1, y0)) end
      local excess = rm.width * rm.height - want * want
      if side and (not best or excess > best_excess or (excess == best_excess and rm.id < best.id)) then
        best, best_side, best_excess = rm, side, excess
      end
    end
  end
  return best, best_side
end

--! Take in a room that is bigger than it needs by a row or column, to free
--! floor for another (out of floor and no cheaper way). Like a person: the
--! room editor, walls down, the room drawn again one tile smaller, its
--! things put back.
function Bot:shrinkRoom(size_of)
  local rm, side = self:oversizedRoom(size_of)
  if not rm then return nil, "nothing to shrink" end
  return self:editRoom(rm, {"shrink:" .. side, "place", "done"})
end

--! A room being edited (Bot:editRoom): one step at a time. True while busy.
function Bot:editTick()
  if not self.editing then return false end
  if builder.edit_tick(self.world, self.editing, log) then self.editing = nil end
  return true
end

--! A room drawn for hand furnishing (Bot:drawRoom with extras): buy the
--! extras in its editor (room_buy), then put every object down one at a
--! time like clicks (room_object), then confirm (room_finish). Extras with
--! no place left are sold again. Returns true while busy.
function Bot:furnishTick()
  local job = self.furnishing
  if not job then return false end
  local world, session = self.world, TheApp.mp_session
  local dlg = world.ui.edit_room
  local step = session.step
  job.since = job.since or step
  if not (dlg and dlg.mp_room_id) then
    if step > job.since + 600 then
      log("furnishing: the " .. job.room_id .. " was not built")
      self.furnishing = nil
    end
    return true
  end
  local function count()
    local n = 0
    for _, o in ipairs(dlg.objects) do n = n + o.qty end
    return n
  end
  if not job.bought then
    job.bought = true
    local buy, cost = {}, 0
    local hospital = world.ui.hospital
    for id, n in pairs(job.extras) do
      if extra_allowed(world, dlg.room, id) then
        local each = hospital:getObjectBuildCost(id)
        if hospital.balance - cost - each * n >= RESERVE then
          buy[id] = n
          cost = cost + each * n
        end
      end
    end
    -- (From now on the extras are those bought: an extra it could not
    -- afford is no extra of a needed object to sell back.)
    job.extras = buy
    local parts = {}
    for id, n in pairs(buy) do parts[#parts + 1] = id .. ":" .. n end
    table.sort(parts)
    if #parts > 0 then
      session:issue({kind = "room_buy", room = dlg.mp_room_id, buy = table.concat(parts, ","), sell = ""})
      log(string.format("furnishing %s #%d: buying %s", job.room_id, dlg.mp_room_id, table.concat(parts, ",")))
    end
    job.wait = step + session.delay + 3
    return true
  end
  if job.wait and step < job.wait then return true end
  job.wait = nil
  if job.pending then
    if count() < job.pending.count or step > job.pending.by_step then
      job.pending = nil
    else
      return true
    end
  end
  local o = dlg.objects[1]
  if not o then
    if dlg.confirm_button.enabled then
      log(string.format("furnished %s #%d", job.room_id, dlg.mp_room_id))
      dlg:confirm()
    else
      log("furnishing: " .. job.room_id .. " cannot be finished; cancelled")
      dlg:cancel()
    end
    self.furnishing = nil
    return false
  end
  job.tried = job.tried or {}
  local rm = dlg.room
  -- Where a player puts things: the furniture against the walls first; a
  -- plant, bin, radiator, bookcase or extinguisher only into a corner or
  -- against a wall, never in the middle of the room.
  local small = {plant = true, bin = true, radiator = true, bookcase = true, extinguisher = true, skeleton = true}
  local tiles = {}
  for ty = rm.y, rm.y + rm.height - 1 do
    for tx = rm.x, rm.x + rm.width - 1 do
      local walls = (tx == rm.x and 1 or 0) + (tx == rm.x + rm.width - 1 and 1 or 0) +
          (ty == rm.y and 1 or 0) + (ty == rm.y + rm.height - 1 and 1 or 0)
      if walls > 0 or not small[o.object.id] then tiles[#tiles + 1] = {tx, ty, walls} end
    end
  end
  table.sort(tiles, function(a, b)
    if a[3] ~= b[3] then return a[3] > b[3] end
    if a[2] ~= b[2] then return a[2] < b[2] end
    return a[1] < b[1]
  end)
  for _, t in ipairs(tiles) do
    local tx, ty = t[1], t[2]
    for _, dir in ipairs({"north", "east", "south", "west"}) do
      local key = string.format("%s:%d,%d:%s", o.object.id, tx, ty, dir)
      if o.object.orientations[dir] and not job.tried[key] then
        dlg:setActiveIndex(1)
        dlg:setOrientation(dir)
        dlg:setBlueprintCell(tx, ty)
        if dlg.object_blueprint_good and not world:anyHumanoidObscuringArea(tx, ty) then
          job.tried[key] = true
          job.pending = {count = count(), by_step = step + session.delay + 3}
          dlg:placeObject()
          return true
        end
      end
    end
  end
  -- No place for it: once the room has all it needs (or for an extra), the
  -- rest of this object is sold again (extras bought of a needed object,
  -- such as more beds, share its line); a needed object stops it all.
  local needed = rm.room_info.objects_needed and rm.room_info.objects_needed[o.object.id]
  -- (Only extras of a needed object left, as a second desk: the needed one
  -- is down, so those go back.)
  local extra = job.extras[o.object.id]
  if dlg.confirm_button.enabled or (extra and (not needed or o.qty <= extra)) then
    log(string.format("furnishing: no place for %d more %s; selling", o.qty, o.object.id))
    session:issue({kind = "room_buy", room = dlg.mp_room_id, buy = "", sell = o.object.id .. ":" .. o.qty})
    job.extras[o.object.id] = nil
    job.wait = step + session.delay + 3
    return true
  end
  log("furnishing: no place for a needed " .. o.object.id .. "; cancelled")
  dlg:cancel()
  -- (Not this room type again for a while.)
  if self.manager then self.manager.failed["room:" .. job.room_id] = self:gameDay() + 20 end
  self.furnishing = nil
  return false
end

--! Draw the next room of the fixed plan (the scripted bot). Returns the
--! type drawn, or nil and why not ("money", "space", "done").
function Bot:buildNextRoom()
  local hospital = self.world.ui.hospital
  for _, room_type in ipairs(self:roomPlan()) do
    local tries = self.room_tries[room_type.id] or 0
    if hospital:countRoomOfType(room_type.id, 1) == 0 and tries < 3 then
      if hospital.balance - self:roomCost(room_type) < RESERVE then return nil, "money" end
      self.room_tries[room_type.id] = tries + 1
      local ok, why = self:drawRoom(room_type)
      if ok then return room_type end
      if why == "space" or why == "money" then return nil, why end
    end
  end
  return nil, "done"
end

--! Buy the cheapest plot of land it may buy (on its side of the map) if it
--! can afford it and still keep money for a room.
--! The cheapest plot this hospital may buy and its price, or nil. On its own
--! side of the map; with none left there and its land filling up (or a room
--! that did not fit in the last month), on another's side too (that goes to
--! auction).
function Bot:cheapestPlot()
  local world = self.world
  local th, hospital = world.map.th, world.ui.hospital
  local me = world:getHospitalIndex(hospital)
  local function cheapest(anywhere)
    local best, best_price
    for plot = 1, th:getPlotCount() do
      local side = world.mp_coop and MultiplayerSession.plotSide(world, plot)
      if (anywhere or not side or side == me) and th:isParcelPurchasable(plot, hospital:getPlayerIndex()) then
        local price = world.map:getParcelPrice(plot)
        if not best or price < best_price then best, best_price = plot, price end
      end
    end
    return best, best_price
  end
  local best, best_price = cheapest(false)
  local cramped = self.no_space_day and self:gameDay() - self.no_space_day < 30
  if not best and world.mp_coop and (cramped or MultiplayerSession.landNeed(world, hospital) >= 0.5) then
    best, best_price = cheapest(true)
  end
  return best, best_price
end

--! An auction this hospital bids in, while a person sharing it is away (or
--! nobody does: then the game bids, MultiplayerSession's bots_bid): bid
--! once a step up to what the plot is worth to it, then drop out. True
--! while there is an auction (the bot does nothing else meanwhile).
function Bot:bidAtAuction()
  local world = self.world
  local auction = world.mp_auction
  if not auction then return false end
  local me = self:hospitalIndex()
  local bidder = false
  for _, i in ipairs(auction.bidders) do bidder = bidder or i == me end
  if not bidder or auction.out[me] or auction.leader == me then return true end
  if (world.mp_coop.bot_hospitals or {})[me] or #self:hospitalMates() == 0 or self:sharesWithPerson() then
    return true
  end
  local key = auction.id .. ":" .. auction.bid
  if self.auction_tried == key then return true end -- (once for each bid; it comes back as the new bid)
  if not (self.auction_worth and self.auction_worth.id == auction.id) then
    local worth, need, fill = MultiplayerSession.botPlotWorth(world, me, auction)
    self.auction_worth = {id = auction.id, worth = worth, fill = fill}
    log(string.format("auction %d for plot %d: worth $%d to us (land %d%% full, need %d%%), the person is away",
        auction.id, auction.plot, worth, math.floor(fill * 100 + 0.5), math.floor(need * 100 + 0.5)))
  end
  local amount = auction.bid + auction.step
  local session = TheApp.mp_session
  local hospital = world.ui.hospital
  local reserve = MultiplayerSession.BOT_AUCTION_RESERVE
  local borrow = MultiplayerSession.botCanBorrow(world, me, self.auction_worth.fill)
  local bids = amount <= self.auction_worth.worth and hospital.balance + borrow - amount >= reserve
  -- (A bid needs the money in the bank: with its land nearly full, a loan
  -- first, once; the bid when it has come.)
  if bids and hospital.balance - amount < reserve then
    if self.auction_borrowed ~= key then
      self.auction_borrowed = key
      local loan = math.min(math.ceil((amount + reserve - hospital.balance) / 5000) * 5000,
          math.floor(borrow / 5000) * 5000)
      log(string.format("auction %d: borrowing $%d to bid $%d", auction.id, loan, amount))
      session:issue({kind = "loan", amount = loan})
    end
    if hospital.balance < amount then return true end
  end
  self.auction_tried = key
  if bids then
    log(string.format("auction %d: bidding $%d", auction.id, amount))
    session:issue({kind = "auction_bid", auction = auction.id, amount = amount})
  else
    log(string.format("auction %d: dropping out at $%d", auction.id, auction.bid))
    session:issue({kind = "auction_pass", auction = auction.id})
  end
  return true
end

function Bot:buyPlot()
  local hospital = self.world.ui.hospital
  local best, best_price = self:cheapestPlot()
  if not best then
    log("no land left to buy")
    return false
  end
  -- (Land is worth more than money in the bank: only the reserve kept.)
  if hospital.balance - best_price < RESERVE then
    log(string.format("plot %d costs $%d: not enough money yet", best, best_price))
    return false
  end
  log(string.format("buying plot %d for $%d", best, best_price))
  TheApp.mp_session:issue({kind = "buy_plot", plot = best})
  return true
end

--! Where to build from: the reception desk, or the middle of the hospital.
function Bot:anchor()
  local world = self.world
  local hosp = world.ui.hospital
  if hosp:getReceptionDesks()[1] then return builder.anchor(world) end
  -- No desk yet: a few tiles inside an entrance, where a player puts the
  -- reception (in the middle it splits the floor into strips no room fits).
  local doors = {}
  for _, e in ipairs(world.entities) do
    local id = e.object_type and e.object_type.id
    if (id == "entrance_left_door" or id == "entrance_right_door") and e.tile_x and
        hosp:isInHospital(e.tile_x, e.tile_y) then
      doors[#doors + 1] = e
    end
  end
  if #doors == 0 then return builder.anchor(world) end
  table.sort(doors, function(a, b)
    if a.tile_y ~= b.tile_y then return a.tile_y < b.tile_y end
    return a.tile_x < b.tile_x
  end)
  local door = doors[1]
  local th = world.map.th
  local best, best_cost
  for y = door.tile_y - 6, door.tile_y + 6 do
    for x = door.tile_x - 6, door.tile_x + 6 do
      if hosp:isInHospital(x, y) and not world:getRoom(x, y) then
        local flags = th:getCellFlags(x, y)
        if flags.buildable and flags.passable then
          local d = math.abs(x - door.tile_x) + math.abs(y - door.tile_y)
          local cost = math.abs(d - 4) + ((x * 7 + y * 13) % 5) * 0.01
          if d >= 3 and (not best_cost or cost < best_cost) then best, best_cost = {x, y}, cost end
        end
      end
    end
  end
  if not best then return builder.anchor(world) end
  return best[1], best[2]
end

--! Buy a corridor object and put it on a free tile near the desk (the first
--! tile, nearest first, where the placement window allows it).
--! Buy a corridor object and put it down against a wall near the reception
--! (or near near_x, near_y, a room's door: a waiting area; then only within
--! a few tiles, else nothing is bought).
function Bot:buyCorridor(object_id, near_x, near_y)
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
  local max_r = 40
  if near_x then ax, ay, max_r = near_x, near_y, 5 end
  local placed
  -- As a player does: against a wall (of the building or a room), never in
  -- front of a door, an entrance or the reception, so the open floor stays
  -- free for rooms and nothing blocks a corridor. (A reception desk itself
  -- goes where there is space around it.)
  local hosp = ui.hospital
  local clear = {}
  local function keep(cx, cy, r)
    for ky = cy - r, cy + r do
      for kx = cx - r, cx + r do clear[ky * 1000 + kx] = true end
    end
  end
  for _, r in pairs(world.rooms) do
    if r.hospital == hosp and r.door and r.door.tile_x then keep(r.door.tile_x, r.door.tile_y, 1) end
  end
  for _, desk in ipairs(hosp:getReceptionDesks()) do
    if desk.tile_x then keep(desk.tile_x, desk.tile_y, 2) end
  end
  for _, e in ipairs(world.entities) do
    local id = e.object_type and e.object_type.id
    if id and id:find("entrance", 1, true) and e.tile_x then keep(e.tile_x, e.tile_y, 2) end
  end
  local function wall(tx, ty)
    return not hosp:isInHospital(tx, ty) or world:getRoom(tx, ty) ~= nil or
        not world.map.th:getCellFlags(tx, ty).passable
  end
  local function fits(tx, ty)
    if world:anyHumanoidObscuringArea(tx, ty) then return false end
    for _, facing in ipairs(facings) do
      place:setOrientation(facing)
      place:setBlueprintCell(tx, ty)
      if place.object_blueprint_good then return true end
    end
    return false
  end
  local x, y
  if object_id ~= "reception_desk" then
    -- Nearest first, in a fixed order.
    for r = 0, max_r do
      for dy = -r, r do
        for dx = -r, r do
          local tx, ty = ax + dx, ay + dy
          if not x and math.max(math.abs(dx), math.abs(dy)) == r and not clear[ty * 1000 + tx] and
              self:freeTile(tx, ty) and (wall(tx - 1, ty) or wall(tx + 1, ty) or wall(tx, ty - 1) or
              wall(tx, ty + 1)) and fits(tx, ty) then
            x, y = tx, ty
          end
        end
      end
      if x then break end
    end
  end
  if not x and not near_x then
    -- Tiles with free floor all around (so nothing blocks a corridor).
    x, y = builder.find_free_rect(world, ax, ay, 1, 1, 40, fits)
  end
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

--! Can it hire somebody of this category (Doctor, Nurse, Handyman,
--! Receptionist, or a specialist: Psychiatrist, Surgeon, Researcher) now?
function Bot:canHire(category, hospital)
  local class, skill = category, SPECIALISTS[category]
  if skill then class = "Doctor" end
  -- (Its hospital's own list; a game without World:staffPool has one list.
  -- Another hospital's list is only looked at, not made: World:staffPool
  -- would make it in this game only.)
  local world = self.world
  local pools
  if hospital and hospital ~= world.ui.hospital then
    pools = hospital.available_staff_made == world.available_staff_made and hospital.available_staff or
        world.available_staff
  else
    pools = world.staffPool and world:staffPool() or world.available_staff
  end
  local pool = pools[class]
  if not pool or #pool == 0 then return false end
  if not skill then return true end
  for _, profile in ipairs(pool) do
    if flag(profile, "is_" .. skill) then return true end
  end
  return false
end

--! Hire one member of staff of this category (see Bot:canHire).
function Bot:hireCategory(category)
  if self.world.ui.hospital.balance < RESERVE or not self:canHire(category) then return false end
  local class, skill = category, SPECIALISTS[category]
  if skill then class = "Doctor" end
  local dx, dy = self:anchor()
  local what = skill and (class .. ":" .. skill) or class
  -- A researcher goes straight into the research room (else the room may
  -- wait a long time for a doctor to be called over).
  if category == "Researcher" and self.manager and self.manager:roomOf("research") then what = what .. "@research" end
  -- The most skilled on the list (of those with the skill wanted).
  local ok, err = pcall(builder.ui_hire, self.world, dx, dy, what, log, function(p) return p.skill or 0 end)
  if not ok then log("could not hire a " .. category .. ": " .. tostring(err)) end
  return ok
end

--! Hire the consultant on the list who would teach best (Bot.teacherScore)
--! straight into the training room.
function Bot:hireTeacher()
  if self.world.ui.hospital.balance < RESERVE or not self:canHire("Consultant") then return false end
  local dx, dy = self:anchor()
  local ok, err = pcall(builder.ui_hire, self.world, dx, dy, "Doctor:consultant@training", log, Bot.teacherScore)
  if not ok then log("could not hire a teacher: " .. tostring(err)) end
  return ok
end

--! Send a member of staff into a room (the move_staff command, as a player
--! dragging them there): onto a free tile inside it, nearest the middle.
function Bot:moveStaffInto(staff, target)
  local session = TheApp.mp_session
  if not session or not staff.mp_id then return false end
  local world = self.world
  local cx, cy = target.x + math.floor(target.width / 2), target.y + math.floor(target.height / 2)
  local best, best_d
  for ty = target.y, target.y + target.height - 1 do
    for tx = target.x, target.x + target.width - 1 do
      local d = math.abs(tx - cx) + math.abs(ty - cy)
      if (not best_d or d < best_d) and world.map.th:getCellFlags(tx, ty).passable and
          not world:getObject(tx, ty) and not world:anyHumanoidObscuringArea(tx, ty) then
        best, best_d = {tx, ty}, d
      end
    end
  end
  if not best then return false end
  log(string.format("sending %s into the %s at %d,%d", tostring(staff.profile and staff.profile:getFullName()),
      target.room_info.id, best[1], best[2]))
  return session:issue({kind = "move_staff", staff = staff.mp_id, x = best[1], y = best[2]}) ~= false
end

--! Hire one member of staff the hospital lacks (specialists first).
function Bot:hireOne()
  local hospital = self.world.ui.hospital
  if hospital.balance < RESERVE then return false end
  local want = self:staffWanted()
  local order = {"Receptionist", "Psychiatrist", "Surgeon", "Researcher", "Doctor", "Nurse", "Handyman"}
  for _, category in ipairs(order) do
    local need = want[category] or 0
    if need > 0 and hospital:countStaffOfCategory(category, need) < need and self:canHire(category) then
      return self:hireCategory(category)
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
  if world.mp_coop and world.mp_coop.tricks_off then return false end -- (switched off in this game)
  local mine = world.ui.hospital
  local target, choice
  if self.manager then
    -- The rival closest to winning, and the trick that hurts it most.
    local hosp, name = self.manager:trickTarget()
    if not hosp then return false end
    target, choice = {hosp, name}, self.manager:trickKind(hosp)
  else
    local targets = {}
    for index, hospital in ipairs(world.hospitals) do
      local peer, name, is_bot = self:playerOfHospital(index)
      if world:mpRivals(mine, hospital) and peer and not is_bot and hospital.opened and #hospital.staff > 0 then
        targets[#targets + 1] = {hospital, name}
      end
    end
    if #targets == 0 then return false end
    target = pick(targets)
    choice = self.tricks_played == 0 and {"handyman", "rats"} or sabotage.KINDS
  end
  local kinds = {}
  -- (Only tricks that can be bought yet: they unlock month by month,
  -- sabotage.unlockMonth.)
  for _, k in ipairs(choice) do
    local from = sabotage.unlockMonth(world, k, 1)
    if not from or world.game_date:monthOfGame() >= from then kinds[#kinds + 1] = k end
  end
  if #kinds == 0 then return false end
  local kind = pick(kinds)
  -- The highest level it can afford with something left over, at most a
  -- random one.
  local level = rand(1, 3)
  -- (Not above the highest level unlocked yet.)
  local month = world.game_date:monthOfGame()
  while level > 1 and (sabotage.unlockMonth(world, kind, level) or 0) > month do level = level - 1 end
  local function cost(l) return sabotage.price(world, mine, kind, l) end
  while level > 1 and mine.balance - cost(level) < 2 * RESERVE do level = level - 1 end
  if mine.balance - cost(level) < 2 * RESERVE then
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
    self:say(line, 20 + rand() * 40, nil, nil, true)
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
      -- of its time in a continued game), each bot at least 6 days after
      -- the one before it (Bot:botRank).
      greet = (month - 1) * 30 + 31 + (self:botRank() - 1) * 12 + rand(0, 6),
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
--! A pay rise is answered: a request left open makes the member of staff
--! quit after a while (Bot Agnes lost staff that way, game after game). The
--! bot pays it while the money and the loan still allow a year of it, and
--! otherwise lets them go; a person sharing the hospital answers it instead.
local CLOSE_WINDOWS = {"UIAnnualReport", "UIInformation", "UIStaffRise"}
function Bot:closeWindows()
  local ui = TheApp.ui
  for i = #ui.windows, 1, -1 do
    local win = ui.windows[i]
    for _, name in ipairs(CLOSE_WINDOWS) do
      local cls = rawget(_G, name)
      if cls and class.is(win, cls) then
        if name == "UIStaffRise" and win.staff and not self:sharesWithPerson() then
          self:answerPayRise(win)
        else
          win:close()
        end
        break
      end
    end
  end
end

function Bot:answerPayRise(win)
  local hospital = self.world.ui.hospital
  local max_loan = math.floor((hospital.value or 0) * 0.33 / 5000) * 5000 + 10000
  local can_spend = hospital.balance + math.max(0, max_loan - (hospital.loan or 0))
  local accept = can_spend > (win.rise_amount or 0) * 12
  log(string.format("pay rise of $%d for %s: %s", win.rise_amount or 0,
      tostring(win.staff.profile and win.staff.profile:getFullName()), accept and "paid" or "let go"))
  -- (A headhunter's offer: a word to the rivals; the game does not say whose.)
  if win.staff.mp_headhunted and self.fiery then
    self:tellRival(accept and "headhunter_kept" or "headhunter_lost")
  end
  if accept then win:increaseSalary() else win:fireStaff() end
end

--! Keep the staff: answer pay rise requests (a request left alone makes
--! them quit; the request is an icon in the message bar, which a bot never
--! opens) and, once a game week, give two bonuses to everybody under half
--! happiness while the balance allows. Both are shared commands.
function Bot:careForStaff(day)
  local hospital = self.world.ui.hospital
  local session = TheApp.mp_session
  if not session or session.held then return end
  local person = self:sharesWithPerson()
  self.rises_answered = self.rises_answered or {}
  for _, staff in ipairs(hospital.staff) do
    local amount
    if staff.quitting_in and not staff.fired then
      amount = type(staff.message) == "number" and staff.message
      if not amount and staff.profile then -- (as Staff:requestRaise asks)
        local wage = staff.profile.wage
        amount = math.floor(math.max(wage * 1.1, (staff.profile:getFairWage() + wage) / 2) - wage)
      end
    elseif staff.mp_id then
      self.rises_answered[staff.mp_id] = nil -- (a later request is a new one)
    end
    if amount and amount > 0 and staff.mp_id and not self.rises_answered[staff.mp_id]
        and (not person or staff.quitting_in <= RISE_LAST_HOURS) then
      self.rises_answered[staff.mp_id] = true
      local max_loan = math.floor((hospital.value or 0) * 0.33 / 5000) * 5000 + 10000
      local can_spend = hospital.balance + math.max(0, max_loan - (hospital.loan or 0))
      local accept = can_spend > amount * 12
      log(string.format("pay rise of $%d for %s: %s", amount,
          tostring(staff.profile and staff.profile:getFullName()), accept and "paid" or "let go"))
      if staff.mp_headhunted and self.fiery then
        self:tellRival(accept and "headhunter_kept" or "headhunter_lost")
      end
      session:issue({kind = "pay_rise", staff = staff.mp_id, accept = accept and 1 or 0, amount = amount})
    end
  end
  if day < (self.next_bonus or 0) then return end
  self.next_bonus = day + BONUS_DAYS
  local balance, given, spent = hospital.balance, 0, 0
  for _, staff in ipairs(hospital.staff) do
    if not staff.fired and staff.mp_id and staff.profile and staff:getAttribute("happiness") < BONUS_BELOW then
      local bonus = math.floor(staff.profile.wage * 0.1)
      if balance - 2 * bonus <= BONUS_FLOOR then break end
      for _ = 1, 2 do session:issue({kind = "staff_bonus", staff = staff.mp_id}) end
      balance, given, spent = balance - 2 * bonus, given + 1, spent + 2 * bonus
    end
  end
  if given > 0 then
    log(string.format("day %d: double bonus for %d unhappy staff ($%d)", day, given, spent))
    if person then
      for _, peer in ipairs(self:hospitalMates()) do
        local line = pick(LINES.bonuses):format(given, spent, self:playerName(peer))
        self:say(line, typing(line), peer)
      end
    end
  end
end

function Bot:think()
  self:watchCommands()
  local world = self.world
  local hospital = world.ui.hospital
  local plan = self.plan
  local day = self:gameDay()
  if self:bidAtAuction() then return end
  self:answerOffers()
  self:careForStaff(day)
  -- (Tests: wishes as if a team mate asked for them.)
  if self.manager and os.getenv("MP_BOT_WISHES") then
    self.test_wishes = self.test_wishes or {}
    for wday, key in os.getenv("MP_BOT_WISHES"):gmatch("(%d+):([^;]+)") do
      if day >= tonumber(wday) and not self.test_wishes[key] then
        self.test_wishes[key] = true
        log(string.format("test wish on day %d: %s (%s)", day, key,
            tostring(self.manager:wish(key))))
      end
    end
  end
  -- (Tests: research of its own to share.)
  local learn = tonumber(os.getenv("MP_BOT_LEARN") or "")
  if learn and day >= learn and not self.learned then
    self.learned = TheApp.mp_session:issue({kind = "probe_learn"}) ~= false
    log(string.format("test: learning something on day %d", day))
  end
  -- (A person sharing the hospital answers its emergencies.)
  if not (self.manager and self:sharesWithPerson()) then self:answerEmergencies() end

  if day >= plan.greet and not plan.greeted then
    plan.greeted = true
    local others = {}
    for peer, p in pairs(self.lobby.players or {}) do
      if p.bot ~= "1" and peer ~= TheApp.mp_session.peer_id then others[#others + 1] = p.name end
    end
    table.sort(others)
    local line = self:ownLine(LINES.greet[self.fiery and "fiery" or "friendly"]):format(others[1] and pick(others) or "everybody")
    self:say(line, typing(line), nil, nil, true)
  end

  if self.manager then
    -- The smart brain: a room being furnished or edited first, then the
    -- manager.
    if self:furnishTick() or self:editTick() then return end
    -- (Not when bots leave the building to the person sharing the hospital:
    -- the "helpers" game option.)
    local leaves_building = self:leavesBuilding()
    if not hospital.mp_place and #hospital:getReceptionDesks() == 0 and not leaves_building then
      if day >= plan.desk then
        plan.desk = self:later(3)
        local ok, err = pcall(self.buyCorridor, self, "reception_desk")
        if not ok then log("could not buy a desk: " .. tostring(err)) end
      end
      return
    end
    self.manager:think()
    if self.fiery and day >= plan.trick and hospital.opened and not hospital.mp_place then
      if self:playTrick() then
        self.tricks_played = self.tricks_played + 1
        plan.trick = self:later(rand(60, 120))
      else
        plan.trick = self:later(7)
      end
    end
    return
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

-- The game's random numbers are game state: the bot's own code, and the
-- game's windows and functions it uses, must leave them as they were, or
-- this computer's game drifts from the others' (a desync). Only this
-- computer runs that code, so a number drawn there anyway is undone (and
-- where it was drawn logged, once per place).
local random_seen = {}
local function pack(...) return {n = select("#", ...), ...} end
local function keepRandom(what, fn, ...)
  local saved = math.randomdump()
  local random, where = math.random, nil
  -- (rawset: luacheck keeps the standard library read-only.)
  rawset(math, "random", function(...)
    where = where or debug.traceback("", 2)
    return random(...)
  end)
  local results = pack(pcall(fn, ...))
  rawset(math, "random", random)
  if math.randomdump() ~= saved then
    math.randomseed(saved)
    local key = where or "?"
    if not random_seen[key] then
      random_seen[key] = true
      log("random number drawn by the bot's own code (undone) in " .. what .. ":" .. key)
    end
  end
  if not results[1] then error(results[2], 0) end
  return unpack_args(results, 2, results.n)
end

function Bot:update()
  return keepRandom("update", Bot._update, self)
end

function Bot:_update()
  local session = TheApp.mp_session
  local world = TheApp.world
  self:flushOutbox()
  self:expireAsks()
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
  if os.getenv("MP_BOT_TESTS") == "1" then builder.register_handlers() end
  sabotage = MultiplayerSession.sabotage
  Manager = assert(loadfile(source_dir .. "/scripts/multiplayer/bot_manager.lua"))()

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
      keepRandom("money", bot.moneyReceived, bot, tonumber(cmd.hospital), tonumber(cmd.amount))
    end
    return ok, why
  end
  -- Why its patients leave (cured, sent away, too dear, fed up), counted
  -- here only (the game's own counts stay as they are).
  local go_home = Patient.goHome
  Patient.goHome = function(patient, reason, ...)
    local manager = bot and bot.manager
    local world = TheApp.world
    if manager and world and world.ui and patient.hospital == world.ui.hospital and not patient.going_home then
      local key = tostring(reason)
      if reason == "kicked" and patient.waiting then key = "fed_up" end
      manager.left[key] = (manager.left[key] or 0) + 1
      if reason ~= "cured" and patient.disease then
        local d = patient.disease.id
        manager.lost[d] = (manager.lost[d] or 0) + 1
      end
    end
    return go_home(patient, reason, ...)
  end
  local counting = Patient.goHome
  -- What the game tells its player (the adviser): dirty tricks it noticed.
  local tell = MultiplayerSession.tellPlayer
  MultiplayerSession.tellPlayer = function(world, hospital, text)
    if bot and bot.manager and world.ui and hospital == world.ui.hospital then
      keepRandom("notice", bot.manager.notice, bot.manager, text)
    end
    return tell(world, hospital, text)
  end
  -- (A saved game must not hold this function: the class gets its own back
  -- while the game is saved, and the counting one again afterwards.)
  local save_game = SaveGameFile
  SaveGameFile = function(...)
    Patient.goHome = go_home
    local results = {pcall(save_game, ...)}
    Patient.goHome = counting
    if not results[1] then error(results[2], 0) end
    return unpack_args(results, 2)
  end
  -- (No loading picture to show: no start pause. The people wait for each
  -- other anyway.)
  MultiplayerSession.START_PAUSE_MS = 0
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
    if event == "chat" then keepRandom("chat", bot.onChat, bot, f) end
  end)
  -- The server's answers to its questions (advice; not a game message).
  lobby._onANSWER = function(_, f) keepRandom("answer", bot.onAnswer, bot, f) end
  local session = TheApp.mp_session
  -- Speed votes are for the people (MultiplayerSession:voterCount).
  if session then session.abstains = true end

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
