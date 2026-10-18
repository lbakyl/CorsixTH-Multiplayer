# CorsixTH-Multiplayer: developer handover

Start here if you are picking up this fork. This page is the map: the current
state, how to build and test, where things are, and what we learned the hard
way. The other files in this folder are detailed reports from each step.

Last updated: 2026-10-18, branch `mp/coop-full`.

## 1. Goal and approach

An experimental multiplayer mod for CorsixTH (an open-source Theme Hospital
remake), planned in this order:

1. **Co-build**: 2–4 players run one shared hospital. *(works)*
2. **Co-op**: one hospital each, with trades between them: money, staff
   transfers; later loans, patient referrals, renting rooms, selling
   research. *(first version works)*
3. **Competitive**: 2–4 humans race for the level goals. AI bot hospitals are
   deferred (lowest priority, not ruled out).

**Sync model: deterministic lockstep.** Every machine runs the full
simulation. Only player *commands* travel over the network, and every peer
applies them at the same game hour in the same order. After each game hour
the peers exchange a short state fingerprint to detect drift.

**Networking: a relay and lobby server** (`mp_server/`, Python, no game
code). Players connect from the game's main menu (Multiplayer), pick or
create a password-protected room, get ready, and the room owner starts.
The server checks that everybody runs the same build, measures ping and
recommends the lockstep delay and fastest smooth speed, starts everyone with
the same seed, level and settings, relays the lockstep messages, compares
fingerprints, and shares speed/pause changes. A headless referee and
desync recovery (milestones S3/S4) are not built yet.

Players bring their own Theme Hospital data (GOG/EA/CD). **Never commit game
data, saves from it, or logs that contain it.**

## 2. Status

| Area | State |
|---|---|
| Linux headless build | Works; Debian 13 recipe in `scripts/multiplayer/setup_debian13.sh` |
| Determinism, same build | Proven for ~3 game years of a busy hospital |
| Single player unchanged | `run_sp_regression.sh`: identical fingerprints for 54,749 hours vs. the pre-multiplayer branch |
| Relay/lobby server | `mp_server/`; rooms, passwords, build check, ping, pacing, start, relay, fingerprint check, leave handling; 19 pytest tests |
| In-game lobby | Main menu → Multiplayer: server address, name, room list, create (shared / a hospital each, level, players), password, ready, start |
| Shared speed and pause | Any player's speed or pause applies to everybody, capped at the room's ping-based maximum |
| Player actions as commands | Corridor objects, hiring, rooms (draw outline/door/windows), opening the hospital early, fax answers, hospital settings (loans, prices, research, policies, plots, heating, handymen, queues), actions on one patient/staff/machine/rat, co-op money and staff transfers |
| Room outlines | While someone draws a room the others see its floor in blue (reserved); the finished room appears for everyone at once |
| Co-op | Original two- to four-player maps (tested with two); a hospital each, kept apart (rooms, staff, patients, heating, research, events, goals); trade window in the Multiplayer menu. Design and open points: `coop-architecture.md` |
| Blocked in multiplayer | Editing/moving existing rooms and objects, picking up staff, firing, pay-rise answers (resolved by policy), load game, restart (menu and hotkeys), cheats and debug tools, pushing patients over, the wage-increase menu setting. Epidemics are off in co-op |
| Windows | CI artifact includes LuaSocket. **S0 passed**: Windows (MSVC) and Linux (GCC), both Lua 5.5, identical for 3 game years; shared and co-op games between a Windows and a Linux player IN SYNC (`cross-platform.md`) |
| Real network | LAN only (Windows desktop ↔ Linux VM); not over the internet yet |
| Linux CI | Fails in the static-analysis step on upstream's own `CMakeLists.txt` formatting (gersemi); not caused by this fork's changes |

## 3. Branches

One branch per step, each stacked on the previous one. PRs #1–#6 cover the
first six; the newer branches have no PR yet (upstream `AGENTS.md` says AI
agents must not open PRs, so the owner opens them).

| Branch | What |
|---|---|
| `mp/runtime-baseline` … `mp/ui-commands` | PRs #1–#6: baseline, determinism probe, cosmetic RNG, busy scenario, commands, in-game lockstep |
| `mp/relay-server` | Relay/lobby server; lobby client, Multiplayer menu and window; shared pause/speed fixes |
| `mp/room-blueprints` | Rooms as commands with reserved outlines; fax decisions as commands |
| `mp/coop-hospitals` | Co-op: a hospital each, money/staff transfers |
| `mp/windows-s0` | LuaSocket in the Windows build; same definition order on every platform; S0 tests |
| `mp/server-docker` | Server container, compose file, image workflow (ghcr.io), VPS guide |
| `mp/coop-full` | Full co-op: settings and entity actions as commands, hospitals kept apart, per-player events, heating, awards, goals |

Working rule: small commits, push work-in-progress, one branch per step,
never push directly to `mp/dev` or `master`.

## 4. Code map

