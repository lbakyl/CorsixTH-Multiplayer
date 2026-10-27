# Competitive mode (a race, with dirty tricks)

Branch `mp/competitive`, based on the stable release `mp-stable-64bede76`.

A third room mode next to `shared` and `coop`. The game runs exactly like
co-op (a `PlayerHospital` per player on an original multiplayer map, every
player action a lockstep command, `world.mp_coop` set), with
`world.mp_coop.competitive = true`. Everything below is gated on that flag;
co-op and shared games are unchanged.

## Mode plumbing

- `MultiplayerLobby.MODES` = shared, coop, competitive;
  `MultiplayerLobby.hospitalEach(mode)`, `modeLabel(mode)`,
  `worldMode(world)` (for the `.mpinfo` of a save and the menu).
- Lobby window: the mode button cycles through the three.
- Server: `MODES` and `HOSPITAL_EACH` (continued games seat players by name
  in both co-op and competitive).

## The race (world.lua)

- `World:checkIfGameWon` calls `World:_mpRaceCheck` in a competitive game
  (end of months 3/6/9 and at each year end, like co-op).
- A hospital that reaches the goals gets `mp_place` (1, 2, ...) and
  `mp_place_how = "won"`; its player alone gets an information fax with
  `mp_leave_game` (back to the lobby: `UIFax:choice` finishes only on that
  player's machine, never on the referee) or `stay_on_level` (watch).
- Year end: a hospital still failing the goals at the second year end in a
  row is out (`mp_place_how = "out"`, places counted from the bottom).
- `World:_mpRaceCheckOver`: at most one hospital still racing -> it takes the
  place left (`"last"`), `world.mp_race_over`, the standings fax to
  everybody (back to the lobby for all, or keep playing).
- A placed hospital (`mp_place` set) gets no patients (`_coopPatientHospital`,
  `_patientsCanArrive`) and no VIP or emergency turns (`_coopTurn`). It keeps
  running otherwise.
- PLAYERS window: the Goals column shows the place or "out"
  (`World:mpPlaceText`).

## Dirty tricks (mp_sabotage.lua, UIMultiplayerSabotage)

One command, `sabotage` {trick, level, to} (`kind` is the command's own name).
`sabotage.refusal` checks the same conditions in the window (an answer at
once) and in the handler (the same on every peer); the buyer pays when it is
done (`spendMoney`, "Dirty tricks"). Prices in `sabotage.PRICES`.

- **Evil handyman.** A new `Handyman` (fresh `StaffProfile`) with
  `mp_saboteur = {owner, target, level, hours}`, walking from the buyer's
  hospital like a transferred member of staff (`mp_in_transit`,
  `world.mp_transfers`); `World:_tickCoopTransfers` hands him to
  `sabotage.arrived`. He is in no hospital's `staff` list (nobody pays him,
  the staff list does not show him), but `hospital` is the target's (so the
  target can click him; his staff window is theirs). `Staff:tick` runs
  `sabotage.tick` instead of the usual rest and pay rise logic, and
  `Handyman:searchForHandymanTask` does nothing for him.
  - He does not meander (that wandered off over the plot outside the
    building); the tick walks him between random corridor tiles of the
    target's building (`sabotage.corridorTile`), standing between walks.
  - Level 2+: litter (`World:newLitter`, trash) on his corridor tile every
    25 hours (twice a game day).
  - Level 3+: every 150 hours he "repairs" the target's machine with the
    most uses left (`sabotage.pickMachine`, game order), like a handyman on
    a call: into the room (`Room:onHumanoidEnter` lets him in without
    answering calls), to its repair tile, waits until nobody uses it, locks
    the room as a repair does and plays the repair
    (`sabotage.fakeRepairTick`). When that is over the machine is worn down
    to two uses (`sabotage.damage`: smoke, the repair call) and he walks
    out. He gives up after 200 hours if he cannot get there.
  - He stays `sabotage.STAY_DAYS` (120, 90 or 60 game days for L1, L2, L3,
    counted from when he was sent), then goes home (`sabotage.goHome`:
    despawns like a sacked member of staff; only the sender is told).
  - Thrown out: `fire_staff` on him (the sack button, by the hospital he is
    in) -> `sabotage.throwOut`: `MultiplayerSession.transferStaff` to the
    owner, where he arrives as an ordinary handyman (on the payroll). He
    cannot be picked up (`move_staff`) or offered to someone else.
