#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_bot_year.sh BINARY GAME_DATA [LEVEL] [STEPS]
#
# The bots' brains side by side: two co-op rooms on the same level, each with
# a scripted player who only watches (its hospital stays closed, so its
# patients go to the bot) and one bot: "plan" has the fixed building plan
# (MP_BOT_BRAIN=script), "smart" the hospital manager (bot_manager.lua).
# Both play STEPS lockstep steps (default 18000, about a game year) as fast
# as they can; every 3000 steps the watcher logs every hospital (rooms,
# staff, money, reputation, value, cures, deaths, goals). Prints the two
# bots' hospitals at the end. Exits 0 if both games stayed in sync.
#
# Needs LuaSocket (LUASOCKET_TREE, a LuaRocks tree containing it) and python3.
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
: "${LUASOCKET_TREE:?Set LUASOCKET_TREE to a LuaRocks tree containing luasocket}"
lua_ver=${LUA_VERSION_DIR:-5.4}
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-botyear.XXXXXXXX")
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
export MP_REFEREE_PROBE_SCENARIO="plan=none;smart=none"
MP_BOT_BRAIN="plan=script;smart=smart" MP_BOT_FAST=1 MP_BOT_SEED="${MP_BOT_SEED:-7}" \
  PYTHONPATH="$source_dir/mp_server" python3 -m corsixth_mp --host 127.0.0.1 --port "$port" \
  --log-level INFO --max-per-address 64 > "$out/server.log" 2>&1 &
server_pid=$!
trap 'kill $server_pid 2>/dev/null || true' EXIT
for _ in $(seq 50); do grep -q listening "$out/server.log" 2>/dev/null && break; sleep 0.1; done
export MP_SERVER="127.0.0.1:$port"

script=""
for s in $(seq 3000 3000 "$steps"); do script="$script;$((s - 10)):hospitals"; done
run_watcher() { # name room
  local name=$1 room=$2 dir="$out/$1"
  mkdir -p "$dir/config" "$dir/saves"
  printf 'theme_hospital_install = [[%s]]\nsavegames = [[%s]]\nplayer_name = "%s"\nlanguage = [[English]]\naudio = false\nplay_intro = false\nmovies = false\ngrant_wage_increase = false\n' \
    "$game_data" "$dir/saves" "$name" > "$dir/config.txt"
  env XDG_CONFIG_HOME="$dir/config" MP_NAME="$name" MP_ROLE=host MP_ROOM="$room" MP_MODE=coop MP_LEVEL="$level" \
    MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none MP_STEPS="$steps" MP_STALL_LIMIT=300 \
    MP_UI_SCRIPT="${script#;}" timeout 5400 "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/lobby_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
}
run_watcher pia plan & a=$!
run_watcher sam smart & b=$!
wait $a $b || true

python3 - "$out" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
fail = False
for name, room in (('pia', 'plan'), ('sam', 'smart')):
    text = (out / name / 'log.txt').read_text()
    res = re.search(r'RESULT: (.*)', text)
    print(f"{room}: {res.group(1) if res else 'no result'}")
    fail |= not (res and res.group(1).startswith('IN SYNC'))
    for step, date, rest in re.findall(r'UI: hospitals at step (\d+) \(([^)]*)\): (.*)', text):
        bot = re.search(r'\[2 (.*?)\]', rest)
        print(f"  step {step} ({date}): {bot.group(1) if bot else '-'}")
sys.exit(1 if fail else 0)
PY
