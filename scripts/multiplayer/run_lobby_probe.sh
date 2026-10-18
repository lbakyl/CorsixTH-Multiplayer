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
#      nurse sent between them, loans, a price, research and heating changed
#      in their windows -> IN SYNC, every command accepted
#   9. co-op events: an emergency and a VIP visit for player 2's hospital,
#      accepted by player 2; the emergency countdown runs in the simulation
#      -> IN SYNC
#  10. staff and queues: two pay rises asked (test command) and answered in
#      the pay rise window (accepted, declined), a nurse fired in staff
#      management, a queue reordered by dragging in the queue window by each
#      player, a bench picked up and put down elsewhere, another sold, a GP's
#      office furnished by hand (one command per object, then confirmed),
#      toilets drawn and cancelled while furnishing -> IN SYNC
#  11. save and continue: a co-op game saved with File > Save, continued from
#      the lobby by the same players (other host, own hospitals by name),
#      loaded state identical to the saved one -> IN SYNC, commands after it
# With MP_REFEREE=1 the local server also runs its headless referee for every
# room, and four more checks: 12. the referee agrees with the players in every
# room except 'cheat' (that one desyncs before the referee is there); 13, 14.
# desync repair in a shared and a co-op game; 15. rejoin after a quit.
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-lobby.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"

# By default a server is started here. MP_EXTERNAL_SERVER=host:port uses a
# running one instead (e.g. the Docker container); MP_SERVER_LOG_CMD then
# prints its log for the checks (e.g. "docker logs corsixth-mp-server").
# All test players connect from one address, above the default limit of 8.
if [[ -n "${MP_EXTERNAL_SERVER:-}" ]]; then
  export MP_SERVER="$MP_EXTERNAL_SERVER"
  echo "Using server $MP_SERVER"
else
  port=$((47000 + RANDOM % 900))
  if [[ "${MP_REFEREE:-0}" == 1 ]]; then
    export CORSIXTH_MP_REFEREE_BINARY="$binary" CORSIXTH_MP_REFEREE_SOURCE="$source_dir"
    export CORSIXTH_MP_REFEREE_DATA="$game_data" CORSIXTH_MP_REFEREE_WORKDIR="$out/referee"
    export CORSIXTH_MP_REFEREE_LUA_CPATH="$MP_LUA_CPATH" CORSIXTH_MP_REFEREE_LUA_PATH="$MP_LUA_PATH"
    export MP_REFEREE_PROBE_SCENARIO="crowd=busy;staff=busy" # the probes' own start, see below
  fi
  PYTHONPATH="$source_dir/mp_server" python3 -m corsixth_mp --host 127.0.0.1 --port "$port" \
    --log-level INFO --max-per-address 64 > "$out/server.log" 2>&1 &
  server_pid=$!
  trap 'kill $server_pid 2>/dev/null || true' EXIT
  for _ in $(seq 50); do grep -q listening "$out/server.log" 2>/dev/null && break; sleep 0.1; done
  export MP_SERVER="127.0.0.1:$port"
fi

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
  MP_UI_SCRIPT="20:openhospital;60:buy:bench;80:hire:Doctor;200:givemoney:5000;250:loan;260:priceup;270:research:cure;280:heatup;400:bonus:Doctor;410:raise:Doctor" & pids+=($!)
sleep 1
run_probe nico MP_ROLE=join MP_ROOM=coop MP_STEPS=1200 MP_DRAW_EVERY=3 \
  MP_UI_SCRIPT="30:openhospital;60:buy:plant;90:hire:Nurse;300:sendstaff:Nurse;350:loan;360:heatup;370:heatup;600:sendhome" & pids+=($!)
