# Computer players (bots)

For testing a build alone or with fewer people: the room's host clicks an
empty place in the room ("waiting for a player... (click: add a bot)") and a
bot takes it. Up to three bots fit in a room for four. A bot runs its own
hospital by what it needs (the "smart" brain, `bot_manager.lua`), and can take
advice from a language model through the server (below).

## How it works

A bot is a whole game, run by the server without a screen, the same way as the
headless referee (`referee.md`): the server starts
`scripts/multiplayer/bot.lua` with the referee's build and game data
(`CORSIXTH_MP_REFEREE_*`), and the bot connects back and joins the room as a
player. It plays through the same game windows and lockstep commands as a
person (it reuses the scripted player's helpers in `probe_builder.lua`), so the
other games need nothing new apart from the lobby button. A server without a
referee build cannot run bots (the button is not shown there).

- Server (`mp_server/corsixth_mp/server.py`): `BOT add=1` / `BOT remove=<peer>`
  from the room owner in the lobby. The server picks a name (`BOT_NAMES`; in
  a continued game the first saved hospital nobody has taken), starts the
  process (`referee.start_bot`) with a token, and keeps the place until the bot
  connects (`HELLO role=bot room token`) or `BOT_START_TIMEOUT` passes. The bot
  joins ready; `PLAYER` lines say `bot=1`, `LOBBY` says how many are still
  `starting`. When the last person leaves a room, its bots are stopped. At most
  `CORSIXTH_MP_MAX_BOTS` (default 7: a room of 8 with one person) run on a server at once.
- Lobby window (`dialogs/resizables/multiplayer.lua`): the player places are
  buttons; `UIMultiplayer:clickPlace` adds or removes a bot
  (`MultiplayerLobby:addBot`, `removeBot`, `canAddBots`).
- The bot (`scripts/multiplayer/bot.lua`): runs the game at its own pace (an
  18 ms tick like the game's timer) and thinks twice a second. It never uses
  the game's random numbers (that would desync its game); it has its own
  generator, seeded from the clock and its name.

## The hospital manager (`scripts/multiplayer/bot_manager.lua`)

The default brain (`MP_BOT_BRAIN=smart`). Every game day it reads its hospital
as a player reads the screen (`Manager:assess`): the patients and the rooms
their diseases need (a decaying demand per room type, more for diagnosed
patients), queues per room type, staff and their tiredness, reception,
litter, worn machines, thirst, warmth, toilets, money, loan, reputation and
the level's goals. Every possible project gets a score from those needs
(`Manager:projects`): the opening basics first (receptionist, GP's office,
doctor), then rooms the patients need, a pharmacy and general diagnosis, a
staff room when staff tire, toilets, a research room for diseases waiting
for undiscovered rooms, a second room of a busy type, staff for rooms short of
them or with long queues (capped by the patients), handymen for litter and
machines, a second desk for a long reception queue, benches for people
standing, drinks machines, radiators for cold patients, bins, plants. The
best project it can afford is done, one every one to four game days.

- **Rooms** are sized per type (`SIZES`: a GP's office 5x5, a ward 7x7, a staff
  room 6x6, ...), placed with a free tile below and to the right where possible
  so the corridor in front of the door is two tiles wide, and furnished by hand
  (`Bot:furnishTick`): the extras are bought in the room editor (`room_buy`)
  and every object is put down like a click. Extras (`EXTRAS`): a radiator, a
  plant and a bin in most rooms; a sofa, a TV and a pool table in the staff
  room; more loos and sinks; two more beds in a ward. Extras without a place
  are sold again. Out of floor: first a room bigger than it needs is taken in
  by a row or column (the room editor, walls down, drawn again one tile
  smaller on a side with nothing on it, its things put back: `Bot:shrinkRoom`,
  the `shrink:<side>` edit step); with no land left to buy, rooms go down to
  their smallest size. Then it buys land. It also looks for land once rooms
  take `MultiplayerSession.BOT_LAND_FILL` (70%) of its indoor floor
  (`MultiplayerSession.landFill`), urgent enough to borrow for. At an
  auction it bids with its money (keeping $5,000) and, from
  `BOT_BORROW_FILL` (60%), with what it can still borrow: a bot hospital
  takes the loan when it wins (`end_auction`), a bot standing in for a
  person borrows before the bid. Up to 6 GP's offices, each only
  for a queue.
- **Rooms nobody uses**: a room nobody has used for about five months (a
  patient in it; staff in a staff room, training room or research room) is
  taken down for its floor, never a GP's office and never in a hospital it
  shares with a person. While the level has a hospital value goal the bot has
  not reached, selling is a last resort (a room sold takes its whole price
  off the value, for half of it back): only a room unused for a year, and only
  when something it wanted found no floor in the last 30 days and no plot is
  left that it may buy and pay for, with a loan if need be
  (`Manager:outOfSpace`); then the cheapest such room, after a room bigger
  than it needs was taken in. Extras the furnishing cannot place are sold back
  at their full price, which takes off only the value their purchase added.
- **The floor in one piece** (Argus, 2026-11-08: a bot's benches and vending
  machines had cut its floor apart, and its patients walked outside and
  through three other hospitals to get between the parts; the game only
  checks that some way exists, even one outside). Before it puts down a
  corridor object (benches, plants, drinks machines, radiators, bins,
  extinguishers, a reception desk) or a room, the bot reads its own floor
  (`Bot:floorMap`: the corridor tiles of its building, in no room, with the
  sides one can cross, which radiators, bins and extinguishers close) and
  refuses a spot that leaves its entrances, both sides of each reception desk
  (patients and receptionist) and the tile before each room's door in more
  parts than before (`Manager.floorParts`; a plot bought may be a building of
  its own, so the rule is "no more parts", not "one part"); a new desk's two
  sides and some tile beside a new room must be reached too. The floor is read
  only when something is about to be put down (once a game step); a room
  search checks at most 60 spots that way. A floor already in parts (an older
  game's) is mended: once a game
  week, every 2 days while mending, it sells (`sell_object`) the corridor
  object that stands first on the shortest way between two parts
  (`Manager.floorBlocker`; never a reception desk, nothing when walls or rooms
  part it), and the waiting-area rules buy what is missing again where it fits.
  Room edits (bigger, moved, taken in) still follow the game's own rule only.
- **Hiring**: the most skilled person on the list (of those with the skill a
  room needs).
- **"Allied bots build: off"** (the room's `helpers` game option): a bot
  sharing a person's hospital builds no rooms, buys nothing for the corridors
  or rooms (no reception desk either) and takes no room in, unless the person
  asks for it in the chat (a wish). Staff, bonuses, research, auctions, land
  and the rest it still does (`Bot:leavesBuilding`).
- **Training**: a training room once it has two juniors, five doctors and
  $20,000, and a consultant to teach. It has 3 to 6 lecture chairs (each bot
  picks a number once from its own random numbers; 5 or 6 want a 6x6 room; an
  older room with fewer than 3 gets one more). How training works in the game
  (`rooms/training.lua`, `Doctor:trainSkills`): a doctor who is not a
  consultant learns only while he sits in a chair and a consultant stands at
  the projector; he does no work for patients meanwhile and keeps his pay. He
  gains general skill every day (a junior becomes a doctor, a doctor a
  consultant); a special skill (surgeon, psychiatrist, researcher) only if the
  teacher has it and he has not. With more than 3 students at once each learns
  at 2/(n-1) of the rate, so the extra chairs fill but slow each other down.
  Every 12 months, the first time in the 2nd month, it picks the teacher
  again (also when there is none for a month): the consultant with the most
  special skills, then skill, from its staff, or hired from the list straight
  into the room when a consultant there has a special skill more. Students
  fill the chairs: juniors first, then the least skilled doctor not yet a
  consultant, but never from a room with a patient in it or in its queue, never
  the last doctor with a skill a room needs, and only while the other rooms
  keep their doctors (one doctor more than they need in the first two years,
  exactly enough from the 3rd year on, when it also reviews its staff every
  30 days, `MP_BOT_STAFF_REVIEW_FROM` in tests). Until the 3rd year (Jan,
  2026-11-08) the chairs are kept full from the day the room has its teacher:
  with no doctor to spare, a junior (else a doctor not yet a consultant) is
  hired straight into the room as a student, one every 3 days while the bank
  holds $10,000 (`Bot:hireStudent`). Students do not count as staff in the
  hiring rules, so the rooms still get their doctors. From the 3rd year
  doctors are hired only for a need, and such a doctor is a junior hired into
  a free chair (when the room has its teacher and the list a junior): he counts
  as staff for that need and learns until he is a doctor before he works. A
  student who becomes a consultant goes back to work at once (to the staff room
  if no room needs one); otherwise one goes back only when fewer doctors work
  than the rooms need (a room without its doctor on a break is no reason):
  until the 3rd year only when none can be hired, from then on the most skilled
  student who is not a junior.
- **Every day**: a handyman to each machine with three uses or fewer, the
  heating up or down for cold or hot patients, a $5,000 loan before the money
  runs out, the faxes (a patient it cannot treat yet: wait if the room is
  there or being built, else send home, never research: that is an autopsy, which costs reputation; a VIP only with a
  good reputation and a clean hospital; an epidemic is declared), and in a
  race it throws out evil handymen a few days after they arrive and shoots
  attack rats.
- **Prices**: a bot never changes the treatment prices (they stay at 100%;
  one changed by an older bot is set back to 100% in its first month).
- **Every month**: repaying the loan once money flows in again (the balance up since last month, over
  $17,000, keeping $12,000; or anything over $25,000), research aimed at the
  disease whose treatment room it lacks most.
- **Sharing a hospital with a person** (one shared hospital, or a team
  hospital): the bot only helps. It builds, furnishes, hires, sends handymen
  and buys corridor items, and leaves prices, loans, heating, research, opening
  the hospital and its faxes (patients, VIPs, epidemics, emergencies) to the
  person (`Bot:sharesWithPerson`). A person who has given no command for 30
  seconds and 7 game days is away: the bot runs the whole hospital and says so
  to them in the chat, until they give a command again ("Welcome back"); it
  sees every command just before it runs (`Bot:watchCommands`). Tests set the
  seconds with `MP_BOT_AWAY_SECONDS`.
- **Dirty tricks** (race): on the rival closest to winning (a person before a
  bot), the kind that hurts it most (an evil handyman for a hospital with
  machines, an epidemic or emergency for a staffed desk, else rats).
- The month in one log line: why patients left (cured, sent away, fed up,
  too dear), the diseases it lost most, patients in the hospital, queues per
  room type, specialists, prices, reputation, money, and its floor (in how many
  parts, in how many without its corridor objects, and how many entrance
  tiles, desk sides and room doors it must reach: `Bot:floorReport`). A plot
  bought is often a building of its own with its own entrance, a part of its own.

`MP_BOT_BRAIN=script` keeps the old fixed plan (described below), also per
bot or per room (`"plan=script;smart=smart"`), for comparing the two:
`scripts/multiplayer/run_bot_year.sh BIN DATA [LEVEL] [STEPS]` runs two co-op
rooms side by side for a game year, one bot each.

## Advice from a language model (`mp_server/corsixth_mp/advisor.py`)

With an Anthropic API key on the server (`/etc/corsixth-mp-secrets.env`,
`ANTHROPIC_API_KEY=...`; `setup-referee-host.sh` lets the service read it and
installs the `anthropic` package in `/opt/corsixth-mp/venv`) the bots ask the
server, never the API (the key is removed from the bots' and referee's
environment):

- `ASK kind=plan` once a game week (at most every 25 seconds): the hospital's
  report (`Manager:report`: money, goals, rooms and queues, rooms patients
  needed, staff, comfort, why patients left, rivals, and what its team
  mates said in the last 30 game days) and the menu of projects
  (`Manager.menu`). The model (default `claude-haiku-5-5`, low effort,
  structured output) answers up to six priorities with weights and a
  one-line note. The server keeps only actions from the menu; the manager adds
  the weights to those projects' scores until they are done. A team mate sometimes says the note in the
  chat; a rival keeps it to itself.
- `ASK kind=chat` when a person writes to the bot (privately or by name): the
  model answers in the bot's voice (friendly, or a cheeky rival), in one short
  line that leaves the money out unless asked; if no answer comes within 10
  seconds the bot uses its stock line. A bot on the person's side also sends
  `menu` (the projects it can do now), and the model names the one asked for
  ("can you build a psychiatry?"); the bot does that next, without waiting
  for the next plan. One message may ask for several things ("a plant and a
  radiator in every room"). Besides rooms, staff and corridor objects, a team
  mate may ask for one more object in a room it has (add:<room>:<object>, the
  room's own extras: a skeleton in the psych room) or a room bigger
  (bigger:<room>: drawn again a tile wider and longer, where there is space,
  and furnished again); the bot does both in the room editor as a person
  would. A wish is over once anybody has done it, and lapses after 60 game
  days if it cannot be done. What a team mate says they will do themselves, or
  takes back, the bot leaves alone for 60 game days ("leave").
- `ASK kind=rescue`: like a plan, for a hospital that is failing its objectives
  (see above); its own prompt, at most every 30 seconds per bot.
- `ANSWER id=...` with `actions` ("action:weight,..."), `note`, or
  `text` (and `wish`, a menu item, a room with a place `room:x@near:y`; `give`,
  the sum an ally asks for, 0 for none named); `error=off|busy|none|failed`. Only
  bots may ask, a plan at most every 20 seconds and a chat line every 3 seconds per bot.
- A daily budget (`CORSIXTH_MP_AI_DAILY_USD`, default $3; kept in
  `/var/lib/corsixth/ai-spend.json` across restarts) stops the advice for the
  rest of the day (UTC). Without a key, or over the budget, the bots play on
  the manager's own rules. Haiku 5.5 costs about $0.001 a plan.

## The fixed plan (`MP_BOT_BRAIN=script`)

- **Builds** (game days): a reception desk after 2 to 5 days, a receptionist,
  then one room every 10 to 20 days while it has the money (it keeps $3,000):
  GP's office first, then pharmacy, general diagnosis, ward, psychiatry, staff
  room, toilets, the diagnosis machines and whatever else the level has
  (not the training room). Rooms are drawn next to the desk with a window and
  furnished automatically, with free floor around them if possible, else
  packed against other walls (free floor below and to the right, where the
  door goes). When nothing fits it buys the cheapest plot of land on its side
  of the map (keeping $9,000); a room that still does not fit after three
  tries is given up. Corridor furniture waits until four rooms stand.
- **Hires** what its rooms need (specialists when the room needs one and the
  list has one), a handyman from 3 rooms and another from 8. A room that
  cannot work at all for want of staff (an operating theatre with one
  surgeon) gets its missing specialist before any new room.
- **Emergencies**: it accepts one when every room that cures the disease
  stands and its staff is complete or on the hiring list. While one is on
  (accepted, or sent by a rival), the missing staff of those rooms comes
  before all but the basics, and a missing room is built at once. The model's
  report starts with the emergency (patients, cured, days left, the rooms)
  and each room short of staff, with the `hire:` project that fixes it.
- **Lends specialists**: when an ally (co-op, or a team mate in a race of
  teams) has a room that cannot work for want of a surgeon or psychiatrist
  (not a researcher) and none is on their hiring list, a bot with one to
  spare (more than its own rooms need) offers its least skilled one for
  free, at most once in 20 game days per ally and kind; people accept it in
  their messages, bots accept by themselves. A bot short of one itself, with
  none to hire, or none hired for 10 game days (3 in an emergency), lends one
  as well. A bot that has lacked one for 10 days (3 in an emergency) for a room
  it has, is building, or one patients ask for, whether or not one is on the
  hiring list, asks in the chat: by name the people who have one to spare, else
  the team chat for everybody on its side (once in 20 days, 7 in an emergency);
  nothing when an allied bot has one to spare for a room that stands (that bot
  offers it) or when nobody on its side is a person. (Before 2026-11-08 it asked
  only when none was on the hiring list, which almost never happens: a bot
  builds a room for a specialist only when one is on the list.) A bot sharing a
  person's hospital lends nobody.
- **The level's requirements**: once a day it works out, as the game does
  (`EndConditions`, the group of goals it is closest to, and no loan), which
  hospitals meet the requirements to win (`Manager.requirements`). When a
  person on its side newly meets them, the allied bot with the lowest hospital
  number says "Good job, X, you now meet the requirements to win." in the team
  chat; a bot that meets them too says so in a line of its own ("I'm also in a
  good spot."); a bot that does not names one thing it still lacks (money
  short, hospital value, reputation, cures, deaths, happiness, the loan),
  with the amount, again every 6 months while an ally meets them and it does
  not. In a race, when an opponent (person or bot) meets them, one allied bot
  (the lowest hospital number) tells its team "Watch out, X has fulfilled the
  winning conditions, we must catch up!" as soon as it sees it and every 4
  months after. Nothing is said when no person is on its side to read it.
- **Failing its objectives**: a bot counts as failing when it is close to a way
  of losing the level (every goal of a lose group past the game's warning and
  half the way to the limit), failed the goals at the last year end
  (`mp_failing_since`), is under 30% of the way on the goals after a year, has
  no money and no loan left for 20 days, or has a reputation under 250 that
  fell by 50 in 3 months. Never in the first game year (Jan, 2026-11-08: the
  thresholds stay, "with the exception of year 1"): no review and no ask before
  month 13. From then on, at most every 3 months, it asks the advisor
  (`ASK kind=rescue`: the report, the reasons and the menu; the plan that comes
  back stays in force for a month) and asks its team in the chat for one
  concrete thing: an amount and what it is for, from the project it wants most
  and cannot pay ("Could you send me $20,000 to build a new X-Ray room and raise
  the value of my hospital?"). `MP_BOT_TEST_FAIL=<day>` forces it in tests.
- **Opens** the hospital once it has a staffed desk, a GP's office and a
  doctor; then buys some benches, plants, a drinks machine and an
  extinguisher for its corridors.
- **Talks**: a greeting in the second to fourth month (friendly in co-op and
  shared games, fiery in a race; the bots of a game greet in turn, at least
  6 game days apart, each with a line of its own), and answers to the chat after a typing
  pause: when written to privately or by name (at most every 10 seconds),
  otherwise seldom (one line in seven, at most every 3 minutes, less often
  with more bots), so the people's own chat stays readable. Its lines are
  grey in the players' chat. The answer depends on a few words (hello,
  thanks, how are you, a question, insults, winning, money, bot; a few Czech
  ones too). Bots do not answer each other. Small talk (greetings, taunts
  about dirty tricks and rats, remarks nobody asked for) goes out marked
  `banter=1`; each player chooses in MULTIPLAYER > BOT CHAT whether to see
  all, everything but the small talk, or nothing from bots
  (`multiplayer_bot_chat` in the config: `all`, `useful`, `off`).
- **Only allies give orders**: wishes, "leave it to me", money, plots and a word to share
  research are done only for an ally (`Bot:isAlly`: the same hospital, the same
  team, or anybody in a co-op game; in a race without teams nobody). Anybody
  else who asks for something gets a short refusal, without a question to the
  advisor.
- **Money on request** (Jan, 2026-11-08): an ally who asks a bot for money in
  the chat (keywords in English and Czech, or the advisor's `give` field) gets
  the sum asked for, up to $20,000 at once, while the bot holds more than
  $15,000 and keeps that much: min(asked, $20,000, bank - $15,000). Small sums
  count too ("$50"). With no sum named it sends half of what is above $15,000
  (whole thousands, $1,000 to $10,000). Less than asked, it says why (the most
  it sends at once, or all it can spare above its floor); with less or nothing
  it also says where its money went lately: its last spending of $2,000 or more
  in the last 90 game days ("Most of my cash went into the new X-Ray room
  ($12,000).": a room, land, a new machine, a loan repaid, money sent to an
  ally, a dirty trick; `Manager:noteSpent`). The bot decides and sends it
  (`give_money`), the line says only what it did, never what the model
  thought. In the team chat (which every bot of the team gets) only the bot
  named answers, or else the richest allied bot. `MP_BOT_GIVE_LIMITS=keep:max`
  sets other limits in tests. (A request through the bank manager's **Ask a
  player** is a fax: the bot pays it in full while it keeps $3,000, see Offers.)
- **A plot on request** (Jan, 2026-11-08): an ally may ask a bot in the chat
  for one of its plots ("give me plot 7", "can I have your plot 7?", "sell me
  plot 7", "can you spare a plot?"; a few Czech words too, or the advisor's
  `plot` field: the number, 0 for any). Its manager decides
  (`Manager:plotRequest`) and the bot offers the plot as a person would
  (`offer_plot`: the ally gets the fax and accepts or declines), with one line
  why. It gives only a plot the game lets it hand over
  (`MultiplayerSession.plotRefusal`: its own, not the starting plot, empty,
  not the plot that joins the rest of its land), and keeps one it needs:
  without it less than 35% of its indoor floor would be free (`PLOT_TAKE_FREE`,
  the share under which it takes a plot an ally offers), or it would be
  looking for land (`Manager:landWanted` counted without the plot: rooms that
  found no floor in the last 30 days while under 120 free tiles would be left,
  or 70% full); a plot it bought itself in the last 30 game days (for rooms to
  come); and, while the hospital has not reached the level's requirements, a
  plot without which its value would be under the level's value goal (minus
  what the plot cost it, `MultiplayerSession.plotPaid`). It gives the plot for
  free, or, with less than $15,000 in the bank (the floor of money on
  request), for what it cost it, rounded to $500 (at least $500, at most
  $50,000). With no number named it picks, among the plots it can spare, one
  that touches the asker's land first, then the smallest. Somebody walking on
  the plot: it says yes and sends the offer once nobody is on it (within 3
  game days). A plot it is handing over gets no rooms or objects of its own
  meanwhile (`Bot:plotsGiven`). In the team chat only the bot named answers,
  or the bot that owns the plot named, or the allied bot with the emptiest
  land among those with a plot to give.
- **A room at a place**: an ally may ask for a room "next to the GP's office",
  "near the entrance" or "by the reception"; the advisor returns it as
  `room:toilets@near:gp` (or `@near:entrance`, `@near:reception`, any room id).
  The bot's layout search then takes the spot within 8 tiles of that place (the
  rooms of that kind, the entrance doors, the reception desks) that is nearest,
  and tells the ally if nothing fits there and it used its normal place.
- **Offers** (staff, patients, research, money requests): after 3 to 8
  seconds it accepts in co-op (unless it cannot pay and keep its reserve) and
  declines in a race, each with a chat line to the sender (its own lines for
  staff, research and patients). Money sent to it is thanked for in co-op and
  sent straight back in a race. When it offers its own research there is no chat
  line: the offer arrives as a fax.
- **Dirty tricks** (race only): the first one, an evil handyman, some time in
  months 7 to 12 on a person's open hospital (never on another bot); then one
  of the four tricks every 60 to 120 days, at a level it can afford while
  keeping $6,000. Half the time it drops a hint in the chat a little later.
- It does not vote on speed changes (only people do, see
  `MultiplayerSession:voterCount`) and closes the windows that would pause
  its game (annual report, information, pay rises).

## Test

`scripts/multiplayer/run_bot_probe.sh BIN DATA`: a co-op room with two bots
and a race with one, the bots running 20 times faster (`MP_BOT_PACE=20`,
`MP_BOT_FAST=1` in the server's environment). The checks (see the top of the
script): lobby, building, co-op offers accepted, race offers refused and money
returned, chat, a dirty trick, everything in sync with the referee, speed
votes, research, tricks on a bot, the bonus, auctions, hands off, and since
2026-11-08 money and orders (15), asking for staff (16), the requirements chat
(17), the warning about a rival (18) and a failing hospital asking for help
(19), with test hooks `MP_BOT_GIVE_LIMITS`, `MP_BOT_TEST_LACK`,
`MP_BOT_TEST_WIN` and `MP_BOT_TEST_FAIL`; check 20 (the floor in one piece)
reads the bots' month lines: their corridor objects never part their floor,
and the entrances, both sides of the desk and the room doors are found; it
also shows how many spots each bot refused because they would cut its floor
in two and what it sold to mend a floor in parts. Check 21 (a plot asked of a
bot): the bot of "lab" wins plot 7 at an auction frank drops out of, keeps it
for the value goal when asked on day 4, and offers it for free when asked for
any plot on day 6 (its requirements count as met from day 5 in that room only:
`MP_BOT_TEST_WIN` entries may name a room, `lab/2:5`); frank accepts the fax and
the plot is his. Lobby probe:
`MP_ADD_BOTS=n` (the host clicks empty places), action `hospitals` (every hospital's rooms and
staff), and chat lines received are logged (`CHAT IN`).
Two small checks need no game, only Lua: `lua scripts/multiplayer/bot_text_test.lua
scripts/multiplayer/bot.lua` (requests, sums, plots asked for, what a bank
gives) and
`lua scripts/multiplayer/bot_manager_test.lua scripts/multiplayer/bot_manager.lua`
(who meets the requirements, what a bot says it lacks, when it is failing and
not in the first year, where its money went, which plot it gives an ally and
for how much, which room it takes down, a split floor refused and the object in
the way found, who goes to the training room).

## Not done

- A bot does not keep up a hospital in the long run (no more rooms when the
  first plan is done, no prices, research, loans, VIPs, emergencies or
  epidemics of its own).
- A bot does not answer the winner's fax in a race or the team win fax; it
  just plays on.
