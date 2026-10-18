#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_s0_fingerprints.sh BINARY GAME_DATA OUT_FILE [CALLBACKS]
#
# Cross-platform determinism check (milestone S0), one side: run the busy
# single-player scenario of sync_probe.lua (seed 12345, no network) headless
# and write one fingerprint line per game hour to OUT_FILE. Run it on Windows
# (Git Bash, with the CI-built CorsixTH.exe) and on Linux with the same
# checkout, then compare the two files (compare_fingerprints.py). The two
# builds must use the same Lua version (Windows: Lua 5.5; on Linux see
# setup_lua55_linux.sh).
set -euo pipefail
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 BINARY GAME_DATA OUT_FILE [CALLBACKS]" >&2
  exit 2
fi
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
binary=$1
game_data=$2
out_file=$3
callbacks=${4:-20000}
work=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-s0.XXXXXXXX")
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # Windows paths for the game and its Lua code.
    source_dir=$(cygpath -m "$source_dir"); game_data=$(cygpath -m "$game_data")
    out_file=$(cygpath -m "$out_file"); work_native=$(cygpath -m "$work") ;;
  *) work_native=$work ;;
esac
mkdir -p "$work/saves"
cat > "$work/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$work_native/saves]]
player_name = "Determinism"
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
check_for_updates = false
EOF
echo "Running $callbacks ticks, output $out_file (work dir $work)"
env CORSIXTH_SOURCE="$source_dir" MP_OUT="$out_file" MP_SCENARIO=busy MP_CALLBACKS="$callbacks" \
  MP_CANONICAL_ORDER=1 \
  SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software \
  "$binary" "--interpreter=$source_dir/scripts/multiplayer/sync_probe.lua" \
  "--config-file=$work_native/config.txt" > "$work/log.txt" 2>&1 || true
if [[ -s "$out_file" ]]; then
  echo "$(wc -l < "$out_file") game hours; last: $(tail -1 "$out_file" | cut -c1-120)"
else
  echo "No fingerprints written; log:"; tail -20 "$work/log.txt"
  exit 1
fi
