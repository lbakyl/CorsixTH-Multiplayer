#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_takeover_probe.sh BINARY GAME_DATA
#
# Places of a running game (Jan, 2026-11-12) through a local relay server
# that runs bots and the headless referee. Two rooms:
#   "take" (a race, level 1): tia hosts with two bots and plays in real
#     time. ugo joins the running game: the list of places, and he takes Bot
#     Agnes's (place 2). He leaves; after a moment a bot plays his place
#     under his name (CORSIXTH_MP_STAND_IN_DELAY=3), quietly. He comes back:
#     his place at once, and the bot goes.
#   "lone" (co-op, level 1): vic plays with one bot and leaves; nobody plays,
#     the bot stops and the referee holds the game. vic comes back: his
#     place, and the bot comes back to its own; one load for both.
#   "shirt" (co-op, level 1): wes (colour 8, black) plays with a bot (7, teal);
#     8 patients arrive at wes's desk (a test command), and he
#     takes pictures of a queue window (Argus: its patients wore the shirt
#     they are drawn from, white).
# Checks:
#   1. ugo sees the places (tia playing, two bots) and takes place 2; Bot
#      Agnes leaves; the room list showed the game running with 2 places
#   2. the bot's hospital is a person's now: no hidden bot bonus for it
#      after that; place 3's bot is a hard one (tia made it so in the room):
#      its bonus says so (the server's LOAD names it)
#   3. ugo leaves: a stand-in bot named ugo takes place 2, says nothing,
#      plays no trick, asks nobody
#   4. ugo comes back by name: place 2 at once, the stand-in leaves
#   5. "lone": the empty game waits (referee held), vic gets his place, the
#      bot comes back, one load for both
#   6. every game IN SYNC to its end, no desync, the referee differs from nobody
#   7. "shirt": the queue window shown with patients in it (pictures queue-*)
#   8. "shirt": wes asks for a plot the bot may want too: the auction screen
#      (plots for sale in sand, the seconds left big), its town map button
#      opens the map, and the auction comes back when it is closed
# Exits 0 only if all checks behave as expected.
#
# Needs LuaSocket (LUASOCKET_TREE, a LuaRocks tree containing it) and python3.
set -euo pipefail
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 BINARY GAME_DATA" >&2
  exit 2
fi
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
binary=$(realpath "$1")
game_data=$(realpath "$2")
[[ -x "$binary" && -d "$game_data" ]]
: "${LUASOCKET_TREE:?Set LUASOCKET_TREE to a LuaRocks tree containing luasocket}"
lua_ver=${LUA_VERSION_DIR:-5.4}
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-takeover.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"

port=$((47000 + RANDOM % 900))
export CORSIXTH_MP_REFEREE_BINARY="$binary" CORSIXTH_MP_REFEREE_SOURCE="$source_dir"
export CORSIXTH_MP_REFEREE_DATA="$game_data" CORSIXTH_MP_REFEREE_WORKDIR="$out/headless"
export CORSIXTH_MP_REFEREE_LUA_CPATH="$MP_LUA_CPATH" CORSIXTH_MP_REFEREE_LUA_PATH="$MP_LUA_PATH"
export MP_REFEREE_PROBE_SCENARIO="take=none;lone=none;shirt=none"
MP_BOT_PACE=20 MP_BOT_FAST=1 MP_BOT_SEED=7 MP_BOT_TESTS=1 \
CORSIXTH_MP_STAND_IN_DELAY=3 CORSIXTH_MP_EMPTY_WAIT=120 PYTHONPATH="$source_dir/mp_server" \
  python3 -m corsixth_mp --host 127.0.0.1 --port "$port" \
  --log-level INFO --max-per-address 64 > "$out/server.log" 2>&1 &
server_pid=$!
trap 'kill $server_pid 2>/dev/null || true' EXIT
for _ in $(seq 50); do grep -q listening "$out/server.log" 2>/dev/null && break; sleep 0.1; done
export MP_SERVER="127.0.0.1:$port"

