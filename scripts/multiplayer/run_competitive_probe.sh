#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_competitive_probe.sh BINARY GAME_DATA
#
# Competitive multiplayer (a hospital each, a race to the level's goals, with
# dirty tricks), through a local relay server, three scripted players in one
# room "race" on level 2 (kim hosts, lou and max join). Checks:
#   1. dirty tricks are commands: kim sends an evil handyman (level 3) to lou
#      and an emergency (level 3) to max, max an epidemic (level 1) to kim;
#      a second emergency for max is refused at once (one is on)
#   2. the evil handyman walks over, drops litter and wears lou's cardiogram
#      machine down; lou throws him out with the sack button and he walks
#      back to kim and works there as an ordinary handyman
#   3. a rat attack (level 2, lou against max): ten rats in max's hospital,
#      max's reputation falls while they live; max shoots one
#   4. the race: lou's hospital reaches the goals (test command) and takes
#      1st place, lou answers "Back to the lobby" and leaves alone; max fails
#      the goals at two year ends and is out (3rd); kim, the last one racing,
#      takes 2nd and the race is over; kim and max stay IN SYNC to the end;
#      max's Progress Report shows his own hospital and, on a click, lou's;
#      the mouse finds nothing of the rivals' hospitals (people, doors), only
#      the player's own and the evil handyman in it; nobody sees a rival's
#      room outline, nor the blue floor of a room lou furnishes by hand
#   6. the newer tricks, in room "tricks" (nia against oz): a headhunter
#      (level 1) after oz's nurse, who leaves for the hiring list when oz does
#      not pay; oz cannot hire them back while they are kept for nia, nia can;
#      a broken boiler (level 1), repaired; a smear campaign (level 1) that
#      runs out at the month's end; espionage (level 3) copies two of oz's
#      results. In room "tricks2" (pia against quin) quin pays the
#      headhunter's rise and keeps the nurse; espionage level 1 is refused
#      at once (nothing improved to copy).
# With MP_REFEREE=1 the server also runs its headless referee, and a 5th
# check needs it to agree with the players to the end (in all three rooms).
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-race.XXXXXXXX")
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
  export MP_REFEREE_PROBE_SCENARIO="race=light;tricks=light;tricks2=light" # the probes' own start on every hospital
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
run_probe kim MP_ROLE=host MP_ROOM=race MP_MODE=competitive MP_PLAYERS=3 MP_LEVEL=2 MP_STEPS=1400 \
  MP_UI_SCRIPT="20:openhospital;100:sabotage:handyman:3:2;150:sabotage:emergency:3:3;160:sabotage:emergency:1:3;1100:goals:2:win;1110:wincheck;1200:goals:3:lose;1210:yearend;1260:yearend;1300:race;1310:players" & pids+=($!)
sleep 1
run_probe lou MP_ROLE=join MP_ROOM=race MP_STEPS=1400 MP_FURNISH_PACE=40 \
  MP_UI_SCRIPT="30:openhospital;60:discover:cardiogram;80:room:cardiogram:4:4;250:sabotage:rats:2:3;560:furnishroom:gp:4:4;600:rivals;950:kickevil;1150:answerfax:information:1:wait" & pids+=($!)
sleep 1
run_probe max MP_ROLE=join MP_ROOM=race MP_STEPS=1400 \
  MP_UI_SCRIPT="40:openhospital;200:sabotage:epidemic:1:1;240:race;600:race;610:rivals;650:shootrat;700:progress;710:progress:2;1300:race" & pids+=($!)
sleep 1
run_probe nia MP_ROLE=host MP_ROOM=tricks MP_MODE=competitive MP_PLAYERS=2 MP_LEVEL=2 MP_STEPS=1700 \
  MP_UI_SCRIPT="20:openhospital;300:sabotage:headhunter:1:2;320:sabotage:boiler:1:2;340:sabotage:smear:1:2;360:sabotage:espionage:3:2;1100:hire:Nurse" & pids+=($!)
sleep 1
run_probe oz MP_ROLE=join MP_ROOM=tricks MP_STEPS=1700 \
  MP_UI_SCRIPT="30:openhospital;60:hire:Nurse;80:buy:radiator;100:learn;150:learn;1000:hire:Nurse" & pids+=($!)
sleep 1
run_probe pia MP_ROLE=host MP_ROOM=tricks2 MP_MODE=competitive MP_PLAYERS=2 MP_LEVEL=2 MP_STEPS=700 \
  MP_UI_SCRIPT="20:openhospital;240:sabotage:headhunter:1:2;260:sabotage:espionage:1:2" & pids+=($!)
sleep 1
run_probe quin MP_ROLE=join MP_ROOM=tricks2 MP_STEPS=700 \
  MP_UI_SCRIPT="30:openhospital;60:hire:Nurse;100:learn;400:answerraise:accept;650:stafflog:Nurse" & pids+=($!)
