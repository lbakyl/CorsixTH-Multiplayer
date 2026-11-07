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
  - **CROSSROADS** (level 9) is Matroftt's map for 8 (with 2 to 4 players,
    the corner hospitals).
- A new room has as many places as its level has hospitals: up to 4, or up
  to 8 on TEAM TOWN and CROSSROADS. Players may still share a hospital (the same colour).
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
- `Levels/crossroads8.map` is Matroftt's `128-8p-v2.map` (2026-11-06), made
  for 8: eight walled hospitals with their doors in three rows of three and
  four walled plots for sale in the middle. The copy here is scaled from
  his 128 x 128 to 192 x 192 by `scripts/multiplayer/scale_map.py`: rows and
  columns that can repeat (no borders, doors or corners across them) are
  repeated, chosen so that every line stays within 3 tiles of its 1.5x
  place and the plots stay fair; rows and columns repeat alike, so the town
  is as symmetric about its diagonal as his. Each hospital has 1,489-1,497
  tiles of floor (his: 670-715) and each plot in the middle 535 (his: 175). His file had
  no heliports (no emergencies, no helicopter trick); the copy has a
  painted helipad (an H, like Finisham's) on the grass by each hospital,
  with its own path onto the nearest road. Land costs $25 a tile, so a
  hospital's plot is worth $41,625 (his: $20,975).
- His roads run through the hospitals, so an empty hospital (a plot nobody
  owns cannot be walked) cut the town apart: with 6 players the south-east
  corner could not be reached at all, with 4 or fewer the corners not from
  each other. Since 2026-11-08 a ring road runs round the four plots in the
  middle, joining every road between two hospitals
  (`scripts/multiplayer/pave_roads.py`, which also draws the pavement's
  edges), so every hospital that has a player is reachable from every other
  and from the edges of town that lead to one.
- With 5 to 7 players, the starting plots of the missing ones are for sale.
- The map editor makes maps for up to 8 players: its player count menu goes
  to 8, and one Camera and one Heliport button set the tiles of the player
  the Player button shows (a click: the next one). It saves players 5 to 8
  in the same spare bytes. (`scripts/multiplayer/editor_probe.lua` tests it.)
- Larger maps, up to 256 x 256: the editor's MAP SIZE menu starts a blank
  map of 128, 192 or 256 tiles. A map of another size than 128 x 128 starts
  with a 16 byte header ("CTHMAP1", the width and the height, low byte
  first, 4 bytes spare); the rest follows Theme Hospital's layout with the
  offsets after the size. 128 x 128 maps are saved exactly as before. The
  town map keeps its 384 pixels (3 a tile at 128, 2 at 192, 1 at 256), the
  level browser's preview its 256. No larger map is made yet: they are for
  map makers.

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
- **Patients:** the original game has 4 shirt colours. Colours 6, 7 and 8
  wear the white, lavender and salmon shirts redrawn blue, teal and pink (a
  palette map on every sprite of that clothes layer, drawn only for their
  patients: `TH.anims:setLayerAltPalette`, `MultiplayerSession.setupShirtColours`).
  Colour 5's mustard shirt is part of the body sprites, not a layer of its
  own: those sprites get a second palette map (`DrawFlags.AltPalette2`) that
  turns only the mustard shades green. The colour bars at the feet tell all
  of them apart too.
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
