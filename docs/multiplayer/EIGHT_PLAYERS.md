# Games of up to 8 players

Status: built on `mp/team-hospitals`, tested on the dev VM, not released.

## What it is

- A room has 2 to 8 places, for people and bots.
- There are 8 colours, so up to 8 hospitals. The new colours are green, blue,
  teal and pink. There are 8 teams.
- How many hospitals a game can have depends on the level's map:
  - Theme Hospital's own maps have room for 4. On those levels, 8 people play
    in at most 4 hospitals, two to a hospital (shared hospitals, as in the
    team modes).
  - **TEAM TOWN** (level 8) also has a map for 8 hospitals.
- The host can't start a game with more colours than the level has room for.
  The room says how many fit, and players share colours instead.
- New players get colours up to the level's number of hospitals. After that,
  they join the hospital with the fewest players.

## The map for 8

- Theme Hospital's map format is fixed at 128 x 128 tiles and stores 4
  players: their camera and heliport tiles, and their starting plots, which
  are plots 1 to 4.
- The engine now takes up to 8 players. Cameras and heliports 5 to 8 go into
  16 of the 56 bytes at the end of the file that the original maps leave
  empty. They are read only when the map says it has more than 4 players, so
  the original maps load exactly as before.
- `Levels/teamtown8.map` is made from Matroftt's TEAM TOWN map
  (`level40teams.map`) by `scripts/multiplayer/make_teamtown8.py`. The town
  itself is the same. Four plots for sale become starting plots:
  - two north of the middle and two south of it, with 352-423 tiles each,
    about as much as the four in the middle have (420-430);
  - each new hospital's camera looks at its plot;
  - its helicopter lands on the nearest of the four original heliports.
- 12 plots stay for sale, instead of 16.
- With 5 to 7 players, the starting plots of the missing ones are for sale.
- The map editor still offers 1 to 4 players (its menu and its camera and
  heliport buttons). Making real 8-player maps in it is a follow-up.

## Other parts that changed

- **Server:**
  - 8 places, colours and teams.
  - The room's `hospitals` count comes from the client in CREATE.
  - The server's own referees and bots (127.0.0.1) no longer count toward the
    limit of 8 connections per address. A room of 7 bots would otherwise have
    locked out other rooms' referees.
- **Room window:** a line per place. It grows by 27 pixels per place above 4,
  so a room of 8 is 403 pixels high.
- **Level browser:** a map for 2 up to 8 players, as many as the level has.
- **Patients:** the original game has 4 shirt colours. Patients of colours 5
  to 8 wear those of 1 to 4. The colour bars at their feet, and at their
  staff's feet, tell the hospitals apart.
- **Auctions:** the auction room's picture has 4 bidder bars. With more
  hospitals, the bidders are the one that asks and the 3 others whose
  hospitals are nearest the plot.
- **Texts:** colours 5 to 8 and the "room for N hospitals" message, in all 22
  languages.

## Limits and open points

- **Bots:** every bot is a whole game on the server, and the server runs at
  most `CORSIXTH_MP_MAX_BOTS` (6) at once. A room of 8 with 7 bots needs that
  raised, on a server big enough to run it. eu1 and eu2 are small.
- **Speed:** 8 hospitals means 8 times the patients in every player's game
  (and the referee's). The slowest computer paces the game.
- **Network:** 8 players from one home share an address. That is still within
  the limit of 8 per address.