for pid in "${pids[@]}"; do wait "$pid" || true; done

python3 - "$out" "${MP_REFEREE:-0}" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
with_referee = sys.argv[2] == '1'
server = (out / 'server.log').read_text()
def log(n): return (out / n / 'log.txt').read_text()
def result(n):
    m = re.search(r'RESULT: (.*)', log(n)); return m.group(1) if m else 'no result'
def applied(n):
    return [l for l in log(n).splitlines() if re.search(r'multiplayer: step \d+: peer', l)]
def ended(text):
    m = re.search(r'LEVEL ENDED at step (\d+)', text); return int(m.group(1)) if m else None
fail = False
k, l, m = log('kim'), log('lou'), log('max')

tricks = [x for x in applied('kim') if ' sabotage -> ' in x]
ok_tricks = [x for x in tricks if x.endswith('-> ok')]
refused = 'dirty trick emergency level 1 against hospital 3' in k and 'they have an emergency on' in k
ok1 = len(ok_tricks) == 4 and refused
print(f"1. Dirty tricks:            {len(ok_tricks)}/4 accepted; second emergency refused at once: {refused}")
for x in tricks: print("   " + x.split('multiplayer: ', 1)[1])
fail |= not ok1

arrived = re.search(r'sabotage \(step \d+\): handyman #(\d+) arrived at hospital 2', k)
litter = len(re.findall(r'sabotage \(step \d+\): handyman #\d+ dropped litter', k))
worn = re.findall(r'sabotage \(step \d+\): machine #\d+ worn down to \d+ uses', k)
thrown = 'thrown out of hospital 2' in k and re.search(r'step \d+: peer 2 #\d+ fire_staff -> ok', k)
back = arrived and re.search(r'transferred staff #%s arrived at hospital 1' % arrived.group(1), k)
race1300 = re.search(r'UI: race at step 1300: .*my staff: (.*)', k)
ok2 = bool(arrived and litter > 0 and worn and thrown and back and race1300 and 'Handyman' in race1300.group(1))
print(f"2. Evil handyman:           arrived: {bool(arrived)}; litter dropped: {litter}; machines worn down: {len(worn)}; "
      f"thrown out: {bool(thrown)}; works for kim now: {bool(back)} (kim's staff at 1300: {race1300.group(1) if race1300 else '-'})")
fail |= not ok2

rats = re.search(r'sabotage \(step \d+\): (\d+) rats let loose in hospital 3', k)
rep_before = re.search(r'UI: race at step 240: .*reputation (\d+)', m)
rep_after = re.search(r'UI: race at step 600: .*reputation (\d+)', m)
shot = re.search(r'step \d+: peer 3 #\d+ shoot_rat -> ok', k)
ok_r = bool(rats and int(rats.group(1)) == 10 and rep_before and rep_after
            # ten rats: 2 points a day (sabotage.ratPoints) for about a week; a
            # point per rat was 70 and more
            and 5 < int(rep_before.group(1)) - int(rep_after.group(1)) < 30 and shot)
print(f"3. Rat attack:              rats: {rats.group(1) if rats else 0}; max's reputation {rep_before.group(1) if rep_before else '-'} -> "
      f"{rep_after.group(1) if rep_after else '-'}; a rat shot: {bool(shot)}")
fail |= not ok_r

race_k = re.search(r'UI: race at step 1300: (.*)', k)
race_m = re.search(r'UI: race at step 1300: (.*)', m)
standings = '1=2(last) 2=1(won) 3=3(out); over: true'
lou_left = ended(l) is not None and re.search(r'step \d+: peer 2 #\d+ fax_choice -> ok', k)
ok3 = (race_k and race_k.group(1).startswith(standings) and race_m and race_m.group(1).startswith(standings)
       and lou_left and ended(k) is None and ended(m) is None
       and result('kim').startswith('IN SYNC') and result('max').startswith('IN SYNC'))
print(f"4. The race:                lou left at step {ended(l)}; standings kim: {race_k.group(1) if race_k else '-'}; "
      f"max: {race_m.group(1) if race_m else '-'}; {result('kim')} / {result('max')}")
players = re.search(r'UI: players at step \d+: (.*)', k)
print(f"   players window: {players.group(1) if players else '-'}")
own_report = re.search(r'UI: progress report at step 700: own (\d+), names enabled (\d+), showing (\d+)', m)
lou_report = re.search(r'UI: progress report at step 710: own \d+, names enabled \d+, showing (\d+) .*', m)
ok_p = bool(own_report and own_report.groups() == ('3', '3', '3') and lou_report and lou_report.group(1) == '2')
print(f"   progress report (max): {own_report.group(0)[4:] if own_report else '-'}; "
      f"{lou_report.group(0)[4:] if lou_report else '-'}")
