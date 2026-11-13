# CorsixTH multiplayer server

The lobby and relay that players connect to from the game (main menu,
**Multiplayer**): rooms with passwords, a game-build check, ping measurement
with a recommended game speed, the start of a game, relaying the players'
moves, comparing their games' fingerprints, shared speed and pause, and
leaving. Protocol: [`docs/multiplayer/protocol.md`](../docs/multiplayer/protocol.md).

The server itself is plain Python 3.11 or newer, standard library only. It
does not run the game and needs no Theme Hospital files, unless you add the
referee (below).

## Which setup do you need?

| Setup | What you need | What you get |
|---|---|---|
| **Plain server** ([quick start](#quick-start-plain-server)) | Any computer with Python 3.11+ (Windows, Linux, macOS) | Rooms and games, on your LAN or the internet. Without a referee a game that gets out of sync ends, a player who left cannot come back, and there are no bots; the referee can be added on Windows too ([below](#with-the-referee-and-bots-on-windows)) |
| **Docker on a VPS** ([`vps-guide.md`](../docs/multiplayer/vps-guide.md), `deploy/setup-vps.sh`) | A Linux VPS with Docker | The plain server as a service on the internet |
| **Server with the referee** ([`SERVER-SETUP.md`](../docs/multiplayer/SERVER-SETUP.md), `deploy/setup-referee-host.sh`) | A Linux x86-64 machine (Ubuntu 24.04+ or Debian 13) and your own Theme Hospital files | What eu1 and eu2 run: games repair themselves when they get out of sync, players can rejoin, bots, players with another Theme Hospital edition can join |

## Quick start (plain server)

1. Get the server code of the **same release your players use**: on the
   [releases page](https://github.com/lbakyl/CorsixTH-Multiplayer/releases),
   under the release, **Source code (zip)**. Unpack it.
2. Open a terminal in its `mp_server` folder and start the server:

   ```bash
   python3 -m corsixth_mp                # Linux, macOS
   py -3 -m corsixth_mp                  # Windows (or: python -m corsixth_mp)
   ```

   It prints `listening on 0.0.0.0:47800` and keeps running until you press
   Ctrl+C.
3. Check from a second terminal (same folder) that it answers:

   ```bash
   python3 -m corsixth_mp.health         # prints: OK players=0 rooms=0
   ```

4. In the game: main menu, **Multiplayer**, type the server's address with the
   port (for example `192.168.1.20:47800`), your name, **Connect**.

## Playing on a LAN (no internet needed)

Nothing in the server or in the game needs the internet while you play: one
computer on your network runs the server, everybody else connects to it.

1. **Everybody installs the same release** of the game (download it while you
   are still online). A room only lets in players with the build of the
   player who made it; rooms of other builds are marked in the room list.
2. **Pick the server computer.** It can be one of the players' computers.
   Install Python 3.11 or newer on it ([python.org](https://www.python.org/downloads/);
   on Linux it is usually there already) and start the server as in the
   quick start above.
3. **Let the port through its firewall** (TCP 47800):
   - Windows: when Windows asks whether Python may communicate on networks,
     allow it on **private networks**. If you missed the question: Windows
     Security, Firewall & network protection, Allow an app through firewall,
     tick Python for Private.
   - Linux with ufw: `sudo ufw allow 47800/tcp`.
   - macOS: allow incoming connections for Python when macOS asks.
4. **Find the server computer's LAN address:**
   - Windows: `ipconfig`, the line **IPv4 Address** (for example `192.168.1.20`).
   - Linux: `hostname -I`.
   - macOS: `ipconfig getifaddr en0`.
5. **Connect:** every player types that address with the port, for example
   `192.168.1.20:47800`, into the Multiplayer window. The player on the server
   computer itself can also use `127.0.0.1:47800`.

Good to know on a LAN:
- **Same Theme Hospital edition.** Editions differ in their multiplayer maps
  and level settings (GOG, CD, EA...), and games with different ones drift
  apart. A plain server does not check this. To have it turn away players
  with another edition, start it with that edition's identity in
  `CORSIXTH_MP_DATA`. This prints the identity of a Theme Hospital folder
  (the one with DATA, LEVELS, ...); run it in the `mp_server` folder (on
  Windows with `py -3` instead of `python3`):

  ```bash
  python3 -c "from corsixth_mp.builds import data_id; print(data_id(r'/path/to/Theme Hospital'))"
  ```

  The GOG edition gives `899c66d0`.
- **Bots and repairs** need the referee: on the plain server as in the next
  section, or on a Linux x86-64 computer set up as in
  [`SERVER-SETUP.md`](../docs/multiplayer/SERVER-SETUP.md) (its script
  downloads the release once; after that the games run without the internet).
  The bots' advice from a language model (optional, below) needs the internet;
  without it the bots play on their own rules.

### With the referee and bots on Windows

The plain server can run the referee itself: the same game the players have,
started without a window or sound, once per game and once per bot. It then
repairs games that get out of sync, lets a player who left rejoin, and runs
bots. Set four environment variables before you start the server:

| Variable | What to set it to |
|---|---|
| `CORSIXTH_MP_REFEREE_BINARY` | The game program of the same release: `CorsixTH.exe` in the unpacked Windows download |
| `CORSIXTH_MP_REFEREE_SOURCE` | The unpacked **Source code (zip)** of that release: the folder with `CorsixTH`, `mp_server` and `scripts` in it |
| `CORSIXTH_MP_REFEREE_DATA` | Your Theme Hospital folder (the one with DATA, LEVELS, ...) |
| `CORSIXTH_MP_REFEREE_WORKDIR` | A folder for the referee's saves and logs, for example `C:\CorsixTH-referee` (the default, `/tmp/corsixth-referee`, is meant for Linux) |

In PowerShell, in the `mp_server` folder (change the paths to yours):

```powershell
$env:CORSIXTH_MP_REFEREE_BINARY  = "C:\Games\CorsixTH-Multiplayer\CorsixTH.exe"
$env:CORSIXTH_MP_REFEREE_SOURCE  = "C:\Games\CorsixTH-Multiplayer-mp-stable-a03adfdc"
$env:CORSIXTH_MP_REFEREE_DATA    = "C:\GOG Games\Theme Hospital"
$env:CORSIXTH_MP_REFEREE_WORKDIR = "C:\CorsixTH-referee"
py -3 -m corsixth_mp
```

The server's first lines then say `headless referee enabled`, `players must
have build ...` (the release's) and `players must have Theme Hospital data
...` (your edition; players with another edition are let in and get the
referee's level files). To add a bot, the room's host clicks an empty place
in the room. Each game and each bot runs one more copy of the game on the
server computer (on the Linux servers about 80 MB of memory each).

On macOS and Linux the same four settings should work with that system's
game program; this has not been tested. On a Linux server the script in
[`SERVER-SETUP.md`](../docs/multiplayer/SERVER-SETUP.md) does all of it.

Tested on 13 November 2026 with release `mp-stable-a03adfdc`:
- The plain server from the release's source zip on Windows 11 (Python 3.11)
  and on Debian 13 (Python 3.13), with two players on Windows, the second
  time over the home network: they joined one room, started the game and
  stayed in sync through game step 800.
- The plain server on Windows 11 with the referee settings above: a forced
  out-of-sync step was repaired by the referee within a step, and a bot added
  from the room built and hired; the referee confirmed both games through
  step 800. The referee and the bot ran without a window.

## Settings

Command line options, or the same as environment variables:

| Option | Environment variable | Default | What it does |
|---|---|---|---|
| `--host` | `CORSIXTH_MP_HOST` | `0.0.0.0` | Address to listen on: `0.0.0.0` every network, `127.0.0.1` this computer only |
| `--port` | `CORSIXTH_MP_PORT` | `47800` | TCP port players connect to |
| `--motd` | `CORSIXTH_MP_MOTD` | (none) | Welcome text players see when they connect |
| `--log-level` | `CORSIXTH_MP_LOG` | `INFO` | `DEBUG`, `INFO`, `WARNING`, ... |
| `--max-connections` | `CORSIXTH_MP_MAX_CONNECTIONS` | `256` | Connections at once |
| `--max-per-address` | `CORSIXTH_MP_MAX_PER_ADDRESS` | `8` | Connections from one IP address (on the internet, players behind one router share one) |
| `--max-bots` | `CORSIXTH_MP_MAX_BOTS` | `7` | Bots at once (only with the referee) |

Environment variables only:

| Variable | What it does |
|---|---|
| `CORSIXTH_MP_BUILD` | The build checksum players must have (8 hex digits), or `any`. Default: the referee's; no check without a referee |
| `CORSIXTH_MP_RELEASE`, `CORSIXTH_MP_RELEASE_URL` | The release players with another build are told to download, and its page |
| `CORSIXTH_MP_DATA` | The Theme Hospital edition players must have (8 hex digits, see above), or `any`. Without a referee, other editions are turned away; with a referee they are let in and get the referee's level files. Default: the referee's edition; no check without a referee |
| `CORSIXTH_MP_REFEREE_BINARY`, `_SOURCE`, `_DATA`, `_LUA_CPATH`, `_LUA_PATH`, `_WORKDIR` | The referee (and bots): the game to run, its source, the Theme Hospital files. `setup-referee-host.sh` sets them; details in [`referee.md`](../docs/multiplayer/referee.md) |
| `ANTHROPIC_API_KEY` | Optional advice for normal and hard bots from a language model (needs the `anthropic` package and the internet). Without it the bots play on their own rules |
| `CORSIXTH_MP_AI_MODEL`, `CORSIXTH_MP_AI_DAILY_USD` | The model (default `claude-haiku-5-5`) and the most the advice may cost a day (default 3 dollars) |
| `DISCORD_WEBHOOK_URL`, `CORSIXTH_MP_SERVER_NAME` | The daily report to Discord (`python3 -m corsixth_mp.daily_report`), and the server's name in it |
| `CORSIXTH_MP_STATS_DIR`, `CORSIXTH_MP_REPORT_TZ` | Where the games are noted for the report (default `/var/lib/corsixth` if it exists) and its time zone (default `Europe/Prague`) |

In the test builds (`mp-test-...` releases from the `mp/team-hospitals`
branch; not in the stable release `mp-stable-a03adfdc` yet) there are also:

| Variable | What it does |
|---|---|
| `CORSIXTH_MP_EXPERTS` | The players hard bots learn to build from: their names in the game, any case, separated by commas (`Argus,Matroftt`). While one of them plays their own hospital, the referee saves the game every game year and when it ends; a job every night learns from the new saves (`python3 -m corsixth_mp.learn`). Needs `CORSIXTH_MP_LEARN_DIR` too. Default: none, no learning. `setup-referee-host.sh --experts "..."` sets it; see [`SERVER-SETUP.md`](../docs/multiplayer/SERVER-SETUP.md) section 10 |
| `CORSIXTH_MP_LEARN_DIR` | The folder for that learning: the experts' saves, what was learnt from them (`learned.lua`, which the bots read) and a line per night's run (the daily report names it). `/var/lib/corsixth/learn` with `setup-referee-host.sh`. Default: none |
| `CORSIXTH_MP_STAND_IN_DELAY` | Seconds after a person leaves a running game before a bot plays their hospital under their name, until somebody takes the place. Default `20` |
| `CORSIXTH_MP_SILENT_DROP` | Seconds a person's connection may stay silent (no answer to the server's ping) before it counts as dropped. A dropped player who joins again under the same name gets their place back. `0`: never. Default `20` |
| `CORSIXTH_MP_DROP_WAIT` | Seconds a game waits for the last person when their connection dropped (they did not quit), before the room closes. Default `300` |
| `CORSIXTH_MP_EMPTY_WAIT` | Seconds a game is kept for somebody to come back once the last person quit, before the room closes. Default `0`: it closes at once |
| `CORSIXTH_MP_KEEP_PLACES` | `0`: nobody can join a running game, a player who leaves gets no bot in their place, and a room closes once nobody plays (the behaviour before these test builds; some older test scripts need it). Default `1` |

On a server set up with `setup-referee-host.sh`, the settings live in
`/etc/corsixth-mp.env`, and the API key and the webhook in
`/etc/corsixth-mp-secrets.env` (see [`SERVER-SETUP.md`](../docs/multiplayer/SERVER-SETUP.md)).

## Security

The connection is plain TCP: room passwords and the game travel
unencrypted. A room password only keeps strangers out of a room; don't use
one you use anywhere else. On the internet, open only the game port (and
SSH); the guides above show how.

## Development

```bash
python3 -m pytest -q                          # tests (needs pytest)
docker build -t corsixth-mp-server mp_server  # container (from the repository root)
docker run -p 47800:47800 corsixth-mp-server
```
