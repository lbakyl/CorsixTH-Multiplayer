# Relay and lobby protocol (version 1)

The game connects to the multiplayer server (`mp_server/`) over one TCP
connection. Every message is one UTF-8 line ending in `\n`: a verb followed by
`key=value` fields separated by single spaces. Values are percent-encoded for
`%`, `=` and whitespace (`%XX` per byte), exactly like the lockstep commands of
`MultiplayerSession.encodeCommand`. Booleans are `0`/`1`. Unknown fields are
ignored, so fields can be added without a protocol bump.

The server never simulates the game. During a game it relays the lockstep
lines of `MultiplayerSession` (see `in-game-lockstep.md`) unchanged:

| Line | Meaning |
|---|---|
| `C key=value ...` | a player command, scheduled for step `step` (must carry the sender's `peer`) |
| `S <peer> <step> <fingerprint>` | the sender finished `step`; state fingerprint |

The server compares the fingerprints of all players for each step. Without a
referee it sends `DESYNC` when they differ; with one it repairs the games
(see `referee.md` and the last section below).

## Client to server

| Message | When | Fields |
|---|---|---|
| `HELLO` | first line | `proto` (1), `build` (game build id, must match the room's), `name`; the server's referee adds `role=referee`, `room` and `token`; a bot the server started `role=bot`, `room` and `token` (it joins that room, ready) |
| `LIST` | lobby | (none) |
| `CREATE` | lobby | `room`, `password` (empty = open), `max` (2–4), optional `mode`: a new game's room is free (each player picks a colour and a team, `SEAT`), and `mode` only says how newcomers are seated at first (`coop`, the default: a colour each on the owner's team; `shared`: one colour; `competitive`: a team each; `teams`, `teamshared`: the smaller of teams 1 and 2); a saved game's `mode` is its own, `level` (1–12), `difficulty` (`easy`/`full`/`hard`), `speed_control` (`any`/`owner`); to continue a saved game also `continue=1`, `step` (the step it was saved at), `date`, `seats` (its hospitals' names, comma-separated; a shared one lists its players, "ANN + BEN"), `seat_colours`, `seat_teams` (each hospital's colour and team, shown in the room) |
| `JOIN` | lobby | `room`, `password`; for a running room: back in one's own place (the name of a player who left, or one a stand-in bot plays for), else `seat=<peer>` takes that place (a bot's, or a player's who left); without `seat` the server answers `SEATS` |
| `READY` | in a room | `ready` |
| `SEAT` | in a new game's room (not a continued one: `locked`) | `colour` (1-4: the hospital; the same colour shares one) and/or `team` (1-4: the same team wins together, different teams race); the owner may add `peer` to change another player's (a bot's too). A colour somebody has brings their team; a team changes it for everybody of that colour. A new player gets the first free colour on the owner's team (error `bad_seat` for other values) |
| `START` | room owner | (none) |
| `BOT` | room owner, in the lobby | `add=1`: the server starts a computer player that joins the room (error `no_bots` on a server without a referee build, `room_full`, `too_many_bots`), optional `level` (`easy`, `normal` or `hard`, the default); `peer=<peer> level=<level>`: that bot's level from now on; `remove=<peer>`: that bot leaves (see `bots.md`) |
| `LEAVE` | in a room | (none) |
| `CHAT` | in a room or game | `text`; optional `to` (a peer): only that player gets it; `team=1` with `to=<peer>,<peer>...` (a race of two teams: the sender's team mates, as its game knows them): only those players get it |
| `SPEED` | in game | `speed`: `Pause` or a speed name up to the room's `max_speed` |
| `SHOW` | in game | cosmetic, outside the lockstep: `kind=blueprint room x y w h` (a room outline being drawn; `w=0` clears it) |
| `DIAG` | after a desync | `step`, `part`, `text`: this game's state (money, rooms, every entity) for the server log, to compare the games |
| `PONG` | reply to `PING` | `id` |
| `PING` | optional | `id` (server answers `PONG id=`) |
| `QUIT` | any time | (none) |
| `HELD` | after `HOLD` | `step`: the last step this game ran |
| `SAVEDATA`, `SAVED` | the referee after `SAVE`; the host of a continued game after `START` | `d` (base64 part of the save); then `step`, `parts` |

## Server to client

| Message | Meaning |
|---|---|
| `WELCOME proto id server motd` | accepted |
| `ERROR code text` | request refused; codes: `expected_hello`, `protocol`, `bad_room`, `room_exists`, `no_room`, `bad_password`, `build_mismatch`, `running`, `busy`, `room_full`, `in_room`, `not_owner`, `not_ready`, `not_enough`, `bad_speed`, `too_fast`, `bad_report`, `bad_command`, `unknown_verb`, `bad_message`, `not_referee`, `bad_seat`, `locked` |
| `ERROR code=data_mismatch text need` | answer to `HELLO` with `data` (the Theme Hospital level files' CRC-32, `MultiplayerLobby.dataId`) other than the server's (`CORSIXTH_MP_DATA`) on a server without a referee; the server then hangs up. A server with a referee lets such a player in: in a new game their `START` has `resume=1` (no level is loaded), the others get `HOLD step=0 why=rejoin`, and everybody loads the referee's game at step 0 |
| `ERROR code=build_mismatch text need release url` | answer to `HELLO` on a server that only lets in its referee's build (`referee.md`): `need` is the Lua code checksum it wants (the last part of the build id), `release` and `url` the release to get and its download page (both optional); the server then hangs up. The game offers `url` only if it is a `https://github.com/` page |
| `ROOM room players max mode level locked state build_ok continue` | one per room after `LIST`, then `ROOMS_END count`; `continue=1` for a saved game |
| `JOINED room peer owner mode free level difficulty max continue date bots` | you are in the room as player `peer` (`free=1`: a new game, colours and teams can change; `mode`: what they make now; `continue`, `date`: a saved game; `bots=1`: this server can add bots) |
| `PLAYER peer name ready rtt owner bot colour team level` | one per player (`bot=1`: a computer player, `level` an easy or hard one, none: normal; `colour`, `team`: 1-4, a continued game's saved ones), followed by |
| `LOBBY room count max mode free level delay speed one_way latency starting` | (`starting`: bots the server is still starting; they keep a place) | the room summary: recommended lockstep `delay` (steps), fastest smooth `speed`, worst player-to-player one-way time (ms) and click-to-effect `latency` at Normal speed (ms). Sent about once a second while in the lobby |
| `OWNER` | you are now the room owner |
| `START peer peers names seed level difficulty mode delay max_speed speed speed_control grant_wage_increase free_build_mode` | the game starts: everybody seeds the gameplay random generator with `seed`, loads `level` and plays as `peer` among `peers` (comma-separated, start order; `names` in the same order). A rejoining player also gets `resume=1` and `active` (the players now) and loads no level. A new game also has `colours` and `teams` (`peer:colour,...`, `peer:team,...`): every peer works out the hospitals from them the same way (`MultiplayerLobby.layout`: a hospital per colour; team mates' hospitals on neighbouring plots, `mp_levels.teamSeats`), and `mode` is what they make (`shared`, `coop`, `competitive`, `teams`, `teamshared` or `mixed`) |
| `SPEED peer name speed` | a player changed the speed (or paused); every client applies it, the sender included |
| `SHOW peer kind ...` | another player's cosmetic information, relayed unchanged with the sender's `peer` |
| `ARRIVED peer name back` | a person took place `peer` of the running game (`back=1`: they had it before); the others' games say so (the adviser, the announcer) |
| `LEFT peer step name` | a player left the game after reporting `step`; stop waiting for them. `replaced=1`: somebody takes the place at once (a load follows; the hospital is not marked away) |
| `SEATS room n peer<i> name<i> state<i> colour<i> team<i> level<i>` | answer to `JOIN` of a running room: its places in start order; `state` is `on` (a person plays it), `bot` (the room's own bot), `standin` (a bot playing for the person named, who left) or `left` (nobody); `level` an own bot's, `easy` or `hard` (none: a normal one) |
| `DESYNC step` | fingerprints differed at `step` and cannot be repaired: the game is over |
| `HOLD step why` | stop stepping and issuing commands; answer `HELD` (`why=desync` at `step`, or `why=rejoin`: a player rejoins). A game that found the desync itself waits 3 s for `HOLD` before it tells its player the games stay different; after a repaired desync (`RESUME`) only the adviser says so |
| `SAVE step why` | referee only: save once at `step` (or later). `why=quorum`: only some players load it, the referee plays on (no hold) |
| `REPAIRING step peers`, `REPAIRED step peers` | a quorum repair: most players agree with the referee and only `peers` (comma-separated) load its game; the others play on. Their games ignore what `peers` report until `REPAIRED` (no "out of sync" notice of their own) |
| `LOAD step parts peers`, `SAVEDATA d`, `LOADEND step` | the shared save (base64 in `parts` lines); load it and restart at `step` with `peers` |
| `RESUME step` | play on |
| `CHAT peer name text [to] [team]` | chat (`peer=0`: a server notice); with `to`, a private line, sent to that player and back to the sender; with `team=1`, a team line, sent to the players in `to` and back to the sender |
| `PING id` | answer with `PONG id=` (every second in the lobby, every 2 seconds during a game); no answer for 20 seconds closes the connection |
| `PLAYERS n peerI nameI stateI rttI quietI stepI` | every 2 seconds during a game, for MULTIPLAYER > PLAYERS: each player (I = 1..n) with `state` `on` or `left`, the average round trip in ms over the last 10 seconds (`-1`: none), seconds since the server last heard from them, and their last reported step. Older clients ignore it |

## Pacing

`mp_server/corsixth_mp/pacing.py`. At Normal and faster one step is one game
hour; at Slower, Slowest and pause the game steps every 54 ms (like Normal)
and an hour passes every 4 (Slower) or 18 to 19 (Slowest) steps, so a click
takes effect as quickly at every speed (World:_mpTick). A peer may run step
*n* only once every other peer reported *n − delay + 1*, so reports must
cross the relay within `(delay − 1)` step durations:

```
(delay − 1) × step_ms ≥ one_way_ms + 9 ms
```

Step durations: 54 ms at Pause, Slowest, Slower and Normal; Max speed 36,
And then some more 18. The server picks the smallest delay (2–6) that keeps
Normal smooth, raises it up to 3 if that allows a faster speed, and allows
the fastest speed that delay keeps smooth (round trips count with a quarter
of their spread). Faster speeds are refused. A click takes effect `delay`
steps later: 2 × 54 ms = 108 ms at Normal and slower.

**Speed changes are commands** (`C kind=set_speed speed=...`), not server
messages, since below Normal the speed decides which steps advance the clock:
every game must switch at the same step. The issuing game checks the room's
limits (top speed, owner only); the server notes the speed for players who
rejoin (a fallback: the shared save carries the speed). (`SPEED` from older
clients is still relayed as before.)

Pause and unpause are `set_speed` at once. **A new speed is voted on**:
`C kind=speed_vote speed=... voters=N` opens the vote (N = the asker's count
of players, so every game uses the same majority, more than N/2 with the
asker counted yes); each other player answers with
`C kind=speed_vote_answer vote=<id> agree=1|0`. The vote is game state
(`world.mp_vote`): the answer that makes the majority applies the speed at
that step on every game, the one that makes it impossible ends the vote, and
an open vote lapses after 30 s of play, counted in steps (each step adds its
world ticks). The fax for it is local to each answering player's screen (not
one of the shared, numbered messages). With one player, or when only the
owner sets the speed, `set_speed` is sent directly.

## Leaving

When a player disconnects during a game the others get `LEFT` with the last
step that player reported. Commands of that player were all sent before the
`LEFT` line, and are for steps nobody has run yet (a command issued after step
*s* is for step *s + delay*, and nobody can run that step before the player's
report of *s + 1*), so every remaining peer applies the same ones and simply
stops waiting for that peer.

## A running game's places

A running game on a server with a referee keeps its places (the peers it
started with). A newcomer who takes one (`JOIN seat=`) gets `JOINED` (with
`standin=1` for a stand-in bot) and `START resume=1`; a bot playing the place
gets `LEFT replaced=1` and is stopped; the others get `HOLD why=rejoin`, and
everybody loads the referee's game. A person who leaves gets a stand-in bot
after `CORSIXTH_MP_STAND_IN_DELAY` seconds (20): the server starts it with
`MP_BOT_STANDIN=1` under their name. When nobody plays, the bots stop and
the room closes; with `CORSIXTH_MP_EMPTY_WAIT` seconds (default 0) the referee
gets `HOLD why=empty` instead (alone it would run on) and the room waits that
long: the first person back starts the bots again, and one load gives
everybody the game. If the last person's connection was lost (it closed
without `QUIT` or `LEAVE`, or went silent) the room waits
`CORSIXTH_MP_DROP_WAIT` seconds (default 300) that way. The game sends `QUIT`
when it leaves a multiplayer game or closes.

The server closes a person's connection it has heard nothing from (no `PONG`
to its `PING`s) for `CORSIXTH_MP_SILENT_DROP` seconds (default 20; 0: never),
as if it had dropped: a connection can die without closing, through a proxy
say. Somebody who joins a room under the name of a person in it whose
connection has been silent for 5 seconds is that person, back: in a room
waiting in the lobby they get the place (its colour, team and the room, if
it was theirs), in a running game the hospital, at once; the silent
connection is closed. `LOAD` names `bots` (the places
the room's own bots play: their hospitals get the hidden bonus) and
`standins` (their hospitals count as away; no hold waits for them), so every
game marks the same hospitals. `ROOM` has `places` for a running room (how
many may be taken); `PLAYERS` has `bot<i>=1`, `standin<i>=1` and an own
bot's `level<i>` (`easy`, `hard`; none for a normal one).

## Repair and rejoin

Only with the headless referee (`referee.md`). After `HOLD`, a game reads no
further lines once it has `LOADEND`: everything after it (the replayed
commands, `RESUME`) belongs to the loaded game and is read after the load.
The server replays every command for a step after the save, also to the
player who sent it, because loading drops every pending command.

With three or more players, when most of them agree with each other and with
the referee (a quorum), only the others are held and load the referee's game
(`REPAIRING` and `REPAIRED` to the rest); when every player agrees and only
the referee differs, one player sends its game and only the referee loads it.
A save keeps every number as it was, an integer an integer and a float a
float (Lua 5.3 and later), so a game loaded alone is the same as the ones
that were not.

## Saving and continuing

Saving is a lockstep command (`save_game`, File > Save) or the monthly
autosave in the simulation: every game saves after the same step into
`<savegames>/Multiplayer/` (`<room> y<Y>-<MM>-<DD>.sav` or `<room>
autosave.sav`) with an `.mpinfo` text file (room, mode, level, difficulty,
step, date, hospitals, players) for the lobby. Continuing: the host creates
the room with `continue=1`; on `START` (with `resume=1`, and in co-op `seats`:
`peer:hospital`, a player getting the hospital with their name, the others
the free ones in order) no game loads a level; the host's game sends the
save, and the server passes it to everybody as `LOAD`/`SAVEDATA`/`LOADEND`/
`RESUME`, like a desync repair.