run_probe olga MP_ROLE=host MP_ROOM=events MP_COOP=1 MP_STEPS=1600   MP_UI_SCRIPT="20:openhospital;100:emergency:2;400:vip:2" & pids+=($!)
sleep 1
run_probe paul MP_ROLE=join MP_ROOM=events MP_STEPS=1600 MP_DRAW_EVERY=3   MP_UI_SCRIPT="30:openhospital;130:answerfax:emergency:1;430:answerfax:personality:1" & pids+=($!)
# Staff and queues: pay rises asked (test command) and answered in the pay
# rise window, one accepted and one declined; a nurse fired; queues
# reordered by dragging in the queue window.
run_probe wade MP_ROLE=host MP_ROOM=staff MP_STEPS=1000 MP_SCENARIO=busy \
  MP_UI_SCRIPT="100:askraise:Doctor;300:askraise:Handyman;400:patients:10;410:queuefront;600:fire:Nurse;650:buy:bench;660:buy:bench;700:moveobject:bench;800:sellobject:bench" & pids+=($!)
sleep 1
run_probe yara MP_ROLE=join MP_ROOM=staff MP_STEPS=1000 MP_SCENARIO=busy \
  MP_UI_SCRIPT="150:answerraise:accept;350:answerraise:decline;420:queuefront;500:furnishroom:gp:5:5;750:cancelroom:toilets:4:4" & pids+=($!)
# Save and continue: a co-op game saves at step 300 (File > Save) and ends;
# then the same two players continue it from the lobby, the other one
# hosting this time (each gets their own hospital back by name).
(
  run_probe sara MP_ROLE=host MP_ROOM=savegame MP_COOP=1 MP_STEPS=400 \
    MP_UI_SCRIPT="20:openhospital;60:buy:bench;80:hire:Doctor;300:mpsave" & a=$!
  sleep 1
  run_probe tom MP_ROLE=join MP_ROOM=savegame MP_STEPS=400 \
    MP_UI_SCRIPT="30:openhospital;90:hire:Nurse" & b=$!
  wait $a $b
  mkdir -p "$out/tom-2/saves"
  cp -r "$out/tom/saves/." "$out/tom-2/saves/"
  run_probe tom-2 MP_NAME=tom MP_ROLE=host MP_ROOM=savegame2 MP_STEPS=700 MP_CONTINUE=latest \
    MP_UI_SCRIPT="450:buy:plant" & a=$!
  sleep 1
  run_probe sara-2 MP_NAME=sara MP_ROLE=join MP_ROOM=savegame2 MP_STEPS=700 \
    MP_UI_SCRIPT="500:hire:Nurse" & b=$!
  wait $a $b
) & pids+=($!)
if [[ "${MP_REFEREE:-0}" == 1 ]]; then
  # Desync repair: one player changes money locally, the server holds both
  # games, both load the referee's save and play on (shared and co-op).
  run_probe quinn MP_ROLE=host MP_ROOM=fix MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="500:buy:bench" & pids+=($!)
  sleep 1
  run_probe rosa MP_ROLE=join MP_ROOM=fix MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="300:cheat;520:hire:Nurse" & pids+=($!)
  run_probe sam MP_ROLE=host MP_ROOM=fixcoop MP_COOP=1 MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="20:openhospital;400:cheat;500:buy:bench" & pids+=($!)
  sleep 1
  run_probe tess MP_ROLE=join MP_ROOM=fixcoop MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="30:openhospital;520:hire:Nurse" & pids+=($!)
  # Rejoin: a player quits (as after a crash) and joins the running game
  # again under the same name, in a new game process.
  # The host pauses after the other one quits, until the rejoin is done.
  run_probe uma MP_ROLE=host MP_ROOM=back MP_COOP=1 MP_STEPS=1500 \
    MP_UI_SCRIPT="20:openhospital;400:waitrejoin;800:buy:bench;900:hire:Doctor" & pids+=($!)
  sleep 1
  run_probe vera MP_ROLE=join MP_ROOM=back MP_STEPS=1500 \
    MP_UI_SCRIPT="30:openhospital;300:quit" & pids+=($!)
  (for _ in $(seq 600); do grep -qs "UI: quitting" "$out/vera/log.txt" && break; sleep 0.1; done
   sleep 1
   run_probe vera-back MP_NAME=vera MP_ROLE=join MP_ROOM=back MP_STEPS=1500 MP_REJOIN=1) & pids+=($!)
fi
for pid in "${pids[@]}"; do wait "$pid" || true; done

