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
  their smallest size. Then it buys land. Up to 6 GP's offices, each only
  for a queue.
- **Hiring**: the most skilled person on the list (of those with the skill a
  room needs).
- **"Allied bots build: off"** (the room's `helpers` game option): a bot
  sharing a person's hospital builds no rooms, buys nothing for the corridors
  or rooms (no reception desk either) and takes no room in, unless the person
  asks for it in the chat (a wish). Staff, bonuses, research, auctions, land
  and the rest it still does (`Bot:leavesBuilding`).
- **Training**: a training room (5x5, three lecture chairs) once it has two
  juniors, five doctors and $30,000, and a consultant to teach. Every 6 months
  it picks the teacher again: the consultant with the most special skills
  (surgeon, psychiatrist, researcher: each one the students can learn), then
  skill, from its staff, or hired from the list straight into the room when a
  consultant there has a special skill more. Juniors go in as students while
  the other rooms keep their doctors; a student who is no longer a junior goes
  back to a room short of a doctor.
- **Every day**: a handyman to each machine with three uses or fewer, the
  heating up or down for cold or hot patients, a $5,000 loan before the money
  runs out, the faxes (a patient it cannot treat yet: wait if the room is
  there or being built, else send home, never research: that is an autopsy, which costs reputation; a VIP only with a
  good reputation and a clean hospital; an epidemic is declared), and in a
  race it throws out evil handymen a few days after they arrive and shoots
  attack rats.
- **Every month**: prices (down 10% when patients walked out over them, else
  up with a good reputation and full queues, down when it suffers), repaying
  the loan once money flows in again (the balance up since last month, over
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
  room type, specialists, prices, reputation, money.

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
  needed, staff, comfort, prices, why patients left, rivals, and what its team
  mates said in the last 30 game days) and the menu of projects
  (`Manager.menu`). The model (default `claude-haiku-5-5`, low effort,
  structured output) answers up to six priorities with weights, a price and a
  one-line note. The server keeps only actions from the menu; the manager adds
  the weights to those projects' scores until they are done, and sets the
  price at the next monthly round. A team mate sometimes says the note in the
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
- `ANSWER id=...` with `actions` ("action:weight,..."), `price`, `note`, or
  `text` (and `wish`, a menu item); `error=off|busy|none|failed`. Only bots
  may ask, a plan at most every 20 seconds and a chat line every 3 seconds per bot.
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
  list has one), a handyman from 3 rooms and another from 8.
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
- **Offers** (staff, patients, research, money requests): after 3 to 8
  seconds it accepts in co-op (unless it cannot pay and keep its reserve) and
  declines in a race, each with a chat line to the sender. Money sent to it is
  thanked for in co-op and sent straight back in a race.
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
`MP_BOT_FAST=1` in the server's environment). Seven checks: lobby, building,
co-op offers accepted, race offers refused and money returned, chat, a dirty
trick, everything in sync with the referee. Lobby probe: `MP_ADD_BOTS=n` (the
host clicks empty places), action `hospitals` (every hospital's rooms and
staff), and chat lines received are logged (`CHAT IN`).

## Not done

- A bot does not keep up a hospital in the long run (no more rooms when the
  first plan is done, no prices, research, loans, VIPs, emergencies or
  epidemics of its own).
- A bot does not answer the winner's fax in a race or the team win fax; it
  just plays on.
