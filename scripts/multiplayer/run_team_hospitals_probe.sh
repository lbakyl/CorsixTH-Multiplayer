#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_team_hospitals_probe.sh BINARY GAME_DATA
#
# A race of two teams with a hospital per team (mode "teamshared"): team
# mates run one hospital together, as in a shared game, and race the other
# team's hospital. Through a local relay server, on level 2. Room "trio": ann
# (host) and ben share hospital 1, cat runs hospital 2 alone. Room "duo": dee
# and gus share hospital 1, eli and fay hospital 2 (800 steps, so the
# referee catches up). Checks:
#   1. seating: two hospitals named after their players ("ANN + BEN", "CAT";
#      "DEE + GUS", "ELI + FAY"), every player in their team's hospital, the
#      same on every peer; nobody has a hospital to trade with, the dirty
#      tricks window offers only the other team's hospital
#   2. team mates build together: ann's bench, ben's doctor and ben's GP's
#      office all go into hospital 1, applied the same on every peer
#   3. tricks: ann's rat attack on cat's hospital and cat's smear campaign on
#      hospital 1 are played
#   4. the race: hospital 1 reaches the goals, so team 1 takes 1st place and
#      cat 2nd, the race is over; ann, ben and cat stay IN SYNC to the end
#   5. team chat: dee's "To team" line is read by gus only
#   6. a team mate leaves: gus quits at step 300; hospital 1 still counts as
#      playing (dee runs it), and dee, eli and fay stay IN SYNC to the end
# With MP_REFEREE=1 the server also runs its headless referee, and a 7th
# check needs it to agree with the players to the end (all rooms). The
# referee also lets the server run bots, for an 8th check in room "mixed":
# hal (host) plays hospital 1 alone; Bot Agnes and ivy share hospital 2 and
# both build in it (the bot its desk, receptionist, rooms and staff, ivy a
# GP's office and a nurse), IN SYNC, and the referee agrees.
# Also a 9th check, room "clinic" (co-op, a hospital each): kim's patient
# gets a fax; lou clicking that patient gets the patient window, not kim's
# fax (another hospital's faxes are its player's); kim gets the fax.
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-teamhosp.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"

port=$((47000 + RANDOM % 900))
if [[ "${MP_REFEREE:-0}" == 1 ]]; then
  export CORSIXTH_MP_REFEREE_BINARY="$binary" CORSIXTH_MP_REFEREE_SOURCE="$source_dir"
  export CORSIXTH_MP_REFEREE_DATA="$game_data" CORSIXTH_MP_REFEREE_WORKDIR="$out/referee"
  export CORSIXTH_MP_REFEREE_LUA_CPATH="$MP_LUA_CPATH" CORSIXTH_MP_REFEREE_LUA_PATH="$MP_LUA_PATH"
  export MP_REFEREE_PROBE_SCENARIO="trio=light;duo=light;mixed=none;clinic=light" # the probes' own start on every hospital
  # Bots act twenty times sooner than a person would, and answer at once.
  export MP_BOT_PACE=20 MP_BOT_FAST=1 MP_BOT_SEED=7
fi
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
run_probe ann MP_ROLE=host MP_ROOM=trio MP_MODE=teamshared MP_TEAM=1 MP_PLAYERS=3 MP_LEVEL=2 MP_STEPS=1100 \
  MP_UI_SCRIPT="20:openhospital;60:teams;80:buy:bench;200:sabotage:rats:1:2;600:goals:1:win;610:wincheck;650:race;950:race" & pids+=($!)
sleep 1
run_probe ben MP_ROLE=join MP_ROOM=trio MP_TEAM=1 MP_STEPS=1100 \
  MP_UI_SCRIPT="60:teams;90:hire:Doctor;120:room:gp:5:5;650:race;950:race" & pids+=($!)
sleep 1
run_probe cat MP_ROLE=join MP_ROOM=trio MP_TEAM=2 MP_STEPS=1100 \
  MP_UI_SCRIPT="40:openhospital;60:teams;250:sabotage:smear:1:1;650:race;950:race" & pids+=($!)
sleep 1
run_probe dee MP_ROLE=host MP_ROOM=duo MP_MODE=teamshared MP_TEAM=1 MP_PLAYERS=4 MP_LEVEL=2 MP_STEPS=800 \
  MP_UI_SCRIPT="20:openhospital;60:teams;150:chat:1:hello team;400:teamstate;780:teamstate" & pids+=($!)
