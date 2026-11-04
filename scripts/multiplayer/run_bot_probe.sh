#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_bot_probe.sh BINARY GAME_DATA
#
# Computer players (bots) through a local relay server that runs them (and
# the headless referee). Three rooms at once:
#   "team" (co-op): ann hosts and adds two bots by clicking empty places;
#   "race" (competitive): bob hosts and adds one bot;
#   "trio" (co-op): cid hosts and adds one bot, dee joins.
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
#   8. speed changes: bots do not vote. ann, alone with bots, changes the
#      speed at once (no vote); in "trio" cid asks for a new speed and it
#      changes only once dee has agreed in the fax
#   9. research ("lab", co-op on level 2, which has research: frank and one
#      bot): the bot (it discovers something on day 20, a test command)
#      offers it to frank for free and tells him; a research room it builds
#      has a second desk
#  11. the hidden monthly bonus: in "team" hospitals 2 and 3 (bots), never
#      ann's; in "duel" hospital 2 (the bot)
#  12. land auctions with a bot ("auc", co-op on level 2: gus and one bot):
#      gus asks for a plot on the bot's side, the bot bids, gus outbids it
#      and gets it (the bot stops at its limit); a second one gus drops out
#      of and the bot gets
#  13. a bot bids for the hospital it shares while its person is away
#      ("afk", a race of team hospitals on level 2: jon alone; kay and one
#      bot share hospital 2, kay gives no commands): jon asks for a plot
#      on their side, the bot bids for hospital 2 (worth to it: the more
#      its land is full, the more) and gets it
#  10. tricks on a bot ("duel", competitive: eve and one bot): eve sends
#      rats, an evil handyman (level 3), a smear campaign and a broken
#      boiler. The bot shoots the rats and throws the handyman out, each at
#      least 10 game days after the trick (as a busy player), notices the
#      smear campaign and the boiler, and tells eve privately
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
export MP_REFEREE_PROBE_SCENARIO="team=none;race=none;trio=none;duel=none;lab=none;auc=none;afk=none"
export CORSIXTH_MP_MAX_BOTS=8 # (eight bots in all the rooms)
# (MP_BOT_AWAY_SECONDS: kay in "afk" counts as away after a game week; the
# bots' games run faster than real time.)
MP_BOT_PACE=20 MP_BOT_FAST=1 MP_BOT_SEED=7 MP_BOT_TESTS=1 MP_BOT_LEARN=20 MP_BOT_AWAY_SECONDS=3 PYTHONPATH="$source_dir/mp_server" \
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
  MP_UI_SCRIPT="20:openhospital;40:hire:Doctor;60:hire:Doctor;400:chat:0:Hello Agnes, how are you?;700:sendstaff:Doctor;900:givemoney:2000;1000:hospitals;2000:hospitals;2900:speedother;2990:hospitals" & pids+=($!)
