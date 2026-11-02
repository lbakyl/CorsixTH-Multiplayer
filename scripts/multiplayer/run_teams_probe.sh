#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_teams_probe.sh BINARY GAME_DATA
#
# A race of two teams (mode "teams": a hospital each, team mates trade and
# help each other, dirty tricks only on the other team), through a local
# relay server, on level 2. Room "trio": ann (host) and ben on team 1, cat on
# team 2 (two against one; each picks a team with their team button). Room
# "duo": dee and gus against eli and fay (800 steps: long enough for the
# referee, which joins a moment after the start, to catch up). Checks:
#   1. seating: team mates get neighbouring hospitals (map 31: ann 1, ben 3,
#      cat 2; map 41: dee 1, gus 3, eli 2, fay 4), the same on every peer;
#      the trade windows offer only team mates, the dirty tricks window
#      only the other team
#   2. trades: ann's money reaches ben (trade window); give_money to the
#      other team is refused (ann to cat, cat to ann)
#   3. tricks: ann's rat attack on ben (her team mate) is refused at once,
#      on cat it is played; cat's smear campaign on ann is played
#   4. the mouse shows a team mate's people, never the other team's
#   5. the team race: ann reaches the goals and plays on (no place yet, her
#      team mate has not); once ben does too, team 1 takes 1st place, cat 2nd,
#      and the race is over; ann, ben and cat stay IN SYNC to the end
#   6. team chat: dee's Tab once is "To team", read by gus only, and the next
#      line (no Tab) goes to the team again; cat, alone on her team, has no
#      "To team" (Tab once is ann)
#   8. three teams (room "three", 800 steps): pam and quin share a hospital
#      (team 1; the host gives each team one colour), rae (team 2) and sol
#      (team 3) have one each. Rae reaches the goals first: 1st place, the
#      others race on; then team 1: 2nd, sol last, and the race is over (the
#      standings fax builds); all four IN SYNC to the end
# With MP_REFEREE=1 the server also runs its headless referee, and a 7th
# check needs it to agree with the players to the end (every room).
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-teams.XXXXXXXX")
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
  export MP_REFEREE_PROBE_SCENARIO="trio=light;duo=light;three=none" # the probes' own start on every hospital
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
run_probe ann MP_ROLE=host MP_ROOM=trio MP_MODE=teams MP_TEAM=1 MP_PLAYERS=3 MP_LEVEL=2 MP_STEPS=1100 \
  MP_UI_SCRIPT="20:openhospital;60:teams;100:givemoney:1000;120:giveto:2:1000;200:sabotage:rats:1:3;210:sabotage:rats:1:2;400:teamview;600:goals:1:win;610:wincheck;650:race;900:goals:3:win;910:wincheck;950:race" & pids+=($!)
sleep 1
run_probe ben MP_ROLE=join MP_ROOM=trio MP_TEAM=1 MP_STEPS=1100 \
  MP_UI_SCRIPT="30:openhospital;60:teams;400:teamview;650:race;950:race" & pids+=($!)
sleep 1
run_probe cat MP_ROLE=join MP_ROOM=trio MP_TEAM=2 MP_STEPS=1100 \
  MP_UI_SCRIPT="40:openhospital;60:teams;130:giveto:1:500;150:chat:1:just me;250:sabotage:smear:1:1;400:teamview;650:race;950:race" & pids+=($!)
sleep 1
run_probe dee MP_ROLE=host MP_ROOM=duo MP_MODE=teams MP_TEAM=1 MP_PLAYERS=4 MP_LEVEL=2 MP_STEPS=800 \
  MP_UI_SCRIPT="20:openhospital;60:teams;150:chat:1:hello team;200:chat:0:still team" & pids+=($!)
