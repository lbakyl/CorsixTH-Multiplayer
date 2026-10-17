#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_ingame_probe.sh BINARY GAME_DATA
#
# In-game multiplayer checks (lockstep done by MultiplayerSession inside the
# game; player actions through the real UI windows):
#   1. single player: the same UI actions still buy/hire immediately
#   2. client buys a bench and a plant and hires a doctor through the UI,
#      tries to pick up an object -> IN SYNC, 3 commands applied on the host,
#      pick-up refused
#   3. both peers act in the same hour (same tile), client renders frames
#      -> IN SYNC, same accept/reject decisions on both peers
#   4. client changes money locally only -> DESYNC on both peers
#   5. host pauses for a while, client uses "Speed Up" -> IN SYNC, peers
#      never more than one step apart, client told it is waiting
# Exits 0 only if all five behave as expected.
#
# Needs LuaSocket: set LUASOCKET_TREE to a LuaRocks tree containing it.
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-ingame.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"
export MP_STEPS=1500

run_probe() { # name, then extra VAR=value assignments
  local name=$1; shift
  local dir="$out/$name"
  mkdir -p "$dir/config" "$dir/saves"
  cat > "$dir/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$dir/saves]]
player_name = "Ingame probe"
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
grant_wage_increase = true
EOF
  env XDG_CONFIG_HOME="$dir/config" "$@" timeout 280 "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/ingame_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
  grep -q 'PROBE: DONE' "$dir/log.txt" || { echo "$name failed:"; tail -20 "$dir/log.txt"; return 1; }
}

port=$((48000 + RANDOM % 1000))
run_probe solo MP_MODE=solo MP_STEPS=300 MP_UI_SCRIPT="30:buy:bench;60:hire:Doctor" &
run_probe host_ui MP_MODE=host MP_PORT=$port &
sleep 0.5; run_probe client_ui MP_MODE=client MP_PORT=$port \
  MP_UI_SCRIPT="30:buy:bench;60:hire:Doctor;120:pickup;200:buy:plant" &
wait
port=$((port + 1))
run_probe host_both MP_MODE=host MP_PORT=$port MP_UI_SCRIPT="30:buy:bench;31:buy:plant" &
sleep 0.5; run_probe client_both MP_MODE=client MP_PORT=$port MP_DRAW_EVERY=3 \
  MP_UI_SCRIPT="30:hire:Doctor;30:buy:bench" &
port=$((port + 1))
run_probe host_cheat MP_MODE=host MP_PORT=$port &
sleep 0.5; run_probe client_cheat MP_MODE=client MP_PORT=$port MP_UI_SCRIPT="50:cheat" &
port=$((port + 1))
run_probe host_pause MP_MODE=host MP_PORT=$port MP_UI_SCRIPT="100:pause:3000;300:buy:bench" &
sleep 0.5; run_probe client_pause MP_MODE=client MP_PORT=$port \
  MP_UI_SCRIPT="500:speedup:200;600:hire:Doctor" &
wait

python3 - "$out" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
def log(n): return (out / n / 'log.txt').read_text()
def result(n):
    m = re.search(r'RESULT: (.*)', log(n)); return m.group(1) if m else 'no result'
def applied(n):
    return [l.split('] ', 1)[1] for l in log(n).splitlines() if re.match(r'\[\w+\] step \d+: peer', l)]
fail = False

solo = log('solo')
ok1 = 'balance unchanged locally: false' in solo and 'pool size still 7' in solo
print(f'1. Single player UI:        bought and hired immediately: {ok1}')
fail |= not ok1

host, client = applied('host_ui'), applied('client_ui')
refused = 'picked up: nil' in log('client_ui')
ok2 = (result('host_ui').startswith('IN SYNC') and host == client and len(host) == 3
       and all(a.endswith('-> ok') for a in host) and refused)
print(f'2. Client UI actions:       {result("host_ui")}; host applied {sum(a.endswith("-> ok") for a in host)}/3; pick-up refused: {refused}')
fail |= not ok2

hb, cb = applied('host_both'), applied('client_both')
ok3 = result('host_both').startswith('IN SYNC') and result('client_both').startswith('IN SYNC') and hb == cb and hb
print(f'3. Same-hour actions:       {result("host_both")}; identical decisions on both: {hb == cb} ({len(hb)} commands)')
fail |= not ok3

ok4 = result('host_cheat').startswith('DESYNC') and result('client_cheat').startswith('DESYNC')
print(f'4. Local-only change:       host {result("host_cheat")}; client {result("client_cheat")}')
fail |= not ok4
gap = max(int(m) for m in re.findall(r'max step gap to peer=(\d+)', log('host_pause') + log('client_pause')))
told = 'NOTICE to player: Waiting' in log('client_pause')
ok5 = (result('host_pause').startswith('IN SYNC') and result('client_pause').startswith('IN SYNC')
       and gap <= 1 and told)
print(f'5. Pause and speed up:      {result("host_pause")}; max step gap {gap}; waiting notice shown: {told}')
fail |= not ok5
sys.exit(1 if fail else 0)
PY
