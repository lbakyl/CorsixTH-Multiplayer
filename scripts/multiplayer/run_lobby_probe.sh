#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_lobby_probe.sh BINARY GAME_DATA
#
# Multiplayer through the relay server, like players would use it: both games
# open Multiplayer from the main menu, connect to a local mp_server, create or
# join a password-protected room, get ready and start. Checks:
#   1. two players: room, ping and pacing in the lobby, game start, actions
#      from both (buy, hire), a pause by one player that both get, an
#      unpause by the other, a speed change -> IN SYNC
#   2. wrong password -> refused
#   3. one player changes money locally only -> DESYNC (found by the game
#      and by the server)
#   4. one player leaves mid-game -> the other is told and carries on alone
#   5. rooms: both draw a room on the same spot in the same hour (one wins
#      on both machines), the other player sees the reserved outline, a
#      later room elsewhere, a window -> IN SYNC, same rooms on both
#   6. rooms drawn where people stand (busy hospital): they are asked to
#      walk out and the build is retried -> IN SYNC, same rooms on both
#   7. faxes: a VIP fax refused by clicking in the fax window, a second one
#      left to time out (accepted), shown at different moments on the two
#      screens -> IN SYNC, same decisions on both
#   8. co-op on an original two-player map: a hospital each, both opened
#      early, purchases and hires in each player's own hospital, money and a
#      nurse sent between them -> IN SYNC, every command accepted
# Exits 0 only if all eight behave as expected.
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-lobby.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"

port=$((47000 + RANDOM % 900))
PYTHONPATH="$source_dir/mp_server" python3 -m corsixth_mp --host 127.0.0.1 --port "$port" \
  --log-level INFO > "$out/server.log" 2>&1 &
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

# grant_wage_increase is false in every config above: the server's START
# must switch it on for the session, or staff would be fired (lesson 4).
# All rooms run at once; wait for the games only (a bare "wait" would also
# wait for the server).
pids=()
run_probe alice MP_ROLE=host MP_ROOM=ward MP_STEPS=1500 \
  MP_UI_SCRIPT="30:buy:bench;60:hire:Doctor;200:pause;700:speed:Slower" & pids+=($!)
sleep 1
run_probe bob MP_ROLE=join MP_ROOM=ward MP_STEPS=1500 MP_DRAW_EVERY=3 \
  MP_UI_SCRIPT="40:buy:plant;90:hire:Nurse;190:unpause:150" & pids+=($!)
sleep 1
run_probe mallory MP_ROLE=join MP_ROOM=ward MP_JOIN_PASSWORD=guess & pids+=($!)
run_probe carol MP_ROLE=host MP_ROOM=cheat MP_STEPS=400 & pids+=($!)
sleep 1
run_probe dave MP_ROLE=join MP_ROOM=cheat MP_STEPS=400 MP_UI_SCRIPT="50:cheat" & pids+=($!)
run_probe erin MP_ROLE=host MP_ROOM=leave MP_STEPS=800 MP_UI_SCRIPT="100:buy:bench" & pids+=($!)
sleep 1
run_probe frank MP_ROLE=join MP_ROOM=leave MP_STEPS=800 MP_UI_SCRIPT="300:quit" & pids+=($!)
run_probe gina MP_ROLE=host MP_ROOM=build MP_STEPS=900 MP_DRAW_EVERY=4   MP_UI_SCRIPT="100:room:gp:5:5:window;400:buy:bench" & pids+=($!)
sleep 1
run_probe hugo MP_ROLE=join MP_ROOM=build MP_STEPS=900   MP_UI_SCRIPT="100:room:pharmacy:4:4;300:room:toilets:4:4" & pids+=($!)
run_probe ivan MP_ROLE=host MP_ROOM=crowd MP_STEPS=1200 MP_SCENARIO=busy & pids+=($!)
sleep 1
run_probe judy MP_ROLE=join MP_ROOM=crowd MP_STEPS=1200 MP_SCENARIO=busy   MP_UI_SCRIPT="300:crowdroom:gp:4:4;340:crowdroom:gp:4:4;380:crowdroom:gp:4:4;500:crowdroom:toilets:4:4" & pids+=($!)
run_probe kate MP_ROLE=host MP_ROOM=fax MP_STEPS=1300 MP_UI_SCRIPT="100:vip;400:vip" & pids+=($!)
sleep 1
run_probe liam MP_ROLE=join MP_ROOM=fax MP_STEPS=1300 MP_DRAW_EVERY=2   MP_UI_SCRIPT="160:answerfax:personality:2" & pids+=($!)
run_probe mira MP_ROLE=host MP_ROOM=coop MP_COOP=1 MP_STEPS=1200 \
  MP_UI_SCRIPT="20:openhospital;60:buy:bench;80:hire:Doctor;200:givemoney:5000" & pids+=($!)
sleep 1
run_probe nico MP_ROLE=join MP_ROOM=coop MP_STEPS=1200 MP_DRAW_EVERY=3 \
  MP_UI_SCRIPT="30:openhospital;60:buy:plant;90:hire:Nurse;300:sendstaff:Nurse" & pids+=($!)
for pid in "${pids[@]}"; do wait "$pid" || true; done

