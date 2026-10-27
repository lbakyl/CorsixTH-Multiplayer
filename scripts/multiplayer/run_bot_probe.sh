#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_bot_probe.sh BINARY GAME_DATA
#
# Computer players (bots) through a local relay server that runs them (and
# the headless referee). Two rooms at once:
#   "team" (co-op): ann hosts and adds two bots by clicking empty places;
#   "race" (competitive): bob hosts and adds one bot.
# The bots run faster than a person would (MP_BOT_PACE=20: twenty times as
# many building steps per game day, the greeting and first dirty trick
# twenty times sooner; MP_BOT_FAST=1: answers at once). Checks:
#   1. the lobby: the host's empty places offer a bot, the bots join ready
#      and the room starts with them
#   2. the bots build: each bot hospital gets a desk, rooms (a GP's office
#      first), staff, and opens
#   3. co-op: ann offers Bot Agnes a doctor and sends money; the bot accepts
#      the doctor and thanks her for both in the chat
#   4. competitive: bob offers the bot a doctor and sends money; the bot
#      declines the doctor and sends the money back, with a word each
#   5. the chat: every bot greets the room; Bot Agnes answers ann's question; bots' lines are grey
#   6. competitive: the bot plays a dirty trick on bob
#   7. both rooms IN SYNC to the end, and the referee agrees (no repairs)
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-bots.XXXXXXXX")
echo "Probe output: $out"

export CORSIXTH_SOURCE="$source_dir"
export USER="${USER:-corsixth-probe}"
export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"

port=$((47000 + RANDOM % 900))
# The server starts bots (and the referee) from this build.
export CORSIXTH_MP_REFEREE_BINARY="$binary" CORSIXTH_MP_REFEREE_SOURCE="$source_dir"
export CORSIXTH_MP_REFEREE_DATA="$game_data" CORSIXTH_MP_REFEREE_WORKDIR="$out/headless"
export CORSIXTH_MP_REFEREE_LUA_CPATH="$MP_LUA_CPATH" CORSIXTH_MP_REFEREE_LUA_PATH="$MP_LUA_PATH"
export MP_REFEREE_PROBE_SCENARIO="team=none;race=none"
MP_BOT_PACE=20 MP_BOT_FAST=1 MP_BOT_SEED=7 PYTHONPATH="$source_dir/mp_server" \
  python3 -m corsixth_mp --host 127.0.0.1 --port "$port" \
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
  env XDG_CONFIG_HOME="$dir/config" MP_NAME="$name" "$@" timeout 900 "$binary" \
    "--interpreter=$source_dir/scripts/multiplayer/lobby_probe.lua" \
    "--config-file=$dir/config.txt" > "$dir/log.txt" 2>&1 || true
  grep -q 'PROBE: DONE' "$dir/log.txt" || { echo "$name failed:"; tail -20 "$dir/log.txt"; return 1; }
}

pids=()
run_probe ann MP_ROLE=host MP_ROOM=team MP_MODE=coop MP_PLAYERS=3 MP_ADD_BOTS=2 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;40:hire:Doctor;60:hire:Doctor;400:chat:0:Hello Agnes, how are you?;700:sendstaff:Doctor;900:givemoney:2000;1000:hospitals;2000:hospitals;2990:hospitals" & pids+=($!)
run_probe bob MP_ROLE=host MP_ROOM=race MP_MODE=competitive MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;40:hire:Doctor;60:hire:Doctor;500:chat:0:I will crush you;700:sendstaff:Doctor;900:givemoney:2000;1000:hospitals;2000:hospitals;2990:hospitals" & pids+=($!)
for pid in "${pids[@]}"; do wait "$pid" || true; done
sleep 2

python3 - "$out" <<'PY'
import pathlib, re, sys
out = pathlib.Path(sys.argv[1])
server = (out / 'server.log').read_text()
def log(n): return (out / n / 'log.txt').read_text()
def result(n):
    m = re.search(r'RESULT: (.*)', log(n)); return m.group(1) if m else 'no result'
def applied(text, peer, kind):
    return re.findall(rf'step (\d+): peer {peer} #\d+ {kind} -> (\S+)', text)
bots = {}  # "room/name" -> its log
for p in (out / 'headless').glob('*-bot-*/bot.log'):
    text = p.read_text()
    m = re.search(r'^\[([^\]]+)\]', text, re.M)
    if m: bots[p.parent.name.split('-bot-')[0] + '/' + m.group(1)] = text
fail = False
a, b = log('ann'), log('bob')

places = re.search(r'UI: room places before bot 1: (.*)', a)
joined = re.search(r'UI: room places with the bots: (.*)', a)
ok1 = bool(places and 'add a bot' in places.group(1) and joined and joined.group(1).count('(bot)') == 2
           and 'Bot Agnes' in joined.group(1) and re.search(r"room 'race' starts", server)
           and re.search(r"room 'team' starts", server))
