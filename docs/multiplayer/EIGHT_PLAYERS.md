# Games of up to 8 players

Status: on `mp/team-hospitals`; first released in mp-test-d5a471a7 (eu2).

## What it is

- A room has 2 to 8 places, for people and bots.
- There are 8 colours, so up to 8 hospitals. The new colours are green, blue,
  teal and pink. There are 8 teams.
- How many hospitals a game can have depends on the level's map:
  - Theme Hospital's own maps have room for 4, so rooms on those levels have
    up to 4 places.
  - **TEAM TOWN** (level 8) also has a map for 8 hospitals.
- A new room has as many places as its level has hospitals: up to 4, or up
  to 8 on TEAM TOWN. Players may still share a hospital (the same colour).
- The host can't start a game with more colours than the level has room for.

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
  - 8 places, colours and teams; a new room's places capped at its level's
    hospitals.
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
  hospitals are nearest the plot. Each bot wants each plot a little
  differently (1.3 to 1.75 times its price, more when its land is full), so
  that several bots bid against each other.
- **Texts:** colours 5 to 8 and the "room for N hospitals" message, in all 22
  languages.

## Limits and open points

- **Bots:** every bot is a whole game on the server. The server runs at most
  `CORSIXTH_MP_MAX_BOTS` (7) at once, in all rooms together: one room of 8
  with one person. A bigger server can raise it.
- **Speed:** 8 hospitals means 8 times the patients in every player's game
  (and the referee's). The slowest computer paces the game.
- **Network:** 8 players from one home share an address. That is still within
  the limit of 8 per address.