sleep 1
run_probe eli MP_ROLE=join MP_ROOM=duo MP_TEAM=2 MP_STEPS=800 MP_UI_SCRIPT="30:openhospital;60:teams" & pids+=($!)
sleep 1
run_probe fay MP_ROLE=join MP_ROOM=duo MP_TEAM=2 MP_STEPS=800 MP_UI_SCRIPT="60:teams" & pids+=($!)
sleep 1
run_probe gus MP_ROLE=join MP_ROOM=duo MP_TEAM=1 MP_STEPS=800 MP_UI_SCRIPT="60:teams;300:quit" & pids+=($!)
sleep 1
run_probe kim MP_ROLE=host MP_ROOM=clinic MP_MODE=coop MP_PLAYERS=2 MP_LEVEL=2 MP_STEPS=800   MP_UI_SCRIPT="20:openhospital;100:patients:3;150:patientfax:1;220:clickfaxpatient" & pids+=($!)
sleep 1
run_probe lou MP_ROLE=join MP_ROOM=clinic MP_STEPS=800 MP_UI_SCRIPT="30:openhospital;200:clickfaxpatient" & pids+=($!)
if [[ "${MP_REFEREE:-0}" == 1 ]]; then
  sleep 1
  run_probe hal MP_ROLE=host MP_ROOM=mixed MP_MODE=teamshared MP_TEAM=1 MP_PLAYERS=3 MP_ADD_BOTS=1 MP_LEVEL=2     MP_STEPS=1200 MP_SCENARIO=none MP_UI_SCRIPT="60:teams;1150:hospitals" & pids+=($!)
  sleep 3
  run_probe ivy MP_ROLE=join MP_ROOM=mixed MP_TEAM=2 MP_STEPS=1200 MP_SCENARIO=none     MP_UI_SCRIPT="60:teams;120:room:gp:4:4;500:hire:Nurse;1150:hospitals" & pids+=($!)
fi
for pid in "${pids[@]}"; do wait "$pid" || true; done

python3 - "$out" "${MP_REFEREE:-0}" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
with_referee = sys.argv[2] == '1'
server = (out / 'server.log').read_text()
def log(n): return (out / n / 'log.txt').read_text()
def result(n):
    m = re.search(r'RESULT: (.*)', log(n)); return m.group(1) if m else 'no result'
def applied(n, kind):
    return [l.split('multiplayer: ', 1)[1] for l in log(n).splitlines()
            if re.search(rf'multiplayer: step \d+: peer \d+ #\d+ {kind} -> ', l)]
def teams(n):
    m = re.search(r'UI: teams at step \d+: me (\d+); (.*?); trade with (.*?); tricks on (.*)', log(n))
    return m.groups() if m else None
fail = False

# 1. Seating
want = {'ann': ('1', '', '2'), 'ben': ('1', '', '2'), 'cat': ('2', '', '1'),
        'dee': ('1', '', '2'), 'gus': ('1', '', '2'), 'eli': ('2', '', '1'), 'fay': ('2', '', '1')}
layouts = {}
ok1 = True
for n, (me, trade, tricks) in want.items():
    t = teams(n)
    layouts.setdefault(n in ('ann', 'ben', 'cat') and 'trio' or 'duo', set()).add(t[1] if t else None)
    good = bool(t) and (t[0], t[2], t[3]) == (me, trade, tricks)
    ok1 &= good
    print(f"   {n}: {'me %s; %s; trade with [%s]; tricks on [%s]' % t if t else 'no teams line'}"
          f"{'' if good else '  <-- expected me %s, trade [%s], tricks [%s]' % (me, trade, tricks)}")
ok1 &= (layouts.get('trio') == {'1=ANN + BEN:1 2=CAT:2'} and layouts.get('duo') == {'1=DEE + GUS:1 2=ELI + FAY:2'})
print(f"1. Seating:                 a hospital per team, same on every peer: {ok1} {layouts}")
fail |= not ok1

# 2. Team mates build together in hospital 1
built = {n: applied(n, '(place_object|hire|build_room)') for n in ('ann', 'ben', 'cat')}
ok_cmds = [x for x in built['ann'] if x.endswith('-> ok')]
ok2 = (built['ann'] == built['ben'] == built['cat']
       and any('peer 1' in x and 'place_object' in x for x in ok_cmds)
       and any('peer 2' in x and 'hire' in x for x in ok_cmds)
       and any('peer 2' in x and 'build_room' in x for x in ok_cmds))
playing = re.findall(r'co-op: (\d+) hospitals, playing (.*?) \(hospital (\d+)\)', log('ben'))
print(f"2. Team mates build:        {built['ann']}; same on all three: "
      f"{built['ann'] == built['ben'] == built['cat']}; ben plays {playing}")
fail |= not ok2

# 3. Tricks
tricks = applied('ann', 'sabotage')
ok3 = (len([x for x in tricks if 'peer 1' in x and x.endswith('-> ok')]) == 1
       and len([x for x in tricks if 'peer 3' in x and x.endswith('-> ok')]) == 1)
print(f"3. Tricks:                  {tricks}")
fail |= not ok3

