#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_sync_probe.sh BINARY GAME_DATA [CALLBACKS]
#
# Runs three determinism / lockstep experiments with sync_probe.lua:
#   1. two independent solo processes, same seed  -> fingerprints must match
#   2. host + client over loopback TCP             -> must stay IN SYNC
#   3. host + client, client renders every 5 ticks -> must stay IN SYNC
#      (rendering uses math.cosmetic_random, never the gameplay stream)
#   4. host + client, client uses a different seed -> must report DESYNC
#      (proves the probe still detects divergence)
#   5. busy hospital, client sends lockstep commands -> host IN SYNC and
#      identical to a solo run applying the same commands locally
#   6. both peers place a bench on the same tile in the same hour -> IN SYNC,
#      one command rejected on both
#   7. client applies its commands but does not send them -> must DESYNC
# Exits 0 only if all seven behave as expected.
#
# Needs luasocket for the same Lua version as the binary. Point
# LUASOCKET_TREE at a LuaRocks tree containing it (lib/lua/5.x/socket/core.so).
# Output goes to a new temporary directory outside the checkout.
set -euo pipefail
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 BINARY GAME_DATA [CALLBACKS]" >&2
  exit 2
fi
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
binary=$(realpath "$1")
game_data=$(realpath "$2")
callbacks=${3:-6000}
[[ -x "$binary" && -d "$game_data" ]]
: "${LUASOCKET_TREE:?Set LUASOCKET_TREE to a LuaRocks tree containing luasocket}"
lua_ver=${LUA_VERSION_DIR:-5.4}
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-sync.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"
export MP_CALLBACKS="$callbacks"

run_probe() { # name, then extra VAR=value assignments
  local name=$1; shift
  local dir="$out/$name"
  mkdir -p "$dir/config" "$dir/saves"
  cat > "$dir/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$dir/saves]]
player_name = "Sync probe"
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
  env XDG_CONFIG_HOME="$dir/config" MP_OUT="$dir/fp.txt" "$@" timeout 600 "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/sync_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1
  grep -q 'PROBE: DONE' "$dir/log.txt" || { echo "$name failed:"; tail -20 "$dir/log.txt"; return 1; }
}

port=$((47000 + RANDOM % 2000))
run_probe solo_a & run_probe solo_b & wait
run_probe host_ok MP_MODE=host MP_PORT=$port &
sleep 0.5; run_probe client_ok MP_MODE=client MP_PORT=$port & wait
port=$((port + 1))
run_probe host_draw MP_MODE=host MP_PORT=$port &
sleep 0.5; run_probe client_draw MP_MODE=client MP_PORT=$port MP_DRAW_EVERY=5 & wait
port=$((port + 1))
run_probe host_seed MP_MODE=host MP_PORT=$port &
sleep 0.5; run_probe client_seed MP_MODE=client MP_PORT=$port MP_SEED=999 & wait

script="30:object:bench;60:object:plant;100:hire:Doctor;150:room:pharmacy:4:4;400:object:drinks_machine"
busy="MP_SCENARIO=busy MP_CALLBACKS=3000"
port=$((port + 1))
run_probe host_cmd MP_MODE=host MP_PORT=$port $busy &
sleep 0.5; run_probe client_cmd MP_MODE=client MP_PORT=$port $busy MP_SCRIPT="$script" &
run_probe solo_cmd MP_PEER=2 $busy MP_SCRIPT="$script" & wait
port=$((port + 1))
run_probe host_conflict MP_MODE=host MP_PORT=$port $busy MP_SCRIPT="30:object:bench" &
sleep 0.5; run_probe client_conflict MP_MODE=client MP_PORT=$port $busy MP_SCRIPT="30:object:bench" & wait
port=$((port + 1))
run_probe host_drop MP_MODE=host MP_PORT=$port $busy &
sleep 0.5; run_probe client_drop MP_MODE=client MP_PORT=$port $busy MP_SCRIPT="30:object:bench" MP_DROP_COMMANDS=1 & wait

python3 - "$out" <<'PY'
import pathlib, sys
out = pathlib.Path(sys.argv[1])
fail = False
a = (out / 'solo_a/fp.txt').read_text().splitlines()
b = (out / 'solo_b/fp.txt').read_text().splitlines()
if a == b and a:
    print(f'1. Solo, same seed:        IDENTICAL for {len(a)} game hours')
else:
    i = next((i for i, (x, y) in enumerate(zip(a, b)) if x != y), min(len(a), len(b)))
    print(f'1. Solo, same seed:        DIFFERENT at game hour {i + 1}  (unexpected)'); fail = True
def result(name):
    for line in (out / name / 'log.txt').read_text().splitlines():
        if 'RESULT:' in line:
            return line.split('RESULT:', 1)[1].strip()
    return 'no result'
ok = result('host_ok'); draw = result('host_draw'); seed = result('host_seed')
print(f'2. Networked lockstep:     {ok}')
fail |= not ok.startswith('IN SYNC')
print(f'3. Client renders frames:  {draw}')
fail |= not draw.startswith('IN SYNC')
print(f'4. Client different seed:  {seed}')
fail |= not seed.startswith('DESYNC')
def log(name): return (out / name / 'log.txt').read_text()
cmd = result('host_cmd')
same = (out / 'host_cmd/fp.txt').read_text() == (out / 'solo_cmd/fp.txt').read_text()
applied = log('host_cmd').count('-> ok')
print(f'5. Client commands:        {cmd}; host applied {applied}/5; matches local-only run: {same}')
fail |= not (cmd.startswith('IN SYNC') and same and applied == 5)
conflict = result('host_conflict')
rej = log('host_conflict').count('rejected: tile not free') + log('client_conflict').count('rejected: tile not free')
print(f'6. Same-tile conflict:     {conflict}; rejected on both peers: {rej == 2}')
fail |= not (conflict.startswith('IN SYNC') and rej == 2)
drop = result('host_drop')
print(f'7. Commands not sent:      {drop}')
fail |= not drop.startswith('DESYNC')
sys.exit(1 if fail else 0)
PY