run_probe() { # dir name, then extra VAR=value assignments
  local name=$1; shift
  local dir="$out/$name"
  mkdir -p "$dir/config" "$dir/saves"
  cat > "$dir/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$dir/saves]]
player_name = "${name%%-*}"
fullscreen = false
width = 800
height = 600
language = [[English]]
audio = false
play_music = false
play_sounds = false
play_announcements = false
movies = false
play_intro = false
play_demo = false
grant_wage_increase = false
EOF
  env XDG_CONFIG_HOME="$dir/config" MP_NAME="${name%%-*}" MP_SHOT_DIR="$dir" "$@" timeout 900 "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/lobby_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
  grep -q 'PROBE: DONE' "$dir/log.txt" || { echo "$name failed:"; tail -20 "$dir/log.txt"; return 1; }
}
# Wait (at most $2 seconds) for a line of the server's log.
wait_log() {
  for _ in $(seq $(( $2 * 10 ))); do grep -q -- "$1" "$out/server.log" && return 0; sleep 0.1; done
  echo "never in the server log: $1"; return 1
}

pids=()
run_probe tia MP_ROLE=host MP_ROOM=take MP_MODE=competitive MP_PLAYERS=3 MP_ADD_BOTS=2 MP_SCENARIO=none MP_BOT_LEVELS=3:hard \
  MP_REALTIME=1 MP_STEPS=3600 MP_STALL_LIMIT=180 MP_UI_SCRIPT="20:openhospital;3590:hospitals" & pids+=($!)
run_probe vic MP_ROLE=host MP_ROOM=lone MP_MODE=coop MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_REALTIME=1 MP_STEPS=300 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital" & pids+=($!)

run_probe wes MP_ROLE=host MP_ROOM=shirt MP_MODE=coop MP_PLAYERS=2 MP_ADD_BOTS=1 MP_COLOURS=1:8,2:7 MP_SCENARIO=none MP_STEPS=1400 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital;30:buy:reception_desk;50:hire:Receptionist;600:ownpatients:8;660:queueshot;900:ownpatients:8;980:queueshot;1100:auctionbuy;1106:auctionshot;1110:auctionmap;1116:auctionmapclose;1122:auctionshot" & pids+=($!)

# A newcomer takes Bot Agnes's place in the running race, then leaves.
wait_log "room 'take' starts" 60 && sleep 5
run_probe ugo MP_ROLE=join MP_ROOM=take MP_TAKE_SEAT=2 MP_SCENARIO=none MP_STEPS=300 \
  MP_STALL_LIMIT=120 MP_UI_SCRIPT="10:openhospital" || true
# A bot plays his place; then he comes back.
wait_log "bot 'ugo' takes place 2" 90 && sleep 8
run_probe ugo-back MP_ROLE=join MP_ROOM=take MP_REJOIN=1 MP_SCENARIO=none MP_STEPS=300 \
  MP_STALL_LIMIT=120 & pids+=($!)
# vic comes back to his empty game.
wait_log "room 'lone': nobody plays" 120 && sleep 3
run_probe vic-back MP_ROLE=join MP_ROOM=lone MP_REJOIN=1 MP_SCENARIO=none MP_STEPS=300 \
  MP_STALL_LIMIT=120 & pids+=($!)
for pid in "${pids[@]}"; do wait "$pid" || true; done
sleep 2

python3 - "$out" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
server = (out / 'server.log').read_text()
def log(n):
    p = out / n / 'log.txt'
    return p.read_text() if p.exists() else ''
def result(n):
    m = re.search(r'RESULT: (.*)', log(n)); return m.group(1) if m else 'no result'
bots = {}  # "room/name" -> [its logs]
for p in (out / 'headless').glob('*-bot-*/bot.log'):
    text = p.read_text()
    m = re.search(r'^\[([^\]]+)\]', text, re.M)
    if m: bots.setdefault(p.parent.name.split('-bot-')[0] + '/' + m.group(1), []).append(text)
bad = []
t, u, ub, v, vb = log('tia'), log('ugo'), log('ugo-back'), log('vic'), log('vic-back')

places = re.search(r'UI: places (.*)', u)
# (Which bot has place 2 depends on which joined first.)
bot2 = re.search(r"2:(Bot \w+):bot", places.group(1)) if places else None
ok1 = bool(places and re.search(r"1:tia:on", places.group(1)) and bot2
           and re.search(r"3:Bot \w+:bot", places.group(1))
           and f"room 'take': 'ugo' takes place 2 (was '{bot2.group(1)}')" in server
           and re.search(r"REJOINED: loaded the shared save", u))
