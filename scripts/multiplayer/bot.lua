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
-- research, money requests); in a competitive race it plays a dirty trick now
-- and then (the first one in months 7 to 12) and takes only a good deal from
-- a rival: a patient it can treat, research its patients need, a specialist
-- it lacks (Manager:rivalOffer). In a race of two teams it takes what its
-- team mates offer and plays its tricks on the other team. From month 4 it
-- asks allies and rivals for research and specialists it needs (once a month
-- at most), and answers another bot's ask with an offer (Manager:botRequest).
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
--   MP_BOT_LEVEL         easy (no advice from the language model; the game gives
--                        it no hidden money), normal or hard (the game helps it more)
--   MP_BOT_STANDIN       1: it plays the place of a person who left, under their
--                        name, until somebody takes it: quietly (no chat, no asks,
--                        no dirty tricks)
--   MP_BOT_LEARNED       the file of what bots learnt from expert players'
--                        hospitals (layout_learn.py: room recipes, plans;
--                        default: learned.lua in CORSIXTH_MP_LEARN_DIR, the
--                        server's); only a hard bot uses it (Jan)
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
--   MP_BOT_TEST_LACK     tests: "<day>:<Category>:<room>": from that game day the bot lacks a
--                        specialist (Surgeon) for that room, so it asks its allies
--   MP_BOT_GIVE_LIMITS   tests: "<above>:<keep>" replaces the $20000 and $15000 of a money
--                        request (it gives only above the first, and keeps the second)
--   MP_BOT_STAFF_REVIEW_FROM  tests: the game day (default 720, the 3rd year) from which the bot reviews
--                        its staff for the training room every month
--   MP_BOT_TEST_WIN      tests: "<hospital index>:<day>;...": those hospitals meet the level's requirements to
--                        win from that game day on (the bots' chat about it; the value goal of a plot asked
--                        for); "<room>/<hospital index>:<day>" only in that room
--   MP_BOT_TEST_FAIL     tests: from this game day the bot counts as failing its objectives
--   MP_BOT_PLAN          tests: "<action>:<weight>,..." the plan every game week
--                        instead of the server's advice (buy:drinks_machine:10)
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
local standin = os.getenv("MP_BOT_STANDIN") == "1"

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

--! A line with {name}, {amount}... filled in from `vars` (where the words come
--! in a different order in each variant, which format cannot do).
local function fill_in(line, vars)
  return (line:gsub("{(%w+)}", function(k) return vars[k] ~= nil and tostring(vars[k]) or nil end))
end

--------------------------------------------------------------------------------
-- What it says. %s is the other player's name.
--------------------------------------------------------------------------------

local LINES = {
  -- A dirty trick dealt with, to whoever sent it (Bot:tellRival): with their
  -- name when it is known or there is only one rival, else to everybody.
  tricked = {
    handyman = {"Nice try, %s. Your handyman is on his way back to you.",
        "Caught your handyman, %s. He's all yours again.",
        "Your handyman has been shown the door, %s. Better luck next time.",
        "Sneaking a handyman in, %s? He's on his way home."},
    rats = {"Pest control is done, %s. Were those your rats?", "All the rats are shot, %s. Very funny.",
        "Squeak squeak, bang. The rats are gone, %s.",
        "Nice rats, %s. Shame about their aim."},
    boiler = {"Somebody broke my boiler. Very funny, %s. My handymen are on it.",
        "A broken boiler, %s? We have blankets.",
        "Cold hospital? Warm hearts, %s. The boiler is being fixed.",
        "Ha, %s, a cold snap. My handymen love a challenge."},
    smear = {"Bad press, %s? My patients will be back.", "Nice smear campaign, %s. Mine will be better.",
        "Tabloids, %s? Cheap. My patients know better.",
        "Gossip won't cure anybody, %s. My doctors will."},
    espionage = {"Enjoy my research files, %s.", "A spy in my research department, %s? Cheeky.",
        "Hope you can read my handwriting, %s.",
        "Copy my homework all you like, %s. I'll still be ahead."},
    headhunter_kept = {"You wanted my doctor, %s? They're staying with me.",
        "Hands off my staff, %s. They got their pay rise.",
        "Nice offer, %s, but my doctor prefers our coffee.",
        "No poaching, %s. My staff are staying."},
    headhunter_lost = {"Take them, %s. I'll find somebody better.", "Fine, %s, keep them. Good luck with that one.",
        "You win that one, %s. I'll hire again.",
        "Enjoy my old doctor, %s. I hope they snore."},
  },
  tricked_unknown = {
    rats = {"The rats are gone. Whoever sent them: nice try.", "All rats shot. Next time send cheese.",
        "Pest control is done. Somebody has a funny sense of humour.",
        "No more rats here. Whoever sent them, thanks for the exercise."},
    boiler = {"Somebody broke my boiler. Whoever it was: we have blankets.",
        "My boiler is broken. Whoever did that: very funny.",
        "A cold hospital for a day or two. Whoever did it, my handymen are on it."},
    smear = {"Somebody is spreading lies about my hospital. Patients will see the truth.",
        "Bad press from nowhere. My patients will be back.",
        "Whoever is gossiping about my hospital: my doctors will answer."},
    espionage = {"Somebody copied my research. I hope you can read my handwriting.",
        "A spy in my research department. Cheeky, whoever you are.",
        "Somebody peeked at my research. Enjoy it."},
    headhunter_kept = {"Somebody tried to poach my doctor. They're staying.",
        "A headhunter came for my doctor. No luck for them.",
        "My doctor said no to a headhunter. Loyal."},
    headhunter_lost = {"Somebody poached my doctor. Fine, I'll train another.",
        "A headhunter got my doctor. I'll find a new one.",
        "I lost a doctor to a headhunter. Back to the hiring list."},
  },
  -- Specialists lent to an ally and asked for (Manager:helpAllies,
  -- Manager:askAllies): names, who, kind, room, then the emergency's words.
  staff_sent = {"{names}, you can have {who}, a {kind}, for your {room}: free, accept my offer in your messages.{urgent}",
      "{names}: I'm offering you {who}, a {kind} for your {room}. No charge, just accept the fax.{urgent}",
      "{names}, {who} (a {kind}) is yours for your {room}, for nothing. Accept the offer in your messages.{urgent}",
      "Here you go, {names}: {who}, a {kind}, for your {room}. Free of charge, just say yes in the fax.{urgent}"},
  staff_for_emergency = {" It's for the emergency!", " Hurry, the emergency won't wait.",
      " The emergency is on, so please hurry.", " Quick, there is an emergency!"},
  -- (names, kind, room, how many it needs ("2 surgeons"), has, emergency)
  -- (To allies, kindly: there is nobody to hire. Jan, 2026-11-12.)
  staff_ask_one = {"{names}, could you help a friend out? My {room} needs {needs}, I have {have}, and there's no {kind} to hire.{urgent}",
      "{names}, would you have a {kind} to spare? My {room} needs {needs} and I only have {have}. I'd be very grateful.{urgent}",
      "Could I borrow a {kind}, {names}? My {room} needs {needs}, I have {have}, and nobody's on the hiring list. Thank you!{urgent}",
      "{names}, I hate to ask, but my {room} needs {needs} and I have {have}. Could you lend me a {kind}?{urgent}"},
  staff_ask_all = {"Could anybody lend me a {kind}? My {room} needs {needs}, I have {have}, and there's nobody to hire. Thank you!{urgent}",
      "Friends, my {room} needs {needs} and I only have {have}. Would anyone have a {kind} to spare?{urgent}",
      "I'm stuck without a {kind} for my {room} ({needs} needed, {have} here). Could one of you help me out?{urgent}",
      "Would anybody have a {kind} they could send me? My {room} needs {needs} and I have {have}. Much appreciated!{urgent}"},
  -- Asks of Manager:askForNeeds, once a month at most: research its patients
  -- need, from an ally (free) or a rival (for a price); a specialist from a
  -- rival. Another bot reads them back (Manager.readAsk): {item}, {price}
  -- and {kind} must stay apart from other words.
  research_please = {"{name}, could you share your {item} research with me? My patients need a {room}.",
      "{name}, my patients keep asking for a {room}. Would you send me your {item} research? Thank you!",
      "Could I have your {item} research, {name}? My patients need a {room} and I can't build one yet."},
  research_buy = {"While I compete with you, {name}, to increase my chances I'm willing to pay {price} for your {item} research.",
      "{name}, rivals can still do business: {price} for your {item} research. My patients need a {room}.",
      "I'll be honest, {name}: my patients need a {room}. I'd pay {price} for your {item} research."},
  staff_ask_rival = {"I would kill for a good {kind}, {name}. Got one to spare? Offer one in the trade window and name your price.",
      "{name}, I'm not proud: I need a {kind} badly. Sell me one and we're even... for now.",
      "Rivals or not, {name}, I'd pay well for a {kind}. My {room} sits idle without one.",
      "My {room} has no {kind}, {name}. I'd kill for one. Name your price."},
  -- Its answers to another bot's ask (Manager:botRequest).
  ask_research_shared = {"Here you go, {name}: our {item} research, free. Accept it in your messages.",
      "Of course, {name}. The {item} research is on its way, no charge.",
      "For you, {name}, the {item} research for nothing. Check your messages."},
  ask_research_sold = {"Deal, {name}: my {item} research for {price}. Accept it in your messages.",
      "Business is business, {name}. The {item} research is yours for {price}.",
      "{price} it is, {name}. The {item} research is in your messages."},
  ask_research_none = {"Sorry {name}, I have no {item} research to give.",
      "I can't help with {item} research, {name}. I don't have it either."},
  ask_rival_ahead = {"Nice try, {name}. You're ahead of me already: no help from me.",
      "Help you win? Not a chance, {name}.",
      "You're doing too well, {name}. Ask somebody else."},
  ask_staff_sold = {"Fine, {name}: {who}, a {kind}, for {price}. Accept the offer in your messages.",
      "{name}, you can have {who} ({kind}) for {price}. It's in your messages.",
      "A {kind} for you, {name}: {who}, {price}. Don't say I never gave you anything."},
  ask_staff_none = {"Sorry {name}, I have no {kind} to spare.", "No spare {kind} here, {name}. Try the hiring list."},
  -- Answers to a rival's offer (Manager:rivalOffer); {value}: what it pays.
  rival_patient_yes = {"Send them over, {name}. Business is business.", "A patient is a patient, {name}. Thanks.",
      "I'll take good care of them, {name}. Thanks for the referral."},
  rival_patient_busy = {"My queue is long enough, {name}. Try somebody else.",
      "Sorry {name}, my doctors are swamped. Not this one."},
  rival_cannot_treat = {"I can't treat that one, {name}. Keep them.",
      "No room for that here, {name}. Thanks anyway."},
  rival_research_free = {"Free research, {name}? Don't mind if I do.", "Thanks, {name}. I won't tell anyone it was you.",
      "Generous of you, {name}. I'll still try to beat you."},
  rival_research_yes = {"{value}? A fair price, {name}. Pleasure doing business.",
      "Deal, {name}. My patients thank you.", "Good research, {name}. I'm still racing you, though."},
  rival_research_dear = {"Too dear, {name}. I'd pay {value} for that.", "{name}, that's worth {value} to me, not more.",
      "Nice try, {name}. {value} and it's mine."},
  rival_research_useless = {"No thanks, {name}. Nothing there I need.", "Keep it, {name}: I have no use for that."},
  rival_research_later = {"I bought from you not long ago, {name}. Ask me again in a few months.",
      "Not again so soon, {name}. Maybe in a few months."},
  rival_staff_yes = {"A {kind}! Just who I needed, {name}. Pleasure doing business.",
      "Deal, {name}. My new {kind} will be happy here."},
  rival_staff_dear = {"Too rich for me, {name}. {value} and your {kind} is mine.",
      "{name}, a {kind} is worth {value} to me, not more."},
  rival_broke = {"I'd buy it, {name}, but my bank says no.", "Not now, {name}. My bank is nearly empty."},
  -- To an ally it sent its research (Manager:shareResearch): the offer in
  -- the fax says it, so the bot says nothing in the chat.
  -- To whoever asked for a project in the chat (Manager:tellWisher): {name},
  -- {what}, and for a room not built beside what was asked, {near}.
  wish_done = {"{name}, your {what} is ready.", "Done, {name}: the {what} is up and running.",
      "All set, {name}. The {what} is ready.", "{name}, the {what} is finished. Enjoy!",
      "Your {what} is done, {name}."},
  wish_done_add = {"{name}, the {what} is in place.", "Done, {name}: I put the {what} in.",
      "The {what} is in, {name}.", "All done, {name}: there is a {what} now."},
  -- (A room taken down: remove:<room>; said once the walls are coming down.)
  wish_done_remove = {"{name}, the {what} is coming down: its floor will be free.",
      "On it, {name}: the {what} goes, the floor is yours.",
      "The {what} is coming down, {name}. The floor is free soon.", "{name}, the {what} is gone in a moment."},
  wish_no_space = {"Sorry {name}, there is no space for the {what} yet. I'll buy more land first.",
      "{name}, the {what} has no room to go yet. Land first, then the {what}.",
      "No floor left for the {what}, {name}. I'll get some land and try again.",
      "{name}, my land is full. The {what} waits until I have more floor."},
  wish_no_money = {"{name}, the {what} has to wait a little: not enough money yet.",
      "Sorry {name}, I can't afford the {what} just yet.",
      "The {what} costs more than I have, {name}. I'll build it as soon as the money is there.",
      "{name}, my bank is too low for the {what} right now. Soon."},
  research_ask = {"{name}, shall I send {ally} our research for free ({list})? Say \"share\" and I will.",
      "{name}, want me to send {ally} our research ({list})? Say \"share\" and it's theirs.",
      "I could give {ally} our research ({list}), {name}. Just say \"share\".",
      "{name}, should I share our research with {ally} ({list})? Say \"share\" if so."},
  -- To a person sharing the hospital (Bot:sharesWithPerson).
  mate_away = {"You seem to be away, %s. I'll run the whole hospital until you're back.",
      "%s, you're quiet. I'll take over everything until you're back.",
      "Taking the wheel while you're away, %s. Come back whenever.",
      "Away, %s? No problem, I'll keep the hospital running."},
  mate_back = {"Welcome back, %s! Prices, loans and the faxes are yours again.",
      "Good to see you again, %s. Prices, loans and faxes are back with you.",
      "You're back, %s! I'll leave the prices, loans and faxes to you.",
      "Welcome back, %s. The hospital's decisions are yours again."},
  -- To a person sharing the hospital: what the weekly bonuses cost.
  bonuses = {"I gave {n} unhappy staff a double bonus (${spent}), {name}.",
      "{n} unhappy staff got a double bonus, {name}. That was ${spent}.",
      "A bonus for {n} unhappy staff (${spent}), {name}. They needed it."},
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
  -- An ally asked for money (Bot:answerMoneyRequest); {name}, {amount} (sent),
  -- {asked}, {keep} (the bank's floor) and {max} (the most sent at once) are
  -- filled in by `fill_in`.
  gift_sent = {
    "Sent you ${amount}, {name}. That's what allies are for.",
    "On its way, {name}: ${amount}. Spend it wisely!",
    "Done, {name}. ${amount} is in your account.",
    "${amount} coming up, {name}. Good luck with it.",
    "There you go, {name}: ${amount}, as asked.",
  },
  -- No amount named: half of what is above the bank's floor.
  gift_sent_auto = {
    "I sent you ${amount}, {name}: half of what I can spare above my ${keep} floor.",
    "{name}, I put ${amount} your way. That's half of my spare cash; I keep ${keep} for emergencies.",
    "Here's ${amount}, {name}. It's half of what I can spare, I keep a cushion of ${keep}.",
    "Sent ${amount}, {name}. You didn't name a sum, so I took half of my spare cash.",
  },
  -- Less than asked: all it can spare above its floor.
  gift_part = {
    "Sent you ${amount} of the ${asked}, {name}. That's all I can spare above my ${keep} floor.",
    "{name}, ${amount} is on its way. More would take me under the ${keep} I keep for my own bills.",
    "I can only manage ${amount} of it, {name}; I keep ${keep} in the bank. Sent.",
  },
  -- Less than asked: the most it sends at once.
  gift_cap = {
    "Sent you ${amount}, {name}. That's the most I send in one go.",
    "{name}, ${amount} is on its way: I don't send more than ${max} at once.",
    "Here's ${amount}, {name}, my limit for one transfer. Ask again later if you need more.",
  },
  -- After less than asked, or nothing: where its money went ({spent}).
  gift_spent = {
    "Most of my cash went into {spent}.",
    "My money went into {spent} lately.",
    "I just spent a lot on {spent}.",
  },
  -- Nothing to spare.
  gift_none = {
    "Sorry {name}, I have nothing to spare right now.",
    "I'd love to, {name}, but my bank is too low to give anything away.",
    "Not today, {name}. I'm keeping my cash for my own hospital.",
    "My bank is nearly empty, {name}. Ask me again when business picks up.",
  },
  -- It cannot send now (the game is held).
  gift_later = {
    "Ask me again in a moment, {name}.",
    "Give me a minute, {name}, and ask once more.",
    "Not right now, {name}. Try again in a bit.",
  },
  -- The asker plays the same hospital.
  gift_same_bank = {
    "We share one bank account, {name}. Just spend what you need.",
    "It's our hospital's money anyway, {name}. Go ahead and spend it.",
    "No need to send anything, {name}, we use the same bank.",
  },
  accept = {
    "Thank you, %s!",
    "Much appreciated, %s.",
    "Cheers, %s, that helps a lot!",
    "You're a star, %s.",
    "Got it, thanks %s!",
    "That's very kind of you, %s.",
  },
  -- A room built, but not beside what was asked ({near}).
  wish_done_far = {"{name}, the {what} is ready, but nothing fit next to the {near}, so I put it where there was room.",
      "Done, {name}: the {what} is up. There was no space beside the {near}, so it went elsewhere.",
      "{name}, your {what} is built. Sorry, the {near} had no free floor around it, so it stands a bit further away.",
      "The {what} is ready, {name}, though not next to the {near}: nothing fit there."},
  refuse = {
    "Not on my watch, %s!",
    "Nice try, %s. No thanks.",
    "I don't take gifts from rivals, %s.",
    "Keep it, %s. I'll win on my own.",
    "Ha! What's the catch, %s?",
    "Do I look that gullible, %s?",
  },
  -- Thanks for what an ally offers, by kind (Bot:answerOffers).
  accept_staff = {
    "A new colleague! Thank you, %s.",
    "Welcome aboard to the new hire, and thanks %s!",
    "Just what I needed, %s. Thank you for the staff!",
    "Great, I could use the help. Thanks %s!",
    "%s, you're a lifesaver. I'll look after them.",
  },
  accept_research = {
    "Thanks for the research, %s!",
    "Brilliant, %s, now we're getting somewhere. Thanks for the research.",
    "More research for me, %s? You spoil me. Thank you!",
    "Got your research, %s. Much appreciated.",
    "That saves me a lot of lab time, %s. Thanks!",
  },
  accept_patient = {
    "Send them over, %s. Happy to help!",
    "We'll take care of that patient, %s. Thanks.",
    "A new patient for us, %s? Welcome.",
    "Glad to help, %s. The patient is in good hands.",
    "Sure thing, %s. Our doctors will look after them.",
  },
  pay = {
    "Here you go, %s.",
    "Sent, %s. Spend it wisely!",
    "Of course, %s. That's what friends are for.",
    "No problem, %s. It's yours.",
    "Money is on its way, %s.",
  },
  broke = {
    "Sorry %s, I'm broke right now.",
    "I'd love to, %s, but my bank manager says no.",
    "Not this time, %s. My bank is nearly empty.",
    "My wallet is empty, %s. Ask me later.",
    "I'd help if I could, %s, but I'm low on cash myself.",
  },
  -- A referred patient this hospital cannot treat (no room for it).
  cannot_treat = {
    "Sorry, %s, we can't treat that one here. Better keep them.",
    "We have no room for that, %s. Not this time.",
    "I'd only have to send them home, %s. Thanks anyway.",
    "We lack the right room for that one, %s. Sorry.",
    "Not our department, %s. Keep them for now.",
  },
  money_thanks = {
    "Thanks for the cash, %s!",
    "Wow, thank you %s! Straight into new equipment.",
    "%s, you're too generous. Thanks!",
    "Cash from %s! I'll put it to good use.",
    "Much appreciated, %s. That helps a lot.",
  },
  money_back = {
    "Keep your money, %s. You'll need it.",
    "I don't want your charity, %s. Sent it back.",
    "Return to sender, %s!",
    "No gifts from rivals, %s. Here it is again.",
    "Your money is back with you, %s.",
  },
  -- The level's requirements (Manager:winChat), to the team. {names}: the ally
  -- who now meets them.
  win_good = {
    "Good job, {names}, you now meet the requirements to win.",
    "Well done, {names}! You now meet everything the level asks for.",
    "{names}, you did it: all the requirements to win are met on your side.",
    "Nice work, {names}. Your hospital meets the requirements to win now.",
    "Great job, {names}! You are ready to win.",
  },
  -- (The person who shares its hospital.)
  win_own = {
    "Good job, {names}, our hospital now meets the requirements to win.",
    "{names}, we did it: our hospital meets everything the level asks for.",
    "Well done, {names}! Our hospital is ready to win.",
    "{names}, all the requirements are met in our hospital now.",
  },
  win_me_too = {
    "I am also ready to take it to the finish line.",
    "I'm also in a good spot.",
    "My hospital meets the requirements too.",
    "Same here, I'm ready as well.",
    "I'm there too. Now we only have to wait for the others.",
  },
  -- A bot that is failing its objectives asks its team for help (Manager:askForHelp):
  -- {amount}, what it would {purpose} and {goal} with it.
  rescue_ask = {
    "I seem to be failing my objectives. Could you send me ${amount} to {purpose} and {goal}? After all, we are on the same boat here. Thanks.",
    "I'm falling behind on the level's goals. Could someone send me ${amount} so I can {purpose} and {goal}? We're in this together.",
    "My hospital is struggling with its objectives. ${amount} would let me {purpose} and {goal}. Can you spare it? Thanks a lot.",
    "Help, I'm failing my objectives! Could you send me ${amount}? I would {purpose} and {goal}. We win or lose together.",
  },
  -- (When no project is waiting for money.)
  rescue_ask_plain = {
    "I seem to be failing my objectives. Could you send me ${amount} so I can {goal}? After all, we are on the same boat here. Thanks.",
    "I'm falling behind on the level's goals. Could someone spare ${amount} to help me {goal}? We're in this together.",
    "My hospital is struggling with its objectives. ${amount} would help me {goal}. Can you spare it? Thanks a lot.",
  },
  -- An opponent meets the requirements to win (Manager:rivalWatch), to the
  -- team: one name ({names}) or several.
  win_rival = {
    "Watch out, {names} has fulfilled the winning conditions, we must catch up!",
    "Careful, {names} has met all the requirements to win. We have to catch up!",
    "{names} now meets the winning conditions, so we must speed up!",
    "Heads up: {names} is ready to win. Time to catch up!",
  },
  win_rivals = {
    "Watch out, {names} have fulfilled the winning conditions, we must catch up!",
    "Careful, {names} have met all the requirements to win. We have to catch up!",
    "{names} now meet the winning conditions, so we must speed up!",
    "Heads up: {names} are ready to win. Time to catch up!",
  },
  -- What a bot that is not there yet still needs, one thing at a time, by
  -- requirement ({now}, {want}, {left}, {short} money, {loan}).
  win_need = {
    balance = {
      "I'm {short} short, could you spare some cash for me to win together sooner?",
      "I still need {short} more in the bank to win with you. Could someone spare some?",
      "My bank is the last problem: I'm {short} short. Any chance of a gift?",
      "{short} more and I'm ready to win. Can somebody send me some cash?",
    },
    value = {
      "My hospital value is below the required amount, what do you suggest I do?",
      "My hospital is worth {now} and the level wants {want}. Any tips on raising it?",
      "I need a higher hospital value ({want}). Should I buy land or build more rooms?",
      "Hospital value is what I'm missing: {now} of {want}. Any ideas?",
    },
    reputation = {
      "My reputation is {now} and the level wants {want}. What would you do?",
      "I'm short on reputation ({now} of {want}). Any tips?",
      "Reputation is my last problem: {now} against {want}. How do I raise it?",
    },
    num_cured = {
      "I still need {left} more cured patients. Could you send me some to treat?",
      "{left} more cures and I'm ready. Any patients to spare?",
      "I'm {left} cures short of the goal. Could someone refer patients to me?",
    },
    percentage_cured = {
      "My cure rate is {now}% and the level wants {want}%. Any ideas?",
      "I need a better cure rate ({now}% of {want}%). What helps?",
      "Too many patients leave uncured: {now}% against {want}%. What would you do?",
    },
    percentage_killed = {
      "Too many of my patients died: {now}% against a limit of {want}%. How do I cut that?",
      "My death rate ({now}%) is above the limit of {want}%. Any advice?",
      "I have to keep deaths under {want}% and I'm at {now}%. What would you do?",
    },
    staff_happiness = {
      "My staff are not happy enough ({now}% of {want}%). Any tips?",
      "Staff happiness is my last problem: {now}% against {want}%. What helps?",
      "I need happier staff, {now}% now and {want}% to win. Ideas?",
    },
    patient_happiness = {
      "My patients are not happy enough ({now}% of {want}%). Any tips?",
      "Patient happiness is what I'm missing: {now}% against {want}%. What helps?",
      "I need happier patients, {now}% now and {want}% to win. Ideas?",
    },
    months_played = {
      "I only have to wait a little longer, the level wants more months played.",
      "Just time left for me. {left} months to go.",
      "Only the calendar is in my way now, {left} months more.",
    },
    loan = {
      "I still have a {loan} loan to repay and then I'm ready.",
      "My loan of {loan} is the last thing in the way. I'll repay it as soon as I can.",
      "Only my {loan} loan stops me from winning. Paying it back.",
    },
  },
  trick = {
    "Is it just me, or does it smell funny over at %s's place?",
    "Hope your handymen are well rested, %s.",
    "Having a quiet day, %s? Not for long.",
    "Oh dear, %s. Busy, busy, busy.",
    "Watch your back, %s. Rumour has it, things are about to happen.",
    "Sleep well tonight, %s?",
  },
}

local REPLIES = {
  bot = {
    friendly = {"Yes, I'm a bot, %s. Beep boop!", "Guilty, %s. Computer player, at your service.",
        "Part of me is silicon, %s. The rest is coffee.", "A computer player, %s, and proud of it."},
    fiery = {"A bot, %s, and a better manager than you.", "Beep boop, %s. Prepare to lose.",
        "Yes, a bot. Beaten by a bot yet, %s?", "Silicon and steel, %s. Hard to beat."},
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
    friendly = {"Hey, be nice, %s!", "Ouch, %s. I have feelings. Probably.", "That's not very kind, %s.",
        "Easy, %s. We're all just curing patients here."},
    fiery = {"Big words, %s. Let's see the scoreboard.", "Keep talking, %s. I'll keep winning.",
        "Is that all you've got, %s?", "Sticks and stones, %s. I have a hospital to run."},
  },
  race = {
    friendly = {"We're in this together, %s!", "Teamwork, %s. That's how we win.",
        "Side by side, %s. We'll get there.", "One hospital at a time, %s. We can do it."},
    fiery = {"We'll see who's laughing at the year end, %s.", "First place is mine, %s.",
        "You'll be watching my victory from the waiting room, %s."},
  },
  money = {
    friendly = {"Money's tight here too, %s. Ask me later!", "I'd help, %s, but my budget says no today.",
        "Ask me for a sum, %s, and I'll check my bank.", "Cash is king, %s. Name an amount and I'll see."},
    fiery = {"Money? From me? Dream on, %s.", "Not a penny, %s.", "Earn your own, %s.",
        "My money stays in my hospital, %s."},
  },
  -- A request from somebody who is not on its side (Bot:isAlly).
  no_orders = {
    friendly = {"Sorry %s, I only take requests from my own team.", "That's for my team mates to ask, %s.",
        "I'm afraid I can't do that for you, %s."},
    fiery = {"Nice try, %s. I don't take orders from rivals.", "Ask your own staff, %s.",
        "I only work for my team, %s.", "Not a chance, %s. We're rivals, remember?", "Dream on, %s."},
  },
  bye = {
    friendly = {"Bye %s, see you soon!", "Take care, %s!", "See you later, %s!", "Bye for now, %s. Good luck!"},
    fiery = {"Running away already, %s?", "Bye, %s. One less rival.", "Leaving, %s? Smart move.",
        "Don't hurry back, %s."},
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

-- Words of a request: somebody asks the bot to do something for them (it
-- only does that for its allies, Bot:isAlly). Lower case; some Czech too.
local REQUEST_WORDS = {"build", "hire", "buy", "put", "place", "construct", "make", "add", "remove", "demolish",
    "sell", "send", "give", "lend", "spare", "please", "pls", "plz", "could you", "can you", "would you", "need you",
    "i need", "i want", "we need", "can u", "could u", "can i have", "can i get", "could i have", "may i have", "postav", "postavit", "najmi", "kup", "kupit", "pošli",
    "posli", "poslat", "dej", "dejte", "prosim", "prosím", "pujc", "půjč", "pujcit", "půjčit"}
-- Lines that talk about giving rather than ask for something.
local NOT_ASKING = {"i sent", "sent you", "i'll send", "i will send", "i send you", "sending you", "here you go",
    "thank", "thanks", "thx", "diky", "díky", "poslal jsem"}

local function any_word(text, list)
  for _, word in ipairs(list) do
    if has_word(text, word) then return true end
  end
  return false
end

--! Does this chat line ask the bot to do something ("build a toilet", "send
--! me money")?
local function is_request(text)
  text = text:lower()
  return any_word(text, REQUEST_WORDS) and not any_word(text, NOT_ASKING)
end

-- Words for money in a request (and not just talk about it).
local MONEY_WORDS = {"money", "cash", "broke", "loan", "dollar", "dollars", "funds", "bucks", "penize", "peníze", "prachy",
    "korun", "pujcku", "půjčku", "dolaru", "dolarů"}

--! Does this chat line ask the bot for money?
local function is_money_request(text)
  text = text:lower()
  if any_word(text, NOT_ASKING) then return false end
  local money = any_word(text, MONEY_WORDS) or text:find("$", 1, true) ~= nil or text:find("%d%s*k%f[%W]") ~= nil
  return money and (any_word(text, REQUEST_WORDS) or any_word(text, {"help", "short"})) or false
end

--! The amount of money a chat line names, in dollars, or nil: "$20,000",
--! "20k", "2.5k", "20 000", "5000 dollars", "$50". Between $1 and $10,000,000.
--! (A small sum is a sum: before, "$50" counted as none named, and the bot
--! sent thousands.)
local function parse_amount(text)
  text = text:lower()
  local function ok(v)
    v = v and math.floor(v + 0.5)
    if v and v >= 1 and v <= 10000000 then return v end
  end
  local function number(str)
    str = str:gsub(",", "")
    if str:match("^%d+%.%d%d%d$") then str = str:gsub("%.", "") end -- (20.000)
    return tonumber(str)
  end
  local k = text:match("(%d[%d%.,]*)%s*k%f[%W]")
  if k and number(k) then return ok(number(k) * 1000) end
  local thousands, rest = text:match("(%d%d?%d?)[ ](%d%d%d)%f[%D]")
  if thousands then return ok(tonumber(thousands .. rest)) end
  local v = text:match("%$%s*(%d[%d%.,]*)") or text:match("(%d[%d%.,]*)%s*%$") or
      text:match("(%d[%d%.,]*)%s*dollars?") or text:match("(%d[%d%.,]*)%s*bucks") or
      text:match("(%d[%d%.,]*)%s*usd") or text:match("(%d[%d%.,]*)%s*kc") or text:match("(%d%d%d%d+)")
  return v and ok(number((v:gsub("[%.,]+$", "")))) or nil
end

-- A plot of land asked for ("give me plot 7", "can I have your plot 7?", "sell
-- me plot 7", "can you spare a plot?"): words for a plot, words that ask for
-- one, and lines that offer one rather than ask. Lower case; some Czech too.
local PLOT_WORDS = {"plot", "plots", "parcel", "parcels", "land", "pozemek", "pozemku", "pozemky", "parcela",
    "parcelu", "parcely"}
local PLOT_ASKING = {"give me", "give us", "sell me", "sell us", "send me", "hand me", "hand over", "can i have",
    "could i have", "may i have", "can i get", "could i get", "can we have", "could we have", "let me have",
    "spare", "i need", "we need", "i want", "i'd like", "can i buy", "could i buy", "may i buy", "let me buy",
    "from you", "one of your", "dej mi", "dejte mi", "dáš mi", "das mi", "prodej mi", "prodáš mi", "prodas mi",
    "potřebuju", "potrebuju", "chci"}
local PLOT_NOT_ASKING = {"i can spare", "i could spare", "i'll give", "i will give", "i give you", "i gave",
    "i sold", "i'll sell", "i will sell", "i offer", "i offered", "you can have", "take my", "want my", "for you"}

--! The plot number a chat line names ("plot 7", "plot #7", "plot number 7",
--! "parcel no. 7", "pozemek č. 7", "#7"), or nil.
local function parse_plot(text)
  text = text:lower()
  for _, w in ipairs({"plot", "parcel", "pozem", "land"}) do
    local n = text:match(w .. "%a*[%s:#%-]*(%d+)") or text:match(w .. "%a*%s+n[%a%.]*%s*#?%s*(%d+)") or
        text:match(w .. "%a*%s+č%.?%s*(%d+)")
    if n then return tonumber(n) end
  end
  local n = text:match("#%s*(%d+)")
  return n and tonumber(n) or nil
end

--! Does this chat line ask the bot for one of its plots? Not a line that
--! offers one, asks it to build or buy land for itself, or asks for money
--! (unless it names a plot: "sell me plot 7 for 5000 dollars").
local function is_plot_request(text)
  text = text:lower()
  if any_word(text, NOT_ASKING) or any_word(text, PLOT_NOT_ASKING) or not any_word(text, PLOT_WORDS) then
    return false
  end
  if any_word(text, {"build", "construct", "put", "place", "postav", "postavit"}) then return false end
  if has_word(text, "buy") and not any_word(text, {"can i buy", "could i buy", "may i buy", "let me buy", "from you"}) then
    return false
  end
  if any_word(text, MONEY_WORDS) and not parse_plot(text) then return false end
  return any_word(text, PLOT_ASKING)
end

--------------------------------------------------------------------------------
-- The bot
--------------------------------------------------------------------------------

local socket, builder, sabotage, Manager, Learned
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
-- After another rival's dirty trick on a player, a bot leaves that player
-- alone this many game days (Argus, 2026-11-12: two bots sent their evil
-- handymen at the same time).
local TRICK_GAP_DAYS = 30
-- Corridor objects of one kind keep apart (Argus, 2026-11-14: radiators
-- flush against one another): at least this many tiles from the next one of
-- the hospital's corridors; a hard bot as the experts' corridors have them
-- (learned each night, layout_learn.py: their radiators mostly stand 3 or 4
-- apart).
local CORRIDOR_GAPS = {radiator = 3, plant = 2}
-- Dirty tricks by the bot's level (Jan, 2026-11-14): its first one on a day
-- of these months of the game (easy: months 10-12, normal: 7-12, hard:
-- 4-6), then one every so many game days.
local TRICK_FIRST_DAYS = {easy = {271, 359}, normal = {181, 359}, hard = {91, 179}}
local TRICK_EVERY_DAYS = {easy = {90, 150}, normal = {60, 120}, hard = {45, 90}}
-- Staff care (Bot:careForStaff): once a game week everybody under half
-- happiness gets two bonuses (each 10% of their wage and +50% happiness),
-- while the balance stays above BONUS_FLOOR (Jan, 2026-11-03).
local BONUS_DAYS, BONUS_BELOW, BONUS_FLOOR = 7, 0.5, 2000
-- A person sharing the hospital answers pay rises; the bot steps in when
-- they have not and the member of staff would quit within this many hours.
local RISE_LAST_HOURS = 5 * 24
-- No drinks machine closer than this many tiles to another (Bot:buyCorridor).
local DRINKS_APART = 5
-- Corridor furniture once the hospital is open: id -> how many. (No fire
-- extinguisher: they go into the rooms with costly machines, where they
-- stop explosions; Jan, 2026-11-13. M:projects.)
local EXTRAS = {{"bench", 3}, {"plant", 2}, {"drinks_machine", 1}, {"bench", 5}, {"plant", 4}}

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
  -- (Tests: MP_BOT_RESEARCH names a bot that researches hard: a bigger
  -- research room with four desks and a researcher at each.)
  self.research_heavy = (os.getenv("MP_BOT_RESEARCH") or "") == my_name
  if self.research_heavy then log("researches hard (four desks)") end
  -- (In a person's place while they are away: it plays, and says nothing.)
  self.standin = standin
  if standin then log("plays for " .. my_name .. " while they are away (quiet)") end
  self.level = os.getenv("MP_BOT_LEVEL") or "normal"
  -- What it learnt from expert players' hospitals (Jan, 2026-11-12: bots
  -- should build like Argus): room recipes, and plans for the places experts
  -- played (bot_learned.lua). Only a hard bot (Jan, the same night: easy and
  -- normal bots are not changed); not one standing in for a person who left,
  -- whose hospital it keeps going.
  -- (Read here; used only while its level is hard: Bot:applyLevel.)
  local learned_path = os.getenv("MP_BOT_LEARNED") or ""
  local learn_dir = os.getenv("CORSIXTH_MP_LEARN_DIR") or ""
  if learned_path == "" and learn_dir ~= "" then learned_path = learn_dir .. "/learned.lua" end
  if learned_path ~= "" and not standin then
    local data, why = Learned.load(learned_path)
    self.expert_data_read = data
    if data then
      local recipes, plans = 0, 0
      for _ in pairs(data.recipes) do recipes = recipes + 1 end
      for _ in pairs(data.plans) do plans = plans + 1 end
      log(string.format("learnt from %s: %d room recipes, %d plans (a hard bot builds by them)",
          table.concat(data.experts or {}, ", "), recipes, plans))
    else
      log("nothing learnt from " .. learned_path .. ": " .. tostring(why))
    end
  end
  if self.brain ~= "script" then
    self.manager = Manager.new(self, {log = log, rand = rand, pick = pick, sabotage = sabotage, lines = LINES, fill = fill_in,
        typing = function(text) return 1.5 + #text * 0.06 + rand() * 2 end, learned_module = Learned})
  end
  -- "manager": the same brain, without the language model's advice; an easy
  -- bot never asks it either (Bot:applyLevel).
  if self.brain == "manager" then self.ai = "off" end
  self:applyLevel(self.level)
  log("brain: " .. self.brain .. ", level " .. self.level)
  return self
end

--! Play at this level (easy, normal, hard): an easy bot asks the language
--! model nothing, only a hard one builds as the experts do. MP_BOT_LEVEL is
--! the level it was started at; the room's owner may change it in the room
--! before the game starts, and the game's own (START) wins: Bot:attach.
function Bot:applyLevel(level)
  self.level = level
  if level == "easy" and self.ai ~= "off" then
    self.ai, self.ai_easy = "off", true
  elseif level ~= "easy" and self.ai_easy then
    self.ai, self.ai_easy = nil, nil
  end
  self.expert_data = level == "hard" and self.expert_data_read or nil
  if self.expert_data then log("builds as the experts do (a hard bot)") end
  self.expert_plan_world = nil -- (the plan for its place is looked up again)
  if Manager then Manager.learned, Manager.hard = self.expert_data, level == "hard" end
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
      if entry.text and self.standin then
        log("(quiet) " .. entry.text)
      elseif entry.text and entry.to == "team" then
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
-- (Tests: MP_BOT_WATCHER names a scripted player who only watches, seated
-- in a bot's hospital: no player for the bots, so that hospital's bot plays
-- it alone and is asked and answers as if alone.)
local WATCHER = os.getenv("MP_BOT_WATCHER")
function Bot:playerName(peer)
  local p = self.lobby.players and self.lobby.players[peer]
  if p and WATCHER and p.name == WATCHER then return nil, false end
  if p then return p.name, p.bot == "1" end
  for _, gp in ipairs(self.lobby.game_players or {}) do
    if gp.peer == peer then return gp.name, false end
  end
  return nil, false
end

--! The player of a hospital (index): their peer and name.
function Bot:playerOfHospital(index)
  local first
  for peer, h in pairs(self.lobby.peer_hospital or {}) do
    if h == index then
      local name, is_bot = self:playerName(peer)
      if name then return peer, name, is_bot end
      first = first or peer
    end
  end
  return first
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
      local name, is_bot = self:playerName(peer)
      if name and not is_bot then mates[#mates + 1] = peer end
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

--! Is the player of this peer an ally: in the same hospital as this bot, or
--! on its side (co-op: everybody; a race of teams: the same team; a race
--! without teams: nobody)? Only allies get what they ask for (rooms, staff,
--! money, leaving a project to them).
function Bot:isAlly(peer)
  local world = self.world
  local mine = world and world.ui and world.ui.hospital
  local index = self.lobby.peer_hospital and self.lobby.peer_hospital[peer]
  local hosp = index and world and world.hospitals[index]
  if not (hosp and mine) then return false end
  if hosp == mine then return true end
  return world.mpMayTrade ~= nil and world:mpMayTrade(mine, hosp) and not world:mpRivals(mine, hosp)
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
  -- (Tests: a fixed plan, as the model would send it.)
  local fixed = os.getenv("MP_BOT_PLAN")
  if fixed and fixed ~= "" then
    local plan = {priorities = {}}
    for action, weight in fixed:gmatch("([%w_:]+):(%d+)") do
      plan.priorities[#plan.priorities + 1] = {action = action, weight = tonumber(weight)}
    end
    manager:applyPlan(plan)
    return true
  end
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
    local plan = {priorities = {}}
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

--! A hospital failing its objectives: the server's model reviews it (ASK
--! kind=rescue, answered like a weekly plan). `done(plan)` gets the plan
--! ({priorities = {{action, weight}}, note}) or nil if none came within a
--! minute. False if it did not ask (no advice on this server).
function Bot:askRescue(report, menu, done)
  return self:ask("rescue", {text = report, menu = menu}, 60, function(f)
    if not f then return done(nil) end
    local plan = {priorities = {}, note = f.note}
    for action, weight in (f.actions or ""):gmatch("([%w_:]+):(%d+)") do
      plan.priorities[#plan.priorities + 1] = {action = action, weight = tonumber(weight)}
    end
    done(plan)
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
  -- Bots do not chat with each other; another bot's ask to it alone (help,
  -- Manager:askForNeeds) gets an answer and an offer (Manager:botRequest).
  if is_bot and name and f.to and self.manager then self.manager:botRequest(peer, name, f.text or "") end
  if is_bot or not name then return end
  local text = f.text or ""
  -- An ally (same hospital, same team, or anybody in a co-op game) may ask
  -- for things; in a race everybody else is a rival (Bot:isAlly).
  local ally = self:isAlly(peer)
  local rival = self.fiery and not ally
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
  if ally and text ~= "" then
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
    if self:now() - self.last_reply < (fast and 0.2 or 10) then return end
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
  -- Somebody who is not an ally gets no orders done (and no money): at most
  -- a short refusal, without asking the model.
  if (private or named) and not ally and is_request(text) then
    local refusal = rival and kind == "money" and REPLIES.money.fiery or REPLIES.no_orders[rival and "fiery" or "friendly"]
    local reply = pick(refusal):format(name)
    log(string.format("refused a request from %s (not an ally)", name))
    self:say(reply, typing(reply), to)
    return
  end
  -- An ally asks for one of its plots, with or without a number: its land
  -- decides (Manager:plotRequest; the model is not asked). In the team's
  -- chat only the bot named answers, or else the one that owns the plot
  -- named, or has the most room (Bot:isPlotDonor).
  local function plot_turn(plot)
    return named or (private and f.team ~= "1") or
        (not self:namesOtherBot(text) and self:isPlotDonor(self.lobby.peer_hospital and self.lobby.peer_hospital[peer], plot))
  end
  if (private or named) and ally and self.world and is_plot_request(text) then
    local plot = parse_plot(text)
    if plot_turn(plot) then self:answerPlotRequest(peer, name, plot, to) end
    return
  end
  -- An ally asks for money, with or without a sum: the bank decides (the
  -- model is not asked: it could promise what the bank cannot do).
  -- Asked in the team's chat, which every bot of the team gets, only the one
  -- named answers, or else the one with the most money.
  local function money_turn()
    return named or (private and f.team ~= "1") or
        (not self:namesOtherBot(text) and self:isBestDonor(self.lobby.peer_hospital and self.lobby.peer_hospital[peer]))
  end
  if (private or named) and ally and self.world and is_money_request(text) then
    if money_turn() then self:answerMoneyRequest(peer, name, parse_amount(text), to) end
    return
  end
  if (private or named) and self.ai ~= "off" then
    local report = self.manager and self.manager:report() or ""
    local brief = report:match("^[^\n]*\n[^\n]*") or report
    -- (On the person's side it may also do what it is asked: the projects
    -- it can do now go along.)
    local menu = ally and self.manager and table.concat(self.manager:wishMenu(), ",") or nil
    local asked = self:ask("chat", {text = brief, lines = table.concat(self.chat_lines, "\n"),
        rival = rival and 1 or nil, menu = menu}, 10, function(answer)
      local reply = answer and answer.text or line
      -- (Several at once: "a plant and a radiator in every room".)
      if answer and self.manager and ally then
        for key in (answer.wish or ""):gmatch("[^,]+") do self.manager:wish(key, peer) end
        for key in (answer.leave or ""):gmatch("[^,]+") do self.manager:leaveTo(key) end
      end
      -- (The model says whether the ally asked for one of its plots: the
      -- number, 0 none named; and for money, and how much: -1 no, 0 no sum
      -- named. What the bot does and says about it is its own doing, not the
      -- model's reply. An older server sends no plot.)
      local want_plot = answer and ally and self.world and tonumber(answer.plot)
      if want_plot and want_plot >= 0 then
        local plot = want_plot >= 1 and want_plot or parse_plot(text)
        if plot_turn(plot) then self:answerPlotRequest(peer, name, plot, to) end
        return
      end
      local give = answer and ally and tonumber(answer.give)
      if give and give >= 0 then
        local amount = give >= 1 and give <= 10000000 and give or parse_amount(text)
        if money_turn() then self:answerMoneyRequest(peer, name, amount, to) end
        return
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
      local line, filled
      if accept and offer.kind == "plot" then
        -- (A plot from an ally: its manager decides, a loan for it is fine.)
        if self.manager then
          accept, line = self.manager:plotAnswer(offer)
        else
          accept, line = false, pick(LINES.refuse)
        end
      elseif accept then
        local cost = offer.kind == "money" and offer.amount or offer.price or 0
        if cost > 0 and mine.balance - cost < RESERVE then
          accept = false
          line = pick(LINES.broke)
        elseif offer.kind == "patient" and not self:canTreat(self.world:getEntityById(offer.entity)) then
          -- (Taking them in only to send them home helps nobody: Jan, eu2.)
          accept = false
          line = pick(LINES.cannot_treat)
        elseif offer.kind == "money" then
          line = pick(LINES.pay)
        else
          line = pick(offer.kind == "staff" and LINES.accept_staff or offer.kind == "research" and
              LINES.accept_research or offer.kind == "patient" and LINES.accept_patient or LINES.accept)
        end
      else
        -- A rival's offer: a good deal is taken (Jan, 2026-11-12): a patient
        -- it can treat, research its patients need for what it is worth to
        -- it, a specialist it lacks. The answer comes filled in.
        local said
        if self.manager then accept, said = self.manager:rivalOffer(offer, name) end
        line = said or pick(LINES.refuse)
        filled = said ~= nil
      end
      if not filled then line = line:format(name) end
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
      -- (A team mate's offer: the thanks go to the team, not to the rivals.
      -- A rival's: the refusal goes to whoever made the offer, not to
      -- everybody (Jan, 2026-11-11: Bot Bertie's "Do I look that gullible,
      -- Argus?" was seen by all).)
      local to
      if not self.world:mpRivals(self.world.hospitals[offer.from], mine) then
        to = "team"
      else
        -- (A rival bot hears it too: nothing in it is an ask it acts on.)
        local who = self.manager and self.manager:contactsOf(offer.from)
        local peers = who and who.peers or self:peopleOfHospital(offer.from)
        to = #peers > 0 and table.concat(peers, ",") or false
      end
      if to then self:say(line, delay + typing(line), to) end
    end
  end
end

--! Can this hospital treat a patient another player refers? A diagnosed
--! patient needs every treatment room of the disease here, one not yet
--! diagnosed a GP's office.
function Bot:canTreat(patient)
  local mine = self.world.ui.hospital
  if not patient or not patient.disease then return true end
  if patient.diagnosed then
    for _, id in ipairs(patient.disease.treatment_rooms or {}) do
      if mine:countRoomOfType(id, 1) == 0 then return false end
    end
    return true
  end
  return mine:countRoomOfType("gp", 1) > 0
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
        -- (A room not discovered yet: research to ask for, Manager:askForNeeds.)
        local found = mine.room_discoveries and mine.room_discoveries[id]
        if self.manager and found and not found.is_discovered then
          self.manager.research_need[id] = self:gameDay()
          self.manager.demand[id] = (self.manager.demand[id] or 0) + 2
        end
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

-- An ally's request for money (Jan, 2026-11-08): the sum asked for, up to
-- GIVE_MAX at once, while the bank holds more than GIVE_KEEP and keeps that
-- much. (Before, only a bank over $20,000 gave anything, and a sum it could
-- not give in full got nothing: a player who had sent a bot a lot was
-- refused a small sum back.) Tests: the limits "keep:max" in
-- MP_BOT_GIVE_LIMITS.
local GIVE_KEEP, GIVE_MAX = 15000, 20000
do
  local keep, most = (os.getenv("MP_BOT_GIVE_LIMITS") or ""):match("^(%d+):(%d+)$")
  if keep then GIVE_KEEP, GIVE_MAX = tonumber(keep), tonumber(most) end
end

--! Dollars with thousands separators: 20,000.
local function thousands(n)
  local text = string.format("%d", math.max(0, math.floor(n + 0.5)))
  return (text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

--! What a bank of `balance` dollars gives to an ally who asks for `amount`
--! (nil: no sum named): the amount to send (0: none) and the most it could
--! send now. A sum named: min(asked, GIVE_MAX, balance - GIVE_KEEP), so
--! nothing once the bank holds GIVE_KEEP or less. No sum named: half of what
--! is above GIVE_KEEP, in whole thousands, $1,000 to $10,000 (and at most
--! GIVE_MAX): enough to help, and the bank stays well above its floor.
function Bot.giftFor(balance, amount)
  balance = math.floor(balance)
  local most = math.max(0, math.min(GIVE_MAX, balance - GIVE_KEEP))
  if most == 0 then return 0, 0 end
  if amount then return math.min(amount, most), most end
  local spare = math.floor((balance - GIVE_KEEP) / 1000) * 1000
  local give = math.min(10000, most, math.max(1000, math.floor(spare / 2000) * 1000))
  if give > spare then return 0, most end
  return give, most
end

--! Does this chat line name another bot of the room (not this one)?
function Bot:namesOtherBot(text)
  local low = text:lower()
  local me = TheApp.mp_session.peer_id
  for peer, p in pairs(self.lobby.players or {}) do
    local first = p.bot == "1" and peer ~= me and p.name and p.name:lower():match("(%a+)$")
    if first and low:find(first, 1, true) then return true end
  end
  return false
end

--! Is this bot the one among the asker's allied bots with the most money
--! (ties: the lower hospital)? The asker's own hospital does not count. All
--! bots see the same banks, so exactly one is.
function Bot:isBestDonor(asker_index)
  local world, mine = self.world, self.world.ui.hospital
  local best, best_balance
  for peer, p in pairs(self.lobby.players or {}) do
    local index = p.bot == "1" and self.lobby.peer_hospital and self.lobby.peer_hospital[peer]
    local h = index and world.hospitals[index]
    if h and index ~= asker_index and
        (h == mine or (world:mpMayTrade(mine, h) and not world:mpRivals(mine, h))) then
      local balance = math.floor(h.balance)
      if not best_balance or balance > best_balance or (balance == best_balance and index < best) then
        best, best_balance = index, balance
      end
    end
  end
  return best == nil or best == self:hospitalIndex()
end

--! An ally asked in the chat for money (`amount`: the sum named, or nil):
--! the bot decides by its own bank (Bot.giftFor), sends it as a person would
--! (a give_money command) and says what it did, never more. `to` is where
--! the answer goes (the team, the asker, or everybody). Less than asked, or
--! nothing: it also says where its money went lately (its last big spending,
--! Manager:spentWords), so a player who gave it money sees what became of it.
function Bot:answerMoneyRequest(peer, name, amount, to)
  local world, session = self.world, TheApp.mp_session
  local mine = world.ui.hospital
  local index = self.lobby.peer_hospital and self.lobby.peer_hospital[peer]
  local line
  local vars = {name = name, keep = thousands(GIVE_KEEP), max = thousands(GIVE_MAX)}
  -- (Where the money went, after a line that gives less than asked.)
  local function spent(text)
    local words = self.manager and self.manager:spentWords(self:gameDay())
    local more = words and text .. " " .. fill_in(pick(LINES.gift_spent), {spent = words})
    return more and #more <= 195 and more or text -- (the server cuts a chat line at 200 letters)
  end
  if not index or world.hospitals[index] == mine then
    line = fill_in(pick(LINES.gift_same_bank), vars)
  else
    local give, most = Bot.giftFor(mine.balance, amount)
    vars.amount, vars.asked = thousands(give), amount and thousands(amount)
    if give > 0 and (not session or session.held) then
      line = fill_in(pick(LINES.gift_later), vars)
    elseif give > 0 then
      session:issue({kind = "give_money", to = index, amount = give})
      if self.manager then self.manager:noteSpent("gift:" .. name, give) end
      if amount and give < amount then
        -- (The most it sends at once, or all it can spare above its floor.)
        local capped = give >= GIVE_MAX
        log(string.format("money for %s: sent $%d, less than the $%d asked (%s; bank $%d)", name, give, amount,
            capped and "the most at once" or "all it can spare", math.floor(mine.balance)))
        line = fill_in(pick(capped and LINES.gift_cap or LINES.gift_part), vars)
        if not capped then line = spent(line) end
      else
        log(string.format("money for %s: sent $%d (asked %s, bank $%d)", name, give, tostring(amount),
            math.floor(mine.balance)))
        line = fill_in(pick(amount and LINES.gift_sent or LINES.gift_sent_auto), vars)
      end
    else
      log(string.format("money for %s: declined (asked %s, bank $%d, most it could send $%d)", name,
          tostring(amount), math.floor(mine.balance), most))
      line = spent(fill_in(pick(LINES.gift_none), vars))
    end
  end
  self:say(line, typing(line), to)
end

-- A plot promised while somebody was on it is offered once nobody is, for at
-- most this many game days (Bot:plotWaitTick).
local PLOT_WAIT_DAYS = 3

--! Asked in the team's chat for a plot (which every bot of the team gets)
--! without a bot named: is it this bot's turn to answer? A plot named: its
--! owner's, if that is an allied bot. Any plot: the allied bot with the
--! emptiest land (MultiplayerSession.landFill) among those with a plot the
--! game would let go (ties: the lower hospital). Else the richest
--! (Bot:isBestDonor). All bots see the same land, so exactly one answers.
function Bot:isPlotDonor(asker_index, plot)
  local world, mine = self.world, self.world.ui.hospital
  local th = world.map.th
  local best, best_fill
  for peer, p in pairs(self.lobby.players or {}) do
    local index = p.bot == "1" and self.lobby.peer_hospital and self.lobby.peer_hospital[peer]
    local h = index and world.hospitals[index]
    if h and index ~= asker_index and
        (h == mine or (world:mpMayTrade(mine, h) and not world:mpRivals(mine, h))) then
      local owner = h:getPlayerIndex()
      if plot then
        if plot >= 1 and plot <= th:getPlotCount() and th:getPlotOwner(plot) == owner then return h == mine end
      else
        local has = false
        for q = 1, th:getPlotCount() do
          local why = th:getPlotOwner(q) == owner and MultiplayerSession.plotRefusal(world, h, q)
          if why == nil or why == "people on the plot" then has = true end
        end
        local fill = has and MultiplayerSession.landFill(world, h)
        if fill and (not best_fill or fill < best_fill or (fill == best_fill and index < best)) then
          best, best_fill = index, fill
        end
      end
    end
  end
  if best then return best == self:hospitalIndex() end
  return self:isBestDonor(asker_index)
end

--! Offer `plot` to hospital `index` for `price`, as a person would (the
--! ally gets the fax).
function Bot:offerPlot(plot, index, price)
  TheApp.mp_session:issue({kind = "offer_plot", to = index, plot = plot, price = price})
  self.manager:notePlotOffered(plot)
end

--! An ally asked in the chat for one of its plots (`plot`, or nil: any it
--! can spare): its manager decides (Manager:plotRequest), the bot offers it
--! as a person would (an offer_plot command: the ally gets the fax) and says
--! one line why, never more. A plot somebody is walking on is offered once
--! nobody is (Bot:plotWaitTick). `to` is where the answer goes.
function Bot:answerPlotRequest(peer, name, plot, to)
  local session = TheApp.mp_session
  local index = self.lobby.peer_hospital and self.lobby.peer_hospital[peer]
  local line
  if not self.manager then
    line = fill_in(pick(Manager.PLOT_ASK_LINES.none), {name = name})
  else
    local v = self.manager:plotRequest(index, plot, GIVE_KEEP, name)
    line = v.line
    if v.give and (not session or session.held) then
      line = fill_in(pick(LINES.gift_later), {name = name})
    elseif v.give and v.wait then
      self.plot_wait = {plot = v.plot, to = index, price = v.price, name = name, reply_to = to,
          until_day = self:gameDay() + PLOT_WAIT_DAYS}
    elseif v.give then
      self:offerPlot(v.plot, index, v.price)
    end
  end
  self:say(line, typing(line), to)
end

--! A plot promised while somebody was on it (Bot:answerPlotRequest): offered
--! as soon as nobody is. After PLOT_WAIT_DAYS, or when it cannot go any more
--! (a room on it, say), it is not, and the ally is told why.
function Bot:plotWaitTick()
  local w = self.plot_wait
  if not w or not self.manager then return end
  local world = self.world
  local why = MultiplayerSession.plotRefusal(world, world.ui.hospital, w.plot, nil, true)
  local to = world.hospitals[w.to]
  if not why and to and MultiplayerSession.plotHandoverRefusal then
    why = MultiplayerSession.plotHandoverRefusal(world, to, w.plot)
  end
  if why == "people on the plot" and self:gameDay() <= w.until_day then return end
  self.plot_wait = nil
  if not why then
    log(string.format("plot %d for %s: nobody on it now, offered for $%d", w.plot, w.name, w.price))
    self:offerPlot(w.plot, w.to, w.price)
    return
  end
  log(string.format("plot %d for %s: not offered after all (%s)", w.plot, w.name, why))
  local key = why == "people on the plot" and "busy" or Manager.PLOT_REFUSED[why] or "none"
  local line = fill_in(pick(Manager.PLOT_ASK_LINES[key]), {name = w.name, plot = w.plot})
  self:say(line, typing(line), w.reply_to)
end

--! The plots this hospital is handing over (an offer waiting for an answer,
--! or one promised once nobody is on it): nothing is built or put on them.
--! A set, worked out once a game step.
function Bot:plotsGiven()
  local session = TheApp.mp_session
  local step = session and session.step
  if self.given_plots and self.given_step == step then return self.given_plots end
  local world = self.world
  local set = {}
  local mine = world.ui.hospital:getPlayerIndex()
  for plot in pairs(world.mp_plot_offers or {}) do
    if world.map.th:getPlotOwner(plot) == mine and Manager.plotOnOffer(world, plot) then set[plot] = true end
  end
  if self.plot_wait then set[self.plot_wait.plot] = true end
  self.given_plots, self.given_step = set, step
  return set
end

--! Money arrived from another player (give_money, seen as it happens).
--! A dirty trick was played (any player's, as the game applies it): who on
--! whom, when (Bot:playTrick waits after another rival's).
function Bot:trickSeen(to_index, kind, from_index)
  if not (to_index and self.world) then return end
  self.tricks_seen = self.tricks_seen or {}
  self.tricks_seen[to_index] = {day = self:gameDay(), kind = kind, by = from_index}
end

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
  -- (A plot it is handing over: Bot:plotsGiven.)
  for plot in pairs(self:plotsGiven()) do
    local tiles = MultiplayerSession.plotTiles(self.world.map.th, plot)
    for i = 1, #tiles, 2 do reserved[tiles[i + 1] * 1000 + tiles[i]] = true end
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

--! Is this tile free floor of this hospital (no room, no object but litter on
--! it, not on a plot it is handing over)?
function Bot:freeTile(x, y)
  local world = self.world
  local th = world.map.th
  local mw, mh = th:size()
  if x < 1 or y < 1 or x > mw or y > mh then return false end
  if self.reserved and self.reserved[y * 1000 + x] then return false end
  if not world.ui.hospital:isInHospital(x, y) or world:getRoom(x, y) or builder.solid_object(world, x, y) then
    return false
  end
  local flags = th:getCellFlags(x, y)
  if self:plotsGiven()[flags.parcelId] then return false end
  return flags.buildable and flags.passable
end

--! The plan an expert left for this hospital's place (bot_learned.lua): the
--! same level, map size, number of hospitals and place among them as a game
--! they played, or nil.
function Bot:learnedPlan()
  local world = self.world
  if not (self.expert_data and world and world.ui and world.ui.hospital) then return nil end
  if self.expert_plan_world ~= world then
    self.expert_plan_world = world
    local w, h = world.map.th:size()
    local key = Learned.planKey(world.map.level_name, w, h, #world.hospitals,
        world:getHospitalIndex(world.ui.hospital))
    self.expert_plan = Learned.plan(self.expert_data, key)
    if self.expert_plan then
      log(string.format("plays %s like %s did (%d rooms in their plan)", key, tostring(self.expert_plan.player),
          #self.expert_plan.rooms))
    end
  end
  return self.expert_plan
end

--! An expert's room of kind `id` from the plan for this place that it can
--! build now: all of it free floor of its own, not refused by the room
--! editor lately (`refused(x, y, w, h)`), clear of the reception's queue and
--! the entrances, and leaving the corridor and its floor in one piece.
function Bot:planSlot(id, refused)
  local plan = self:learnedPlan()
  if not plan then return nil end
  local world, hosp = self.world, self.world.ui.hospital
  local keep = {}
  local function protect(cx, cy, r)
    for ky = cy - r, cy + r do
      for kx = cx - r, cx + r do keep[ky * 1000 + kx] = true end
    end
  end
  for _, desk in ipairs(hosp:getReceptionDesks()) do
    if desk.tile_x then protect(desk.tile_x, desk.tile_y, 2) end
  end
  for _, e in ipairs(world.entities) do
    local oid = e.object_type and e.object_type.id
    if oid and oid:find("entrance", 1, true) and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) then
      protect(e.tile_x, e.tile_y, 2)
    end
  end
  for _, slot in ipairs(Learned.slots(plan, id)) do
    local ok = not (refused and refused(slot.x, slot.y, slot.w, slot.h))
    for ty = slot.y, slot.y + slot.h - 1 do
      for tx = slot.x, slot.x + slot.w - 1 do
        if ok and (keep[ty * 1000 + tx] or not self:freeTile(tx, ty)) then ok = false end
      end
    end
    if ok and self:keepsCorridor(slot.x, slot.y, slot.w, slot.h) and
        self:roomKeepsFloor(slot.x, slot.y, slot.w, slot.h) then
      return slot
    end
  end
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

-- A room asked for "next to" something is built within this many tiles of it,
-- else the normal place is used and the person told.
local NEAR_MAX_GAP = 8
-- Spots for a room checked against its whole floor (Bot:roomKeepsFloor) in one
-- search at most.
local FLOOR_TRIES = 60
-- Points off a room's spot for each tile of a one tile wide gap it leaves.
local THIN_GAP = 4

--! Where a player would put a w x h room (squares from `size` down to
--! `min`, and one tile shorter): against the building's walls and the other
--! rooms, in rows, with a corridor in front of the door (the row below it;
--! two rows if possible), without thin gaps that nothing fits into, near the
--! reception, and never on the reception's or the entrances' floor.
--! With `near` (a list of {x0, y0, x1, y1} rectangles: the room, desk or door
--! a person asked to build beside) only spots within NEAR_MAX_GAP tiles of one
--! of them count, and the nearer the better.
--!return x, y, w, h or nil
--!param shapes (list) optional {{w, h, side}, ...}: only these sizes (an
--!  expert's room), each with the corridor (the door) on `side` (default south)
--!return x, y, w, h, side
function Bot:layoutSpot(min, size, near, shapes)
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
  if not shapes then
    shapes = {}
    for s = size, min, -1 do
      shapes[#shapes + 1] = {s, s}
      if s - 1 >= min then shapes[#shapes + 1] = {s, s - 1} end
    end
  end
  for _, shape in ipairs(shapes) do
    local w, h, side = shape[1], shape[2], shape[3] or "south"
    -- The room, and the row (or column) on its door's side: the corridor
    -- (that may be floor kept clear, it is corridor anyway).
    local sx0, sy0, sx1, sy1 = 0, 0, w - 1, h -- (south: the row below)
    if side == "north" then sy0, sy1 = -1, h - 1
    elseif side == "east" then sx1, sy1 = w, h - 1
    elseif side == "west" then sx0, sy1 = -1, h - 1 end
    for y = y0 - sy0, y1 - sy1 do
      for x = x0 - sx0, x1 - sx1 do
        local ok = true
        for ty = y + sy0, y + sy1 do
          for tx = x + sx0, x + sx1 do
            local strip = ty < y or ty >= y + h or tx < x or tx >= x + w
            if not f(tx, ty) and not (strip and keep[ty * 1000 + tx]) then ok = false break end
          end
          if not ok then break end
        end
        if ok then
          -- (Against walls and other rooms, and the size asked: the
          -- smallest only where nothing bigger fits snugly.)
          local score = w * h * 0.5
          -- (A gap one tile wide beside it: nothing fits in it, and as a
          -- corridor patients jam in it and no bench fits. Worse than a wall
          -- touched is good, on the door's side too. Jan, 2026-11-13: Agnes
          -- reached her rooms on the left through one narrow passage.)
          for tx = x, x + w - 1 do
            if solid(tx, y - 1) then score = score + 1.5 end
            if f(tx, y - 1) and solid(tx, y - 2) then score = score - THIN_GAP end
            if solid(tx, y + h) then score = score + 1.5 end
            if f(tx, y + h) and solid(tx, y + h + 1) then score = score - THIN_GAP end
            if side == "south" and f(tx, y + h + 1) then score = score + 0.3 end
          end
          for ty = y, y + h - 1 do
            if solid(x - 1, ty) then score = score + 1.5 end
            if solid(x + w, ty) then score = score + 1.5 end
            if f(x - 1, ty) and solid(x - 2, ty) then score = score - THIN_GAP end
            if f(x + w, ty) and solid(x + w + 1, ty) then score = score - THIN_GAP end
          end
          score = score - 0.12 * (math.abs(x + w / 2 - ax) + math.abs(y + h / 2 - ay))
          if near then
            -- Tiles between the spot and the nearest anchor (0: they touch).
            local gap
            for _, r in ipairs(near) do
              local g = math.max(0, r[1] - (x + w - 1), x - r[3]) + math.max(0, r[2] - (y + h - 1), y - r[4])
              if not gap or g < gap then gap = g end
            end
            if gap and gap <= NEAR_MAX_GAP then
              score = score - 1.5 * gap
              spots[#spots + 1] = {score, x, y, w, h, side}
            end
          else
            spots[#spots + 1] = {score, x, y, w, h, side}
          end
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
  -- (And its own floor stays one piece with every door on it, Bot:roomKeepsFloor:
  -- a scan of the floor per spot, so at most FLOOR_TRIES of them.)
  local floor_tries = 0
  for i, spot in ipairs(spots) do
    if self:keepsCorridor(spot[2], spot[3], spot[4], spot[5]) then
      floor_tries = floor_tries + 1
      if floor_tries > FLOOR_TRIES then
        log(string.format("layout: %d spots would cut its floor in two; no more tried", FLOOR_TRIES))
        return nil
      end
      if self:roomKeepsFloor(spot[2], spot[3], spot[4], spot[5]) then
        if i > 1 then log(string.format("layout: %d better spots would cut the corridor or the floor in two", i - 1)) end
        return spot[2], spot[3], spot[4], spot[5], spot[6]
      end
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

--! Its hospital's floor for Manager.floorParts: the corridor tiles of its own
--! building (in no room) one can walk on and those an object stands on, each
--! with the sides one can cross (the game's travel flags), and the places
--! that must be reached: its entrances, both sides of each reception desk
--! (patients and receptionist) and the tile before each room's door. Made
--! once a game step (a scan of the map), so only when the bot is about to put
--! something down.
function Bot:floorMap()
  local world, session = self.world, TheApp.mp_session
  local step = session and session.step
  local cache = self.floor_cache
  if cache and cache.world == world and cache.step == step then return cache.floor end
  local hosp = world.ui.hospital
  local th = world.map.th
  local mw, mh = th:size()
  local me = hosp:getPlayerIndex()
  local W = Manager.FLOOR_W
  local rooms = world.rooms
  local walk, held, flags = {}, {}, {}
  for y = 1, mh do
    for x = 1, mw do
      th:getCellFlags(x, y, flags)
      local room_id = flags.roomId or 0
      if flags.hospital and flags.owner == me and (room_id == 0 or not rooms[room_id]) then
        local bits = (flags.travelNorth and 1 or 0) + (flags.travelEast and 2 or 0) +
            (flags.travelSouth and 4 or 0) + (flags.travelWest and 8 or 0)
        if flags.passable then walk[y * W + x] = bits else held[y * W + x] = bits end
      end
    end
  end
  local targets, seen = {}, {}
  local counts = {entrances = 0, desks = 0, doors = 0} -- (for the month's log line)
  local function target(k, kind)
    if k and (walk[k] or held[k]) and not seen[k] then
      seen[k] = true
      targets[#targets + 1] = k
      counts[kind] = counts[kind] + 1
    end
  end
  -- (An entrance door stands on the tile south or east of its wall: the
  -- floor inside may be the tile on the other side.)
  for _, e in ipairs(world.entities) do
    local id = e.object_type and e.object_type.id
    if (id == "entrance_left_door" or id == "entrance_right_door") and e.tile_x then
      local k = e.tile_y * W + e.tile_x
      if not (walk[k] or held[k]) then k = e.direction == "west" and k - 1 or k - W end
      target(k, "entrances")
    end
  end
  -- (A desk: where its patients stand, and its receptionist.)
  for _, desk in ipairs(hosp:getReceptionDesks()) do
    local o = desk.tile_x and desk.object_type.orientations[desk.direction]
    for _, use in ipairs(o and {o.use_position, o.use_position_secondary} or {}) do
      target((desk.tile_y + use[2]) * W + desk.tile_x + use[1], "desks")
    end
  end
  local own = {}
  for _, rm in pairs(rooms) do
    if rm.hospital == hosp and rm.door and rm.door.tile_x and not rm.crashed then own[#own + 1] = rm end
  end
  table.sort(own, function(a, b) return a.id < b.id end)
  for _, rm in ipairs(own) do
    local ok, x, y = pcall(rm.getEntranceXY, rm, false)
    if ok and x then target(y * W + x, "doors") end
  end
  local floor = {walk = walk, held = held, targets = targets, counts = counts}
  floor.parts = Manager.floorParts(floor)
  self.floor_cache = {world = world, step = step, floor = floor}
  return floor
end

--! Would `change` (Manager.objectChange: an object put down) leave the
--! hospital's floor in no more parts than now (Bot:floorMap)? `extra`
--! (optional): more tiles that must be reached (a new desk's two sides).
function Bot:floorKept(floor, change, extra)
  if not extra then return Manager.floorParts(floor, change) <= floor.parts end
  local with = {walk = floor.walk, held = floor.held, targets = {}}
  for _, k in ipairs(extra) do with.targets[#with.targets + 1] = k end
  for _, k in ipairs(floor.targets) do with.targets[#with.targets + 1] = k end
  return Manager.floorParts(with, change) <= Manager.floorParts(with)
end

--! Would a w x h room at x, y keep the hospital's floor in one piece
--! (Bot:floorKept) and open onto it: some tile along its sides reached from
--! the entrances, the desks and the other rooms, where its door can go?
function Bot:roomKeepsFloor(x, y, w, h)
  local floor = self:floorMap()
  local W = Manager.FLOOR_W
  local change = {block = {}}
  for ty = y, y + h - 1 do
    for tx = x, x + w - 1 do change.block[ty * W + tx] = true end
  end
  local after, part = Manager.floorParts(floor, change)
  if after > floor.parts then return false end
  if #floor.targets == 0 then return true end
  for tx = x, x + w - 1 do
    if part[(y - 1) * W + tx] or part[(y + h) * W + tx] then return true end
  end
  for ty = y, y + h - 1 do
    if part[ty * W + x - 1] or part[ty * W + x + w] then return true end
  end
  return false
end

--! The corridor objects of its hospital but the reception desks (which a bot
--! may sell): all of them taken away, as a Manager.objectChange, and which
--! object stands on each tile or closes each side.
--!return away, object by tile key, object by side key
function Bot:floorObjects()
  local world = self.world
  local hosp = world.ui.hospital
  local away, by_tile, by_side = {open = {}, join = {}}, {}, {}
  for _, e in ipairs(world.entities) do
    local ot = e.object_type
    if ot and ot.corridor_object and ot.id ~= "reception_desk" and e.tile_x and e.mp_id and e.direction and
        hosp:isInHospital(e.tile_x, e.tile_y) and not world:getRoom(e.tile_x, e.tile_y) then
      local one = Manager.objectChange(ot, e.tile_x, e.tile_y, e.direction, nil, true)
      for k in pairs(one.open or {}) do by_tile[k], away.open[k] = e, true end
      for k in pairs(one.join or {}) do by_side[k], away.join[k] = e, true end
    end
  end
  return away, by_tile, by_side
end

--! Its floor in words for the month's log line: in how many parts, in how
--! many it would be without its corridor objects (more than that: objects
--! cut it), and what must be reached. (A plot bought is often a building of
--! its own, with its own entrance: a part of its own.)
function Bot:floorReport()
  local floor = self:floorMap()
  local c = floor.counts
  return string.format("%d part(s) (%d without its corridor objects), to reach %d entrance tile(s), %d desk side(s),"
      .. " %d door(s)", floor.parts, Manager.floorParts(floor, (self:floorObjects())), c.entrances, c.desks, c.doors)
end

--! A floor already in pieces (from an older game, or objects put down before
--! the bot checked): the corridor object that stands first in the way
--! between two parts (Manager.floorBlocker) is sold, with the sell_object
--! command a person's click sends (its price comes back; the waiting-area
--! rules buy what is missing again where it fits). Never a reception desk.
--! One object a call (Manager:daily).
--!return a line for the log when it sold something, else nil
function Bot:repairFloor()
  local session = TheApp.mp_session
  if not session or session.held or not MultiplayerSession.default_handlers.sell_object then return nil end
  local floor = self:floorMap()
  if floor.parts <= 1 then return nil end
  local away, by_tile, by_side = self:floorObjects()
  local kind, key = Manager.floorBlocker(floor, away)
  local e = kind == "tile" and by_tile[key] or kind == "side" and by_side[key] or nil
  if not e then return nil end
  session:issue({kind = "sell_object", object = e.mp_id})
  return string.format("its floor is in %d parts: sold the %s at %d,%d, which was in the way",
      floor.parts, e.object_type.id, e.tile_x, e.tile_y)
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
-- Game days a spot the room editor refused is left alone.
local REFUSED_SPOT_DAYS = 90

--! The tiles a person means by "next to the <place>": rectangles {x0, y0,
--! x1, y1} of the reception desks, the entrance doors, or the rooms of that
--! type (`place`: "reception", "entrance" or a room id), in a fixed order.
function Bot:nearRects(place)
  local world, hosp = self.world, self.world.ui.hospital
  local out = {}
  if place == "reception" then
    for _, desk in ipairs(hosp:getReceptionDesks()) do
      if desk.tile_x then out[#out + 1] = {desk.tile_x, desk.tile_y, desk.tile_x, desk.tile_y} end
    end
  elseif place == "entrance" then
    for _, e in ipairs(world.entities) do
      local id = e.object_type and e.object_type.id
      if id and id:find("entrance", 1, true) and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) then
        out[#out + 1] = {e.tile_x, e.tile_y, e.tile_x, e.tile_y}
      end
    end
    table.sort(out, function(a, b) return a[2] < b[2] or (a[2] == b[2] and a[1] < b[1]) end)
  else
    for _, rm in pairs(world.rooms) do
      if rm.hospital == hosp and rm.is_active and not rm.crashed and rm.room_info.id == place then
        out[#out + 1] = {rm.x, rm.y, rm.x + rm.width - 1, rm.y + rm.height - 1, rm.id}
      end
    end
    table.sort(out, function(a, b) return a[5] < b[5] end)
  end
  return out
end

--!param near (string) optional: "reception", "entrance" or a room id: build the
--! room as close to that as it fits (within NEAR_MAX_GAP tiles). When nothing
--! fits there, the normal place is used and `self.near_missed` is set.
function Bot:drawRoom(room_type, size, extras, near)
  local hospital = self.world.ui.hospital
  if self.furnishing then return nil, "busy" end
  if hospital.balance - self:roomCost(room_type) < RESERVE then return nil, "money" end
  local min = math.max(room_type.minimum_size or 4, SMALLEST[room_type.id] or 0)
  -- (Four desks need a bigger room: a 5 x 5 one took two, a 7 x 7 one three.
  -- Bot.research_heavy, Manager.roomPlan.)
  if (self.research_heavy or self.level == "hard") and room_type.id == "research" then min = math.max(min, 6) end
  local ax, ay = self:anchor()
  size = math.max(min, size or min + 1) -- (one more than the smallest: room for a plant)
  self.reserved = self:reservedTiles()
  -- Spots the room editor refused lately (it would cut off part of the
  -- hospital): the same search found the same spot every time, and Bot Agnes
  -- drew a hair restoration room there six times in 60 days (eu2).
  local today = self:gameDay()
  local function refused(fx, fy, fw, fh)
    local day = self.refused_spots and self.refused_spots[string.format("%d,%d,%d,%d", fx, fy, fw, fh)]
    return day and today - day < REFUSED_SPOT_DAYS
  end
  local x, y, w, h
  -- An expert's room (bot_learned.lua): on the same map and place as an
  -- expert played, their spot for it; else their size and door, the layout
  -- put in afterwards (Bot:furnishTick).
  local layout, door_pref
  -- (The smart brain only: the fixed plan's rooms are furnished by the game.)
  if self.expert_data and self.manager and not near then
    local slot = self:planSlot(room_type.id, refused)
    if slot then
      x, y, w, h = slot.x, slot.y, slot.w, slot.h
      layout = {w = slot.fw, d = slot.fd, layouts = {{w = slot.fw, d = slot.fd, wall = slot.wall,
          col = slot.door, objects = slot.objects}}}
      door_pref = {wall = slot.wall, col = slot.door}
      log(string.format("%s where the expert had it: %dx%d at %d,%d (door in the %s wall)", room_type.id,
          w, h, x, y, slot.wall))
    else
      local recipe = Learned.recipe(self.expert_data, room_type.id, size, 0)
      if recipe and math.max(recipe.w, recipe.d) >= size - 1 then
        -- A spot with the corridor on the side of a door wall the expert used
        -- (their layout fits that room exactly), else on any side.
        local shapes, by_side = {}, {}
        for _, v in ipairs(recipe.variants or {}) do
          if not by_side[v.wall] then
            by_side[v.wall] = v
            local across = v.wall == "north" or v.wall == "south"
            shapes[#shapes + 1] = {across and recipe.w or recipe.d, across and recipe.d or recipe.w, v.wall}
          end
        end
        if #shapes == 0 then shapes[1] = {recipe.w, recipe.d, "south"} end
        local ok_l, lx, ly, lw, lh, side = pcall(self.layoutSpot, self, min, size, nil, shapes)
        if ok_l and lx and not refused(lx, ly, lw, lh) then
          x, y, w, h = lx, ly, lw, lh
          layout = {w = recipe.w, d = recipe.d, layouts = Learned.layouts(recipe)}
          local v = by_side[side]
          door_pref = v and {wall = v.wall, col = v.col} or {width = recipe.w, cols = {recipe.door, recipe.w - 1 - recipe.door}}
          log(string.format("%s as the expert builds it: %dx%d at %d,%d, door in the %s wall", room_type.id,
              w, h, x, y, tostring(side)))
        elseif not ok_l then
          log("layout: " .. tostring(lx))
        end
      end
    end
  end
  -- Beside what a person asked for, if it fits within reach.
  self.near_missed = nil
  if near then
    local rects = self:nearRects(near)
    local ok_near, nx, ny, nw, nh = true
    if #rects > 0 then ok_near, nx, ny, nw, nh = pcall(self.layoutSpot, self, min, size, rects) end
    if ok_near and nx and not refused(nx, ny, nw, nh or nw) then
      x, y, w, h = nx, ny, nw, nh
      log(string.format("%s next to the %s (%d anchors, the first at %d,%d-%d,%d): %dx%d at %d,%d", room_type.id, near,
          #rects, rects[1][1], rects[1][2], rects[1][3], rects[1][4], nw, nh or nw, nx, ny))
    else
      if not ok_near then log("layout: " .. tostring(nx)) end
      self.near_missed = near
      log(string.format("no place for a %s next to the %s: the normal place", room_type.id, near))
    end
  end
  -- Where a player would put it (against walls and rooms, in rows).
  if not x then
    local ok_layout, lx, ly, lw, lh = pcall(self.layoutSpot, self, min, size)
    if ok_layout and lx and not refused(lx, ly, lw, lh or lw) then
      x, y, w, h = lx, ly, lw, lh
    elseif not ok_layout then
      log("layout: " .. tostring(lx))
    end
  end
  -- Else a free tile more below and to the right (where the door goes), so
  -- the corridor in front of it is two tiles wide.
  -- (Each only if it leaves the corridor in one piece.)
  local function try(s, fx, fy)
    if x or not fx or refused(fx, fy, s, s) then return end
    for ty = fy, fy + s - 1 do
      for tx = fx, fx + s - 1 do
        if self.reserved[ty * 1000 + tx] then return end -- (a room being edited, an outline)
      end
    end
    if self:keepsCorridor(fx, fy, s, s) and self:roomKeepsFloor(fx, fy, s, s) then x, y, w = fx, fy, s end
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
  -- (A size other than the expert's: no layout of theirs.)
  if layout and not ((w == layout.w and (h or w) == layout.d) or (w == layout.d and (h or w) == layout.w)) then
    layout, door_pref = nil, nil
  end
  local by_hand = (extras and next(extras) ~= nil) or layout ~= nil
  local ok, res = pcall(builder.ui_room, self.world, ax, ay, room_type.id, w, h or w, true, log, {x, y}, by_hand,
      {ax, ay}, door_pref)
  if not ok then log("could not draw " .. room_type.id .. ": " .. tostring(res)) end
  if ok and res then
    if by_hand then self.furnishing = {extras = extras or {}, room_id = room_type.id, layout = layout} end
    return true
  end
  self.refused_spots = self.refused_spots or {}
  self.refused_spots[string.format("%d,%d,%d,%d", x, y, w, h or w)] = today
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

-- What a player puts in a corner or against a wall of a room, never in the
-- middle (a sink too: Jan, 2026-11-12).
local AGAINST_WALL = {plant = true, bin = true, radiator = true, bookcase = true, extinguisher = true, skeleton = true,
    sink = true}

--! Edit one of this hospital's rooms like a person would (a team mate asked
--! for it): steps as in builder.edit_tick ("buy:skeleton", "place", "done";
--! "resize:1:1", "place", "done"). False if another edit is going on.
function Bot:editRoom(rm, steps)
  if self.editing or self.furnishing then return false, "busy" end
  self.editing = {room_type = rm.room_info.id, room_id = rm.id, steps = steps}
  log(string.format("editing %s #%d: %s", rm.room_info.id, rm.id, table.concat(steps, ", ")))
  return true
end

--! Game days a room whose shrink failed is left alone (Bot:editTick).
local SHRINK_RETRY_DAYS = 120

--! A room of its own bigger than it needs, and the side of it to take in:
--! the room with the most floor over `size_of(room id)` (its planned size);
--! the side whose last row or column has the fewest things in it (they are
--! put back elsewhere in the room). Only a side whose freed row or column
--! joins a corridor: a strip shut in by the outer wall and other rooms is
--! refused by the room editor (Bot Bertie's ward, four tries in one game,
--! 2026-11-11). Only a room with no patient in it: the editor opens once the
--! room is empty, and an operating theatre in use stayed closed for ten days
--! before the edit was given up (Bot Agnes). Returns room, side or nil.
function Bot:oversizedRoom(size_of)
  local world, hospital = self.world, self.world.ui.hospital
  local th = world.map.th
  local today = self:gameDay()
  local best, best_side, best_excess
  for _, rm in pairs(world.rooms) do
    local id = rm.room_info.id
    local want = size_of(id) or (rm.room_info.minimum_size or 4) + 1
    local failed = self.edit_failed and self.edit_failed[rm.id]
    if rm.hospital == hospital and rm.built and rm.is_active and not rm.crashed and
        (rm.width > want or rm.height > want) and rm:getPatientCount() == 0 and
        not (failed and today - failed < SHRINK_RETRY_DAYS) then
      local function things(x0, y0, x1, y1)
        local n = 0
        for ty = y0, y1 do
          for tx = x0, x1 do
            if world:getObject(tx, ty) then n = n + 1 end
          end
        end
        return n
      end
      -- Does the strip x0,y0-x1,y1 (to be freed) touch corridor floor
      -- outside the room (dx, dy: the way out of the room from it)?
      local function joins(sx0, sy0, sx1, sy1, dx, dy)
        local function open(tx, ty)
          if not hospital:isInHospital(tx, ty) or world:getRoom(tx, ty) then return false end
          return th:getCellFlags(tx, ty).passable
        end
        for ty = sy0, sy1 do
          for tx = sx0, sx1 do
            if open(tx + dx, ty + dy) then return true end
          end
        end
        -- (Its two ends, past the room's corners.)
        if dx ~= 0 then return open(sx0, sy0 - 1) or open(sx1, sy1 + 1) end
        return open(sx0 - 1, sy0) or open(sx1 + 1, sy1)
      end
      local x0, y0, x1, y1 = rm.x, rm.y, rm.x + rm.width - 1, rm.y + rm.height - 1
      local side, fewest
      local function consider(name, n, ok)
        if ok and (not fewest or n < fewest) then side, fewest = name, n end
      end
      if rm.width > want then
        consider("right", things(x1, y0, x1, y1), joins(x1, y0, x1, y1, 1, 0))
        consider("left", things(x0, y0, x0, y1), joins(x0, y0, x0, y1, -1, 0))
      end
      if rm.height > want then
        consider("top", things(x0, y0, x1, y0), joins(x0, y0, x1, y0, 0, -1))
        consider("bottom", things(x0, y1, x1, y1), joins(x0, y1, x1, y1, 0, 1))
      end
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
  if builder.edit_tick(self.world, self.editing, log) then
    -- (A shrink that did not work is not tried on that room again for a
    -- while: each try closes the room, Bot:oversizedRoom.)
    if self.editing.failed and self.editing.room_id then
      self.edit_failed = self.edit_failed or {}
      self.edit_failed[self.editing.room_id] = self:gameDay()
    end
    self.editing = nil
  end
  return true
end

-- Colder than this on the heat map (0..1; 50 is degrees: 0.25 is 12.5, a
-- patient is cold below 0.22) a radiator is wanted.
Bot.COLD = 0.25

--! The average of the heat map over its hospital's tiles within r of x, y
--! (nil: none of them).
function Bot:temperatureAround(x, y, r)
  local th, hosp = self.world.map.th, self.world.ui.hospital
  local sum, n = 0, 0
  for ty = y - r, y + r do
    for tx = x - r, x + r do
      if hosp:isInHospital(tx, ty) then
        sum, n = sum + th:getCellTemperature(tx, ty), n + 1
      end
    end
  end
  return n > 0 and sum / n or nil
end

--! Is it cold there on the heat map (a radiator wanted)?
function Bot:coldAround(x, y, r)
  local t = self:temperatureAround(x, y, r)
  return t ~= nil and t < Bot.COLD
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
    for id, wanted in pairs(job.extras) do
      -- (A second or third radiator, as an expert puts in a big room, only
      -- where the heat map is cold: Jan, 2026-11-13.)
      local n = wanted
      local r = dlg.room
      if id == "radiator" and n > 1 and r and r.width and
          not self:coldAround(r.x + math.floor(r.width / 2), r.y + math.floor(r.height / 2),
              math.floor(math.max(r.width, r.height) / 2)) then
        n = 1
      end
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
      log(string.format("furnished %s #%d%s", job.room_id, dlg.mp_room_id,
          job.spots and string.format(" (%d of its %d objects at the expert's places)", job.learned_placed or 0,
              job.total or 0) or ""))
      dlg:confirm()
    else
      log("furnishing: " .. job.room_id .. " cannot be finished; cancelled")
      dlg:cancel()
    end
    self.furnishing = nil
    return false
  end
  job.tried = job.tried or {}
  job.total = job.total or count()
  local rm = dlg.room
  -- The expert's layout (bot_learned.lua): each object where theirs stood,
  -- seen from the door; mirrored when this door is at the other end.
  if job.layout and job.spots == nil then
    job.spots = false
    local door = rm.door
    if door and door.tile_x then
      local f = Learned.frame(rm.x, rm.y, rm.width, rm.height, door.tile_x, door.tile_y, door.direction)
      local placed, n = Learned.best(job.layout.layouts, f, TheApp.objects)
      if placed then
        job.spots = placed
        log(string.format("furnishing %s #%d as the expert does (door in the %s wall at column %d; %d of the %d " ..
            "objects fit their tiles)", job.room_id, dlg.mp_room_id, f.wall, f.col, n, #placed))
      else
        log(string.format("furnishing %s #%d: its door (column %d of %d, %d deep) suits none of the expert's " ..
            "layouts (%d wide, %d deep)", job.room_id, dlg.mp_room_id, f.col, f.W, f.D, job.layout.w, job.layout.d))
      end
    end
  end
  for i, spot in ipairs(job.spots or {}) do
    local key = "learned:" .. i
    -- (A sink, plant, bin or the like the expert had in the middle of the
    -- room goes against a wall instead: the rules below. Jan, 2026-11-12:
    -- a sink in the middle of the toilets, as in Argus's.)
    if spot.id == o.object.id and not job.tried[key] and AGAINST_WALL[spot.id] then
      local edge = false
      for _, t in ipairs(spot.tiles) do
        if t[1] == rm.x or t[2] == rm.y or t[1] == rm.x + rm.width - 1 or t[2] == rm.y + rm.height - 1 then
          edge = true
        end
      end
      if not edge then job.tried[key] = true end
    end
    if spot.id == o.object.id and not job.tried[key] then
      job.tried[key] = true
      local ox, oy = Learned.origin(o.object, spot.dir, spot.tiles)
      if ox and o.object.orientations[spot.dir] then
        dlg:setActiveIndex(1)
        dlg:setOrientation(spot.dir)
        dlg:setBlueprintCell(ox, oy)
        if dlg.object_blueprint_good and not world:anyHumanoidObscuringArea(ox, oy) then
          job.learned_placed = (job.learned_placed or 0) + 1
          job.pending = {count = count(), by_step = step + session.delay + 3}
          dlg:placeObject()
          return true
        end
      end
    end
  end
  -- Where a player puts things: the furniture against the walls first; a
  -- plant, bin, radiator, bookcase or extinguisher only into a corner or
  -- against a wall, never in the middle of the room.
  local small = AGAINST_WALL
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

-- Each plot's bounding box {x1, y1, x2, y2}, per map (the plots never change).
local plot_boxes = setmetatable({}, {__mode = "k"})
local function plot_box(th, plot)
  local boxes = plot_boxes[th]
  if not boxes then
    boxes = {}
    plot_boxes[th] = boxes
  end
  local b = boxes[plot]
  if not b then
    local t = MultiplayerSession.plotTiles(th, plot)
    b = {math.huge, math.huge, -math.huge, -math.huge}
    for i = 1, #t, 2 do
      b[1], b[2] = math.min(b[1], t[i]), math.min(b[2], t[i + 1])
      b[3], b[4] = math.max(b[3], t[i]), math.max(b[4], t[i + 1])
    end
    boxes[plot] = b
  end
  return b
end

--! How far a plot is from this hospital's land, in tiles (0: it touches it):
--! from the nearest of its tiles to the nearest plot the hospital owns.
function Bot:plotDistance(plot)
  local th = self.world.map.th
  local me = self.world.ui.hospital:getPlayerIndex()
  local owned = {}
  for p = 1, th:getPlotCount() do
    if th:getPlotOwner(p) == me then owned[#owned + 1] = plot_box(th, p) end
  end
  if #owned == 0 then return 0 end
  local t = MultiplayerSession.plotTiles(th, plot)
  local best = math.huge
  for i = 1, #t, 2 do
    local x, y = t[i], t[i + 1]
    for _, b in ipairs(owned) do
      local d = math.max(0, b[1] - x, x - b[3]) + math.max(0, b[2] - y, y - b[4])
      if d < best then best = d end
    end
    if best <= 1 then break end
  end
  return best
end

--! The plot this hospital would buy next and its price, or nil: the
--! nearest to its land (so the hospital stays in one piece; Jan, 2026-11-13:
--! Clive bought the cheapest, far across the map), the cheaper of two as
--! near. On its own side of the map; with none left there and its land
--! filling up (or a room that did not fit in the last month), on another's
--! side too (that goes to auction). (The name is from when it was the
--! cheapest.)
function Bot:cheapestPlot()
  local world = self.world
  local th, hospital = world.map.th, world.ui.hospital
  local me = world:getHospitalIndex(hospital)
  local function cheapest(anywhere)
    local best, best_price, best_d
    for plot = 1, th:getPlotCount() do
      local side = world.mp_coop and MultiplayerSession.plotSide(world, plot)
      if (anywhere or not side or side == me) and th:isParcelPurchasable(plot, hospital:getPlayerIndex()) then
        local price = world.map:getParcelPrice(plot)
        local d = self:plotDistance(plot)
        if not best or d < best_d or (d == best_d and price < best_price) then
          best, best_price, best_d = plot, price, d
        end
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
  log(string.format("buying plot %d for $%d (%d tiles from our land)", best, best_price, self:plotDistance(best)))
  TheApp.mp_session:issue({kind = "buy_plot", plot = best})
  -- (Bought for rooms to come: kept if an ally asks for it soon, Manager:plotRequest.)
  if self.manager then self.manager:notePlotBought(best) end
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
  -- The entrance the patients come in by: the shortest walk from where they
  -- come onto the map (World.spawn_points). (Jan, 2026-11-12: a bot put its
  -- desk at the door to the helipad, where no patient comes; the first door
  -- on the map was the one taken.)
  local door = doors[1]
  if self.entrance_world ~= world then
    self.entrance_world, self.entrance = world, nil
    -- (One door of each doorway, and every fourth place patients come
    -- from: a few dozen walks, once a game.)
    local best, seen = nil, {}
    local spawns = world.spawn_points or {}
    for _, d in ipairs(doors) do
      local twin = false
      for _, s in ipairs(seen) do
        if math.abs(s.tile_x - d.tile_x) + math.abs(s.tile_y - d.tile_y) <= 2 then twin = true end
      end
      if not twin then
        seen[#seen + 1] = d
        for k = 1, #spawns, 4 do
          local sp = spawns[k]
          local walk = world:getPathDistance(sp.x, sp.y, d.tile_x, d.tile_y)
          if walk and (not best or walk < best) then best, self.entrance = walk, d end
        end
      end
    end
    if self.entrance then
      log(string.format("the patients' entrance: %d,%d (%d tiles from where they come)", self.entrance.tile_x,
          self.entrance.tile_y, best))
    end
  end
  door = self.entrance or door
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
  -- A wall: outside the building, a room, or floor nobody can walk that
  -- nothing stands on. (Not a bench or a drinks machine: plants and benches
  -- went beside them in the open floor as if against a wall; Argus,
  -- 2026-11-14.)
  local function wall(tx, ty)
    if not hosp:isInHospital(tx, ty) or world:getRoom(tx, ty) ~= nil then return true end
    if world.map.th:getCellFlags(tx, ty).passable then return false end
    return #(world:getObjects(tx, ty) or {}) == 0
  end
  -- Radiators and plants keep apart (CORRIDOR_GAPS; the learned ones first).
  local gap = CORRIDOR_GAPS[object_id]
  -- (What experts do: a hard bot's, as its rooms. Jan, 2026-11-12.)
  local habits = self.expert_data and self.expert_data.corridor
  if gap and habits and tonumber(habits[object_id .. "_gap"]) then gap = tonumber(habits[object_id .. "_gap"]) end
  local same = {}
  if gap then
    for _, e in ipairs(world.entities) do
      if e.object_type and e.object_type.id == object_id and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) and
          not world:getRoom(e.tile_x, e.tile_y) then
        same[#same + 1] = e
      end
    end
  end
  -- Drinks machines spread out: none within DRINKS_APART tiles of another of
  -- this hospital's (Matroftt, 2026-11-07: rows of them by the reception).
  local apart = {}
  if object_id == "drinks_machine" then
    for _, e in ipairs(world.entities) do
      if e.object_type and e.object_type.id == object_id and e.tile_x and hosp:isInHospital(e.tile_x, e.tile_y) then
        apart[#apart + 1] = e
      end
    end
  end
  -- Its own floor stays in one piece with the entrances, the desks and every
  -- room's door on it (Bot:floorKept; Argus, 2026-11-08: benches and drinks
  -- machines had cut a bot's hospital in two). A new desk's two sides
  -- (patients, receptionist) must be reached too.
  local object_type = place.objects[1].object
  local floor, cuts = nil, 0
  local function keeps_floor(tx, ty, facing)
    floor = floor or self:floorMap()
    local o = object_type.orientations[facing]
    local extra
    if object_id == "reception_desk" and o then
      extra = {}
      for _, use in ipairs({o.use_position, o.use_position_secondary}) do
        extra[#extra + 1] = (ty + use[2]) * Manager.FLOOR_W + tx + use[1]
      end
    end
    local ok = self:floorKept(floor, Manager.objectChange(object_type, tx, ty, facing), extra)
    if not ok then cuts = cuts + 1 end
    return ok
  end
  local given = self:plotsGiven()
  -- A bench with its back to a wall, facing the corridor, so benches stand
  -- in rows along the walls (Jan, 2026-11-12: Bertie's stood in a block at a
  -- door, each facing another way). Its front is its tile people use.
  local function back_to_wall(tx, ty)
    local out = {}
    for _, facing in ipairs(facings) do
      local front
      for _, t in ipairs(object_type.orientations[facing].footprint or {}) do
        if t.only_passable then front = t end
      end
      if front and wall(tx - front[1], ty - front[2]) and not wall(tx + front[1], ty + front[2]) then
        out[#out + 1] = facing
      end
    end
    return out
  end
  -- (With no such spot free near the door, a bench elsewhere, as long as
  -- the floor stays in one piece: better than patients standing. Jan,
  -- 2026-11-13: Agnes found no place for a bench 28 times.) Then it faces
  -- the door, and first beside a bench facing the same way, so that they
  -- stand in rows (Argus, 2026-11-14: they stood every way round).
  local loose, want_row = false, false
  local function spaced(tx, ty)
    for _, e in ipairs(same) do
      if math.max(math.abs(e.tile_x - tx), math.abs(e.tile_y - ty)) < gap then return false end
    end
    return true
  end
  local function front_of(facing)
    for _, t in ipairs(object_type.orientations[facing].footprint or {}) do
      if t.only_passable then return t end
    end
  end
  local function toward_door(tx, ty)
    if not near_x then return facings end
    local scored = {}
    for _, facing in ipairs(facings) do
      local front = front_of(facing)
      local dot = front and (front[1] * (near_x - tx) + front[2] * (near_y - ty)) or -1
      if dot > 0 then scored[#scored + 1] = {facing, dot} end
    end
    table.sort(scored, function(a, b) return a[2] > b[2] or (a[2] == b[2] and a[1] < b[1]) end)
    local out = {}
    for _, f in ipairs(scored) do out[#out + 1] = f[1] end
    return out
  end
  local function in_row(tx, ty, facing)
    local front = front_of(facing)
    if not front then return false end
    for _, side in ipairs({{front[2], front[1]}, {-front[2], -front[1]}}) do
      for _, e in ipairs(world:getObjects(tx + side[1], ty + side[2]) or {}) do
        if e.object_type and e.object_type.id == "bench" and e.direction == facing then return true end
      end
    end
    return false
  end
  -- Patients standing on a spot do not rule it out: the command asks them to
  -- step aside (handlers.place_object). (Jan, 2026-11-13: a crowd by
  -- Agnes's GP stood on every free spot, so no bench went there, ever.)
  -- A reception desk still waits for an empty spot.
  local people_ok = object_id ~= "reception_desk"
  local function fits(tx, ty)
    if next(given) and given[world.map.th:getCellFlags(tx, ty).parcelId] then return false end
    for _, e in ipairs(apart) do
      if math.abs(e.tile_x - tx) <= DRINKS_APART and math.abs(e.tile_y - ty) <= DRINKS_APART then return false end
    end
    if not people_ok and world:anyHumanoidObscuringArea(tx, ty) then return false end
    if not spaced(tx, ty) then return false end
    local list = facings
    if object_id == "bench" then list = loose and toward_door(tx, ty) or back_to_wall(tx, ty) end
    for _, facing in ipairs(list) do
      if not (want_row and not in_row(tx, ty, facing)) then
        place:setOrientation(facing)
        place:setBlueprintCell(tx, ty)
        if place.object_blueprint_good and keeps_floor(tx, ty, facing) then return true end
      end
    end
    return false
  end
  local x, y
  -- Where the expert of this place had one (bot_learned.lua, plans), the
  -- first such spot that is free (near a door asked for: within reach).
  local plan = self:learnedPlan()
  for _, spot in ipairs(plan and plan.objects or {}) do
    if not x and spot.id == object_id and object_type.orientations[spot.dir] then
      local ox, oy = Learned.origin(object_type, spot.dir, spot.tiles)
      local free = ox ~= nil and (not near_x or (math.abs(ox - ax) <= max_r and math.abs(oy - ay) <= max_r))
      for _, t in ipairs(free and spot.tiles or {}) do
        if not self:freeTile(t[1], t[2]) then free = false end
      end
      if free and not world:anyHumanoidObscuringArea(ox, oy) and
          not (next(given) and given[world.map.th:getCellFlags(ox, oy).parcelId]) then
        place:setOrientation(spot.dir)
        place:setBlueprintCell(ox, oy)
        if place.object_blueprint_good and keeps_floor(ox, oy, spot.dir) then
          x, y = ox, oy
          log(string.format("a %s where the expert had one: %d,%d facing %s", object_id, ox, oy, spot.dir))
        end
      end
    end
  end
  -- Where the experts put this kind of object by a door or a reception desk
  -- (learned each night from their games, layout_learn.py near_spots; Jan,
  -- 2026-11-14), seen from the door or desk it is for, the most seen first:
  -- Argus's benches stand beside the door along the room's wall and in a
  -- row across the corridor facing it.
  if not x and near_x and habits and Learned then
    local spots = {}
    for _, r in pairs(world.rooms) do
      local door = r.door
      if r.hospital == hosp and door and door.tile_x == near_x and door.tile_y == near_y and r.width then
        spots = Learned.doorSpots(habits, object_id, r.x, r.y, r.width, r.height, door.tile_x, door.tile_y,
            door.direction)
      end
    end
    if #spots == 0 then
      for _, desk in ipairs(hosp:getReceptionDesks()) do
        if desk.tile_x == near_x and desk.tile_y == near_y then
          spots = Learned.deskSpots(habits, object_id, near_x, near_y, desk.direction)
        end
      end
    end
    for _, sp in ipairs(spots) do
      if not x and object_type.orientations[sp.dir] and world:isOnMap(sp.x, sp.y) and self:freeTile(sp.x, sp.y) and
          spaced(sp.x, sp.y) and (people_ok or not world:anyHumanoidObscuringArea(sp.x, sp.y)) and
          not (next(given) and given[world.map.th:getCellFlags(sp.x, sp.y).parcelId]) then
        place:setOrientation(sp.dir)
        place:setBlueprintCell(sp.x, sp.y)
        if place.object_blueprint_good and keeps_floor(sp.x, sp.y, sp.dir) then
          x, y = sp.x, sp.y
          log(string.format("a %s where the experts have one by a door: %d,%d facing %s (seen %d times)",
              object_id, sp.x, sp.y, sp.dir, sp.seen or 0))
        end
      end
    end
  end
  local function nearest()
    -- Nearest first, in a fixed order.
    for r = 0, max_r do
      for dy = -r, r do
        for dx = -r, r do
          local tx, ty = ax + dx, ay + dy
          if not x and math.max(math.abs(dx), math.abs(dy)) == r and not clear[ty * 1000 + tx] and
              self:freeTile(tx, ty) and (want_row or wall(tx - 1, ty) or wall(tx + 1, ty) or
              wall(tx, ty - 1) or wall(tx, ty + 1)) and fits(tx, ty) then
            x, y = tx, ty
          end
        end
      end
      if x then break end
    end
  end
  if not x and object_id ~= "reception_desk" then nearest() end
  -- (A bench: facing the door beside another one, then by a wall facing the
  -- door; the same a bit further from the door, as a standing patient looks
  -- for a free bench up to 10 tiles from it, humanoid_actions/queue.lua.)
  local function loose_bench()
    loose, want_row = true, true
    nearest()
    if not x then
      want_row = false
      nearest()
    end
    loose, want_row = false, false
  end
  if not x and object_id == "bench" then
    loose_bench()
    if x then log("no spot with its back to a wall: a bench facing the door") end
  end
  if not x and object_id == "bench" and near_x then
    max_r = 8
    nearest()
    if not x then loose_bench() end
    if x then log(string.format("a bench %d,%d tiles from the door", x - ax, y - ay)) end
  end
  if not x and not near_x then
    -- Tiles with free floor all around (so nothing blocks a corridor).
    x, y = builder.find_free_rect(world, ax, ay, 1, 1, 40, fits)
  end
  local refused = cuts > 0 and string.format(" (%d spot(s) refused: they would cut its floor in two)", cuts) or ""
  if x then
    place.object_cell_x, place.object_cell_y = x, y
    if world:anyHumanoidObscuringArea(x, y) then
      -- (The click would wait for an empty spot; the command asks whoever
      -- stands there to step aside.)
      place:placeObject()
    else
      place:onMouseUp("left", 100000, 100000) -- a click outside the window
    end
    placed = true
    log(string.format("bought a %s at %d,%d%s", object_id, x, y, refused))
  else
    log("no place for a " .. object_id .. refused)
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
  -- The most skilled on the list (of those with the skill wanted), anybody
  -- before a junior (Argus, 2026-11-14: juniors are catastrophically slow;
  -- one only when nobody else is on the list).
  local ok, err = pcall(builder.ui_hire, self.world, dx, dy, what, log, function(p)
    return (p.skill or 0) - (flag(p, "is_junior") and 2 or 0)
  end)
  if not ok then log("could not hire a " .. category .. ": " .. tostring(err)) end
  return ok
end

--! Is somebody of this category (Nurse, Handyman, Receptionist) on its list
--! with a skill above `min` (0 to 1)?
function Bot:canHireSkilled(category, min)
  local world = self.world
  local pools = world.staffPool and world:staffPool() or world.available_staff
  for _, profile in ipairs(pools[category] or {}) do
    if (profile.skill or 0) > min then return true end
  end
  return false
end

--! Is somebody of this category (see Bot:canHire) on its list who is not a
--! junior?
function Bot:canHireSenior(category)
  local class, skill = category, SPECIALISTS[category]
  if skill then class = "Doctor" end
  local world = self.world
  local pools = world.staffPool and world:staffPool() or world.available_staff
  for _, profile in ipairs(pools[class] or {}) do
    if not flag(profile, "is_junior") and (not skill or flag(profile, "is_" .. skill)) then return true end
  end
  return false
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

--! Hire a doctor straight into the training room as a student: the most
--! skilled junior on the list, else (unless `junior_only`) the most skilled
--! doctor not yet a consultant (he learns too). False if there is none.
function Bot:hireStudent(junior_only)
  local world = self.world
  if world.ui.hospital.balance < RESERVE then return false end
  local pool = (world.staffPool and world:staffPool() or world.available_staff).Doctor or {}
  local junior, other = false, false
  for _, p in ipairs(pool) do
    if flag(p, "is_junior") then junior = true elseif not flag(p, "is_consultant") then other = true end
  end
  if not junior and (junior_only or not other) then return false end
  local dx, dy = self:anchor()
  local ok, err = pcall(builder.ui_hire, world, dx, dy, junior and "Doctor:junior@training" or "Doctor@training", log,
      function(p)
        if flag(p, "is_consultant") then return nil end
        return p.skill or 0
      end)
  if not ok then log("could not hire a student: " .. tostring(err)) end
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

--! A corridor tile of `target` (a rival) to put a litter bomb on: near one
--! of its reception desks if it can (where the most people pass), else near
--! its start view; one of the free ones at random (the bot's own random).
--! A hard bot hides it: on a quiet corridor, far from every reception desk.
--! Nil if there is none.
function Bot:bombSpot(target)
  local world = self.world
  local mine = world.ui.hospital
  local th = world.map.th
  local width, height = th:size()
  local function free_tiles(cx, cy, r)
    local tiles = {}
    for y = math.max(1, cy - r), math.min(height, cy + r) do
      for x = math.max(1, cx - r), math.min(width, cx + r) do
        if target:isInHospital(x, y) and th:getCellFlags(x, y).passable and not world:getRoom(x, y) and
            #(world:getObjects(x, y) or {}) == 0 then
          tiles[#tiles + 1] = {x, y}
        end
      end
    end
    return tiles
  end
  local tiles = {}
  if self.level == "hard" then
    local cx, cy = th:getCameraTile(target:getPlayerIndex())
    for _, t in ipairs(free_tiles(cx, cy, 20)) do
      local near = false
      for _, desk in ipairs(target:getReceptionDesks()) do
        if desk.tile_x and math.abs(desk.tile_x - t[1]) + math.abs(desk.tile_y - t[2]) < 8 then near = true end
      end
      if not near then tiles[#tiles + 1] = t end
    end
  end
  if #tiles == 0 then
    for _, desk in ipairs(target:getReceptionDesks()) do
      if desk.tile_x then
        for _, t in ipairs(free_tiles(desk.tile_x, desk.tile_y, 4)) do tiles[#tiles + 1] = t end
      end
    end
  end
  if #tiles == 0 then
    local cx, cy = th:getCameraTile(target:getPlayerIndex())
    tiles = free_tiles(cx, cy, 15)
  end
  -- (The game checks the rest: no bomb there yet, not too many of them.)
  for _ = 1, math.min(8, #tiles) do
    local t = pick(tiles)
    if sabotage.bombSpot(world, mine, t[1], t[2]) == target then return t[1], t[2] end
  end
end

--! Game days to the next dirty trick, by the bot's level.
function Bot:trickGap()
  local r = TRICK_EVERY_DAYS[self.level] or TRICK_EVERY_DAYS.normal
  return rand(r[1], r[2])
end

function Bot:playTrick()
  local world = self.world
  if world.mp_coop and world.mp_coop.tricks_off then return false end -- (switched off in this game)
  if self.standin then return false end -- (not in a person's name)
  local mine = world.ui.hospital
  -- (Not while it owes the bank: Jan, 2026-11-14.)
  if (mine.loan or 0) > 0 then
    log(string.format("no trick: it owes the bank $%d", math.floor(mine.loan)))
    return false
  end
  local target, choice
  if self.manager then
    -- The rival closest to winning, and the trick that hurts it most.
    local hosp, name = self.manager:trickTarget()
    if not hosp then return false end
    target, choice = {hosp, name}, self.manager:trickKind(hosp)
    -- Another rival tricked that player lately: not now; and no second evil
    -- handyman while one is there (TRICK_GAP_DAYS).
    local seen = self.tricks_seen and self.tricks_seen[world:getHospitalIndex(hosp)]
    if seen and seen.by ~= world:getHospitalIndex(mine) and self:gameDay() - seen.day < TRICK_GAP_DAYS then
      log(string.format("no trick on %s: %s got a %s trick %d days ago", tostring(name), tostring(name),
          tostring(seen.kind), self:gameDay() - seen.day))
      return false
    end
    for i = #choice, 1, -1 do
      if choice[i] == "handyman" then
        for _, e in ipairs(world.entities) do
          if e.mp_saboteur and e.mp_saboteur.target == world:getHospitalIndex(hosp) then
            table.remove(choice, i)
            break
          end
        end
      end
    end
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
  -- (Nor one the room's game options leave out: the rat attack unless the
  -- host allowed it; sabotage.allowed, newer games only.)
  for _, k in ipairs(choice) do
    local from = sabotage.unlockMonth(world, k, 1)
    local allowed = not sabotage.allowed or sabotage.allowed(world, k)
    if allowed and (not from or world.game_date:monthOfGame() >= from) then kinds[#kinds + 1] = k end
  end
  if #kinds == 0 then return false end
  local kind = pick(kinds)
  -- The highest level it can afford with something left over, at most a
  -- random one.
  local level = rand(1, 3)
  -- (Not above the highest level unlocked yet.)
  local month = world.game_date:monthOfGame()
  while level > 1 and (sabotage.unlockMonth(world, kind, level) or 0) > month do level = level - 1 end
  -- (An easy bot's litter bombs are the small ones.)
  if kind == "litter_bomb" and self.level == "easy" then level = 1 end
  local function cost(l) return sabotage.price(world, mine, kind, l) end
  while level > 1 and mine.balance - cost(level) < 2 * RESERVE do level = level - 1 end
  if mine.balance - cost(level) < 2 * RESERVE then
    log(string.format("no %s trick: not enough money ($%d)", kind, math.floor(mine.balance)))
    return false
  end
  -- (Nor when what it needs most would then be short of money.)
  local short = self.manager and self.manager:trickMoney(cost(level))
  if short then
    log(string.format("no %s trick: %s", kind, short))
    return false
  end
  local why = sabotage.refusal(world, mine, target[1], kind, level)
  if why then
    log(string.format("no %s trick (level %d) on %s: %s", kind, level, target[2], why))
    return false
  end
  local cmd = {kind = "sabotage", trick = kind, level = level, to = world:getHospitalIndex(target[1])}
  if kind == "litter_bomb" then
    -- (Put down by its reception desk, where the most people pass.)
    cmd.x, cmd.y = self:bombSpot(target[1])
    if not cmd.x then
      log(string.format("no litter bomb on %s: no free corridor tile", target[2]))
      return false
    end
  end
  log(string.format("dirty trick: %s level %d on %s", kind, level, target[2]))
  TheApp.mp_session:issue(cmd)
  if self.manager then self.manager:noteSpent("trick", cost(level)) end
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
  -- Its level as the game has it (the room's owner may have changed it
  -- after this bot was started).
  local level = MultiplayerSession.botLevel and MultiplayerSession.botLevel(world, self:hospitalIndex())
  if level and level ~= self.level and not self.standin then
    log(string.format("level %s (started as %s)", level, self.level))
    self:applyLevel(level)
  end
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
      -- The first dirty trick: in months 7 to 12 (easy 10 to 12, hard 4 to 6).
      trick = (month - 1) * 30 + rand(unpack_args(TRICK_FIRST_DAYS[self.level] or TRICK_FIRST_DAYS.normal)),
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
        local line = fill_in(pick(LINES.bonuses), {n = given, spent = spent, name = self:playerName(peer)})
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
  self:plotWaitTick()
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
        plan.trick = self:later(self:trickGap())
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
      plan.trick = self:later(self:trickGap())
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
  Learned = assert(loadfile(source_dir .. "/scripts/multiplayer/bot_learned.lua"))()

  local bot
  -- Money sent to it: seen when the command runs here (the game itself
  -- does the same on every computer).
  local handlers = MultiplayerSession.default_handlers
  -- Dirty tricks played (anybody's): Bot:trickSeen.
  local sabotage_command = handlers.sabotage
  handlers.sabotage = function(world, cmd)
    local ok, why = sabotage_command(world, cmd)
    if ok and bot then
      keepRandom("trick", bot.trickSeen, bot, tonumber(cmd.to), cmd.trick, tonumber(cmd.hospital))
    end
    return ok, why
  end
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