sleep 1
run_probe eli MP_ROLE=join MP_ROOM=duo MP_TEAM=2 MP_STEPS=800 MP_UI_SCRIPT="30:openhospital;60:teams" & pids+=($!)
sleep 1
run_probe fay MP_ROLE=join MP_ROOM=duo MP_TEAM=2 MP_STEPS=800 MP_UI_SCRIPT="30:openhospital;60:teams" & pids+=($!)
sleep 1
run_probe gus MP_ROLE=join MP_ROOM=duo MP_TEAM=1 MP_STEPS=800 MP_UI_SCRIPT="30:openhospital;60:teams" & pids+=($!)
three="60:teams;300:goals:2:win;310:wincheck;350:race;600:goals:1:win;610:wincheck;650:race"
run_probe pam MP_ROLE=host MP_ROOM=three MP_MODE=teamshared MP_TEAM=1 MP_PLAYERS=4 MP_LEVEL=2 MP_STEPS=800 \
  MP_SCENARIO=none MP_UI_SCRIPT="$three" & pids+=($!)
sleep 1
for who in quin:1 rae:2 sol:3; do
  run_probe "${who%%:*}" MP_ROLE=join MP_ROOM=three MP_TEAM="${who##*:}" MP_STEPS=800 MP_SCENARIO=none \
    MP_UI_SCRIPT="$three" & pids+=($!)
  sleep 1
done
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
want = {'ann': ('1', '3', '2'), 'ben': ('3', '1', '2'), 'cat': ('2', '', '1,3'),
        'dee': ('1', '3', '2,4'), 'gus': ('3', '1', '2,4'), 'eli': ('2', '4', '1,3'), 'fay': ('4', '2', '1,3')}
layouts = {}
ok1 = True
for n, (me, trade, tricks) in want.items():
    t = teams(n)
    layouts.setdefault(n in ('ann', 'ben', 'cat') and 'trio' or 'duo', set()).add(t[1] if t else None)
    good = bool(t) and (t[0], t[2], t[3]) == (me, trade, tricks)
    ok1 &= good
    print(f"   {n}: {'me %s; %s; trade with [%s]; tricks on [%s]' % t if t else 'no teams line'}{'' if good else '  <-- expected me %s, trade [%s], tricks [%s]' % (me, trade, tricks)}")
same = all(len(v) == 1 for v in layouts.values())
ok1 &= same and layouts.get('trio') == {'1=ANN:1 2=CAT:2 3=BEN:1'} and layouts.get('duo') == {'1=DEE:1 2=ELI:2 3=GUS:1 4=FAY:2'}
print(f"1. Seating:                 team mates side by side, same on every peer: {ok1}")
fail |= not ok1

# 2. Trades
money = applied('ann', 'give_money')
ok2 = (any('peer 1' in x and x.endswith('-> ok') for x in money)
       and any('peer 1' in x and 'rejected: not on your team' in x for x in money)
       and any('peer 3' in x and 'rejected: not on your team' in x for x in money)
       and 'sent $1000 to BEN' in log('ann'))
print(f"2. Trades:                  {money}")
fail |= not ok2

# 3. Tricks
tricks = applied('ann', 'sabotage')
on_mate = 'dirty trick rats level 1 against hospital 3' in log('ann') and 'they are on your team' in log('ann')
ok3 = (on_mate
       and len([x for x in tricks if 'peer 1' in x and x.endswith('-> ok')]) == 1
       and len([x for x in tricks if 'peer 3' in x and x.endswith('-> ok')]) == 1)
print(f"3. Tricks:                  on the team mate refused at once: {on_mate}; {tricks}")
fail |= not ok3

# 4. What the mouse shows
views = {n: re.search(r'teamview at step \d+: team mates\' people shown (\d+) of (\d+); other team\'s shown (\d+) of (\d+)', log(n))
         for n in ('ann', 'ben', 'cat')}
def view_ok(v, mates):
    if not v: return False
    shown, total, other_shown, other = map(int, v.groups())
    return other > 0 and other_shown == 0 and (shown == total and (total > 0) == mates)