if [[ -n "${MP_SERVER_LOG_CMD:-}" ]]; then eval "$MP_SERVER_LOG_CMD" > "$out/server.log" 2>&1 || true; fi
if [[ ! -f "$out/server.log" ]]; then
  echo "No server log (set MP_SERVER_LOG_CMD): the server-side part of check 3 fails."
  : > "$out/server.log"
fi

python3 - "$out" "${MP_REFEREE:-0}" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
with_referee = sys.argv[2] == '1' 
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
                                               'hire', 'hire', 'give_money', 'send_staff', 'loan', 'loan',
                                               'set_price', 'research_frac', 'set_heat', 'set_heat', 'set_heat',
                                               'staff_bonus', 'raise_wage', 'send_home'])
       and 'co-op: 2 hospitals' in m)
print(f"8. Co-op, a hospital each:  {result('mira')}; commands {len(cm)} all ok: {ok_all}; identical: {cm == applied('nico')}")
for line in re.findall(r'hospital \d (?:[A-Z]+:|settings:).*', m)[-4:]:
    print("   " + line)
fail |= not ok8

o, q = log('olga'), log('paul')
co = applied('olga')
okc = [x for x in co if x.endswith('-> ok')]
kinds9 = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in okc)
helicopter_crash = 'Traceback' in o or 'Traceback' in q
ok9 = (result('olga').startswith('IN SYNC') and result('paul').startswith('IN SYNC') and co == applied('paul')
       and kinds9 == sorted(['open_hospital', 'open_hospital', 'probe_emergency', 'fax_choice', 'probe_vip', 'fax_choice'])
       and 'clicked choice 1 of emergency fax' in q and 'clicked choice 1 of personality fax' in q)
print(f"9. Co-op events, player 2:  {result('olga')}; emergency and VIP for hospital 2 accepted: {ok9}; commands {len(okc)}/{len(co)} ok")
for x in co: print("   " + x)
fail |= not ok9

w_, y_ = log('wade'), log('yara')
cw = applied('wade')
okw = [x for x in cw if x.endswith('-> ok')]
kinds10 = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in okw)
m10 = re.search(r'rooms built: (.*)', w_)
rooms10 = m10.group(1) if m10 else ''
# Where yara drew the furnished GP's office and the cancelled toilets.
drawn10 = {k: f"{k}@{x},{yy}" for k, x, yy in re.findall(r'UI: drew (\w+) at (\d+),(\d+)', y_)}

ok10 = (result('wade').startswith('IN SYNC through step 1000') and result('yara').startswith('IN SYNC')
        and cw == applied('yara') and kinds10.count('pay_rise') == 2 and kinds10.count('probe_raise') == 2
        and 'fire_staff' in kinds10 and kinds10.count('queue_move') >= 1 and 'probe_patients' in kinds10
        and 'move_object' in kinds10 and 'sell_object' in kinds10
        and kinds10.count('room_object') >= 2 and 'room_finish' in kinds10 and 'room_abort' in kinds10
        and rooms10 == re.search(r'rooms built: (.*)', y_).group(1)
        and drawn10.get('gp', '-') in rooms10.split() and drawn10.get('toilets', '-') not in rooms10.split()
        and 'accepted the pay rise' in y_ and 'declined the pay rise' in y_)
print(f"10. Staff and queues:       {result('wade')}; commands {len(okw)}/{len(cw)} ok, identical: {cw == applied('yara')}; {' '.join(kinds10)}; rooms {rooms10 or 'none'}")
fail |= not ok10

sa, to, t2, s2 = log('sara'), log('tom'), log('tom-2'), log('sara-2')
saved_s = re.search(r"SAVED savegame (\S+) at step (\d+): (.*)", sa)
saved_t = re.search(r"SAVED savegame (\S+) at step (\d+): (.*)", to)
loaded_t = re.search(r"LOADED: loaded the shared save at step (\d+); playing (\S+) \(hospital (\d)\): (.*)", t2)
loaded_s = re.search(r"LOADED: loaded the shared save at step (\d+); playing (\S+) \(hospital (\d)\): (.*)", s2)
same_save = bool(saved_s and saved_t and saved_s.group(2, 3) == saved_t.group(2, 3))
# The state right after loading (money reads 39654.0 once loaded: same value).
def at_load(text):
    m = re.search(r"multiplayer: loaded the shared save at step (\d+) \(\d+ bytes\): (.*)", text)
    return m and (m.group(1), re.sub(r"(\d)\.0(?!\d)", r"\1", m.group(2)))