print(f"1. Takes a bot's place:     places {places.group(1) if places else '-'}; "
      f"took place 2: {'takes place 2 (was' in server}; loaded: {'REJOINED' in u}")
if not ok1: bad.append("ok1")

# The bonus months after the take-over (tia's game held for it): hospital 2
# not among them; before it, 2 and 3.
taken = t.find('(rejoin at step')
before = re.findall(r'bot bonus for hospital\(s\) (\S+)', t[:taken]) if taken >= 0 else []
after = re.findall(r'bot bonus for hospital\(s\) (\S+)', t[taken:]) if taken >= 0 else []
ok2 = (taken >= 0 and len(after) > 0 and all(h == '3:hard' for h in after)
       and all(h == '2,3:hard' for h in before) and re.search(r'Bot \w+, hard', t) is not None)
print(f"2. No bonus for a person:   before the take-over {before or 'none'}, after {after or 'none'}")
if not ok2: bad.append("ok2")

standin = bots.get('take/ugo', [''])[0]
ok3 = ("room 'take': a bot for place 2 ('ugo', for the player who left)" in server
       and "bot 'ugo' takes place 2" in server and 'while they are away (quiet)' in standin
       and not re.search(r'\] CHAT[: (]', standin) and 'dirty trick:' not in standin)
quiet = re.findall(r'\(quiet\) (.*)', standin)
print(f"3. A bot plays for ugo:     started: {'for the player who left' in server}; "
      f"joined: {'bot ' + chr(39) + 'ugo' + chr(39) + ' takes place 2' in server}; quiet lines: {len(quiet)}")
if not ok3: bad.append("ok3")

ok4 = ("room 'take': 'ugo' rejoins as player 2" in server and 'REJOINED' in ub
       and result('ugo-back').startswith('IN SYNC'))
print(f"4. ugo comes back:          {result('ugo-back')}; back by name: {'rejoins as player 2' in server}")
if not ok4: bad.append("ok4")

ok5 = ("room 'lone': nobody plays; the game waits" in server and "room 'lone': 'vic' rejoins as player 1" in server
       and "room 'lone': bot 'Bot Agnes' takes place 2" in server and 'REJOINED' in vb
       and result('vic-back').startswith('IN SYNC'))
print(f"5. An empty game waits:     held: {'lone' in server and 'nobody plays' in server}; vic back: {result('vic-back')}")
if not ok5: bad.append("ok5")

# (The rooms wait for somebody when the probes end: no "referee confirmed"
# line yet; the referee differed from nobody.)
desyncs = re.findall(r"WARNING room '(take|lone)': desync[^\n]*", server)
ok6 = (result('tia').startswith('IN SYNC') and result('ugo').startswith('IN SYNC')
       and result('vic').startswith('IN SYNC') and not desyncs
       and not re.search(r"room '(take|lone)': (the players differ|only the referee differs)", server))
print(f"6. In sync:                 tia {result('tia')}; ugo {result('ugo')}; vic {result('vic')}; "
      f"desyncs repaired: {len(desyncs)}")
if not ok6: bad.append("ok6")
w = log('wes')
shots = re.findall(r'UI: queue window of (\d+) patients at step (\d+), the first in shirt (\S+)', w)
ok7 = bool(shots) and result('wes').startswith('IN SYNC') and 'colour 8' in w
print(f"7. Queue window, colour 8:  {shots or 'no queue'}; {result('wes')}")
if not ok7: bad.append("ok7")
# The auction screen: its town map button opens the map, the auction
# comes back after it (8. below; pictures auction-* and auctionmap-*).
opened = re.search(r'UI: auctionmap at step \d+: town map true, auction screen false', w)
back = re.search(r'UI: auctionshot at step 112\d: screen true', w)
ok8 = bool(opened and back)
print(f"8. Auction, town map:       map opened from the auction: {bool(opened)}; auction screen back: {bool(back)}")
if not ok8: bad.append("ok8")
print("failed checks:", " ".join(bad) if bad else "none")
sys.exit(1 if bad else 0)
PY