print(f"1. Lobby:                   places offered: {places.group(1) if places else '-'}")
print(f"                            with the bots: {joined.group(1) if joined else '-'}; bot logs: {sorted(bots)}")
fail |= not ok1

def last_hospitals(text):
    found = re.findall(r'UI: hospitals at step (\d+) \(([^)]*)\): (.*)', text)
    return found[-1] if found else None
ok2 = True
for host, text, idx in (('ann', a, [2, 3]), ('bob', b, [2])):
    last = last_hospitals(text)
    print(f"2. Bots build ({host}):       at step {last[0] if last else '-'} ({last[1] if last else '-'})")
    if not last:
        ok2 = False
        continue
    hosps = dict(re.findall(r'\[(\d+) (.*?)\]', last[2]))
    for i in idx:
        h = hosps.get(str(i), '')
        rooms = re.search(r'rooms=(\S*)', h)
        rooms = rooms.group(1).split(',') if rooms and rooms.group(1) else []
        good = ('opened=true' in h and 'gp' in rooms and len(rooms) >= 3 and 'Receptionist=1' in h
                and 'Doctor=' in h)
        ok2 &= good
        print(f"     hospital {i}: {h}")
fail |= not ok2

def chats_from(text, who):
    return re.findall(rf'CHAT IN at step (\d+): {re.escape(who)}(?: \(private\))?: (.*)', text, re.I)
# ann's offers go to hospital 2: whichever bot joined first.
last = last_hospitals(a)
first_bot = re.search(r'\[2 (.*?) opened', last[2]).group(1) if last else 'Bot Agnes'
agnes = chats_from(a, first_bot)
accepted = re.search(r'offer of staff #\d+ to hospital 2 accepted: on the way', a)
agnes_answer = [s for s, cmd in applied(a, 2, 'fax_choice') if cmd == 'ok']
thanked = [t for _, t in agnes if 'ann' in t]
ok3 = bool(accepted and agnes_answer and len(thanked) >= 2)
print(f"3. Co-op offers:            {first_bot.title()}: doctor accepted: {bool(accepted)} (fax answer at {agnes_answer}); lines to ann: {thanked}")
fail |= not ok3

race_bot = next((n.split('/', 1)[1] for n in bots if n.startswith('race/')), None)
rb = chats_from(b, race_bot) if race_bot else []
declined = [s for s, cmd in applied(b, 2, 'fax_choice') if cmd == 'ok']
returned = applied(b, 2, 'give_money')
staff_kept = 'accepted' not in ''.join(re.findall(r'offer of staff .*', b))
to_bob = [t for _, t in rb if 'bob' in t]
ok4 = bool(race_bot and declined and staff_kept and returned and returned[0][1] == 'ok' and len(to_bob) >= 2)
print(f"4. Competitive refusals:    {race_bot}: declined at {declined}; doctor stayed: {staff_kept}; money sent back: {returned}; lines to bob: {to_bob}")
fail |= not ok4

greets = {}
for name, text in bots.items():
    greets[name] = re.findall(r'CHAT: (.*)', text)[:1]
# (ann's question names Agnes: she answers whichever hospital she has.)
answer = [t for s, t in chats_from(a, 'Bot Agnes') if int(s) >= 400 and 'ann' in t]
distinct = len(set(g[0] for g in greets.values() if g)) > 1
# The bots' lines in ann's chat are grey.
colours = set(re.findall(r'CHAT COLOUR: (Bot [^ ]+) (\S+)', a + b))
grey = bool(colours) and all(c == '75,75,75' for _, c in colours)
ok5 = len(bots) == 3 and all(greets.values()) and bool(answer) and distinct and grey
print(f"5. Chat:                    first lines: {greets}; Bot Agnes's answer to ann: {answer[:1]}; bots grey: {grey} {sorted(colours)}")
fail |= not ok5

tricks = applied(b, 2, 'sabotage')
ok6 = any(r == 'ok' for _, r in tricks)
print(f"6. Dirty trick:             {tricks}")
fail |= not ok6

differ = re.findall(r"room '(\w+)': the players differ from the referee", server)
repaired = re.findall(r"room '(\w+)': repaired", server)
confirmed = dict(re.findall(r"room '(\w+)': referee confirmed steps through (\d+)", server))
ok7 = (result('ann').startswith('IN SYNC') and result('bob').startswith('IN SYNC') and not differ and not repaired
       and int(confirmed.get('team', 0)) > 2500 and int(confirmed.get('race', 0)) > 2500)
print(f"7. In sync:                 ann {result('ann')}; bob {result('bob')}; referee differs {differ}, repairs {repaired}, confirmed {confirmed}")
fail |= not ok7
for name, text in sorted(bots.items()):
    errors = [l for l in text.splitlines() if 'ERROR' in l or 'could not' in l]
    if errors: print(f"   {name} problems: {errors[:5]}")
sys.exit(1 if fail else 0)
PY
