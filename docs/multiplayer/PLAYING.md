# Playing CorsixTH multiplayer (test version)

This fork adds network multiplayer to CorsixTH: two to four players run one
game together over the internet, either in **one shared hospital** or in
**a hospital each** (co-op) on Theme Hospital's original multiplayer maps.
It is a test version: expect rough edges, and please report what you find.

## What you need

- **Windows** (the builds below are for Windows; Linux players can build it
  themselves, see `README.md` in this folder).
- **Your own Theme Hospital game data** (GOG, EA or the original CD). It is
  not included and must never be shared.
- **The multiplayer build of this fork**, the same one as everybody you play
  with. The server only lets players with the same build into a room.
- **A server address** (`host:port`, port 47800 by default). Anybody can run
  one; see [vps-guide.md](vps-guide.md).

## Get the game

1. Open the fork's [Releases](https://github.com/lbakyl/CorsixTH-Multiplayer/releases)
   and download the newest **Multiplayer test build** zip (no GitHub account
   needed). Unzip it into a new folder.
2. Start `CorsixTH.exe`. The first time it asks for your Theme Hospital
   folder.
3. Use **English** as the game language for now: everybody in a game needs
   the same language.

Everybody in a game must use the same test build, and the server must run the
matching version (each release names its server image). Builds of newer
commits are also on the fork's **Actions** tab (Windows workflow, a run on
`master`, Artifacts, CorsixTH; this needs a GitHub account).

## Play

1. Main menu, **Multiplayer**. Enter the server address and your name, then
   **Connect**.
2. **To host:** type a room name, and a password if you like. Choose **One
   shared hospital** or **A hospital each**, the level and the number of
   players (or a saved game with **Continue**, see below), then **Create**.
   When everybody has pressed **Ready**, press **Start game**.
3. **To join:** pick the room in the list, type its password, **Join**, then
   **Ready**.

The lobby measures everybody's connection and shows the fastest speed that
stays smooth, and how long a click takes to happen ("actions take 108 ms").

## In the game

- **Everything is shared:** every action happens on every player's game a
  moment after the click. If one player is slower or pauses, the others wait
  ("Waiting for the other player...").
- **Speed and pause** are shared too; the room's connection limits the top
  speed.
- **Rooms:** after the walls, door and windows, you place the furniture as
  usual; the other players see the room fill up. While you draw a room, the
  others see its outline in blue (the space is reserved). While furnishing
  you can buy extra objects and pick up and move the ones you placed.
- **Editing rooms:** the edit room button, then click one of your rooms.
  Everybody inside walks out first (the adviser says so); then the editor
  opens as in single player: pick up and move objects, buy or sell extras,
  confirm. Cancel takes the walls down to move or resize the room (draw it
  again, door, windows, then place the furniture); cancel once more to
  remove the room. If you leave the game meanwhile, the room is finished
  for you (or removed if its walls are down).
- **Objects** in corridors can be bought, picked up, moved and sold.
- **Staff:** hire, fire, answer pay rises, and pick up and move them (right
  click, or the pick up button in their window), as usual.
- **A hospital each (co-op):** each player runs their own hospital and can
  look at, but not act on, the others' patients, staff and machines. The
  **MULTIPLAYER** menu, **TRADE WITH OTHER PLAYERS** sends money, or a
  member of staff, who then walks over to the other hospital (it takes a few
  game days). Land: you can buy the plots on your side of the map (nearest
  to your hospital), not the other players'. Faxes, emergencies and VIP visits come to the hospital they
  are for.
- **Players:** the **MULTIPLAYER** menu, **PLAYERS** lists everybody in the
  game: their ping (average of the last 10 seconds), whether they are still
  connected (or have not answered for a while, or are behind), and their
  hospital's value, balance and reputation.
- If an action cannot be done (somebody stands in the way, a candidate is
  gone), the adviser tells you why.

## Saving and continuing

- **File > Save** saves the game on every player's computer at the same
  moment (folder `Multiplayer` in your saves folder). The game also saves
  itself at the end of every month ("<room> autosave").
- To continue, the host chooses the save with **Continue** when creating a
  room (it sets the mode, level and players). In a hospital-each game, every
  player gets their own hospital back if they use the same name as before.
- The normal Load menu does not load multiplayer saves.

## If the games go out of sync

The game says so ("Multiplayer games are out of sync"). This should not
happen; if it does, please report it (below). Then continue from the last
save or autosave. Servers that run the headless referee repair this
automatically and let a player who dropped out rejoin (not yet in the
standard server image).

## Not there yet

- Epidemics in hospital-each games.
- In-game chat, asking another player for money, competitive games.
- Passwords and traffic are not encrypted.

## Reporting a problem

Please tell the fork's owner (an issue on the fork is fine): the server
address, the room name, roughly when it happened, and what you were doing,
and attach the newest file from the game's `Logs` folder (in
`%APPDATA%\CorsixTH`, or next to `CorsixTH.exe` if `config.txt` is there).
After an out-of-sync, a game error or a game that stopped, the server's log
also says what happened, which helps a lot.
