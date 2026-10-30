# Headless referee, desync repair and rejoin (S3/S4)

The relay server can run one extra copy of every game: the **referee**. It is
CorsixTH itself without a screen (`scripts/multiplayer/referee.lua`), started
by the server when a room's game starts. It plays the same game as the
players from the same commands, never issues a command, and the players never
wait for it.

It gives three things:

1. **A second opinion.** When the players agree on a step, the server also
   compares their fingerprint with the referee's.
2. **Desync repair.** When games differ, the server holds every game, the
   referee sends its saved game, and everybody (the referee too) loads it and
   plays on from there. Nobody restarts.
3. **Rejoin.** A player whose game crashed or who left can connect again,
   join the running room under the same name, and is back in the game.

Without a referee the server works as before: a desync ends the game, and a
player who left cannot come back.

## Turning it on

The referee is off unless `CORSIXTH_MP_REFEREE_BINARY` is set. It needs a
CorsixTH build of the same version as the players (the build id must match;
it includes the Lua code checksum and the language), its source tree, Theme
Hospital data and LuaSocket.

| Variable | Meaning |
|---|---|
| `CORSIXTH_MP_REFEREE_BINARY` | the `corsix-th` executable |
| `CORSIXTH_MP_REFEREE_SOURCE` | CorsixTH checkout (for `CorsixTH/` and `scripts/multiplayer/referee.lua`) |
| `CORSIXTH_MP_REFEREE_DATA` | Theme Hospital data folder (read only is enough) |
| `CORSIXTH_MP_REFEREE_LUA_CPATH`, `..._LUA_PATH` | where LuaSocket is, if not in the standard paths |
| `CORSIXTH_MP_REFEREE_WORKDIR` | configs and logs, one folder per game (default `/tmp/corsixth-referee`) |

### Only the referee's build may connect

With a referee, the server turns away every player whose game code is not the
referee's, right at `HELLO` (they could make rooms, but nobody could referee
them or add bots to them). It compares only the Lua code checksum, the last
part of the build id, so the language does not count. The refusal names the
release to get; the lobby window shows "Other game version: get
mp-test-6d85201a on GitHub", and newer games also offer a button that opens
the release page.

| Variable | Meaning |
|---|---|
| `CORSIXTH_MP_RELEASE` | the release players must get, e.g. `mp-test-6d85201a` (`setup-referee-host.sh` writes it) |
| `CORSIXTH_MP_RELEASE_URL` | its download page (default: the GitHub release page of `CORSIXTH_MP_RELEASE`) |
| `CORSIXTH_MP_BUILD` | the checksum players must have; default: computed from `<CORSIXTH_MP_REFEREE_SOURCE>/CorsixTH/Lua` at start; `any`: let every build in |

The server log says `players must have build <checksum> (<release>)` at
start, and `refused: build ...` for each player turned away.

Example on the dev VM (see `README.md`, section 6, for the build):

```
export CORSIXTH_MP_REFEREE_BINARY=$BIN CORSIXTH_MP_REFEREE_SOURCE=~/CorsixTH
export CORSIXTH_MP_REFEREE_DATA=$THDATA
export CORSIXTH_MP_REFEREE_LUA_CPATH="$LUASOCKET_TREE/lib/lua/5.4/?.so"
export CORSIXTH_MP_REFEREE_LUA_PATH="$LUASOCKET_TREE/share/lua/5.4/?.lua"
PYTHONPATH=mp_server python3 -m corsixth_mp --port 47123
```

The server log shows `headless referee enabled`, then for each game
`referee started`, `referee connected` and, when the room closes, `referee
confirmed steps through N`. The referee's own log is
`<workdir>/<room>-<id>/referee.log`.

On a VPS, `mp_server/deploy/setup-referee-host.sh` sets it all up in one
command: the server as a systemd service (instead of the Docker container),
the Linux package of a test release as the referee, the server code from the
same commit, and your game data readable only by the service account:

```
sudo bash setup-referee-host.sh --release mp-test-<commit> --data /path/to/themehos
```

Run it again with each new release (without `--data`): the referee must run
the same build as the players, or the server starts no referee for their
games (it logs "referee build ... differs") and a desync ends the game as
before. Restarting drops the players, so check that nobody is playing. The
game binary needs some desktop libraries (sound, X11, Wayland) to start even
though the referee shows nothing; the script installs them. The Docker image
has no referee.

## How it works

**Start.** On `START` the server makes a random token for the room and starts
the referee, which connects back to `127.0.0.1` with `HELLO role=referee room
token`. It gets the same `START` as the players with `peer=0` (not in
`peers`). It usually connects half a second or more after the players
started, so the server keeps every command and `LEFT` of the room and replays
them, with each player's latest step report, before the live lines.

**Checking.** The referee sends `S 0 <step> <fp>` like a player; the server
never relays it. When all players agree on a step, the server compares with
the referee's fingerprint, whichever arrives second.

