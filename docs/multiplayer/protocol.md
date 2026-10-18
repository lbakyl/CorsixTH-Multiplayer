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
| `HELLO` | first line | `proto` (1), `build` (game build id, must match the room's), `name`; the server's referee adds `role=referee`, `room` and `token` |
| `LIST` | lobby | (none) |
| `CREATE` | lobby | `room`, `password` (empty = open), `max` (2–4), `mode` (`shared` = one hospital for everybody, `coop` = one hospital each), `level` (1–12), `difficulty` (`easy`/`full`/`hard`), `speed_control` (`any`/`owner`) |
| `JOIN` | lobby | `room`, `password`; for a running room: rejoin under the name of a player who left |
| `READY` | in a room | `ready` |
| `START` | room owner | (none) |
| `LEAVE` | in a room | (none) |
| `CHAT` | in a room | `text` |
| `SPEED` | in game | `speed`: `Pause` or a speed name up to the room's `max_speed` |
| `SHOW` | in game | cosmetic, outside the lockstep: `kind=blueprint room x y w h` (a room outline being drawn; `w=0` clears it) |
| `DIAG` | after a desync | `step`, `part`, `text`: this game's state (money, rooms, every entity) for the server log, to compare the games |
| `PONG` | reply to `PING` | `id` |
| `PING` | optional | `id` (server answers `PONG id=`) |
| `QUIT` | any time | (none) |
| `HELD` | after `HOLD` | `step`: the last step this game ran |
| `SAVEDATA`, `SAVED` | referee only, after `SAVE` | `d` (base64 part of the save); then `step`, `parts` |

## Server to client

| Message | Meaning |
|---|---|
| `WELCOME proto id server motd` | accepted |
| `ERROR code text` | request refused; codes: `expected_hello`, `protocol`, `bad_room`, `room_exists`, `no_room`, `bad_password`, `build_mismatch`, `running`, `busy`, `room_full`, `in_room`, `not_owner`, `not_ready`, `not_enough`, `bad_speed`, `too_fast`, `bad_report`, `bad_command`, `unknown_verb`, `bad_message`, `not_referee` |
| `ROOM room players max mode level locked state build_ok` | one per room after `LIST`, then `ROOMS_END count` |
| `JOINED room peer owner mode level difficulty max` | you are in the room as player `peer` |
| `PLAYER peer name ready rtt owner` | one per player, followed by |
| `LOBBY room count max mode level delay speed one_way latency` | the room summary: recommended lockstep `delay` (steps), fastest smooth `speed`, worst player-to-player one-way time (ms) and click-to-effect `latency` at Normal speed (ms). Sent about once a second while in the lobby |
| `OWNER` | you are now the room owner |
| `START peer peers names seed level difficulty mode delay max_speed speed speed_control grant_wage_increase free_build_mode` | the game starts: everybody seeds the gameplay random generator with `seed`, loads `level` and plays as `peer` among `peers` (comma-separated, start order; `names` in the same order). A rejoining player also gets `resume=1` and `active` (the players now) and loads no level |
| `SPEED peer name speed` | a player changed the speed (or paused); every client applies it, the sender included |
| `SHOW peer kind ...` | another player's cosmetic information, relayed unchanged with the sender's `peer` |
| `LEFT peer step name` | a player left the game after reporting `step`; stop waiting for them |
| `DESYNC step` | fingerprints differed at `step` and cannot be repaired: the game is over |
| `HOLD step` | stop stepping and issuing commands; answer `HELD` (desync at `step`, or a player rejoins) |
| `SAVE step` | referee only: save once at `step` (or later) |
| `LOAD step parts peers`, `SAVEDATA d`, `LOADEND step` | the shared save (base64 in `parts` lines); load it and restart at `step` with `peers` |
| `RESUME step` | play on |
| `CHAT peer name text` | chat (`peer=0`: a server notice) |
| `PING id` | answer with `PONG id=` |

## Pacing

`mp_server/corsixth_mp/pacing.py`. One step is one game hour. A peer may run
step *n* only once every other peer reported *n − delay + 1*, so reports must
cross the relay within `(delay − 1)` step durations:

```
(delay − 1) × step_ms ≥ 1.25 × one_way_ms + 18 ms
```

Step durations: Slowest 1008 ms, Slower 216, Normal 54, Max speed 36, And
then some more 18. The server picks the smallest delay (2–6) that keeps
Normal smooth, then the fastest speed that delay allows. Faster speeds are
refused (`too_fast`). The trade-off: a click takes effect `delay` steps later,
for example 2 × 54 ms = 108 ms at Normal, but 2 s at Slowest.

## Leaving

When a player disconnects during a game the others get `LEFT` with the last
step that player reported. Commands of that player were all sent before the
`LEFT` line, and are for steps nobody has run yet (a command issued after step
*s* is for step *s + delay*, and nobody can run that step before the player's
report of *s + 1*), so every remaining peer applies the same ones and simply
stops waiting for that peer.

## Repair and rejoin

Only with the headless referee (`referee.md`). After `HOLD`, a game reads no
further lines once it has `LOADEND`: everything after it (the replayed
commands, `RESUME`) belongs to the loaded game and is read after the load.
The server replays every command for a step after the save, also to the
player who sent it, because loading drops every pending command.