same_load = bool(saved_t and at_load(t2) and at_load(t2) == at_load(s2) == saved_t.group(2, 3))
seats = bool(loaded_t and loaded_s and loaded_t.group(2) == 'TOM' and loaded_s.group(2) == 'SARA')
after = [x for x in applied('tom-2') if x.endswith('-> ok')]
kinds11 = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in after)
ok11 = (same_save and same_load and seats and result('tom-2').startswith('IN SYNC through step 700')
        and result('sara-2').startswith('IN SYNC through step 700') and applied('tom-2') == applied('sara-2')
        and kinds11 == ['hire', 'place_object'])
print(f"11. Save and continue:      saved at step {saved_t.group(2) if saved_t else '-'} on both: {same_save}; "
      f"continued from it: {same_load}; own hospitals: {seats}; {result('tom-2')} / {result('sara-2')}; "
      f"commands after it: {' '.join(kinds11)}")
fail |= not ok11

if with_referee:
    rooms = ['ward', 'leave', 'build', 'crowd', 'fax', 'coop', 'events', 'staff']
    connected = [r for r in rooms if f"room '{r}': referee connected" in server]
    differ = re.findall(r"room '(\w+)': the players differ from the referee", server)
    confirmed = dict(re.findall(r"room '(\w+)': referee confirmed steps through (\d+)", server))
    def confirmed_after(room): return confirmed.get(room, 0)
    ok10 = connected == rooms and not differ and all(int(confirmed.get(r, 0)) > 300 for r in rooms)
    print(f"12. Headless referee:       connected in {len(connected)}/{len(rooms)} rooms; "
          f"differs in {differ or 'none'}; confirmed through " +
          ", ".join(f"{r} {confirmed.get(r, 0)}" for r in rooms))
    fail |= not ok10

    for n, (host, join, room) in enumerate([('quinn', 'rosa', 'fix'), ('sam', 'tess', 'fixcoop')]):
        hl, jl = log(host), log(join)
        repaired = 'REPAIRED' in hl and 'REPAIRED' in jl
        fixed = re.search(rf"room '{room}': repaired: everybody loads the referee's game at step (\d+) \((\d+) bytes", server)
        same = applied(host) == applied(join)
        kinds = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in applied(host) if x.endswith('-> ok'))
        later = 'place_object' in kinds and 'hire' in kinds
        ok = (repaired and fixed is not None and same and later
              and result(host).startswith('IN SYNC through step 1000')
              and result(join).startswith('IN SYNC through step 1000')
              and int(confirmed_after(room)) >= 900)
        where = f"at step {fixed.group(1)}, save {int(fixed.group(2)) // 1024} KiB" if fixed else "not repaired"
        print(f"{13 + n}. Desync repair ({room}):{' ' * (8 - len(room))}{result(host)} / {result(join)}; "
              f"{where}; commands after it ok on both: {same and later}")
        fail |= not ok

    u, v = log('uma'), log('vera-back')
    rejoined = re.search(r"REJOINED: loaded the shared save at step (\d+)", v)
    at = int(rejoined.group(1)) if rejoined else 10**9
    after_u = [x for x in applied('uma') if int(re.search(r'step (\d+):', x).group(1)) > at]
    after_v = [x for x in applied('vera-back') if int(re.search(r'step (\d+):', x).group(1)) > at]
    kinds = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in after_u if x.endswith('-> ok'))
    ok13 = (rejoined is not None and "room 'back': 'vera' rejoins as player 2" in server
            and result('uma').startswith('IN SYNC through step 1500')
            and result('vera-back').startswith('IN SYNC through step 1500')
            and after_u == after_v and kinds == ['hire', 'place_object']
            and int(confirmed_after('back')) >= 1400)
    print(f"15. Rejoin after a crash:   {result('uma')} / {result('vera-back')}; "
          f"rejoined at step {at if rejoined else '-'}; commands after it on both: {after_u == after_v} {kinds}")
    fail |= not ok13
sys.exit(1 if fail else 0)
PY