Gameplay code (`CorsixTH/Lua/`):

| File | Role |
|---|---|
| `mp_session.lua` | `MultiplayerSession`: command queue, lockstep rule, fingerprints, desync detection, all command handlers (`place_object`, `hire`, `build_room`, `open_hospital`, `fax_choice`, `give_money`, `send_staff`), retries, remote room outlines, `actionsAreCommands()`, `blockUnsupported()` |
| `mp_lobby.lua` | `MultiplayerLobby`: server connection, build id, rooms, start handshake; starts the level and the session; handles `SPEED`, `LEFT`, `DESYNC`, `SHOW`, `CHAT` during the game |
| `mp_transport.lua` | Line-based TCP over LuaSocket |
| `mp_room_builder.lua` | Builds a finished room for `build_room` with a hidden room editor |
| `dialogs/resizables/multiplayer.lua` | `UIMultiplayer`: the lobby window |
| `dialogs/resizables/multiplayer_trade.lua` | `UIMultiplayerTrade`: co-op trade window |
| `cosmetic_random.lua` | `math.cosmetic_random` for cosmetic choices |
| `world.lua` | Lockstep in `World:onTick`/`_advanceHours`; co-op hospitals, `getUIHospital`, `getTileHospital`, co-op opening countdowns |
| `map.lua` | Loads original multiplayer levels (`"net20"` … `"net44"`) |
| `dialogs/edit_room.lua`, `place_objects.lua`, `place_staff.lua`, `furnish_corridor.lua`, `hire_staff.lua`, `watch.lua`, `fullscreen/fax.lua`, `message.lua`, `bottom_panel.lua` | Player actions turned into commands; fax numbering and game-hour timeouts |

**Everything multiplayer is gated on `TheApp.mp_session`** (and co-op on
`world.mp_coop`). With no session the code paths are the original ones. The
session and lobby live on the App, not the World, so they are never saved.

Server (`mp_server/`): `corsixth_mp/server.py` (rooms, relay),
`pacing.py` (delay/speed from ping), `protocol.py` (line codec); protocol in
`docs/multiplayer/protocol.md`.

Tests and tools (`scripts/multiplayer/` unless noted):

| Path | Role |
|---|---|
| `CorsixTH/Luatest/spec/mp_session_spec.lua`, `mp_lobby_spec.lua` | Unit tests |
| `mp_server/tests/` | Server tests (pytest) |
| `run_lobby_probe.sh` | **Main integration test.** A local server (or `MP_EXTERNAL_SERVER`) and pairs of real games going through the main menu and lobby window. 9 checks, ~3 min |
| `run_ingame_probe.sh` | Two games connected directly (no server). 5 checks |
| `run_sync_probe.sh` | Harness-level determinism checks. 7 checks |
| `run_sp_regression.sh` | Single player, two builds, 3 game years, fingerprints must match |
| `setup_debian13.sh` | Build environment for Debian 13 |
| `setup_lua55_linux.sh` | Lua 5.5 build on Linux (to play with Windows builds) |
| `run_s0_fingerprints.sh`, `compare_fingerprints.py` | Cross-platform determinism check |
| `run_lobby_player.sh` | One scripted player against any server (tests across machines) |
| `lobby_probe.lua` with `MP_SHOT_DIR` | Saves screenshots (PNG) of the lobby views and of game moments (reserved outline, fax, trade window, `shot:<name>` in the UI script). They show graphics from the game data: never commit them |
| `lobby_probe.lua`, `ingame_probe.lua`, `probe_builder.lua` | Scripted players |

## 5. Lockstep in one paragraph

A command issued after step *k* is scheduled for step *k + delay* (delay ≥ 2,
chosen by the server from ping) and sent immediately. After finishing step
*n* a peer sends `S <peer> <n> <fingerprint>`. A peer may run step *n* only
when every other peer has reported *n − delay + 1*. Commands for the same step
run in order (step, peer, seq). Every handler re-validates against the shared
state, so a conflicting command is rejected identically on every peer; a
handler can also ask for a retry a few steps later (rooms wait for people to
walk out). Handlers run with `session.applying` set, so the game code they
call really acts instead of issuing another command.

## 6. Build and test (Debian 13 VM)

```bash
bash scripts/multiplayer/setup_debian13.sh ~/thdata/themehos   # once
. ~/mp-env.sh
cmake -S . -B build -G Ninja -DCMAKE_PREFIX_PATH="$PREFIX" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DUSE_SOURCE_DATADIRS=ON -DENABLE_UNIT_TESTS=ON -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF
cmake --build build -j4
busted --directory=CorsixTH/Luatest          # 144 successes
luacheck --quiet --codes --ranges CorsixTH    # 0 warnings
(cd mp_server && python3 -m pytest -q)        # 19 passed
bash scripts/multiplayer/run_lobby_probe.sh  $BIN $THDATA
bash scripts/multiplayer/run_ingame_probe.sh $BIN $THDATA
bash scripts/multiplayer/run_sync_probe.sh   $BIN $THDATA 6000
```

