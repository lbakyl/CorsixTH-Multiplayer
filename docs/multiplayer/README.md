# CorsixTH-Multiplayer: developer handover

Start here if you are picking up this fork. This page is the map: the current
state, how to build and test, where things are, and what we learned the hard
way. The other files in this folder are detailed reports from each step.

Last updated: 2026-10-17, branch `mp/ui-commands` (PR #6).

## 1. Goal and approach

An experimental multiplayer mod for CorsixTH (an open-source Theme Hospital
remake), planned in this order:

1. **Co-build**: two players run one shared hospital on a LAN. *(in progress)*
2. **Co-op**: one hospital each, with trades between them: loans, staff
   transfers, patient referrals, renting rooms, selling research.
3. **Competitive**: 2–4 humans race for the level goals. No AI bots (a
   deliberate decision; bots could become a separate project later).

**Sync model: deterministic lockstep.** Every machine runs the full
simulation. Only player *commands* travel over the network, and every peer
applies them at the same game hour in the same order. After each game hour
the peers exchange a short state fingerprint to detect drift. We chose this
over a host-streams-state model because CorsixTH's simulation already
advances in discrete game hours and turned out to be deterministic once the
problems below were fixed.

Players bring their own Theme Hospital data (GOG/EA/CD). **Never commit game
data, saves from it, or logs that contain it.**

## 2. Status

| Area | State |
|---|---|
| Linux headless build and smoke test | Works (PR #1) |
| Same seed, two processes give identical games | Proven for ~3 game years of a busy hospital (PRs #2, #4) |
| Rendering/audio no longer affect gameplay randomness | Fixed (PR #3) |
| Lockstep inside the game (`MultiplayerSession`) | Works over loopback TCP (PR #6) |
| Real UI actions as commands | Corridor objects (buy and place), hiring |
| Pause / speed | Handled by the lockstep rule; "waiting for the other player" notice |
| Desync detection | Hourly fingerprint; adviser warning on both peers |
| Unsupported actions in MP | Refused with an adviser message: rooms, moving objects/staff, firing, pay-rise requests |
| Host/join screen | **Not started.** Sessions are started by a script |
| Windows | **Not tested yet.** The upstream Windows CI workflow should build the fork, but no successful run has been confirmed |
| Real network / two machines | **Not tested yet.** All tests ran on one Linux machine over 127.0.0.1 |

## 3. Branches and PRs

Each step is a branch stacked on the previous one. None are merged into
`mp/dev` yet. Merge in order (#1 → #6); after merging one, retarget the next
PR to `mp/dev`.

| PR | Branch | What |
|---|---|---|
| [#1](https://github.com/lbakyl/CorsixTH-Multiplayer/pull/1) | `mp/runtime-baseline` | Linux build notes, headless smoke test |
| [#2](https://github.com/lbakyl/CorsixTH-Multiplayer/pull/2) | `mp/sync-probe` | Determinism probe, loopback lockstep experiment |
| [#3](https://github.com/lbakyl/CorsixTH-Multiplayer/pull/3) | `mp/cosmetic-rng` | Separate random stream for cosmetic code (first gameplay-code change) |
| [#4](https://github.com/lbakyl/CorsixTH-Multiplayer/pull/4) | `mp/heavy-scenario` | Busy-hospital scenario, 3-year sync test |
| [#5](https://github.com/lbakyl/CorsixTH-Multiplayer/pull/5) | `mp/first-command` | Harness-level command layer |
| [#6](https://github.com/lbakyl/CorsixTH-Multiplayer/pull/6) | `mp/ui-commands` | Lockstep inside the game, real UI actions, pause/speed |

Working rule we follow: small commits, push work-in-progress, one branch per
step, never push directly to `mp/dev` or `master`.

## 4. Code map

Gameplay code (`CorsixTH/Lua/`):

| File | Role |
|---|---|
| `mp_session.lua` | `MultiplayerSession`: command queue, lockstep rule, fingerprints, desync detection, command handlers (`place_object`, `hire`), `blockUnsupported()`, player notices |
| `mp_transport.lua` | `MultiplayerTransport`: line-based TCP over LuaSocket; non-blocking after connecting |
| `cosmetic_random.lua` | `math.cosmetic_random`: Park-Miller generator for cosmetic choices |
| `world.lua` | `World:onTick` → `World:_advanceHours`; in MP one game hour per step, gated by `session:canStep()` |
| `dialogs/place_objects.lua`, `furnish_corridor.lua` | In MP, placing a new corridor object issues `place_object`; payment happens in the handler |
| `dialogs/hire_staff.lua`, `place_staff.lua` | In MP, placing a new hire issues `hire` |
| `room.lua`, `dialogs/build_room.lua`, `entities/object.lua`, `entities/humanoids/staff.lua`, `dialogs/staff_dialog.lua`, `fullscreen/staff_management.lua`, `dialogs/message.lua` | One-line `blockUnsupported` guards |

**Everything multiplayer is gated on `TheApp.mp_session`.** When it is nil
(single player) the code paths are the original ones. The session lives on
the App, not the World, so it is never written into save games.

Tests and tools:

| Path | Role |
|---|---|
| `CorsixTH/Luatest/spec/mp_session_spec.lua` | 13 unit tests: encoding, ordering, stalls, early/late commands, desync, notices |
| `CorsixTH/Luatest/spec/cosmetic_random_spec.lua` | 6 unit tests |
| `scripts/multiplayer/run_ingame_probe.sh` | **Main integration test.** Two real game processes over TCP, actions through the real windows. 5 checks, ~15 s |
| `scripts/multiplayer/run_sync_probe.sh` | Harness-level determinism/lockstep checks. 7 checks, ~40 s |
| `scripts/multiplayer/run_headless_smoke.sh` | Load, tick, save, reload |
| `scripts/multiplayer/probe_builder.lua` | Drives the room editor, object placement and hiring without a mouse; used to build test hospitals |
| `scripts/multiplayer/sync_probe.lua`, `commands.lua` | Harness from PRs #2–#5. Superseded by `mp_session.lua` for real play but kept as a regression test |

## 5. Lockstep in one paragraph

A command issued after step *k* is scheduled for step *k + 2* and sent
immediately (`C key=value ...`, keys sorted, values percent-encoded). After
finishing step *n* a peer sends `S <peer> <n> <fingerprint>`. A peer may run
step *n* only when every other peer has reported *n − 1*. That guarantees all
commands for step *n* have arrived, keeps peers at most one step apart, and
makes pause and speed work with no extra protocol: a paused or slow peer
simply holds the other back. Commands for the same step run in order
(step, peer, seq). Every handler re-validates against the shared state, so a
conflicting command is rejected identically on every peer.

## 6. Build and test (Linux)

The full dependency recipe is in `runtime-baseline.md`. In short: SDL 3.4.18,
SDL_mixer 3.2.4, FluidSynth 2.4.8 and zstd 1.5.7 built into a prefix, then:

```bash
cmake -S . -B build/linux-runtime -G Ninja -DCMAKE_PREFIX_PATH="$PREFIX" \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DUSE_SOURCE_DATADIRS=ON \
  -DENABLE_UNIT_TESTS=ON -DFETCH_CATCH2=ON \
  -DWITH_MOVIES=OFF -DWITH_UPDATE_CHECK=OFF -DWITH_MIDI_DEVICE=OFF
cmake --build build/linux-runtime -j2
```

LuaRocks tree with `busted`, `luacheck` and `luasocket 3.1.0-1` for Lua 5.4:

```bash
eval "$(luarocks --tree="$ROCKS" path)"
busted --directory=CorsixTH/Luatest          # expect 136 successes
luacheck --quiet --codes --ranges CorsixTH    # expect 0 warnings
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib" LUASOCKET_TREE="$ROCKS"
bash scripts/multiplayer/run_ingame_probe.sh build/linux-runtime/CorsixTH/corsix-th /path/to/ThemeHospital
bash scripts/multiplayer/run_sync_probe.sh  build/linux-runtime/CorsixTH/corsix-th /path/to/ThemeHospital 6000
```

**Before every push, run:** busted, luacheck, both probe scripts. **If you
touch `world.lua`, `hospital.lua`, entity code or anything else on the
simulation path**, also run the single-player regression: a busy 3-year solo
run (`MP_SCENARIO=busy MP_CALLBACKS=80000` with `sync_probe.lua`) must produce
fingerprints identical to the previous build for all 54,749 hours. That run
caught a real bug (lesson 7).

## 7. Lessons learned

These cost real debugging time. Read them before changing anything.

1. **Rendering consumed gameplay randomness.** `GameUI:draw` called
   `math.random()` for screen shake on every frame, even with no earthquake.
   Different frame rates gave different games. Cosmetic code must use
   `math.cosmetic_random`. Rule: anything that can run a different number of
   times on different machines (drawing, audio, UI, announcements) must not
   touch `math.random`.
2. **`pairs()` order differs between processes.** Lua 5.4 randomises string
   hashing per process. `UIEditRoom` builds its object list with `pairs()`,
   so the GP's furniture landed in different places in different runs. Never
   let `pairs()` order decide game state; sort keys, or have commands carry
   explicit positions.
3. **Save files are not a state hash.** The persistence layer walks tables in
   `lua_next` order and includes UI state. Use an explicit, ordered gameplay
   fingerprint (`MultiplayerSession.defaultFingerprint`).
4. **Gameplay-affecting settings come from each player's config.**
   `grant_wage_increase` (and likely `free_build_mode`, difficulty and
   others) must be agreed when the session starts. Without it, staff were
   fired on one machine only.
5. **Names are translated.** Staff names are `LocalisedString` objects that
   differ between languages. Identify game objects by position, index or
   numeric attributes, never by display text. (Hires use pool index + wage +
   skill.)
6. **Some purchases are charged at confirm, not at placement.** The corridor
   shop charges in `UIFurnishCorridor:confirm`. In MP that charge is skipped
   and the `place_object` handler pays. Check where money moves before
   turning an action into a command.
7. **The original tick has quirks that single player depends on.** When the
   annual report pauses the game mid-tick, the original `World:onTick` runs
   no hourly update for that tick. The first refactor ran one; only the
   3-year regression run caught it. Preserve such behaviour exactly
   (`loop_hours = min(hours, self.hours_per_tick)` in `_advanceHours`).
8. **Command handlers must not advance game time.** Building a room normally
   waits for people to leave the area. In a command it must fail on every
   peer instead (`build_room(..., no_wait)` in the harness).
9. **"The game stalled at year end" was really the level being lost**
   (back to the main menu). Probes now detect level end. Check for that
   before blaming sync.
10. **`UIAdviser:say` needs a table `{text = ..., priority = ...}`**, not a
    plain string. It asserts.
11. **The receptionist needs `setHospital()` before `onPlaceInCorridor()`.**
12. **Make the tests fail on purpose too.** Every probe script has a negative
    check (different seed, dropped command, local-only change) that must
    report DESYNC. Without those, "IN SYNC" could just mean the check is
    broken.

Sandbox-specific notes for AI agents continuing this work: there is no
`diff`/`cmp` (use Python); long software-rendered runs exceed a ~290 s
command limit, so run them with `nohup` in the background; GitHub pushes go
through the API, so `git reset` to the remote branch afterwards to keep the
local clone in step.

## 8. Next steps

1. **Pay rises and fax decisions as commands.** Currently pay-rise requests
   are blocked and resolve by policy; fax choices (VIPs, emergencies,
   epidemics) are not intercepted at all and would desync.
2. **Host/join screen.** Enter an address and port, start the session, and
   agree on the seed, level and gameplay settings (lesson 4).
3. **First Windows test.** Two laptops on a LAN. Needs LuaSocket in the
   Windows build (vcpkg port or bundled DLL) and a firewall rule for the
   game port.
4. **Ghost previews for pending placements.** Items appear two game hours
   after the click, with nothing shown in between.
5. **More actions as commands:** rooms (with explicit object positions),
   moving and selling objects, firing, prices, policies, loans, research.
6. **Resync/rejoin** from a host save; **more than two peers**; **one
   hospital per player** (`Hospital:getPlayerIndex`, plot ownership, the
   `getLocalPlayerHospital()` call sites) for co-op and competitive modes.

## 9. Open questions

- **Production networking library.** LuaSocket works and keeps the code in
  Lua, but upstream dropped it. The alternative is a small C++ binding
  (ENet or SDL3_net).
- **Cross-platform determinism.** Windows vs Linux, MSVC vs GCC, Lua 5.4 vs
  LuaJIT floating point: unproven. Ideally the mod would refuse to start a
  session unless both peers run the same build.
- **Upstreaming.** Generic fixes like the cosmetic random stream (#3) could
  be offered to upstream CorsixTH separately.
