# Computer players (bots)

For testing a build alone or with fewer people: the room's host clicks an
empty place in the room ("waiting for a player... (click: add a bot)") and a
bot takes it. Up to three bots fit in a room for four. A bot is meant to make
the first year or so look like somebody is playing, not to be a good player.

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
  `CORSIXTH_MP_MAX_BOTS` (default 6) run on a server at once.
- Lobby window (`dialogs/resizables/multiplayer.lua`): the player places are
  buttons; `UIMultiplayer:clickPlace` adds or removes a bot
  (`MultiplayerLobby:addBot`, `removeBot`, `canAddBots`).
- The bot (`scripts/multiplayer/bot.lua`): runs the game at its own pace (an
  18 ms tick like the game's timer) and thinks twice a second. It never uses
  the game's random numbers (that would desync its game); it has its own
  generator, seeded from the clock and its name.

## What it does

- **Builds** (game days): a reception desk after 2 to 5 days, a receptionist,
  then one room every 10 to 20 days while it has the money (it keeps $3,000):
  GP's office first, then pharmacy, general diagnosis, ward, psychiatry, staff
  room, toilets, the diagnosis machines and whatever else the level has
  (not the training room). Rooms are drawn next to the desk with a window and
  furnished automatically; a room with no space is given up.
- **Hires** what its rooms need (specialists when the room needs one and the
  list has one), a handyman from 3 rooms and another from 8.
- **Opens** the hospital once it has a staffed desk, a GP's office and a
  doctor; then buys some benches, plants, a drinks machine and an
  extinguisher for its corridors.
- **Talks**: a greeting in the second to fourth month (friendly in co-op and
  shared games, fiery in a race), and answers to the chat after a typing
  pause: always when written to privately or by name, otherwise now and then
  (less often with more bots). The answer depends on a few words (hello,
  thanks, how are you, a question, insults, winning, money, bot; a few Czech
  ones too). Bots do not answer each other.
- **Offers** (staff, patients, research, money requests): after 3 to 8
  seconds it accepts in co-op (unless it cannot pay and keep its reserve) and
  declines in a race, each with a chat line to the sender. Money sent to it is
  thanked for in co-op and sent straight back in a race.
- **Dirty tricks** (race only): the first one, an evil handyman, some time in
  months 7 to 12 on a person's open hospital (never on another bot); then one
  of the four tricks every 60 to 120 days, at a level it can afford while
  keeping $6,000. Half the time it drops a hint in the chat a little later.
- It agrees to every speed vote and closes the windows that would pause its
  game (annual report, information, pay rises).

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
