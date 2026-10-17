#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_sp_regression.sh BASE_CHECKOUT BASE_BINARY \
#            NEW_CHECKOUT NEW_BINARY GAME_DATA [CALLBACKS]
#
# Single-player regression check for changes on the simulation path: a busy
# hospital (sync_probe.lua, MP_SCENARIO=busy, no multiplayer session) is run
# with the same seed on two builds, and the hourly fingerprints must be
# identical. Default 80000 game ticks, about three game years (until the
# level is lost). Runs both builds in parallel; takes several minutes.
set -euo pipefail
if [[ $# -lt 5 ]]; then
  echo "Usage: $0 BASE_CHECKOUT BASE_BINARY NEW_CHECKOUT NEW_BINARY GAME_DATA [CALLBACKS]" >&2
  exit 2
fi
base_src=$(realpath "$1"); base_bin=$(realpath "$2")
new_src=$(realpath "$3"); new_bin=$(realpath "$4")
game_data=$(realpath "$5")
callbacks=${6:-80000}
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-spreg.XXXXXXXX")
echo "Output: $out"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software

run() { # name source binary
  local dir="$out/$1"
  mkdir -p "$dir/config" "$dir/saves"
  cat > "$dir/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$dir/saves]]
player_name = "Regression"
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
  env XDG_CONFIG_HOME="$dir/config" CORSIXTH_SOURCE="$2" MP_OUT="$dir/fp.txt" \
    MP_SCENARIO=busy MP_CALLBACKS="$callbacks" "$3" \
    "--interpreter=$2/scripts/multiplayer/sync_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
}
run base "$base_src" "$base_bin" & p1=$!
run new "$new_src" "$new_bin" & p2=$!
wait $p1 $p2

python3 - "$out" <<'PY'
import pathlib, sys
out = pathlib.Path(sys.argv[1])
a = (out / 'base/fp.txt').read_text().splitlines()
b = (out / 'new/fp.txt').read_text().splitlines()
if a and a == b:
    print(f"IDENTICAL for {len(a)} game hours; last: {a[-1][:100]}")
    sys.exit(0)
first = next((i for i, (x, y) in enumerate(zip(a, b)) if x != y), min(len(a), len(b)))
print(f"DIFFERENT: base {len(a)} hours, new {len(b)} hours, first difference at hour {first + 1}")
if first < min(len(a), len(b)):
    print("  base:", a[first][:160]); print("  new: ", b[first][:160])
sys.exit(1)
PY
