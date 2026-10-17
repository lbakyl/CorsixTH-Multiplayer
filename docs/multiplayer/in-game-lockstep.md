# Experimental multiplayer: lockstep inside the game

From this step on, lockstep is done by the game itself, not by a test
harness. Real UI actions become commands. No host/join screen yet: a session
is started by a script (`scripts/multiplayer/ingame_probe.lua`).

## Pieces

- `CorsixTH/Lua/mp_session.lua` — `MultiplayerSession`: command queue,
  lockstep rule, fingerprint exchange, desync detection, command handlers,
  player notices. Stored as `TheApp.mp_session`, never on the World, so it is
  not written into save games.
- `CorsixTH/Lua/mp_transport.lua` — `MultiplayerTransport`: line-based TCP
  over LuaSocket. Connecting blocks with a timeout; afterwards sending and
  receiving never block the game. LuaSocket is optional; without it
  multiplayer cannot be started.
- `World:onTick` — game time now advances through `World:_advanceHours`.
  Single player calls it exactly as before. In multiplayer each game hour is
  one *step*, run only if the session allows it; otherwise the remaining
  hours of that tick wait and the UI keeps running.

## Lockstep rule

A command issued after step *k* runs at step *k + delay* (delay 2). It is sent
at once. After each step a peer sends `S <peer> <step> <fingerprint>`. A peer
may run step *n* only when every other peer has reported step *n − 1*, so
every command for step *n* has arrived. Same-step commands run in the order
step, peer, sequence. Every handler re-checks validity against the shared
state, so a conflicting action is rejected identically everywhere.

Consequences that come for free:
- **Pause**: if one player pauses, the other stops one step later and waits.
- **Speed**: a faster player is held back by the slower one. Each step is
  always one game hour, so "Speed Up" (8 hours per tick) stays consistent.
- A player that is held back for more than 1.5 s is told
  "Waiting for the other player...". A desync shows an adviser message.

## Player actions

| Action | In multiplayer |
|---|---|
| Buy a corridor object in the shop and click it onto the map | `place_object` command; paid for when it runs on every peer |
| Hire staff and click them onto the map | `hire` command; the profile leaves the shared hiring pool when it runs |
| Build or edit a room, pick up an object or staff member, fire staff, open a pay-rise request | Refused with an adviser message ("not available in multiplayer yet") |
| Anything else that changes the game | Not intercepted yet: would desync (and the desync would be reported) |

Staff in the hiring pool are identified by their position in the pool plus
wage and skill, not by name: names are translated strings and may differ
between players using different languages.

Single player is unchanged: all of the above only applies while
`TheApp.mp_session` exists.

## Results (Linux, two processes, loopback TCP, 2026-10-17)

`run_ingame_probe.sh` (5 checks, ~15 s) and the earlier
`run_sync_probe.sh` (7 checks) all pass.

| Check | Result |
|---|---|
| Single player, same UI actions | Bought and hired immediately, as before |
| Client buys a bench and a plant and hires a doctor through the real windows; tries to pick up an object | IN SYNC 1,500 steps; host applied all 3; pick-up refused |
| Both peers act in the same hour on the same tile; client renders every 3 ticks | IN SYNC; identical accept/reject decisions on both peers |
| Client changes money locally only | DESYNC detected on both peers at step 51 (balance 31,851 vs 31,850) |
| Host pauses for 3,000 ticks; client uses Speed Up | IN SYNC; peers never more than 1 step apart; client told it is waiting |
| Single player 3-year busy run after the `World:onTick` change | Identical to before for all 54,749 hours |

Bug found and fixed on the way: in the original code, when the annual
report pauses the game during a tick, no hourly updates run for that tick.
The first version of the refactor ran one; the single player regression run
caught it at exactly 1 January of year 2.

## Known gaps

- Placements appear 2 game hours after the click. Nothing is shown in the
  meantime, so a player can click a second object onto the same tile and see
  it rejected. Pending placements should be drawn as ghosts.
- Room building/editing, moving and selling objects, firing, pay rises,
  fax decisions, prices, policies, loans, research: not commands yet.
- No host/join screen; sessions are started by a script.
- Only two peers; only hospital 1 (co-build); same build and machine tested.