ok3 = ok3 and ok_p
riv_l = re.search(r'UI: rivals at step 600: own hidden (\d+) of (\d+); rivals shown (\d+) of (\d+); rival doors shown (\d+) of (\d+); evil handyman shown ([^;\s]+)', l)
riv_m = re.search(r'UI: rivals at step 610: own hidden (\d+) of (\d+); rivals shown (\d+) of (\d+); rival doors shown (\d+) of (\d+); evil handyman shown ([^;\s]+); rival rooms being furnished (\d+), blue tiles (\d+)', m)
ok_v = bool(riv_l and riv_m and riv_l.group(1) == '0' and riv_l.group(3) == '0' and int(riv_l.group(4)) > 0
            and riv_l.group(5) == '0' and riv_l.group(7) == 'true'
            and riv_m.group(1) == '0' and riv_m.group(3) == '0' and int(riv_m.group(4)) > 0
            and riv_m.group(5) == '0' and int(riv_m.group(6)) > 0
            and int(riv_m.group(8)) > 0 and riv_m.group(9) == '0')
# kim draws a cardiogram: the rivals do not see its outline.
outlines = sum(text.count("showing reserved area of player") for text in (k, l, m))
print(f"   rivals hidden: lou {riv_l.group(0)[4:] if riv_l else '-'}; max {riv_m.group(0)[4:] if riv_m else '-'}; "
      f"rivals' room outlines shown: {outlines}")
ok3 = ok3 and ok_v and outlines == 0
fail |= not ok3

o, q = log('oz'), log('quin')
poached = 'headhunter after Nurse' in o and re.search(r'Nurse #\d+ left hospital 2 for the hiring list', o)
kept_for_nia = 'hire -> rejected: promised to another hospital' in o and re.search(r'step 110\d: peer 1 #\d+ hire -> ok', o)
boiler = 'boiler of hospital 2 broken' in o and 'working properly again' in o
smear = re.search(r'smear campaign against hospital 2 over: (\d+) patients', o)
spied = re.search(r'hospital 1 spied on hospital 2: ([^\n]+)', o)
# What nia picked in the spy window is what she got.
picked = re.search(r'dirty trick espionage level 3 against hospital 2 at step \d+: .*\(picked ([^)]+)\)', log('nia'))
spied = spied if spied and picked and picked.group(1) == spied.group(1) else None
paid = 'accepted the pay rise' in q and 'left hospital 2' not in q and re.search(r'staff Nurse #\d+ at step 650', q)
# (Level 2 has no drug or machine improvements to copy: refused at once.)
spied1 = 'dirty trick espionage level 1 against hospital 2 at step 260: they know nothing that you do not' in log('pia')
ok6 = bool(poached and kept_for_nia and boiler and smear and spied and spied.group(1).count(',') == 1 and paid and spied1
           and all(result(n).startswith('IN SYNC') for n in ('nia', 'oz', 'pia', 'quin')))
print(f"6. Newer tricks:            poached: {bool(poached)}; kept for the buyer: {bool(kept_for_nia)}; boiler broken and repaired: {boiler}; "
      f"smear over: {smear.group(1) + ' sent elsewhere' if smear else '-'}; espionage L3: {spied.group(1) if spied else '-'}; "
      f"rise paid, nurse kept: {bool(paid)}; espionage L1 with nothing to copy refused: {spied1}; "
      f"{result('nia')} / {result('oz')} / {result('pia')} / {result('quin')}")
fail |= not ok6

if with_referee:
    for room, least in (('tricks', 1700), ('tricks2', 700)):
        confirmed = re.search(rf"room '{room}': referee confirmed steps through (\d+)", server)
        clean = not re.search(rf"room '{room}': (the players differ|repaired)", server)
        ok_r6 = bool(confirmed and int(confirmed.group(1)) >= least and clean)
        print(f"   referee in '{room}': confirmed through {confirmed.group(1) if confirmed else '-'}, no differences: {clean}")
        fail |= not ok_r6
    connected = "room 'race': referee connected" in server
    differ = re.findall(r"room 'race': the players differ from the referee", server)
    repaired = re.findall(r"room 'race': repaired", server)
    confirmed = re.search(r"room 'race': referee confirmed steps through (\d+)", server)
    ok4 = connected and not differ and not repaired and confirmed and int(confirmed.group(1)) >= 1300
    print(f"5. Headless referee:        connected: {connected}; differs: {len(differ)}; repairs: {len(repaired)}; "
          f"confirmed through {confirmed.group(1) if confirmed else '-'}")
    fail |= not ok4
sys.exit(1 if fail else 0)
PY
