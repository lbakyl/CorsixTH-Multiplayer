#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_bot_year.sh BINARY GAME_DATA [LEVEL] [STEPS]
#
# The bots' brains side by side: co-op rooms on the same level, each with a
# scripted player who only watches (its hospital stays closed, so its
# patients go to the bot) and one bot. MP_YEAR_ROOMS lists room:brain pairs
# (default "plan:script smart:smart": the fixed building plan against the
# hospital manager, bot_manager.lua; "manager" is the manager without the
# server's advice). With ANTHROPIC_API_KEY set (and the anthropic package
# for MP_PYTHON) the "smart" bots get the language model's advice.
# MP_YEAR_REALTIME=1 plays at Normal speed in real time, as with people (a
# game year takes about 17 minutes), so the advice comes as often as it would
# in a real game (once a game month); otherwise everything runs as fast as it
# can.
# Both play STEPS lockstep steps (default 18000, about a game year) as fast
# as they can; every 3000 steps the watcher logs every hospital (rooms,
# staff, money, reputation, value, cures, deaths, goals). Prints the two
# bots' hospitals at the end. Exits 0 if both games stayed in sync.
# MP_YEAR_MATCH=1 plays one race instead: room "match", the watcher (its
# hospital stays closed) and two bots of the first room's brain against each
# other (STEPS 36000 for two game years); MP_YEAR_BOTS=3 for three bots.
# MP_YEAR_PHOTOS="6,12" saves pictures of the bots' hospitals at those game
# months in <output>/shots (MP_YEAR_SCREEN, default 2880x1800, sets the size).
#
# Needs LuaSocket (LUASOCKET_TREE, a LuaRocks tree containing it, or
# MP_LUA_CPATH/MP_LUA_PATH set) and python3 (MP_PYTHON).
set -euo pipefail
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 BINARY GAME_DATA [LEVEL] [STEPS]" >&2
  exit 2
fi
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
binary=$(realpath "$1")
game_data=$(realpath "$2")
level=${3:-1}
steps=${4:-18000}
rooms=${MP_YEAR_ROOMS:-plan:script smart:smart}
python=${MP_PYTHON:-python3}
lua_ver=${LUA_VERSION_DIR:-5.4}
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-botyear.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
if [[ -z "${MP_LUA_CPATH:-}" ]]; then
  : "${LUASOCKET_TREE:?Set LUASOCKET_TREE to a LuaRocks tree containing luasocket}"
  export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
  export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"
fi
match=${MP_YEAR_MATCH:-0}
if [[ "$match" == 1 ]]; then first_room=${rooms%% *}; rooms="match:${first_room#*:}"; fi
brains="" scenarios=""
for r in $rooms; do brains="$brains;${r%%:*}=${r#*:}"; scenarios="$scenarios;${r%%:*}=none"; done

port=$((47000 + RANDOM % 900))
export CORSIXTH_MP_REFEREE_BINARY="$binary" CORSIXTH_MP_REFEREE_SOURCE="$source_dir"
export CORSIXTH_MP_REFEREE_DATA="$game_data" CORSIXTH_MP_REFEREE_WORKDIR="$out/headless"
export CORSIXTH_MP_REFEREE_LUA_CPATH="$MP_LUA_CPATH" CORSIXTH_MP_REFEREE_LUA_PATH="$MP_LUA_PATH"
export MP_REFEREE_PROBE_SCENARIO="${scenarios#;}"
realtime=${MP_YEAR_REALTIME:-0}
bot_fast=1 watch="MP_FAST=1" first=""
if [[ "$realtime" == 1 ]]; then bot_fast=0 watch="MP_FAST=0 MP_REALTIME=1" first="5:speed:Normal;"; fi
MP_BOT_DIAG="${MP_BOT_DIAG:-}" MP_BOT_BRAIN="${brains#;}" MP_BOT_FAST=$bot_fast MP_BOT_SEED="${MP_BOT_SEED:-7}" CORSIXTH_MP_AI_STATE="$out/ai-spend.json" \
  PYTHONPATH="$source_dir/mp_server" "$python" -m corsixth_mp --host 127.0.0.1 --port "$port" \
  --log-level INFO --max-per-address 64 > "$out/server.log" 2>&1 &
server_pid=$!
trap 'kill $server_pid 2>/dev/null || true' EXIT
for _ in $(seq 50); do grep -q listening "$out/server.log" 2>/dev/null && break; sleep 0.1; done
export MP_SERVER="127.0.0.1:$port"

script=""
for s in $(seq 3000 3000 "$steps"); do script="$script;$((s - 10)):hospitals"; done
script="$script;$((steps - 5)):map:2"
run_watcher() { # name room
  local name=$1 room=$2 dir="$out/$1"
  local mode=coop players=2 bots=1
  if [[ "$match" == 1 ]]; then mode=competitive bots=${MP_YEAR_BOTS:-2} players=$((${MP_YEAR_BOTS:-2} + 1)); fi
  local screen=${MP_YEAR_SCREEN:-2880x1800} photos=()
  if [[ -n "${MP_YEAR_PHOTOS:-}" ]]; then
    mkdir -p "$out/shots"
    photos=(MP_SHOT_DIR="$out/shots" MP_PHOTO_MONTHS="$MP_YEAR_PHOTOS")
  fi
  mkdir -p "$dir/config" "$dir/saves"
  printf 'theme_hospital_install = [[%s]]\nsavegames = [[%s]]\nplayer_name = "%s"\nlanguage = [[English]]\naudio = false\nplay_intro = false\nmovies = false\ngrant_wage_increase = false\nwidth = %s\nheight = %s\n' \
    "$game_data" "$dir/saves" "$name" "${screen%x*}" "${screen#*x}" > "$dir/config.txt"
  env XDG_CONFIG_HOME="$dir/config" MP_NAME="$name" MP_ROLE=host MP_ROOM="$room" MP_MODE=$mode MP_LEVEL="$level" \
    MP_PLAYERS=$players MP_ADD_BOTS=$bots MP_SCENARIO=none MP_STEPS="$steps" MP_STALL_LIMIT=300 $watch \
    MP_UI_SCRIPT="$first${script#;}" "${photos[@]}" timeout $((5400 + steps / 10)) "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/lobby_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
}
pids=()
for r in $rooms; do run_watcher "w${r%%:*}" "${r%%:*}" & pids+=($!); done
wait "${pids[@]}" || true

python3 - "$out" $rooms <<'PY'
import json, pathlib, re, sys
out = pathlib.Path(sys.argv[1])
fail = False
for spec in sys.argv[2:]:
    room = spec.split(':')[0]
    name = 'w' + room
    text = (out / name / 'log.txt').read_text()
    res = re.search(r'RESULT: (.*)', text)
    print(f"{room}: {res.group(1) if res else 'no result'}")
    fail |= not (res and res.group(1).startswith('IN SYNC'))
    for step, date, rest in re.findall(r'UI: hospitals at step (\d+) \(([^)]*)\): (.*)', text):
        for bot in re.findall(r'\[([234] .*?)\]', rest):
            print(f"  step {step} ({date}): {bot}")
server = (out / 'server.log').read_text()
asks = len(re.findall(r'advice: \d+ in', server))
spend = out / 'ai-spend.json'
if asks:
    spent = json.loads(spend.read_text())['spent'] if spend.exists() else 0
    print(f"advice: {asks} answers, ${spent:.4f}")
sys.exit(1 if fail else 0)
PY
