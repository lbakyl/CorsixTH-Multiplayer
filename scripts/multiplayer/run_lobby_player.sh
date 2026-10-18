#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_lobby_player.sh BINARY GAME_DATA LOG_FILE [VAR=value ...]
#
# Run one scripted player (lobby_probe.lua) against a multiplayer server,
# for tests across machines: for example a Linux host on one computer and a
# Windows player on another (milestone S0). The VAR=value arguments are
# lobby_probe.lua settings, e.g. MP_ROLE=join MP_SERVER=192.168.8.13:47800
# MP_ROOM=s0 MP_NAME=windows MP_UI_SCRIPT="30:buy:bench". Works in Git Bash
# on Windows and in bash on Linux. For a Lua 5.5 Linux build also set
# MP_LUA_CPATH/MP_LUA_PATH to its LuaSocket (see setup_lua55_linux.sh).
set -euo pipefail
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 BINARY GAME_DATA LOG_FILE [VAR=value ...]" >&2
  exit 2
fi
source_dir=$(cd "$(dirname "$0")/../.." && pwd)
binary=$1; game_data=$2; log_file=$3; shift 3
work=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-player.XXXXXXXX")
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    source_dir=$(cygpath -m "$source_dir"); game_data=$(cygpath -m "$game_data")
    work_native=$(cygpath -m "$work") ;;
  *) work_native=$work ;;
esac
mkdir -p "$work/saves" "$work/config"
cat > "$work/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$work_native/saves]]
player_name = "Player"
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
check_for_updates = false
EOF
env CORSIXTH_SOURCE="$source_dir" XDG_CONFIG_HOME="$work/config" \
  SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software "$@" \
  "$binary" "--interpreter=$source_dir/scripts/multiplayer/lobby_probe.lua" \
  "--config-file=$work_native/config.txt" > "$log_file" 2>&1 || true
grep -E "RESULT|PROBE: DONE|REFUSED" "$log_file" || { echo "no result; log tail:"; tail -15 "$log_file"; }