run_probe bob MP_ROLE=host MP_ROOM=race MP_MODE=competitive MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;40:hire:Doctor;60:hire:Doctor;500:chat:0:I will crush you;700:sendstaff:Doctor;900:givemoney:2000;1000:hospitals;2000:hospitals;2990:hospitals" & pids+=($!)
run_probe eve MP_ROLE=host MP_ROOM=duel MP_MODE=competitive MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;320:sabotage:handyman:3:2;340:sabotage:smear:1:2;900:sabotage:rats:1:2;1500:sabotage:boiler:1:2;2990:hospitals" & pids+=($!)
run_probe frank MP_ROLE=host MP_ROOM=lab MP_MODE=coop MP_PLAYERS=2 MP_ADD_BOTS=1 MP_LEVEL=2 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital;2990:hospitals" & pids+=($!)
run_probe gus MP_ROLE=host MP_ROOM=auc MP_MODE=coop MP_PLAYERS=2 MP_ADD_BOTS=1 MP_LEVEL=2 MP_SCENARIO=none   MP_STEPS=1100 MP_STALL_LIMIT=120   MP_UI_SCRIPT="20:openhospital;200:auctionbuy;260:auctionbid;700:auctionbuy;760:auctionpass" & pids+=($!)
run_probe cid MP_ROLE=host MP_ROOM=trio MP_MODE=coop MP_PLAYERS=3 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=600 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital;300:speedother" & pids+=($!)
run_probe jon MP_ROLE=host MP_ROOM=afk MP_MODE=teamshared MP_TEAM=1 MP_PLAYERS=3 MP_ADD_BOTS=1 MP_LEVEL=2   MP_SCENARIO=none MP_STEPS=1300 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital;900:auctionbuy" & pids+=($!)
sleep 3
run_probe kay MP_ROLE=join MP_ROOM=afk MP_TEAM=2 MP_SCENARIO=none MP_STEPS=1300 MP_STALL_LIMIT=120   MP_UI_SCRIPT="60:teams" & pids+=($!)
run_probe dee MP_ROLE=join MP_ROOM=trio MP_SCENARIO=none MP_STEPS=600 MP_STALL_LIMIT=120 MP_VOTE=ask \
  MP_UI_SCRIPT="30:openhospital;310:votefax:1" & pids+=($!)
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
    return re.findall(rf'CHAT IN at step (\d+): {re.escape(who)}(?: \((?:private|team)\))?: (.*)', text, re.I)
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
ok5 = len(bots) == 8 and all(greets.values()) and bool(answer) and distinct and grey
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
       and int(confirmed.get('team', 0)) > 2500 and int(confirmed.get('race', 0)) > 2500
       and int(confirmed.get('duel', 0)) > 2500 and int(confirmed.get('lab', 0)) > 2500)
print(f"7. In sync:                 ann {result('ann')}; bob {result('bob')}; referee differs {differ}, repairs {repaired}, confirmed {confirmed}")
fail |= not ok7
c, d = log('cid'), log('dee')
alone_votes = re.findall(r'speed vote \d+ for ([\w ]+): (\w+)', a)
alone_set = [s for s, r in applied(a, 1, 'set_speed') if r == 'ok' and int(s) >= 2900]
answered = d.find('UI: answered the speed vote fax with 1')
agreed = d.find('speed vote 1 for ')
trio_votes = {n: re.findall(r'speed vote \d+ for ([\w ]+): (\w+)', t) for n, t in (('cid', c), ('dee', d))}
ok8 = (not alone_votes and bool(alone_set) and answered >= 0 and agreed > answered
       and all(v and v[0][1] == 'agreed' for v in trio_votes.values())
       and result('cid').startswith('IN SYNC') and result('dee').startswith('IN SYNC'))
print(f"8. Speed and bots:          ann alone with bots: votes {alone_votes}, speed set at step {alone_set[:1]}; "
      f"trio: dee answered the fax before the vote ended: {answered >= 0 and agreed > answered}; votes {trio_votes}; "
      f"cid {result('cid')}; dee {result('dee')}")
fail |= not ok8
# 9. Research: the co-op bot offers what it learnt to frank, for free.
f = log('frank')
lab_bot = next((n.split('/', 1)[1] for n in bots if n.startswith('lab/')), None)
lb = bots.get('lab/' + lab_bot, '') if lab_bot else ''
offers9 = applied(f, 2, 'offer_research')
offer_text = re.findall(r'research offer[^\n]*', f)
research_lines = [t for _, t in chats_from(f, lab_bot) if 'research' in t] if lab_bot else []
lab_rooms = re.findall(r'furnishing research #\d+: buying ([^\n]*)', lb)
desks = all('desk:1' in r for r in lab_rooms)
ok9 = (any(r == 'ok' for _, r in offers9) and bool(research_lines) and desks
       and result('frank').startswith('IN SYNC'))
print(f"9. Research shared:         offers to frank {offers9}; told: {research_lines[:1]}; "
      f"research room furnished with {lab_rooms or 'none built'}; frank {result('frank')}")