**Before every push:** busted, luacheck, pytest, the three probe scripts.
**If you touch the simulation path** (world, hospital, entities), also run
`run_sp_regression.sh` against a build of the previous commit.

Running the server: `python3 -m corsixth_mp --port 47800` in `mp_server/`,
or on a VPS with Docker: see `vps-guide.md` (image `ghcr.io/lbakyl/corsixth-mp-server`,
`mp_server/compose.yaml`). In the game: main menu, Multiplayer, server address.

## 7. Lessons learned

1. **Rendering consumed gameplay randomness** (screen shake). Cosmetic code
   must use `math.cosmetic_random`.
2. **`pairs()` order differs between processes** (Lua 5.4 string hashing).
   Never let it decide game state.
3. **Save files are not a state hash.** Use the ordered fingerprint.
4. **Gameplay settings come from each player's config.** The server sends
   them at the start (`grant_wage_increase`, `free_build_mode`).
5. **Names are translated.** Identify things by index or numbers.
6. **Some purchases are charged at confirm.** Check where money moves.
7. **The original tick has quirks single player depends on** (no hourly update
   in the tick the annual report pauses). Preserve them.
8. **Command handlers must not advance game time.**
9. **"Stalled at year end" was the level being lost.**
10. **`UIAdviser:say` needs `{text, priority}`.**
11. **Receptionist: `setHospital()` before `onPlaceInCorridor()`.**
12. **Make the tests fail on purpose too** (negative checks).
13. **A shared pause can arrive in the middle of a tick's step loop.** Reading
    the network inside `canStep()` may set the speed to Pause; running that
    step anyway advanced the date with no hourly ticks, on one peer only.
    Re-check the speed after reading. And keep reading the network while
    paused, or nobody ever receives the unpause.
14. **Some "UI" is simulation.** Fax icons appear after a door animation that
    runs on screen ticks, and their timeout used to start only then: a
    timed-out fax happened at different game hours on different machines. In
    multiplayer all message timers run in game hours from creation, in
    creation order.
15. **Room editing changes shared state before the room exists** (asking
    people to leave, path flags). In multiplayer the drawing player only
    draws; one command builds the room everywhere through a hidden editor
    that is never added to the UI (adding it would close the local player's
    windows: windows with the same modal class replace each other).
16. **`__random` strings use gameplay randomness**, and the number of
    candidates depends on the language: players must use the same language
    (it is part of the build id).
17. **Local config leaks into building**: average room contents and the
    blocking-off-areas rule are fixed while a room command runs.
18. **`getLocalPlayerHospital()` is called by simulation code**, so in co-op
    it must stay the same on every peer (hospital 1). The UI uses
    `World:getUIHospital()`; simulation code that needs the right hospital
    uses the tile owner or the entity's own hospital.
19. **Watches share one modal slot.** A second timer window closes the first,
    and the opening watch exists only for the local player in co-op, so
    timers that matter run in the simulation (`World:_tickCoopOpenings`).
20. **Test timing is not game timing.** Several probe failures were the test
    acting at a step the paused peer never reached; schedule actions on
    conditions, not only on step numbers.
21. **Directory listing order is platform state.** Game definitions are
    loaded in `lfs.dir()` order (ext4 hash order, NTFS name order) and picked
    by index, so Windows and Linux differed from the first patient on. A
    multiplayer game sorts them by id (`MultiplayerLobby.useCanonicalOrder`).
22. **UI windows can hide simulation.** The annual report paid its awards
    when the player closed it, and closing it ran the win check; both
    happened at a different moment on every machine. Look for game changes
    in window `close()` and `onTick()` code.
23. **The room editor's placement checks are not enough for automatic
    furnishing**: a desk could wall off the cabinet, and the GP then crashed
    looking for it. The builder checks that every use tile stays reachable.

## 8. Next steps

1. **Internet test**: the server on the VPS, two Windows clients (S7);
   real latency for the pacing.
2. **S3/S4: headless referee and desync recovery**: the server runs one game
   per room, saves regularly; on desync everyone reloads its save.
3. **VPS**: image, compose file and guide are done (`vps-guide.md`); the
   internet test itself is still to do.
4. **Co-op, missing pieces**: epidemics, emergencies and VIPs for every
   player, level goals per player, per-hospital heating, loans, patient
   referrals, renting rooms, selling research; hide other players' adviser
   messages.
5. **Rooms**: let the drawing player place the objects (now automatic), move
   and sell objects, edit rooms.
6. **Pay rises** as commands; picking up staff/objects as commands.
7. **Encryption** (S8): passwords travel in clear text now.

## 9. Open questions

- **Production networking library.** LuaSocket keeps the code in Lua; the
  alternative is a small C++ binding (ENet or SDL3_net).
- **Cross-platform determinism** (MSVC vs GCC, Lua 5.4 vs LuaJIT): unproven.
- **Upstreaming** generic fixes (cosmetic random stream).