# 4. The race
races = {n: re.findall(r'UI: race at step (\d+): (.*?); over: (\w+)', log(n)) for n in ('ann', 'ben', 'cat')}
last = races['ann'][-1] if races['ann'] else None
ok4 = (last is not None and last[1] == '1=1(won)* 2=2(last)' and last[2] == 'true'
       and all(r and r[-1][1:] == last[1:] for r in races.values())
       and all(result(n).startswith('IN SYNC') for n in ('ann', 'ben', 'cat')))
print(f"4. Race:                    at the end {last[1:] if last else '-'}; "
      f"{result('ann')} / {result('ben')} / {result('cat')}")
fail |= not ok4

# 5. Team chat
team_in = [n for n in ('dee', 'eli', 'fay', 'gus') if 'dee (team): hello team' in log(n)]
ok5 = team_in == ['dee', 'gus']
print(f"5. Team chat:               read by {team_in}")
fail |= not ok5

# 6. A team mate leaves
states = re.findall(r'UI: team at step (\d+): (.*?); won', log('dee'))
away = applied('dee', 'player_away')
ok6 = (len(states) == 2 and all(s[1] == '1:playing 2:playing' for s in states) and not away
       and 'UI: quitting at step' in log('gus')
       and all(result(n).startswith('IN SYNC through step 800') for n in ('dee', 'eli', 'fay')))
print(f"6. Team mate leaves:        dee sees {states}; player_away commands {away}; "
      f"{result('dee')} / {result('eli')} / {result('fay')}")
fail |= not ok6

# 9. Another hospital's patient: its fax is not for this player
def click(n):
    m = re.search(r"UI: clicked hospital (\d+)'s patient with a fax at step \d+ \(mine: (\w+)\): fax shown (\w+), patient window (\w+)", log(n))
    return m.groups() if m else None
faxcmd = applied('kim', 'probe_patientfax')
ok9 = (click('lou') == ('1', 'false', 'false', 'true') and click('kim') == ('1', 'true', 'true', 'false')
       and any(x.endswith('-> ok') for x in faxcmd)
       and result('kim').startswith('IN SYNC') and result('lou').startswith('IN SYNC'))
print(f"9. Other hospital's fax:    lou {click('lou')}; kim {click('kim')}; {faxcmd}; {result('kim')} / {result('lou')}")
fail |= not ok9

if with_referee:
    # 8. A bot shares a team hospital with a person
    ivy_teams = teams('ivy')
    cmds = applied('hal', '(place_object|hire|build_room)')
    bot_ok = {k for k in ('place_object', 'hire', 'build_room')
              if any('peer 2 ' in x and k in x and x.endswith('-> ok') for x in cmds)}
    ivy_room = any('peer 3 ' in x and 'build_room' in x and x.endswith('-> ok') for x in cmds)
    report = re.findall(r'UI: hospitals at step \d+ .*?: (.*)', log('hal'))
    h1 = re.search(r'\[1 HAL opened=\w+ balance=-?\d+ reputation=\d+ rooms=(\S*) ', report[-1]) if report else None
    h2 = re.search(r'\[2 BOT AGNES \+ IVY opened=\w+ balance=-?\d+ reputation=\d+ rooms=(\S*) staff=(\S*) ', report[-1]) if report else None
    ok8 = (ivy_teams is not None and ivy_teams[0] == '2' and ivy_teams[1] == '1=HAL:1 2=BOT AGNES + IVY:2'
           and bot_ok == {'place_object', 'hire', 'build_room'} and ivy_room
           and h1 is not None and h1.group(1) == '' and h2 is not None and 'gp' in h2.group(1)
           and 'Receptionist' in h2.group(2)
           and result('hal').startswith('IN SYNC') and result('ivy').startswith('IN SYNC'))
    print(f"8. Bot shares a hospital:   ivy {ivy_teams[:2] if ivy_teams else '-'}; bot's commands ok: {sorted(bot_ok)}; "
          f"ivy's room: {ivy_room}; hospital 2 rooms {h2.groups() if h2 else '-'}, hospital 1 rooms "
          f"[{h1.group(1) if h1 else '-'}]; {result('hal')} / {result('ivy')}")
    fail |= not ok8
    for room, least in (('trio', 1100), ('duo', 800), ('mixed', 1200), ('clinic', 800)):
        confirmed = re.search(rf"room '{room}': referee confirmed steps through (\d+)", server)
        clean = not re.search(rf"room '{room}': (the players differ|repaired)", server)
        ok7 = bool(confirmed and int(confirmed.group(1)) >= least - 100 and clean)
        print(f"7. Referee in '{room}':       confirmed through {confirmed.group(1) if confirmed else '-'}, "
              f"no differences: {clean}")
        fail |= not ok7
sys.exit(1 if fail else 0)
PY
