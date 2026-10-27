#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_levels_probe.sh BINARY GAME_DATA
#
# The five levels of a game with a hospital each (mp_levels.lua), through a
# local relay server: for each level, two scripted players start a co-op room
# on it and the host logs what the level has. Checks, per level:
#   * the diseases, rooms and research of its campaign level (1, 3, 5, 8, 11):
#     level 1 has no research department, X-ray or cardiogram at all; each
#     level adds rooms; the expensive late rooms only on the last levels;
#     the training room from the start on every level but the first
#   * the starting money and the goals: reputation, balance, hospital value
#     (above the plot's own worth), patients cured and cure rate, all rising
#     from level to level
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-levels.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"

port=$((47000 + RANDOM % 900))
PYTHONPATH="$source_dir/mp_server" python3 -m corsixth_mp --host 127.0.0.1 --port "$port" \
  --log-level INFO --max-per-address 64 > "$out/server.log" 2>&1 &
server_pid=$!
trap 'kill $server_pid 2>/dev/null || true' EXIT
for _ in $(seq 50); do grep -q listening "$out/server.log" 2>/dev/null && break; sleep 0.1; done
export MP_SERVER="127.0.0.1:$port"

run_probe() { # name, then extra VAR=value assignments
  local name=$1; shift
  local dir="$out/$name"
  mkdir -p "$dir/config" "$dir/saves"
  cat > "$dir/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$dir/saves]]
player_name = "$name"
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
  env XDG_CONFIG_HOME="$dir/config" MP_NAME="$name" "$@" timeout 280 "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/lobby_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
  grep -q 'PROBE: DONE' "$dir/log.txt" || { echo "$name failed:"; tail -20 "$dir/log.txt"; return 1; }
}

pids=()
for level in 1 2 3 4 5; do
  run_probe "host$level" MP_ROLE=host MP_ROOM="level$level" MP_MODE=coop MP_PLAYERS=2 MP_LEVEL=$level \
    MP_STEPS=60 MP_SCENARIO=none MP_UI_SCRIPT="10:level" & pids+=($!)
  sleep 1
  run_probe "join$level" MP_ROLE=join MP_ROOM="level$level" MP_STEPS=60 MP_SCENARIO=none & pids+=($!)
  sleep 1
done
for pid in "${pids[@]}"; do wait "$pid" || true; done

python3 - "$out" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
LATE = ['scanner', 'ultrascan', 'hair_restoration', 'electrolysis', 'blood_machine', 'decontamination',
        'dna_fixer', 'jelly_vat']
# Per level: rooms it must have (now or later) and rooms it must not have.
WANT = {
    1: ({'gp', 'pharmacy', 'psych', 'inflation'}, {'research', 'x_ray', 'cardiogram', 'operating_theatre'} | set(LATE)),
    2: ({'research', 'cardiogram', 'x_ray', 'operating_theatre'}, set(LATE)),
    3: ({'scanner', 'fracture_clinic'}, set(LATE) - {'scanner'}),
    4: ({'ultrascan', 'hair_restoration', 'electrolysis', 'blood_machine', 'decontamination'}, {'dna_fixer', 'jelly_vat'}),
    5: ({'dna_fixer', 'jelly_vat'}, set()),
}
fail, prev = False, None
for level in range(1, 6):
    text = (out / f'host{level}' / 'log.txt').read_text()
    lv = re.search(r'UI: level at step \d+: level (\S+); diseases (\d+); balance (\d+); rooms now: (\S*); '
                   r'later: (\S*); goals: (.*)', text)
    if not lv:
        print(f"Level {level}: no level line"); fail = True; continue
    rooms = set(lv.group(4).split(',')) | set(filter(None, lv.group(5).split(',')))
    goals = {k: int(v) for k, v in (g.split('=') for g in lv.group(6).split())}
    must, must_not = WANT[level]
    cur = (int(lv.group(2)), len(rooms), goals)
    # Training from the start on every level but the first.
    training = 'training' in lv.group(4).split(',')
    ok = (lv.group(1) == str(level) and must <= rooms and not must_not & rooms
          and training == (level > 1) and (level > 1 or 'training' not in rooms)
          and set(goals) == {'reputation', 'balance', 'value', 'num_cured', 'percentage_cured'}
          and goals['value'] > int(lv.group(3)))
    if prev:
        ok = ok and cur[0] >= prev[0] and cur[1] > prev[1] and all(cur[2][k] > prev[2][k] for k in goals)
    prev = cur
    print(f"Level {level}: {'ok' if ok else 'WRONG'}; diseases {lv.group(2)}; money {lv.group(3)}; "
          f"goals {lv.group(6)}\n   rooms now: {lv.group(4)}\n   later: {lv.group(5) or '-'}")
    fail |= not ok
sys.exit(1 if fail else 0)
PY