python3 - "$out" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
def log(n): return (out / n / 'log.txt').read_text()
def result(n):
    m = re.search(r'RESULT: (.*)', log(n)); return m.group(1) if m else 'no result'
def applied(n):
    return [l for l in log(n).splitlines() if re.search(r'multiplayer: step \d+: peer', l)]
server = (out / 'server.log').read_text()
fail = False

a, b = log('alice'), log('bob')
lobby = re.search(r'lobby: .*', a)
paused_both = 'speed is now Pause' in a and 'speed is now Pause' in b
unpaused = bool(re.search(r'\[bob\] UI: pressed P at step \d+ \(paused\)', b))
slower_both = 'speed is now Slower' in a and 'speed is now Slower' in b
ok_cmds = [x for x in applied('alice') if x.endswith('-> ok')]
ok1 = (result('alice').startswith('IN SYNC') and result('bob').startswith('IN SYNC')
       and applied('alice') == applied('bob') and len(ok_cmds) == 4
       and paused_both and unpaused and slower_both)
print(f"1. Two players via server:  {result('alice')}; commands applied {len(ok_cmds)}/4, identical: {applied('alice') == applied('bob')}")
print(f"   {lobby.group(0) if lobby else 'no lobby line'}")
print(f"   shared pause on both: {paused_both}; unpaused by the other player: {unpaused}; shared speed change: {slower_both}")
fail |= not ok1

refused = 'JOIN REFUSED: bad_password' in log('mallory')
print(f"2. Wrong password:          refused: {refused}")
fail |= not refused

server_desync = "room 'cheat': desync" in server
ok3 = result('carol').startswith('DESYNC') and result('dave').startswith('DESYNC') and server_desync
print(f"3. Local-only change:       {result('carol')} / {result('dave')}; server noticed: {server_desync}")
fail |= not ok3

e = log('erin')
told = re.search(r'multiplayer: peer 2 left after step \d+', e) is not None
alone = re.search(r'steps=800 .* peers=1', e) is not None
ok4 = told and alone and result('erin').startswith('IN SYNC through step 800')
print(f"4. Player leaves:           told: {told}; carried on alone to step 800: {alone}")
fail |= not ok4

g, h = log('gina'), log('hugo')
rooms_g = re.search(r'rooms built: (.*)', g); rooms_h = re.search(r'rooms built: (.*)', h)
rooms_g = rooms_g.group(1).split() if rooms_g else []; rooms_h = rooms_h.group(1).split() if rooms_h else []
saw = 'showing reserved area of player 1: gp' in h and 'showing reserved area of player 2: toilets' in g
built = sorted(r.split('@')[0] for r in rooms_g)
ok5 = (result('gina').startswith('IN SYNC') and result('hugo').startswith('IN SYNC')
       and rooms_g == rooms_h and built == ['gp', 'toilets'] and saw)
print(f"5. Rooms:                   {result('gina')}; built on both: {rooms_g == rooms_h} {rooms_g}; reserved outlines seen: {saw}")
fail |= not ok5

i, j = log('ivan'), log('judy')
ri = re.search(r'rooms built: (.*)', i); rj = re.search(r'rooms built: (.*)', j)
ri = ri.group(1) if ri else None; rj = rj.group(1) if rj else None
retries = len(re.findall(r'build_room -> rejected: retry', j))
drawn = len(re.findall(r'UI: drew ', j))
ok6 = (result('ivan').startswith('IN SYNC') and result('judy').startswith('IN SYNC') and ri == rj
       and drawn >= 1 and retries > 0)
print(f"6. Rooms over people:       {result('ivan')}; same rooms on both: {ri == rj}; drawn over people: {drawn}; retries while people left: {retries}")
for l in sorted(set(re.findall(r'step \d+: peer 2 #\d+ build_room -> .*', j))):
    print("   " + l)
fail |= not ok6

k, l = log('kate'), log('liam')
choices = [x for x in applied('kate') if 'fax_choice' in x]
clicked = 'UI: clicked choice 2 of personality fax' in l
ok7 = (result('kate').startswith('IN SYNC') and result('liam').startswith('IN SYNC')
       and applied('kate') == applied('liam') and clicked and len(choices) == 1
       and choices[0].endswith('-> ok'))
print(f"7. Fax decisions:           {result('kate')}; refusal clicked: {clicked}; applied on both: {applied('kate') == applied('liam')} {choices}")
fail |= not ok7

m, n = log('mira'), log('nico')
cm = applied('mira')
kinds = [re.search(r'#\d+ (\w+) ->', x).group(1) for x in cm]
ok_all = all(x.endswith('-> ok') for x in cm)
ok8 = (result('mira').startswith('IN SYNC') and result('nico').startswith('IN SYNC') and cm == applied('nico')
       and ok_all and sorted(kinds) == sorted(['open_hospital', 'open_hospital', 'place_object', 'place_object',
                                               'hire', 'hire', 'give_money', 'send_staff'])
       and 'co-op: 2 hospitals' in m)
print(f"8. Co-op, a hospital each:  {result('mira')}; commands {len(cm)} all ok: {ok_all}; identical: {cm == applied('nico')}")
for line in re.findall(r'hospital \d .*', m)[-2:]:
    print("   " + line)
fail |= not ok8
sys.exit(1 if fail else 0)
PY
