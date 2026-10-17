#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_headless_smoke.sh BINARY GAME_DATA [OUTPUT_DIR]
# Keep OUTPUT_DIR and GAME_DATA outside the git checkout. This test creates saves.
set -euo pipefail
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 BINARY GAME_DATA [OUTPUT_DIR]" >&2
  exit 2
fi
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
binary=$(realpath "$1")
game_data=$(realpath "$2")
[[ -x "$binary" && -d "$game_data" ]]
if [[ $# -eq 3 ]]; then
  output_dir=$(realpath -m "$3")
  case "$output_dir/" in
    "$source_dir/"*) echo "Output directory must be outside the checkout" >&2; exit 2 ;;
  esac
  # Refuse to overwrite an existing test directory or its configuration/save.
  mkdir "$output_dir"
else
  output_dir=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-smoke.XXXXXXXX")
fi
case "$output_dir/" in
  "$source_dir/"*) echo "Output directory must be outside the checkout" >&2; exit 2 ;;
esac
mkdir -p "$output_dir/config" "$output_dir/saves"
export CORSIXTH_SOURCE="$source_dir" CORSIXTH_SMOKE_OUTPUT="$output_dir"
export XDG_CONFIG_HOME="$output_dir/config"
export USER="${USER:-corsixth-test}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
# Set LD_LIBRARY_PATH before invoking this script if dependencies live in a
# custom prefix. CORSIXTH_SMOKE_FONT is optional; it avoids font fallback notices.
python3 - "$game_data" "$output_dir" <<'PY'
import json
import os
import pathlib
import sys

data, output = sys.argv[1:]
values = {
    'theme_hospital_install': data,
    'savegames': str(pathlib.Path(output) / 'saves'),
    'player_name': 'Runtime smoke test',
    'fullscreen': False, 'width': 800, 'height': 600,
    'language': 'English', 'audio': False, 'play_music': False,
    'play_sounds': False, 'play_announcements': False,
    'movies': False, 'play_intro': False, 'play_demo': False,
}
if os.environ.get('CORSIXTH_SMOKE_FONT'):
    values['unicode_font'] = os.environ['CORSIXTH_SMOKE_FONT']

def lua_value(value):
    if isinstance(value, bool):
        return 'true' if value else 'false'
    return json.dumps(value, ensure_ascii=False)

pathlib.Path(output, 'config.txt').write_text(
    ''.join(f'{key} = {lua_value(value)}\n' for key, value in values.items()),
    encoding='utf-8',
)
PY
printf 'Smoke output: %s\n' "$output_dir"
set +e
timeout 60 "$binary" \
  "--interpreter=$source_dir/scripts/multiplayer/runtime_smoke.lua" \
  "--config-file=$output_dir/config.txt" > "$output_dir/smoke.log" 2>&1
status=$?
set -e
cat "$output_dir/smoke.log"
if [[ $status -ne 0 ]]; then
  exit "$status"
fi
# CorsixTH can return success after an interpreter/bootstrap error, so require
# the completion marker as well as a zero process exit code.
grep -q '^SMOKE: PASS$' "$output_dir/smoke.log"