fail |= not ok9

# 10. Tricks on a bot: dealt with after a while, and a word to eve.
e = log('eve')
duel_bot = next((n.split('/', 1)[1] for n in bots if n.startswith('duel/')), None)
db = bots.get('duel/' + duel_bot, '') if duel_bot else ''
played = {m.group(1): int(m.group(2)) for m in re.finditer(r'UI: dirty trick (\w+) level \d+ against hospital 2 at step (\d+)', e)}
tricks10 = [(s, r) for s, r in applied(e, 1, 'sabotage')]
shots = [int(s) for s, r in applied(e, 2, 'shoot_rat') if r == 'ok']
fired = [int(s) for s, r in applied(e, 2, 'fire_staff') if r == 'ok']
noticed = re.findall(r'dirty trick noticed: (\w+)', db)
to_eve = [t for _, t in chats_from(e, duel_bot)] if duel_bot else []
DAY = 50  # lockstep steps in a game day
late_rats = bool(shots) and 'rats' in played and min(shots) >= played['rats'] + 10 * DAY
late_handyman = bool(fired) and 'handyman' in played and min(fired) >= played['handyman'] + 10 * DAY
ok10 = (late_rats and late_handyman and 'smear' in noticed and 'boiler' in noticed
        and any('eve' in t and ('rat' in t.lower() or 'pest' in t.lower()) for t in to_eve)
        and any('eve' in t and 'handyman' in t.lower() for t in to_eve)
        and result('eve').startswith('IN SYNC'))
print(f"10. Tricks on a bot:        played {played} {tricks10}; rats shot from step {min(shots) if shots else '-'} "
      f"({len(shots)} shots), handyman out at {fired}; noticed {noticed}; to eve: {to_eve}; eve {result('eve')}")
fail |= not ok10
# 11. The hidden monthly bonus, for hospitals only bots play.
bonus_team = re.findall(r'bot bonus for hospital\(s\) ([\d,]+)', a)
bonus_duel = re.findall(r'bot bonus for hospital\(s\) ([\d,]+)', e)
ok11 = bool(bonus_team) and set(bonus_team) == {'2,3'} and bool(bonus_duel) and set(bonus_duel) == {'2'}
print(f"11. Bot bonus:              team {bonus_team}; duel {bonus_duel}")
fail |= not ok11
# 12. Land auctions with a bot.
g = log('gus')
bot_bids12 = re.findall(r'auction (\d): hospital 2 bids', g)
sold12 = re.findall(r'auction (\d): plot \d+ sold to hospital (\d)', g)
ok12 = (sold12 == [('1', '1'), ('2', '2')] and '1' in bot_bids12 and '2' in bot_bids12
        and 'auction 2: hospital 1 drops out' in g and result('gus').startswith('IN SYNC'))
print(f"12. Auctions with a bot:    bot bid in {sorted(set(bot_bids12))}; sold {sold12}; gus {result('gus')}")
fail |= not ok12
# 13. A bot bids for its shared hospital while its person is away.
j = log('jon')
bids13 = re.findall(r'auction \d+: hospital 2 bids \$(\d+)', j)
sold13 = re.findall(r'auction \d+: plot \d+ sold to hospital (\d)', j)
away13 = [l for k, t in bots.items() if k.startswith('afk/') for l in t.splitlines() if 'the person is away' in l]
ok13 = (bool(bids13) and sold13 == ['2'] and bool(away13)
        and result('jon').startswith('IN SYNC') and result('kay').startswith('IN SYNC'))
print(f"13. Bot bids for away mate: bids {bids13}; sold to {sold13}; bot: {away13[:1]}; {result('jon')} / {result('kay')}")
fail |= not ok13
for name, text in sorted(bots.items()):
    errors = [l for l in text.splitlines() if 'ERROR' in l or 'could not' in l]
    if errors: print(f"   {name} problems: {errors[:5]}")
sys.exit(1 if fail else 0)
PY