- **Epidemic.** `sabotage.startEpidemic`: 2/4/7 patients of one contagious
  disease, by the helipad (or a map edge), `addToEpidemic`; the epidemic then
  runs as any other (reveal, cover-up countdown, inspector).
- **Emergency.** `sabotage.sendEmergency`: `hospital.emergency` with 3/6/10
  victims, then what accepting the fax does (helicopter,
  `mp_emergency_timer`, the watch for its player) and an information fax
  that says it cannot be refused. Level 3 may pick a disease the target has
  not discovered.

- **Rat attack.** `sabotage.ratAttack`: `Hospital:mpAddRatholes` (random
  corridor wall spots near the target's start view; the daily rathole update
  tries spots over the whole map and seldom hits a small hospital), then
  5/10/20 rats (`spawnRat`) with `mp_attack_rat`. Such a rat runs on to
  another hole instead of going in (`Rat:_arrive`); `sabotage.dailyRats`
  (from `Hospital:onEndDay`) takes a reputation point per live attack rat a
  day and ends the attack after 60 days. Shooting is the existing
  `shoot_rat` command (a click). In the original rules rats only run from
  hole to hole and are a target for the rat-catching award; they do no harm.

## Window and Progress Report

- Rivals' hospitals are closed to the mouse: `GameUI:_isRivals` drops a
  hovered entity in a rival's building, or a person of a rival's hospital
  outside your own (no staff or patient windows, door queues, bottom panel
  details or hover cursor). The evil handyman in your own hospital stays
  clickable (his `hospital` is yours). Co-op teams still see each other.
- Sounds of a hospital (sack, calls to a room, repairs, cheers, VIPs and so
  on) play only for its own player (`World:isUIHospital`); every peer still
  runs the code around them.

- DIRTY TRICKS: the first click on a level shows what it does in a box
  (`sabotage_levels`), a second click buys it.
- Progress Report (any multiplayer game with a hospital each): it opens on
  the player's own hospital (not hospital 1), and the other players' names
  can be clicked to see their goal bars, share of the town and patient
  happiness, thirst and warmth. The criteria tooltips still give the
  player's own values; the warnings are only for the own hospital.

## Fixed on the way

`UIBottomPanel:canQueueFax` checked epidemic/emergency fax clashes across
every hospital and `cancelFax` then cancelled the event of the *local*
player's hospital (different on every computer: a desync, or a crash on a
nil epidemic). In multiplayer with a hospital each, only faxes of the same
hospital clash now, and the cancelled event is that hospital's.

## Tests

`scripts/multiplayer/run_competitive_probe.sh BIN DATA` (three scripted
players on level 2; `MP_REFEREE=1` adds the headless referee and a 5th check):
1. tricks as commands; a second emergency refused at once;
2. the evil handyman arrives, drops litter, wears the cardiogram machine
   down, is thrown out and works for the buyer;
3. a rat attack: ten rats, the target's reputation falls, one is shot;
4. places, a winner leaving alone, elimination at two year ends, final
   standings; the others IN SYNC to the end;
5. (referee) no repairs, confirmed to the end.

Probe actions: `sabotage:<trick>:<level>:<hospital>`, `kickevil`, `shootrat`, `race`;
`MP_MODE=competitive` for the host.

## Ideas not done yet

See the report in the session; the main ones: a security guard or CCTV to
spot evil handymen, poaching a rival's staff, a smear campaign (reputation),
bribing the health inspector or a VIP, insurance against
tricks, a cooldown between tricks, and showing the race (places and goal
progress) on the town map or the status bar.
