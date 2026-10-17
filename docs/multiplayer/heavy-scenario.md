# Experimental multiplayer: busy-hospital determinism test

Diagnostic only; no gameplay source files are changed by this step.

## Scenario (`MP_SCENARIO=busy`)

On top of the light scenario (reception desk, receptionist, hospital open):

- Rooms built **through the game's own room editor** (`UIEditRoom`), driven
  without mouse input by `scripts/multiplayer/probe_builder.lua`: GP's office,
  pharmacy, general diagnosis, staff room, toilets.
- Staff: 3 doctors, 2 nurses, 2 handymen (plus the receptionist).
- Corridor objects: 4 benches, 2 plants, a drinks machine.
- `grant_wage_increase = true` in the probe config, so unanswered pay-rise
  requests are granted instead of staff being fired.
- Annual report windows are closed automatically at the same game moment on
  every peer.
- If the level is won or lost, the probe stops and, in host/client mode,
  checks that both peers ended after the same game hour.

Level 1 is lost at the end of year 3 ("killed more than 50 percent of the
patients"): it has no treatment rooms beyond the pharmacy. For a stress test
that is fine; both peers lose at the same hour.

## Results (Linux, 2026-10-17, one machine, Lua 5.4)

| Run | Result |
|---|---|
| Two solo processes, same seed, until level end | Identical for all 54,749 game hours (~3 years): 130 visitors, 21 cured, 8 staff, 2 annual reports |
| Host + client over TCP, host renders every 7 ticks, client every 2 | IN SYNC 54,749/54,749 hours; both lost the level after the same hour |
| Same pair vs. a solo run with no rendering | Fingerprints identical for every hour |
| Busy setup run 8 times in parallel | Identical setup every time (after the fix below) |

Wall time for the networked 3-year run with rendering: about 8 minutes.

## Findings

1. **Lua table order is not stable between processes.** `UIEditRoom` builds
   its list of required objects with `pairs()` over a string-keyed table. Lua
   5.4 randomises string hashing per process, so the GP's chair and cabinet
   were placed in different orders, and therefore different positions, in
   different runs (3 variants in 8 runs). The probe builder now places objects
   in name order. In real multiplayer this exact case is harmless, because a
   build command will carry explicit object positions, but it is concrete
   evidence that `pairs()` order can leak into game state.
2. **Gameplay-affecting settings must match on every peer.** Staff kept
   quitting because `grant_wage_increase` was off and nobody answered their
   pay-rise requests. Settings like this (and `free_build_mode`, difficulty
   etc.) must be agreed at game start, not read from each player's config.
3. **The year-end stall in earlier runs was the level being lost**, which
   returns to the main menu. Earlier year-long results remain valid for
   year 1 only.
4. **Pay-rise requests, annual reports and similar windows are player
   decisions.** In multiplayer they have to become commands (or follow a
   shared policy); the probe currently grants and closes them automatically.

## Not covered

Emergencies and epidemics were not deliberately triggered; wards, surgery,
research and many diseases do not exist on level 1. Same build, same machine,
loopback only.