ok4 = view_ok(views['ann'], True) and view_ok(views['ben'], True) and view_ok(views['cat'], False)
print(f"4. Mouse:                   " + "; ".join(f"{n} {v.groups() if v else '-'}" for n, v in views.items()))
fail |= not ok4

# 5. The team race
races = {n: re.findall(r'UI: race at step (\d+): (.*?); over: (\w+)', log(n)) for n in ('ann', 'ben', 'cat')}
first = races['ann'][0] if races['ann'] else None
last = races['ann'][-1] if len(races['ann']) > 1 else None
ok5 = (first is not None and first[1] == '1=-* 2=- 3=-' and first[2] == 'false'
       and last is not None and last[1] == '1=1(won)* 2=2(last) 3=1(won)*' and last[2] == 'true'
       and all(r and r[-1][1:] == last[1:] for r in races.values())
       and all(result(n).startswith('IN SYNC') for n in ('ann', 'ben', 'cat', 'dee', 'eli', 'fay', 'gus')))
print(f"5. Team race:               after ann {first[1:] if first else '-'}; at the end {last[1:] if last else '-'}; "
      f"{result('ann')} / {result('ben')} / {result('cat')}; duo: {result('dee')} / {result('eli')} / {result('fay')} / {result('gus')}")
fail |= not ok5

# 6. Team chat
def chat_to(n, text):
    m = re.search(rf'UI: chat "{text}" to (?:<LocalisedString> Current value:)?(.*?) at step', log(n))
    return m.group(1) if m else None
team_in = [n for n in ('dee', 'eli', 'fay', 'gus') if 'dee (team): hello team' in log(n) and 'dee (team): still team' in log(n)]
leaked = [n for n in ('eli', 'fay') if 'team' in ''.join(re.findall(r'CHAT IN at step \d+: dee.*', log(n)))]
ok6 = (chat_to('dee', 'hello team') == 'To team:' and chat_to('dee', 'still team') == 'To team:'
       and team_in == ['dee', 'gus'] and not leaked and chat_to('cat', 'just me') == 'To ann:'
       and 'cat (private): just me' in log('ann') and 'just me' not in log('ben'))
print(f"6. Team chat:               dee to {chat_to('dee', 'hello team')} then {chat_to('dee', 'still team')}; "
      f"read by {team_in}; seen by the other team: {leaked}; cat to {chat_to('cat', 'just me')}")
fail |= not ok6

# 8. Three teams
three = ('pam', 'quin', 'rae', 'sol')
seats = {n: teams(n) for n in three}
races = {n: re.findall(r'UI: race at step (\d+): (.*?); over: (\w+)', log(n)) for n in three}
errors = [n for n in three if 'could not be done' in log(n)]
ok8 = (all(t and t[1] == '1=PAM + QUIN:1 2=RAE:2 3=SOL:3' for t in seats.values())
       and all([r[1:] for r in rs] == [('1=- 2=1(won)* 3=-', 'false'), ('1=2(won)* 2=1(won)* 3=3(last)', 'true')]
               for rs in races.values())
       and not errors and all(result(n).startswith('IN SYNC') for n in three))
print(f"8. Three teams:             {seats['pam'][1] if seats['pam'] else '-'}; {[r[1:] for r in races['pam']]}; "
      f"errors {errors}; {' / '.join(result(n) for n in three)}")
fail |= not ok8

if with_referee:
    for room, least in (('trio', 1100), ('duo', 800), ('three', 800)):
        confirmed = re.search(rf"room '{room}': referee confirmed steps through (\d+)", server)
        clean = not re.search(rf"room '{room}': (the players differ|repaired)", server)
        ok6 = bool(confirmed and int(confirmed.group(1)) >= least - 100 and clean)
        print(f"7. Referee in '{room}':       confirmed through {confirmed.group(1) if confirmed else '-'}, no differences: {clean}")
        fail |= not ok6
sys.exit(1 if fail else 0)
PY
