# Playing CorsixTH multiplayer (test version)

This fork adds network multiplayer to CorsixTH: two to four players run one
game together over the internet, either in **one shared hospital**, in
**a hospital each** as a team (co-op), or in a **competitive race** with a
hospital each, on Theme Hospital's original multiplayer maps.
It is a test version: expect rough edges, and please report what you find.

## What you need

- **Windows or Linux** (64-bit), or **macOS 26 Tahoe or newer on Apple
  Silicon** (M1 or later). Players on all three can play together.
- **Your own Theme Hospital game data** (GOG, EA or the original CD). It is
  not included and must never be shared.
- **The multiplayer build of this fork**, the same one as everybody you play
  with. The server only lets players with the same build into a room.
- **A server address** (`host:port`, port 47800 by default). The test
  server is `eu1.bachelor-tech.com:47800` (it runs the newest release).
  Anybody can run one; see [vps-guide.md](vps-guide.md).

## Get the game

1. Open the fork's [Releases](https://github.com/lbakyl/CorsixTH-Multiplayer/releases)
   and download the newest **Multiplayer test build** zip (no GitHub account
   needed). Unzip it into a new folder.
2. Start `CorsixTH.exe`. The first time it asks for your Theme Hospital
   folder.
3. Use **English** as the game language for now: everybody in a game needs
   the same language.

**Linux** (x86_64; Linux Mint 22, Ubuntu 24.04 or newer): download the
`...-linux-x86_64.tar.gz` of the same release, unpack it
(`tar xzf CorsixTH-Multiplayer-*-linux-x86_64.tar.gz`) and start
`CorsixTH-Multiplayer/CorsixTH-Multiplayer.sh`. Settings and saves stay in
that folder. It brings its own libraries; the usual desktop ones (graphics,
sound) come from your system.

**macOS** (Apple Silicon, macOS 26 Tahoe or newer): download the
`...-macos-arm64.zip` of the same release, unzip it and move
`CorsixTH.app` to Applications. The app is not notarized by Apple, so the
first time macOS refuses to open it: open **System Settings > Privacy &
Security**, scroll down to the note about CorsixTH and click **Open
Anyway** (once). (Or in Terminal:
`xattr -dr com.apple.quarantine /Applications/CorsixTH.app`.) Settings
and saves are in the hidden folder `~/.config/CorsixTH`.

Everybody in a game must use the same test build, and the server must run the
matching version (each release names its server image). Builds of newer
commits are also on the fork's **Actions** tab (a run of the Windows, the
Linux package or the macOS app workflow on `master`, Artifacts; this needs a GitHub account).

## Play

1. Main menu, **Multiplayer**. Enter the server address and your name, then
   **Connect**.
2. **To host:** type a room name, and a password if you like. Choose **One
   shared hospital**, **A hospital each** (co-op) or **Competitive race**
   (click the button to cycle through them), the level and the number of
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
  speed. Any player can pause or unpause, at once (the chat works while
  paused). A different speed is a vote: the other players get a purple fax
  with a fast-forward sign (Agree or Decline); it does not pause the game.
  The speed changes once more than half of the players agree, the asker
  included (with two players the other one must agree; with three, one of
  the other two). A vote nobody decides lapses after 30 seconds. Scripted
  players agree by themselves. If the room lets only its owner set the
  speed, the owner changes it without a vote. A click takes effect a moment
  later at every speed, Slowest and pause included (about a tenth of a
  second on a good connection). A window that pauses your own game makes
  the others wait and tells them why.
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
  **MULTIPLAYER** menu, **TRADE WITH OTHER PLAYERS** sends money, or offers
  a member of staff, free or for a price up to $10,000 (the -$500 and +$500 buttons;
  the other player pays it on accepting, if they can afford it); patients
  are offered with the purple **Refer** icon in
  the patient window or the "refer" answer on a "no treatment" fax. The
  other player gets a purple icon at the bottom and accepts or declines;
  an accepted person walks over (it takes a few game days). Land: you can buy the plots on your side of the map (nearest
  to your hospital), not the other players'. Faxes, emergencies and VIP visits come to the hospital they
  are for.
- **Sharing research (co-op):** **Share research** on the research
  blackboard (left of the total), or **MULTIPLAYER**, **SHARE RESEARCH**
  (no research room needed). Pick what to share (equipment you have found,
  better drugs, improved machines; only what the other hospital lacks) or
  **All**, set a price on the bar ($0 to $20,000 in $500 steps) and
  **Offer**. The other player gets a purple icon with a flask: a fax lists
  the research and the price, and they accept or reject it. On acceptance
  they pay you and get what they still lack; you keep your research. No
  answer within 20 game days counts as a rejection.
- **Chat:** press **Enter** and type; **Tab** chooses who it is for (all
  players, or one), and the game remembers it for next time; **Enter**
  sends, **Escape** cancels. Messages show at the top left for a few
  seconds; private ones in purple. (If a window is waiting for Enter, such
  as an information box, Enter goes to it: close it first.) Players on an
  older server get private lines as public ones.
