# Experimental multiplayer: determinism and lockstep probe

Diagnostic only. No gameplay source files are changed. This is the first
Milestone 1 experiment: can two CorsixTH processes run the same game and stay
in sync, with no player commands yet?

## What the probe does

`scripts/multiplayer/sync_probe.lua` runs through the CorsixTH executable
(`--interpreter=`). It:

1. Starts the game normally, then replaces the clock-based random seed with a
   fixed one (`MP_SEED`, default 12345) before loading campaign level 1.
2. Runs an identical scripted setup on every peer: one reception desk near the
   start camera, one receptionist, hospital opened. This stands in for player
   commands, so patients arrive and walk around.
3. Advances the game with `App:onTick` at the fastest normal speed and records a
   **fingerprint** every game hour: date, balance, visitor count, entity count,
   CRC32 of every entity's class and tile in `world.entities` order, and CRC32
   of the MT19937 random state (`math.randomdump()`).
4. In `host`/`client` mode the two processes connect over TCP and exchange
   fingerprints after every game hour. Each waits for the other before
   simulating further (a lockstep barrier). The first mismatch is reported.

The fingerprint is a small explicit gameplay projection, not a save file; save
bytes are not canonical (see runtime-baseline.md).

## Results (Linux, 2026-10-17, same machine, two processes)

| Experiment | Result |
|---|---|
| Two solo processes, same seed, 6,000 game hours | Identical every hour |
| Two solo processes, different seeds | Differ at hour 1 (probe detects differences) |
| One solo process renders a frame every 5 ticks | RNG differs at hour 5; by month 4 entity count and positions differ |
| Host + client over loopback TCP, 6,000 hours | IN SYNC, 6,000/6,000 hourly comparisons |
| Host + client, client renders every 5 ticks | DESYNC reported at hour 5 |
| Host + client, 30,000 ticks | IN SYNC for 18,250 hours (one full game year, 29 visitors, 66 entities) |

The year-long run stopped advancing at 1 January of year 2, presumably because
the annual report window pauses the game. Both peers paused at the same point.
In real multiplayer, modal windows that pause the game need a shared rule.

## What this does and does not show

Shows:
- With a fixed seed and no rendering, the simulation is deterministic across
  independent processes on the same build and machine, for at least one game
  year of light activity.
- A per-hour fingerprint exchanged over TCP detects divergence immediately.
- Rendering (`GameUI:draw` screen-shake `math.random` calls) breaks determinism
  and changes gameplay outcomes, not just RNG state.

Does not show:
- Determinism with real player activity (rooms, many staff, treatments,
  emergencies, epidemics). The scenario is deliberately light.
- Determinism across different machines, compilers, operating systems or Lua
  runtimes (Windows vs Linux, Lua 5.4 vs LuaJIT).
- Anything about real networks: both peers ran on one host over 127.0.0.1.
- Player commands, latency handling, pause/speed agreement, join or resync.

## Next steps

1. Give cosmetic code (screen shake, audio choices) its own random stream so
   rendering never touches the gameplay RNG. Re-run with rendering enabled on
   one peer; expect IN SYNC.
2. Make the scenario heavier (GP office, more staff, longer runs) and look for
   ordering-dependent drift (`pairs` loops that mutate state or consume RNG).
3. Introduce the first real command (e.g. place object) sent between peers
   instead of being scripted identically on both.
4. Repeat on Windows and Windows-to-Linux.

## Running it

Needs luasocket for the binary's Lua version (tested with luasocket 3.1.0-1
from LuaRocks, Lua 5.4). Upstream CorsixTH does not bundle luasocket; choosing
the production networking library is still open.

```bash
"$PREFIX/bin/luarocks" --tree="$RUNTIME_ROOT/rocks" install luasocket 3.1.0-1
export LUASOCKET_TREE="$RUNTIME_ROOT/rocks"
bash scripts/multiplayer/run_sync_probe.sh \
  build/linux-runtime/CorsixTH/corsix-th /path/to/ThemeHospital [CALLBACKS]
```

The runner runs all three checks above (solo pair, networked, networked with
the client rendering) and exits 0 only if they behave as expected. About 30 s
for the default 6,000 callbacks. Output goes to a new temp directory; game data
stays local.

Individual runs can be driven with `MP_MODE`, `MP_SEED`, `MP_CALLBACKS`,
`MP_DRAW_EVERY`, `MP_HOST`, `MP_PORT` and `MP_OUT`; see the header of
`sync_probe.lua`.
