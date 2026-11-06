# Competitive mode (a race, with dirty tricks)

Branch `mp/competitive`, based on the stable release `mp-stable-64bede76`.

A third room mode next to `shared` and `coop`. The game runs exactly like
co-op (a `PlayerHospital` per player on an original multiplayer map, every
player action a lockstep command, `world.mp_coop` set), with
`world.mp_coop.competitive = true`. Everything below is gated on that flag;
co-op and shared games are unchanged.

## Mode plumbing

- The room decides the mode: every player picks a colour (1-4, the
  hospital; the same colour shares one) and a team (1-4, who they win
  with). `MultiplayerLobby.deriveMode` (and the server's `derive_mode`) say
  what that makes: shared, coop, competitive, teams, teamshared or mixed
  (`MultiplayerLobby.MODES`); `MultiplayerLobby.layout` turns it into the
  hospitals at the start (`world.mp_coop.colours`, `.teams`, `.mode`).
  `hospitalEach(mode)`, `isRace(mode)`, `modeLabel(mode)`,
  `worldMode(world)` (for the `.mpinfo` of a save and the menu).
- Lobby window: a colour and a team button on each player's line (`SEAT`,
  protocol.md); a continued game shows its saved colours and teams, fixed.
- Server: `MODES` and `HOSPITAL_EACH` (continued games seat players by the
  names in the saved hospitals' names, "ANN + BEN" for a shared one).

## The race (world.lua)

- `World:checkIfGameWon` calls `World:_mpRaceCheck` in a competitive game
  (at the end of every month, like co-op; December's at the year end, after
  the awards: `World:onEndMonth`, `World:onEndYear`).
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
In every race the levels unlock month by month in the first year
(`sabotage.SCHEDULE`: kind -> month of the game of L1, L2, L3, all by month
12; no emergency before month 3); `sabotage.unlockMonth` takes the later of
that and a level's own rules (level 7), and the refusal says "not before
month N" (handler and window, which greys the level out with the month;
bots pick only unlocked levels). The room option `tricks=2` (no button; the
probe's rooms use it unless `MP_OPTIONS` is set) unlocks every trick from
the start, as before.

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
  (from `Hospital:onEndDay`) takes a reputation point a day for every 5 live
  attack rats, at most 3 (`sabotage.ratPoints`; a point per rat was up to
  1200 for one level 3 attack), and ends the attack after 30 days. Shooting is the existing
  `shoot_rat` command (a click). In the original rules rats only run from
  hole to hole and are a target for the rat-catching award; they do no harm.

- **Headhunter.** `sabotage.headhunt`: the target's most skilled member of
  staff of the level's kind (`headhuntTarget`: L1 junior doctor or nurse, L2
  doctor, L3 consultant or specialist) gets `mp_headhunted = {by}` and a pay
  rise request (`Hospital:makeRaiseRequest`, +50/75/100 % of the wage,
  `quitting_in` 10 days). Paid (`pay_rise` command, accept): they stay.
  Declined, or not answered (`Staff:checkIfWaitedTooLongForRaise`, before the
  grant-wage policy): `sabotage.poached` - they leave without severance or
  reputation loss, and their profile goes to the top of the hiring list with
  `mp_reserved = {hospital, days = 14}`; `handlers.hire` refuses it to
  others (`sabotage.hireRefusal`) until `sabotage.daily` (from
  `World:onEndDay`) counts it down.
- **Broken boiler.** `sabotage.breakBoiler`: the original boiler breakdown
  without its handyman check (radiator heat 0 from October to March, else 1;
  repair work 15/30/50, which `Hospital:_fixBoiler` takes off 1-3 a day by
  the number of handymen). Refused while the heating is broken, or without
  radiators.
- **Smear campaign.** `sabotage.smear` sets `hospital.mp_smear = {share,
  until_month}` (30/40/50 % for 1/2/3 months); `World:_coopPatientHospital`
  asks `sabotage.smearRedirect`, which (a shared random number, drawn only
  while a campaign runs) sends that share to the next other hospital in the
  race; `sabotage.daily` ends the campaign at `until_month`.
- **Espionage.** `sabotage.spy`: `sabotage.stealable` filters
  `MultiplayerSession.shareableResearch(target, buyer)` (L1 improvements, L2
  discoveries, L3 either) and `MultiplayerSession.applyResearchItem` gives
  one (two at L3, `sabotage.spyItems`); L3 also halves the target's points on
  every current research topic. The player picks them in `UIMultiplayerSpy`
  (opened by the second click on an espionage level), which sends their keys
  with the command (`items`, ";"-separated); the handler takes those still
  stealable, or refuses. Bots send none and get them at random.