- **Asking for money (co-op):** the bank manager (click your balance at the
  bottom), **Ask a player**: set the amount ($500 to $50,000) and **Ask**.
  The other player gets a coin icon; its fax shows the amount and your
  balance, and they pay or decline. No answer within 20 game days counts
  as no.
- **Players:** the **MULTIPLAYER** menu, **PLAYERS** lists everybody in the
  game: their ping (average of the last 10 seconds), whether they are still
  connected (or have not answered for a while, or are behind), and their
  hospital's value, balance and reputation.
- If an action cannot be done (somebody stands in the way, a candidate is
  gone), the adviser tells you why.

## Winning and losing

- **One shared hospital:** the single-player rules. When the hospital meets
  the level's goals, everybody gets the win fax: **Back to the lobby** ends
  the game for everybody (whoever answers first decides), **Keep playing**
  carries on. Moving on to the next level is not available in multiplayer.
  Losing at a year end ends the game for everybody.
- **A hospital each (co-op) is a team game:** a hospital that reaches the
  level's goals is told so, and everybody hears who is still missing (the
  Goals column in MULTIPLAYER > PLAYERS shows it too). When the last
  hospital gets there, everybody gets the win fax (back to the lobby or keep
  playing). A hospital that fails the goals at a year end is not thrown
  out: it and the others are told, and they can help it with money or
  staff. If it still fails them at the next year end, the team loses and
  the game ends for everybody.
- **Competitive race:** a hospital each, but every player for themselves.
  The first hospital to reach the level's goals takes 1st place, the next
  one 2nd, and so on. A placed player gets a fax: **Back to the lobby**
  (only that player leaves; the others play on) or **Watch**. A placed
  hospital gets no more patients. A hospital that fails the goals at two
  year ends in a row is out, at the bottom of the standings. When only one
  hospital is still racing, it takes the place left and everybody gets the
  final standings. MULTIPLAYER > PLAYERS shows each place. In the Progress
  Report, click another player's name to see how their hospital is doing.

## Dirty tricks (competitive race)

MULTIPLAYER > **DIRTY TRICKS** sells tricks to play on a rival, each at three
levels; **Next rival** picks whom. Click a level to see what it does, and
click it again to buy it. You pay when the trick is done. The rival
is not told who sent an epidemic or an emergency.

| Trick | L1 | L2 | L3 |
|---|---|---|---|
| **Evil handyman**: looks like one of their handymen and strolls their corridors; stays 4, 3 or 2 months (L1, L2, L3), then goes home | $5,000: does no work | $12,500: also drops litter | $20,000: also "repairs" a machine about every three days, and walks away leaving it nearly broken |
| **Epidemic**: contagious patients of one disease arrive at their hospital | $6,000: 2 patients | $12,000: 4 | $20,000: 7 |
| **Emergency** they cannot refuse: patients arrive by helicopter | $5,000: 3 patients | $10,000: 6 | $18,000: 10, maybe of a disease they have not discovered |
| **Rat attack**: rats come out of new holes in their walls; each rat alive costs them a reputation point a day (for 60 days at most) | $4,000: 5 rats | $9,000: 10 | $15,000: 20 |

**Found a handyman who is not on your staff list?** Click him and press the
sack button: he is thrown out (no severance pay) and walks back to whoever
sent him, who has to employ him from then on. **Rats?** Click them to shoot
them (it counts for the rat-catching award too). A trick is refused while it
cannot work, for example while their emergency is still on.

Trading staff and money and sharing research work as in co-op.

## Saving and continuing

- **File > Save** saves the game on every player's computer at the same
  moment (folder `Multiplayer` in your saves folder). The game also saves
  itself at the end of every month ("<room> autosave").
- To continue, the host chooses the save with **Continue** when creating a
  room (it sets the mode, level and players). In a hospital-each game, every
  player gets their own hospital back if they use the same name as before.
- The normal Load menu does not load multiplayer saves.

## If the games go out of sync

Servers that run the headless referee repair this automatically, within a
second: everybody loads the server's copy of the game and plays on, each
player's view stays where it was, and the adviser says "Your game got out of
sync and was recovered successfully." (People may jump a little.) They also
let a player who dropped out rejoin: join the same room again under the same
name. The test server runs the referee for the current test release.

Without a referee the game says so a moment later ("Multiplayer games are
out of sync"); then continue from the last save or autosave. Either way,
please report it (below).

## Not there yet

- Passwords and traffic are not encrypted.

## Reporting a problem

Please tell the fork's owner (an issue on the fork is fine): the server
address, the room name, roughly when it happened, and what you were doing,
and attach the newest file from the game's `Logs` folder (in
`%APPDATA%\CorsixTH`, or next to `CorsixTH.exe` if `config.txt` is there).
After an out-of-sync, a game error or a game that stopped, the server's log
also says what happened, which helps a lot.