**Repair.** On a mismatch (players among themselves, or players and
referee):

1. The server sends `HOLD` to every player. Each stops stepping and issuing
   commands and answers `HELD step=<its step>`. Commands sent before that are
   still logged.
2. When all players have stopped, the server sends `SAVE step=<lowest held
   step>` to the referee. The referee runs up to that step (it has every
   command for it), saves (`persist.compress(SaveGame())`, base64, in
   `SAVEDATA` lines of 48,000 characters), sends `SAVED step parts` and
   holds.
3. The server sends to everybody, the referee included: `LOAD step parts
   peers`, the `SAVEDATA` lines, `LOADEND`, every logged command for a step
   after the save, then `RESUME`.
4. Each game loads the save between two ticks (`App:onTick`), shows its own
   hospital again (co-op), restarts the lockstep at that step with the
   players named in `LOAD`, and takes the replayed commands. On `RESUME` it
   plays on at the shared speed.

Everybody loads the same bytes, the referee too, so all games continue from
an identical loaded state. Nobody goes back further than the slowest player
had played. If the referee does not answer within 60 seconds, or
disconnects, the server falls back to `DESYNC` and the game is over as
before.

**Rejoin.** A `JOIN` for a running room is accepted when the name matches a
player who left (case does not matter) and the room has a referee. The
player gets `JOINED` and `START` with `resume=1` and `active` (the players
now): its game loads no level and waits. The server then runs the same repair
as above; the rejoining player has no game yet and counts as stopped. The
`LOAD` line names the rejoined player among the `peers`, so every game waits
for them again.

### Only the referee's Theme Hospital data may connect

Editions of Theme Hospital differ in their level files: the GOG version and
older downloads have other multiplayer maps (`LEVEL.L20` ... `L44`) and level
settings (`NET00.SAM`, `FULL02`-`04.SAM`), and games with both drift apart
(desyncs the referee keeps repairing). The game sends a CRC-32 of its
`FULLnn.SAM`, `NETnn.SAM` and `LEVEL.Ln` files in `HELLO` (`data`,
`MultiplayerLobby.dataId`); a server with a referee computes the same over
`CORSIXTH_MP_REFEREE_DATA` and refuses other data ("Your Theme Hospital files
differ from this server's"; newer games explain it in a window). Older games
send no `data` and are let in. `CORSIXTH_MP_DATA` sets the value (8 hex digits)
or `any`. The GOG version is `899c66d0`. The server log says
`players must have Theme Hospital data <id>` at start.

### A desync in the random numbers only

Sometimes two games differ only in their random numbers (`rng=` in the
fingerprints): one game drew a number the others did not, and nothing else
differs yet. While a multiplayer game runs, every `math.random` call notes its
step and source line (the last 2,000, `MultiplayerSession.traceRandomDraws`);
after a desync each game's diagnostics in the server log end with that list
("random <n> draws, the last ..."). To see which line drew in one game only:

```
sudo journalctl -u corsixth-mp --since today | python3 scripts/multiplayer/compare_draws.py - "<room>"
```

It compares each game's list with the referee's; the extra (`+`) or missing
(`-`) entry is the culprit.

### A desync in people or money

When the random numbers agree but people stand elsewhere or a balance
differs, the draws show nothing. Every game also keeps, for the last few
steps, each person's tile, action and target and each hospital's last five
money transactions (`MultiplayerSession.stepDetail`), and after a desync sends
those of the desync step itself ("AT STEP <n>: ..."), the same step in every
report. To list what differs from the referee's game:

```
sudo journalctl -u corsixth-mp --since today | python3 scripts/multiplayer/compare_states.py - "<room>"
```

Fax answers are logged with what they answered (`fax_choice -> ok (mp_offer:
mp_offer_accept)`), so a desync after one can be traced to it.

## Tests

- `mp_server/tests/test_server.py`: referee hello and token, catching up,
  fingerprint check, repair, timeout, rejoin (26 tests in total).
- `MP_REFEREE=1 scripts/multiplayer/run_lobby_probe.sh BIN DATA` runs the ten
  lobby checks with a referee and adds four:
  11. the referee agrees with the players in all eight rooms;
  12. shared game: one player changes money locally at step 300; both load
      the referee's game at step 301 and play on to step 1000 in sync, with
      commands after it;
  13. the same in a co-op game (step 401);
  14. a co-op player quits at step 300 and joins again in a new game process;
      both play on to step 1500 in sync, with commands after the rejoin.

## Limits and next steps

- Saves are only made for a repair or a rejoin. Regular saves (and keeping
  the command log short with them) are a small addition: `SAVE` without a
  hold.
- A crashed referee is not restarted; the room then plays on without one.
- The player's camera and open windows are those of the referee after a
  load (the map position is the referee's default).
- Rejoining is matched by name; the room password is the only protection.
- The referee runs at full speed as a normal process; one per running game.