## Level 7, Cutthroat (mp_levels.lua)
A level made for the race (`scenario = "cutthroat"`, `config.mp_events`).
Its rules for the tricks are data in the level config, read by
`mp_sabotage.lua`; other levels have none and are unchanged.
- `config.mp_tricks = {unlock, top_level_month}`: `sabotage.unlockMonth`
  (the later of these and `sabotage.SCHEDULE`) and the refusal "not before
  month N" (handler and window).
- `sabotage.price(world, buyer, kind, level)` is the price everywhere (the
  window, the handler, bots): `PRICES` times `mp_levels.trickPriceFactor`,
  which halves the trick of the month (`levels.trickOfTheMonth`) and applies
  the place in the race (`world.mp_level_events.ranks`, set on the 1st of a
  month by `rankRace`: the average share of each win goal reached).
- Events in `cutthroatDay` (World:onEndDay): the first year's emergencies,
  race emergencies (`emergency.mp_race`; `Hospital:resolveEmergency` calls
  `levels.raceEmergencyResolved`), breakthroughs (`hospital.mp_spied` marks a
  discovery copied by espionage), quarterly rankings, notices.
- `config.mp_rat_bounty`: `handlers.shoot_rat` pays it for an attack rat.
- Applied at load: job fair hiring lists (`staff_levels`), machine strength
  x 3/4, `quake_control` (four earthquakes).
Tests: `mp_levels_spec.lua`; the probe action `trickprices` logs prices,
refusals, the trick of the month, the rank and the hiring list.

## Window and Progress Report

- Rivals' hospitals are closed to the mouse: `GameUI:_isRivals` drops a
  hovered entity in a rival's building, or a person of a rival's hospital
  outside your own (no staff or patient windows, door queues, bottom panel
  details or hover cursor). The evil handyman in your own hospital stays
  clickable (his `hospital` is yours). Co-op teams still see each other.
- Rivals' room outlines are not shown (`MultiplayerLobby:_onSHOW` drops
  their blueprint notes in a race), nor the blue floor of a rival's room
  being furnished (every peer's room editor paints it while building the
  room; `hide_rivals_floor` in `mp_session.lua` takes it off again).
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
5. (referee) no repairs, confirmed to the end (also in rooms tricks and
   tricks2);
6. the newer tricks (rooms tricks and tricks2): a headhunted nurse leaves and
   is kept for the buyer, or stays when the rise is paid; a boiler breaks and
   is repaired; a smear campaign runs out; espionage L3, and L1 refused with nothing to copy.

Probe actions: `sabotage:<trick>:<level>:<hospital>`, `kickevil`, `shootrat`, `race`,
`answerraise:accept`, `learn`;
`MP_MODE=competitive` for the host.

## A race of teams (modes `teams`, `teamshared`, `mixed`)

Two to four teams race each other (2 against 2, 2 against 1, 2 against 1
against 1, ...): a competitive game (`world.mp_coop.competitive`) with
`world.mp_coop.teams = {[hospital index] = team (1-4)}`. Mode `teams` is two
teams with a hospital per player, `teamshared` two teams with a hospital per
team (below), `mixed` anything else.

- Lobby and server: the players' colours and teams (verb `SEAT`,
  `UIMultiplayer:clickColour`, `clickTeam`); the host changes anybody's, bots'
  too. `START` carries `colours=peer:colour` and `teams=peer:team`;
  `MultiplayerLobby.layout` gives every colour a hospital and, when a team has
  several, seats team mates on the closest hospitals of the map
  (`mp_levels.hospitalTiles` reads the map's starting camera tiles,
  `mp_levels.teamSeats` picks the split with the smallest spread, team by
  team), the same on every peer, the referee and bots included. A continued
  game keeps the teams of its save (fixed buttons).
- `World:mpTeam(hosp)`, `World:mpRivals(a, b)` (a race, not team mates),
  `World:mpMayTrade(from, to)` (any other hospital, but in a team race only
  team mates).
- Trades: `give_money`, `send_staff`, `offer_staff`, `offer_patient`,
  `offer_research`, `ask_money` are refused across teams ("not on your team");
  the trade, money, research and refer windows offer only team mates, and
  the staff and patient windows' send icons are not there without one.
