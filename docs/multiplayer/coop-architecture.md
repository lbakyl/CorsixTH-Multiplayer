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
- **Players act on their own hospital only.** Everyone can look at every
  patient, member of staff and machine, but each command that acts on one
  checks that it belongs to the sender's hospital (`ours()` in
  `mp_session.lua`), and the windows about another player's ones are for
  looking only (`MultiplayerSession.viewOnly`).
- **Staff transfers walk.** `send_staff` takes the person off the sender's
  staff list; they walk over (at a brisk pace) and join the other hospital
  on arrival (`World:_tickCoopTransfers`). On the way they belong to neither
  hospital, are not paid, and take no orders. On the original two-player
  map the walk takes about ten game days.

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
| Actions on one entity | Applied locally | Commands by entity id: `send_home`, `guess_cure`, `to_reception`, `staff_bonus`, `raise_wage`, `call_handyman`, `replace_machine`, `shoot_rat` (own hospital's rats only), `mark_vaccinate`, `remove_crashed_room` (with the single player "remove destroyed rooms" option on) |
| Sending staff, referring patients | Staff moved at once | Offers the other player accepts: `offer_staff`, `offer_patient` (purple icon; see below) |
| Epidemics | Off in co-op | Cover-up countdown in the simulation (`World:_tickCoopOpenings`), the watch only shows it to the owner |
| Cheats, debug, load/restart hotkeys, pushing patients | Worked locally | Blocked in multiplayer |
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

- **Offers** (`mp_session.lua`, `dialogs/resizables/multiplayer_offer.lua`):
  sending a member of staff (trade window) or referring a patient (purple
  icon in the patient window, or "Refer to another hospital" on the "no
  treatment" and "no diagnosis" faxes) creates a message of type
  `mp_offer` on every peer, shown only to the receiving player as a purple
  icon. Its window shows the person; Accept and Decline are `fax_choice`
  commands, and 20 game days without an answer decline it (the VIP fax
  waits as long, but its default is yes). An accepted person walks over at
  the "transit" speed and joins the other hospital on arrival
  (`World:_tickCoopTransfers`). With more than one other player, the
  sender chooses the hospital. Emergency, infected and in-room patients
  cannot be referred.
- **Staff and objects** are commands with explicit positions: firing
  (`fire_staff`), pay rise answers (`pay_rise`), the queue window
  (`queue_move`, `queue_redirect`), moving and selling corridor objects
  (`move_object`, `sell_object`) and moving staff (`move_staff`: the player
  chooses the tile in a placement window on their machine only; every peer
  then picks them up and puts them down at once, PickupAction with
  `mp_place`).
- **Rooms** are commands throughout (`mp_room_builder.lua`): building
  (`build_room`, with `furnish=1` furnished by hand: `room_object`,
  `room_pickup`, `room_buy`, then `room_finish`), editing a built room
  (`room_edit`: it empties, then the same editor commands), moving or
  resizing (`room_unbuild`, then `room_rebuild` with the new outline, door
  and windows) and removing (`room_delete`, or `room_abort` for a room
  closed unfinished). Every peer keeps an editor for such a room and runs
  the single player editor code on it; only its player's machine shows it.
  A player who leaves hands their rooms over (`room_takeover`: finished, or
  removed if their walls are down).
- **Trades beyond money, staff, patients and research**: loans between
  players, renting rooms.
- **Research sharing** (done on `mp/research-sharing`): `offer_research`
  {to, items, price} offers equipment discoveries (`e:<object>`), drug
  improvements (`d:<disease>`) and machine improvements (`m:<object>`) that
  the receiver lacks, for $0 to $20,000. It is a message of type
  `mp_research` (purple icon with a flask) answered in the fax window
  (`fax_choice`); on acceptance the receiver pays and gets what it still
  lacks then (`MultiplayerSession.resolveOffer`). In multiplayer the
  research code visits its tables in a fixed order (`research_pairs`),
  since it picks "the first" or "the last" of several targets.
- **Competitive mode**: a winner, and approval votes for speed and pause.
- **Loading** a multiplayer save from the game's Load menu (stays blocked;
  saved games are continued from the lobby, see `protocol.md`). Rejoining
  and desync repair from the server's referee are done: `referee.md`.
- **Other players' sounds and announcements** are still heard by everyone
  (cosmetic).

## 5. Tests

`scripts/multiplayer/run_lobby_probe.sh`, checks 8 and 9, play co-op through
the lobby. Check 8 uses every settings and entity command through the real
windows, and check 9 runs an emergency and a VIP visit for player 2. A
9,000-hour busy co-op soak test with both hospitals fully set up (see
`README.md`) passed on this branch, and the single-player regression is
identical for 54,749 hours.
