# Windows vs Linux (milestone S0)

Date: 2026-10-18. Branch `mp/windows-s0`.

## Question

Lockstep needs every machine to compute exactly the same game. Does a
Windows build (MSVC, vcpkg) compute the same game as a Linux build (GCC)?

## Setup

- **Windows**: the CI artifact of commit `0193e5c6` (workflow "Windows",
  preset `win-x64-rel`, Lua 5.5.0 from vcpkg), run headless on Windows 11
  (`SDL_VIDEODRIVER=dummy`) from Git Bash.
- **Linux**: Debian 13 VM, GCC 14, SDL 3.4.18, Lua 5.5.0 built with
  `scripts/multiplayer/setup_lua55_linux.sh`. Also the usual Lua 5.4.7 build.
- Same game data and same Lua code (one commit) on both.
- Scenario: `sync_probe.lua` busy hospital (seed 12345, five rooms, seven
  staff, no network), one fingerprint per game hour
  (`run_s0_fingerprints.sh`, `compare_fingerprints.py`).

## Results

| Comparison | Result |
|---|---|
| Windows (MSVC, Lua 5.5) vs Linux (GCC, Lua 5.5), first try | **Different from game hour 50**: only the random generator state differed, the hour the first patient arrives |
| Same, with the definition lists in a canonical order | **Identical for 54,749 game hours** (3 game years, until the level is lost) |
| Linux Lua 5.4 vs Linux Lua 5.5 (same machine) | Identical for 54,749 game hours |
| Networked game through the server, Linux host (VM) + Windows player (desktop, LAN), shared hospital: purchases, hires, two rooms, pause by one and unpause by the other, speed change, Windows drawing frames | IN SYNC through 1,500 steps; same build id on both; all 6 commands identical |
| Same, co-op (a hospital each on a two-player map): opening, purchases, hires, $5,000 and a nurse sent between them | IN SYNC through 1,200 steps; all 8 commands identical; same state of both hospitals on both machines |

## The bug: directory listing order

`App:loadLuaFolder()` fills `TheApp.diseases`, `rooms`, `objects` and
`walls` in the order `lfs.dir()` returns the files. That is the file
system's order: ext4 returns names in hash order, NTFS in name order. The
game picks from these lists by index (for example the disease of a new
patient: `available_diseases[math.random(1, n)]`), so the same seed gave a
different first patient. Two Linux machines can differ too.

Fix (multiplayer only, so single player plays exactly as before):
`MultiplayerLobby.useCanonicalOrder()` sorts the four lists by id before the
level loads and restores the original order when the session ends.
`sync_probe.lua` does the same with `MP_CANONICAL_ORDER=1`.

## LuaSocket on Windows

`vcpkg.json` now pulls the `luasocket` port on Windows, and the CMake build
copies `socket/core.dll` and `socket.lua` next to `CorsixTH.exe`; the Windows
install rule (and so the CI artifact) includes them. Lua's default Windows
search paths find them there.

## Notes

- The multiplayer build id contains the Lua version, so a Linux build with
  the distribution's Lua 5.4 cannot join a Windows player (Lua 5.5). Use
  `setup_lua55_linux.sh` on Linux. Since 5.4 and 5.5 gave identical games,
  the build id could later allow both.
- CMake 3.31's FindLua does not know Lua 5.5; the Linux script works around
  that with a wrapper header (see its comments).
- The lobby's ping numbers in scripted tests are rough: the test players
  answer pings only between their own steps.

## How to repeat

```bash
# Linux (VM)
. ~/mp-env.sh; bash scripts/multiplayer/setup_lua55_linux.sh; . ~/lua55-env.sh
bash scripts/multiplayer/run_s0_fingerprints.sh $BIN55 $THDATA ~/s0-linux.txt 80000
# Windows (Git Bash), CI artifact unpacked
bash scripts/multiplayer/run_s0_fingerprints.sh /c/path/CorsixTH/CorsixTH.exe /c/path/themehos s0-windows.txt 80000
python scripts/multiplayer/compare_fingerprints.py s0-linux.txt s0-windows.txt
```

Networked: start `python3 -m corsixth_mp --port 47811` on the server, then
`run_lobby_player.sh` once per machine (`MP_ROLE=host` / `MP_ROLE=join`,
`MP_SERVER=host:port`, same `MP_ROOM`; add `MP_COOP=1` on the host for co-op).