- Tricks: `sabotage.refusal` refuses a team mate ("they are on your team"),
  the window cycles through the other team only, a smear campaign sends
  patients to the other team, the leader and last price factors rank the
  teams (average of their hospitals' goal scores).
- Looking in: a team mate's hospital is open to the mouse (`GameUI:_isRivals`),
  their room outlines and the blue floor of a room they furnish are shown.
- The race (`World:_mpTeamRaceCheck`): a hospital that reaches the goals is
  marked (`mp_goals_reached`) and plays on; a team takes the next place once
  every hospital of it that still counts has reached them
  (`World:_mpTeamPlace`; with more than two teams everybody is told and the
  others race on). A hospital failing the goals at two year ends in a row is
  out (`mp_place = 0`, "out"), its team races on; a team with all its
  hospitals out takes the lowest place left. Once at most one team still
  races (`_mpTeamRaceCheckOver`), it takes the place left and everybody gets
  the standings fax. With two teams this is the first place given. A
  hospital whose player left does not count until they rejoin
  (`player_away`, as in co-op).
- PLAYERS window: the team number after each hospital.
- Bots: offers and money from a team mate are welcome, tricks only on the
  other team (`World:mpRivals`).
- Team chat: Tab in the chat line goes everybody, **To team**, then each
  player (`UIMultiplayerChatInput:_targets`, remembered in
  `lobby.chat_target = "team"`). The line goes as `CHAT team=1
  to=<mates' peers>` (`MultiplayerLobby:teamMates`: from the game's teams,
  so a continued game works too); the server sends it to those players and
  back to the sender only. A green mark at the start of the line.

Tests: `scripts/multiplayer/run_teams_probe.sh BIN DATA` (rooms trio, 2
against 1, and duo, 2 against 2; `MP_REFEREE=1` adds the referee check).
Probe settings and actions: `MP_MODE=teams` (the room's preset for
newcomers), `MP_TEAM=1-4`, `teams`, `giveto:<hospital>:<amount>`, `teamview`,
`chat:<tabs>:<text>`. Specs: `mp_levels_spec.lua` ("two teams"),
`mp_lobby_spec.lua` (the layout). Server: `test_colours_and_teams`,
`test_derive_mode`.

## A race of team hospitals (mode `teamshared`)

The race of two teams with one hospital per team: team mates run it
together, as in a shared game, and the two hospitals race. Same machinery
as `teams` (`world.mp_coop.competitive`, `world.mp_coop.teams = {1, 2}`),
plus `world.mp_coop.team_hospitals = true`. Any game where players share a
colour works the same way: co-op with a shared hospital, or a `mixed` race.

- Game start (`MultiplayerLobby:_beginGame`): a hospital per colour, so the
  level loads the map for that many (`coopLevelId(count, level)`); each
  hospital is named after its players in peer order ("ANN + BEN"). Commands
  carry the hospital (`session.hospital_index`), so everything a team mate
  does goes to the shared hospital, as in a shared game.
- Menu: TRADE and RESEARCH only when some other hospital may trade with this
  one (`World:mpMayTrade`): not with a hospital per team.
- Leaving: `MultiplayerSession:_markPlayerAway` marks a hospital away only
  when none of its players is left in the game.
- Continued games: the save names each hospital after its players; the
  server (`Server._seats`) seats every player in the hospital whose name
  lists theirs, anybody else in the hospital with fewer players, and sizes
  the room by the number of saved names.
- Bots: a bot may share its team's hospital with people (or other bots). It
  decides from what the hospital already has (a desk, one room of each type,
  the staff the rooms need), so it adds to what its team mates build; two
  builds on the same spot are refused on every peer as usual. In a continued
  game a bot takes a saved player's name and sits in that player's hospital.

Tests: `scripts/multiplayer/run_team_hospitals_probe.sh BIN DATA` (rooms
trio, 2 against 1, and duo, 2 against 2; `MP_REFEREE=1` adds the referee
check, and with it room "mixed": a bot and a person share hospital 2).
Server: `test_team_hospitals_room_and_bots`, `test_team_hospitals_continued_seats`,
`test_team_hospitals_continued_with_a_bot`, `test_team_seats_without_a_saved_name`.

## Ideas not done yet

See the report in the session; the main ones: a security guard or CCTV to
spot evil handymen, poaching a rival's staff, a smear campaign (reputation),
bribing the health inspector or a VIP, insurance against
tricks, a cooldown between tricks, and showing the race (places and goal
progress) on the town map or the status bar.
