# Co-op architecture: a hospital each

Branch `mp/coop-full` (2026-10-18). This page explains how two to four
players each run their own hospital in one shared world, what had to change
for that, the rules new code must follow, and what is still missing.

## 1. The model

- **One world, simulated everywhere.** Every peer runs the whole game,
  every hospital included (deterministic lockstep, see `README.md`).
- **Hospital *i* belongs to player *i*.** `world.hospitals[1..N]` are
  `PlayerHospital`s; hospital *i* owns the plots of player *i* on one of Theme
  Hospital's original multiplayer maps (`LEVEL.L20`–`L44`, configs
  `NET*.SAM`; map ids `net20`–`net44`). `Hospital:getPlayerIndex()` returns
  `player_index`. There are no computer hospitals in co-op.
- **Each peer looks at its own hospital.** `world.mp_local_index` and
  `World:getUIHospital()` give the hospital this machine's player runs;
  `ui.hospital` is that one. `World:getLocalPlayerHospital()` stays
  hospital 1, because simulation code calls it and every peer must agree.
- **Everything a player does is a command** (`MultiplayerSession:issue`,
  handlers in `mp_session.lua`) carrying the issuer's hospital, applied on
  every peer at the same step. Commands name things by stable identifiers:
  rooms by `room.id`, entities by `entity.mp_id` (assigned in creation
  order by `World:_numberEntity`, the same on every peer), plots by number,
  diseases and research areas by id.
- **What a player sees is local.** Adviser messages, sounds, faxes, watch
  windows and the annual report of another player's hospital are hidden, but
  everything behind them still runs on every peer.

## 2. Rules for new code

1. **No UI code may change shared state.** If a window or click changes the
   game, it must issue a command in multiplayer
   (`MultiplayerSession.actionsAreCommands()`), and the handler does the
   change. A handler must check again that the action still makes sense.
   If there is no command yet, block it (`MultiplayerSession.blockUnsupported`).
2. **No simulation code may depend on the local player.** Don't read
   `ui.hospital`, `getUIHospital()`, open windows (`ui:getWindow(...)`) or
   window timers from simulation code. Use the entity's or room's
   `hospital`, the tile owner (`World:getTileHospital`), or loop over the
   player hospitals in index order.
3. **Timers that matter run in the simulation**, on game hours, never in a
   window (`onTick` counts screen ticks). Example: `World.newCountdown` and
   `World:_tickCoopOpenings` for the opening and emergency countdowns; the
   watch window only displays them.
4. **Gameplay randomness (`math.random`) only from simulation code or
   command handlers**, in the same order on every peer. Cosmetic choices use
   `math.cosmetic_random`.
5. **Hospitals stay apart.** People use only their own hospital's rooms
   (`World:findRoomNear`), staff are only called to their own hospital
   (calls dispatcher), receptionists only take their own desks, VIPs only
   visit and rate their own hospital, rats belong to a hospital.
6. **Gate co-op changes on `world.mp_coop`**, and multiplayer-only changes on
   `TheApp.mp_session`, so single player plays exactly as before
   (`run_sp_regression.sh` checks 3 game years).

## 3. What this branch changed

| Area | Before | Now |
|---|---|---|
| Hospital settings | Windows changed them on one machine | Commands: `loan`, `set_price`, `concentrate_research`, `research_frac`, `set_policy`, `buy_plot`, `set_heat`, `handyman_parcel`, `handyman_prio`, `queue_size` |
| Actions on one entity | Applied locally | Commands by entity id: `send_home`, `guess_cure`, `to_reception`, `staff_bonus`, `raise_wage`, `call_handyman`, `replace_machine`, `shoot_rat`, `mark_vaccinate` |
| Cheats, debug, load/restart hotkeys, pushing patients, crashed-room removal | Worked locally | Blocked in multiplayer |
| Rooms used by people | Any hospital's | Own hospital's only |
| Staff called to rooms, receptionists | Any hospital's | Own hospital's only |
| Patients | To closed hospitals too; disease from hospital 1; 1/N each | Only open hospitals; disease from their hospital; N times as many |
| Research cost | All research rooms | Own research rooms |
| Heating | Hospital 1's setting for the whole map | Each hospital's radiators at its own setting (C++ `update_temperatures`) |
| Annual awards | Paid when the window closed (different moment per machine), local hospital only | Paid at the year end for every hospital, in order; only the local report is shown |
| Emergencies and VIPs | Only player 1; countdown driven by a window | Players take turns; the countdown runs in the simulation |
| Helicopter | Crashed the other players' games | Belongs to the emergency's hospital |
| Earthquakes | Counted the current speed's hours; patients of hospital 1 only | Count the step's game hours; patients of every hospital |
| Adviser | Every hospital's advice to every player | Only to the hospital's player (`PlayerHospital:say`) |
| Level goals | No end in co-op | Each player is told when their hospital reaches or fails them; the game goes on |
| Automatic room furnishing | Could wall off an object's use tile | Keeps every use tile reachable |

## 4. Still missing

- **Epidemics** stay disabled in co-op (`hospital.epidemics_disabled`):
  the epidemic countdown and the vaccination cursor still live in windows.
  Move the countdown to the simulation like the emergency one.
- **Pay rises** are resolved by the hospital policy in multiplayer; the
  raise window is blocked. Needs a command per answer.
- **Moving and selling objects, picking up and moving staff, editing and
  selling rooms, firing**: blocked. Each needs a command with explicit
  positions.
- **Queue reordering and dragging patients between rooms** (queue window):
  not converted yet; not blocked either (see the audit list in the commit
  history of this branch).
- **Placing objects inside a room by hand**: rooms are furnished
  automatically when the command builds them.
- **Trades beyond money and staff**: loans between players, patient
  referrals, renting rooms, selling research.
- **Competitive mode**: a winner, and approval votes for speed and pause.
- **Saving and loading** a multiplayer game, and rejoining (milestone S4).
- **Other players' sounds and announcements** are still heard by everyone
  (cosmetic).

## 5. Tests

`scripts/multiplayer/run_lobby_probe.sh`, checks 8 and 9, play co-op through
the lobby. Check 8 uses every settings and entity command through the real
windows, and check 9 runs an emergency and a VIP visit for player 2. A
9,000-hour busy co-op soak test with both hospitals fully set up (see
`README.md`) passed on this branch, and the single-player regression is
identical for 54,749 hours.
