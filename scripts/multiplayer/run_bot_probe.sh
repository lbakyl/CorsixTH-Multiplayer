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
#      offers it to frank for free, without a chat line (the fax says it); a research room it builds
#      has two more desks (a normal bot plays as the experts)
#  11. the hidden monthly bonus: none for these normal bots (Jan,
#      2026-11-14: only hard bots get it; run_takeover_probe.sh checks one),
#      in "team" (hospitals 2 and 3 bots) and "duel" (hospital 2)
#  12. land auctions with a bot ("auc", co-op on level 2: gus and one bot):
#      gus asks for a plot on the bot's side, the bot bids (a moment after
#      each bid, not at once: MultiplayerSession.BOT_BID_SECONDS), gus outbids
#      it twice and gets it (the bot stops at its limit); a second one gus
#      drops out
#      of and the bot gets
#  13. a bot bids for the hospital it shares while its person is away
#      ("afk", a race of team hospitals on level 2: jon alone; kay and one
#      bot share hospital 2, kay gives no commands): jon asks for a plot
#      on their side, the bot bids for hospital 2 (worth to it: the more
#      its land is full, the more) and gets it
#  14. "Allied bots build: off" ("hands", one shared hospital on level 2: liv
#      and a bot, the game option helpers=0): the bot builds no room and
#      buys nothing for the corridors (land, staff and the rest it may)
#  15. orders only from allies, money on request: in "team" ann asks a bot for
#      $1000 (sent), $9,000,000 (it sends the most it gives at once and says so)
#      and some cash (half of its spare money); in "race" bob, a rival, asks it
#      for money and a room (refused, no money sent). The bots keep $1,000 and
#      send at most $2,000 at once here (MP_BOT_GIVE_LIMITS=1000:2000) instead of
#      $15,000 and $20,000
#  16. asking for staff: from game day 5 the bots lack a surgeon (MP_BOT_TEST_LACK);
#      after 10 days they ask the allies in the team chat
#  17. the level's requirements (MP_BOT_TEST_WIN: ann's hospital meets them from day
#      10, the others from day 12): the bot of hospital 2 says "good job" to ann, and
#      each bot says what it still needs, then that it is ready too
#  18. a warning that an opponent meets them: in "afk" the bot tells the person it shares with, in
#      "duel" nobody is there to read it
#  19. failing its objectives (MP_BOT_TEST_FAIL): both bots of "team" ask ann for
#      an amount, once
#  20. the floor in one piece: each bot that builds reads its own floor as one
#      part with its entrance, desk and room doors on it (its month line);
#      also shown: spots refused because they would cut the floor in two, and
#      objects sold to mend a floor in parts
#  21. a plot asked of an allied bot ("lab"): frank asks for plot 7 at auction
#      and drops out once the bot has bid (a moment after him), so the bot gets
#      it (the game stands still meanwhile); asked for plot 7 on game day 4 it
#      keeps it for the level's value goal (its requirements count as met only
#      from day 5 there, MP_BOT_TEST_WIN "lab/2:5"); asked for any plot on day 6
#      it offers plot 7 for free (it holds more than the $1,000 it keeps here),
#      frank gets the fax, accepts, and the plot is his
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
export CORSIXTH_MP_KEEP_PLACES=0 # (rooms close once nobody plays, no stand-in bots: run_takeover_probe.sh)
export MP_LUA_CPATH="$LUASOCKET_TREE/lib/lua/$lua_ver/?.so"
export MP_LUA_PATH="$LUASOCKET_TREE/share/lua/$lua_ver/?.lua"
# (The hosts make their bots normal ones, as these checks expect; a new bot
# is a hard one: run_takeover_probe.sh.)
export MP_BOT_LEVELS=all:normal

port=$((47000 + RANDOM % 900))
# The server starts bots (and the referee) from this build.
export CORSIXTH_MP_REFEREE_BINARY="$binary" CORSIXTH_MP_REFEREE_SOURCE="$source_dir"
export CORSIXTH_MP_REFEREE_DATA="$game_data" CORSIXTH_MP_REFEREE_WORKDIR="$out/headless"
export CORSIXTH_MP_REFEREE_LUA_CPATH="$MP_LUA_CPATH" CORSIXTH_MP_REFEREE_LUA_PATH="$MP_LUA_PATH"
export MP_REFEREE_PROBE_SCENARIO="team=none;race=none;trio=none;duel=none;lab=none;auc=none;afk=none;hands=none"
export CORSIXTH_MP_MAX_BOTS=9 # (nine bots in all the rooms)
# (MP_BOT_AWAY_SECONDS: kay in "afk" counts as away after a game week; the
# bots' games run faster than real time.)
MP_BOT_PACE=20 MP_BOT_FAST=1 MP_BOT_SEED=7 MP_BOT_TESTS=1 MP_BOT_LEARN=20 MP_BOT_AWAY_SECONDS=3 MP_BOT_GIVE_LIMITS=1000:2000 MP_BOT_TEST_LACK=5:Surgeon:operating_theatre MP_BOT_TEST_WIN="1:10;2:12;3:12;lab/2:5" MP_BOT_TEST_FAIL=20 PYTHONPATH="$source_dir/mp_server" \
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
  MP_UI_SCRIPT="20:openhospital;40:hire:Doctor;60:hire:Doctor;400:chat:0:Hello Agnes, how are you?;700:sendstaff:Doctor;900:givemoney:2000;1000:hospitals;1100:chat:1:Agnes, please send me \$1000;1300:chat:1:Agnes, could you lend me \$9,000,000?;1500:chat:0:Agnes, please send me some cash;2000:hospitals;2900:speedother;2990:hospitals" & pids+=($!)
run_probe bob MP_ROLE=host MP_ROOM=race MP_MODE=competitive MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;40:hire:Doctor;60:hire:Doctor;500:chat:0:I will crush you;600:chat:1:Please send me \$1000;800:chat:0:Could you build a toilet for me?;700:sendstaff:Doctor;900:givemoney:2000;1000:hospitals;2000:hospitals;2990:hospitals" & pids+=($!)
run_probe eve MP_ROLE=host MP_ROOM=duel MP_MODE=competitive MP_PLAYERS=2 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;320:sabotage:handyman:3:2;340:sabotage:smear:1:2;900:sabotage:rats:1:2;1500:sabotage:boiler:1:2;2990:hospitals" & pids+=($!)
run_probe frank MP_ROLE=host MP_ROOM=lab MP_MODE=coop MP_PLAYERS=2 MP_ADD_BOTS=1 MP_LEVEL=2 MP_SCENARIO=none \
  MP_STEPS=3000 MP_STALL_LIMIT=120 \
  MP_UI_SCRIPT="20:openhospital;100:auctionbuy;170:auctionpass;200:chat:1:Agnes, can I have plot 7?;300:chat:1:Agnes, could you spare me a plot?;360:answerplot:accept;400:plotmap;2990:hospitals" & pids+=($!)
run_probe gus MP_ROLE=host MP_ROOM=auc MP_MODE=coop MP_PLAYERS=2 MP_ADD_BOTS=1 MP_LEVEL=2 MP_SCENARIO=none   MP_STEPS=1300 MP_STALL_LIMIT=120   MP_UI_SCRIPT="20:openhospital;200:auctionbuy;300:auctionbid;400:auctionbid;900:auctionbuy;1000:auctionpass" & pids+=($!)
run_probe cid MP_ROLE=host MP_ROOM=trio MP_MODE=coop MP_PLAYERS=3 MP_ADD_BOTS=1 MP_SCENARIO=none \
  MP_STEPS=600 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital;300:speedother" & pids+=($!)
run_probe jon MP_ROLE=host MP_ROOM=afk MP_MODE=teamshared MP_TEAM=1 MP_PLAYERS=3 MP_ADD_BOTS=1 MP_LEVEL=2   MP_SCENARIO=none MP_STEPS=1300 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital;900:auctionbuy" & pids+=($!)
sleep 3
run_probe kay MP_ROLE=join MP_ROOM=afk MP_TEAM=2 MP_SCENARIO=none MP_STEPS=1300 MP_STALL_LIMIT=120   MP_UI_SCRIPT="60:teams" & pids+=($!)
run_probe liv MP_ROLE=host MP_ROOM=hands MP_MODE=shared MP_PLAYERS=2 MP_ADD_BOTS=1 MP_LEVEL=2 MP_SCENARIO=none   MP_OPTIONS="helpers=0" MP_STEPS=1500 MP_STALL_LIMIT=120 MP_UI_SCRIPT="20:openhospital" & pids+=($!)
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
bad = []
a, b = log('ann'), log('bob')

places = re.search(r'UI: room places before bot 1: (.*)', a)
joined = re.search(r'UI: room places with the bots: (.*)', a)
# (The bots' lines say their level: the hosts make them normal ones.)
ok1 = bool(places and 'add a bot' in places.group(1) and joined
           and len(re.findall(r'Bot \w+ \(normal bot\)', joined.group(1))) == 2
           and 'Bot Agnes' in joined.group(1) and re.search(r"room 'race' starts", server)
           and re.search(r"room 'team' starts", server))
print(f"1. Lobby:                   places offered: {places.group(1) if places else '-'}")
print(f"                            with the bots: {joined.group(1) if joined else '-'}; bot logs: {sorted(bots)}")
fail |= not ok1
if not ok1: bad.append("ok1")
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
if not ok2: bad.append("ok2")
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
if not ok3: bad.append("ok3")
race_bot = next((n.split('/', 1)[1] for n in bots if n.startswith('race/')), None)
rb = chats_from(b, race_bot) if race_bot else []
declined = [s for s, cmd in applied(b, 2, 'fax_choice') if cmd == 'ok']
# (Money never goes to a rival, 2026-11-12: bob's gift is refused by the
# game, so the bot has none to send back.)
returned = applied(b, 2, 'give_money')
bob_gift = applied(b, 1, 'give_money')
staff_kept = 'accepted' not in ''.join(re.findall(r'offer of staff .*', b))
to_bob = [t for _, t in rb if 'bob' in t]
# (A doctor the race bot lacks, a surgeon while MP_BOT_TEST_LACK makes every
# bot short of one, it may buy: Manager:rivalOffer.)
bought4 = re.findall(r'buys a \w+ from bob for \$\d+', bots.get('race/' + race_bot, '') if race_bot else '')
ok4 = bool(race_bot and declined and (staff_kept or bought4) and not returned and bob_gift and
           all(r == 'rejected:' or r.startswith('rejected') for _, r in bob_gift) and len(to_bob) >= 2)
print(f"4. Competitive refusals:    {race_bot}: declined at {declined}; doctor stayed: {staff_kept} (bought: {bought4}); bob's gift {bob_gift}, "
      f"money sent back: {returned}; lines to bob: {to_bob}")
fail |= not ok4
if not ok4: bad.append("ok4")
greets = {}
for name, text in bots.items():
    greets[name] = re.findall(r'CHAT: (.*)', text)[:1]
# (ann's question names Agnes: she answers whichever hospital she has.)
answer = [t for s, t in chats_from(a, 'Bot Agnes') if int(s) >= 400 and 'ann' in t]
distinct = len(set(g[0] for g in greets.values() if g)) > 1
# The bots' lines in ann's chat are grey.
colours = set(re.findall(r'CHAT COLOUR: (Bot [^ ]+) (\S+)', a + b))
grey = bool(colours) and all(c == '75,75,75' for _, c in colours)
ok5 = len(bots) == 9 and all(greets.values()) and bool(answer) and distinct and grey
print(f"5. Chat:                    first lines: {greets}; Bot Agnes's answer to ann: {answer[:1]}; bots grey: {grey} {sorted(colours)}")
fail |= not ok5
if not ok5: bad.append("ok5")
tricks = applied(b, 2, 'sabotage')
ok6 = any(r == 'ok' for _, r in tricks)
print(f"6. Dirty trick:             {tricks}")
fail |= not ok6
if not ok6: bad.append("ok6")
differ = re.findall(r"room '(\w+)': the players differ from the referee", server)
repaired = re.findall(r"room '(\w+)': repaired", server)
confirmed = dict(re.findall(r"room '(\w+)': referee confirmed steps through (\d+)", server))
ok7 = (result('ann').startswith('IN SYNC') and result('bob').startswith('IN SYNC') and not differ and not repaired
       and int(confirmed.get('team', 0)) > 2500 and int(confirmed.get('race', 0)) > 2500
       and int(confirmed.get('duel', 0)) > 2500 and int(confirmed.get('lab', 0)) > 2500)
print(f"7. In sync:                 ann {result('ann')}; bob {result('bob')}; referee differs {differ}, repairs {repaired}, confirmed {confirmed}")
fail |= not ok7
if not ok7: bad.append("ok7")
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
if not ok8: bad.append("ok8")
# 9. Research: the co-op bot offers what it learnt to frank, for free.
f = log('frank')
lab_bot = next((n.split('/', 1)[1] for n in bots if n.startswith('lab/')), None)
lb = bots.get('lab/' + lab_bot, '') if lab_bot else ''
offers9 = applied(f, 2, 'offer_research')
offer_text = re.findall(r'research offer[^\n]*', f)
# (Not its money ask when it fails its goals: "send me $10,000 so I can build
# a new research room".)
research_lines = [t for _, t in chats_from(f, lab_bot) if 'research' in t and '$' not in t] if lab_bot else []
lab_rooms = re.findall(r'furnishing research #\d+: buying ([^\n]*)', lb)
# (A normal bot plays as the experts: two more desks, no plant; Jan, 2026-11-14.)
desks = all('desk:2' in r for r in lab_rooms)
ok9 = (any(r == 'ok' for _, r in offers9) and not research_lines and desks
       and result('frank').startswith('IN SYNC'))
print(f"9. Research shared:         offers to frank {offers9}; research chat lines (none expected, the fax says it): {research_lines[:1]}; "
      f"research room furnished with {lab_rooms or 'none built'}; frank {result('frank')}")
fail |= not ok9
if not ok9: bad.append("ok9")
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
if not ok10: bad.append("ok10")
# 11. The hidden monthly bonus, for hospitals only bots play.
bonus_team = re.findall(r'bot bonus for hospital\(s\) (\S+)', a)
bonus_duel = re.findall(r'bot bonus for hospital\(s\) (\S+)', e)
ok11 = bool(bonus_team) and set(bonus_team) == {'none'} and bool(bonus_duel) and set(bonus_duel) == {'none'}
print(f"11. Bot bonus:              team {bonus_team}; duel {bonus_duel}")
fail |= not ok11
if not ok11: bad.append("ok11")
# 12. Land auctions with a bot.
g = log('gus')
bot_bids12 = re.findall(r'auction (\d): hospital 2 bids', g)
sold12 = re.findall(r'auction (\d): plot \d+ sold to hospital (\d)', g)
ok12 = (sold12 == [('1', '1'), ('2', '2')] and '1' in bot_bids12 and '2' in bot_bids12
        and 'auction 2: hospital 1 drops out' in g and result('gus').startswith('IN SYNC'))
print(f"12. Auctions with a bot:    bot bid in {sorted(set(bot_bids12))}; sold {sold12}; gus {result('gus')}")
fail |= not ok12
if not ok12: bad.append("ok12")
# 13. A bot bids for its shared hospital while its person is away.
j = log('jon')
bids13 = re.findall(r'auction \d+: hospital 2 bids \$(\d+)', j)
sold13 = re.findall(r'auction \d+: plot \d+ sold to hospital (\d)', j)
away13 = [l for k, t in bots.items() if k.startswith('afk/') for l in t.splitlines() if 'the person is away' in l]
ok13 = (bool(bids13) and sold13 == ['2'] and bool(away13)
        and result('jon').startswith('IN SYNC') and result('kay').startswith('IN SYNC'))
print(f"13. Bot bids for away mate: bids {bids13}; sold to {sold13}; bot: {away13[:1]}; {result('jon')} / {result('kay')}")
fail |= not ok13
if not ok13: bad.append("ok13")
# 14. "Allied bots build: off": the bot sharing liv's hospital builds nothing
# and buys nothing for it (no rooms, no corridor objects, no desk).
lv = log('liv')
hands = [t for k, t in bots.items() if k.startswith('hands/')]
bot_cmds14 = re.findall(r'step \d+: peer 2 #\d+ (\w+) -> ok', lv)
built14 = [c for c in bot_cmds14 if c in ('build_room', 'place_object', 'room_buy', 'room_object', 'room_finish', 'room_edit')]
said14 = any('leaves the rooms and corridors to the person' in t for t in hands)
ok14 = ('game option helpers=0' in lv and not built14 and said14 and result('liv').startswith('IN SYNC'))
print(f"14. Allied bots build: off: bot commands {sorted(set(bot_cmds14))}; built {built14[:5]}; said so: {said14}; {result('liv')}")
fail |= not ok14
if not ok14: bad.append("ok14")
# 15. Orders only from allies; money on request. In "team" (co-op) ann asks
# Agnes (a bot, her ally) for $1000 (to the allies), then for $9,000,000 and for some cash (to her; the chat remembers who it was for)
# with no sum: the bot checks its own bank (it keeps $1,000 and sends at most
# $2,000 at once here) and says what it did: the $9,000,000 gets $2,000 and a
# word that this is the most at once. In "race" bob (a rival) asks the bot for
# money and for a room: a refusal, no money sent before the bounce of his gift
# (step 900).
# (Which bot is "Agnes" and which peer it is varies from run to run: any bot of the room.)
gives15 = [(int(st), r) for st, p, r in re.findall(r'step (\d+): peer ([2-9]) #\d+ give_money -> (\S+)', a)]
to_ann15 = [(int(st), t) for who in ('Bot Agnes', 'Bot Bertie') for st, t in chats_from(a, who)
            if int(st) >= 1100 and 'ann' in t]
sent_log15 = [l for k, t in bots.items() if k.startswith('team/') for l in t.splitlines() if 'money for ann' in l]
sent_lines15 = [t for _, t in to_ann15 if re.search(r'\$\d', t)]
declined15 = [l for l in sent_log15 if 'declined' in l]
sent15 = [l for l in sent_log15 if ': sent $' in l]
part15 = [l for l in sent15 if 'less than the $9000000 asked (the most at once' in l]
cap_lines15 = [t for _, t in to_ann15 if re.search(r'most I send|more than \$2,000 at once|limit for one transfer', t)]
rb_lines15 = [t for st, t in rb if int(st) < 800 and 'bob' in t]
early_money15 = [st for st, r in applied(b, 2, 'give_money') if int(st) < 900]
refused15 = [l for l in (bots.get('race/' + race_bot, '') if race_bot else '').splitlines() if 'refused a request from bob' in l]
ok15 = (len(sent15) >= 2 and any(r == 'ok' for _, r in gives15) and len(gives15) == len(sent15)
        and bool(part15) and bool(cap_lines15) and len(sent_lines15) >= 2 and len(refused15) >= 2
        and not early_money15 and len(rb_lines15) >= 2)
print(f"15. Money and orders:       Agnes sent {[l.split(': ',1)[1] for l in sent15]}, declined {[l.split(': ',1)[1] for l in declined15]}; "
      f"the most at once: {cap_lines15[:1]}; "
      f"give_money commands {gives15}; her lines {sent_lines15}; the race bot refused bob {len(refused15)} times "
      f"({rb_lines15[:2]}), money sent to him early: {early_money15}")
fail |= not ok15
if not ok15: bad.append("ok15")
# 16. Asking for staff. From game day 5 every bot "lacks" a surgeon for an
# operating theatre (test hook MP_BOT_TEST_LACK); after 10 days it asks its
# allies in the team's chat, which ann reads.
asks16 = [(int(st), t) for who in ('Bot Agnes', 'Bot Bertie') for st, t in chats_from(a, who) if 'urgeon' in t]
notes16 = [l for k, t in bots.items() if k.startswith('team/') for l in t.splitlines()
           if 'asked the allies for a Surgeon' in l]
ok16 = bool(asks16) and bool(notes16) and min(s for s, _ in asks16) >= (5 - 1) * 50 + 10 * 50
print(f"16. Asking for staff:       lines to ann {asks16[:2]}; bot notes {[n.split('] ', 1)[1] for n in notes16][:2]}")
fail |= not ok16
if not ok16: bad.append("ok16")
# 17. The level's requirements in the team chat (test hook MP_BOT_TEST_WIN:
# ann's hospital 1 meets them from game day 10, hospitals 2 and 3 from day
# 12). The bot of hospital 2 (the lower number) says "good job" to ann, once;
# the bot of hospital 3 does not. Until day 12 each says what it still needs
# (one requirement), then that it is ready too.
win_words = re.compile(r'requirements|ready to win|did it|Good job|Well done|Great job|Nice work|level asks', re.I)
last_a = last_hospitals(a)
low17 = re.search(r'\[2 (.*?) opened', last_a[2]).group(1) if last_a else 'Bot Agnes'
high17 = re.search(r'\[3 (.*?) opened', last_a[2]).group(1) if last_a else 'Bot Bertie'
low_lines, high_lines = chats_from(a, low17), chats_from(a, high17)
too_re = re.compile(r"also|good spot|requirements too|ready as well|there too")
need_re = re.compile(r"short|value|reputation|cure|died|death|happy|months|loan|worth|bank|cash")
def needs17(lines):
    return [t for st, t in lines if 450 <= int(st) < 900 and not too_re.search(t) and not win_words.search(t)
            and not re.search(r'objectives|Sent \$|Thanks|thank', t) and need_re.search(t)]
good17 = [t for st, t in low_lines if int(st) >= 450 and 'ann' in t and win_words.search(t)]
good17_high = [t for st, t in high_lines if int(st) >= 450 and 'ann' in t and win_words.search(t)]
too17 = [[t for st, t in lines if int(st) >= 550 and too_re.search(t)] for lines in (low_lines, high_lines)]
ok17 = (len(good17) == 1 and not good17_high and all(too17) and len(needs17(low_lines)) == 1
        and len(needs17(high_lines)) == 1)
print(f"17. Requirements chat:      hospital 2 to ann {good17}; hospital 3 to ann {good17_high}; both also ready {[x[:1] for x in too17]}; "
      f"needs {needs17(low_lines)} / {needs17(high_lines)}")
fail |= not ok17
if not ok17: bad.append("ok17")
# 18. A warning that an opponent meets the requirements (MP_BOT_TEST_WIN:
# hospital 1 from game day 10, hospital 2 from day 12). In "afk" the bot shares
# its hospital with jon or with kay (it varies) and so warns that person
# about the other, once. In "duel" the bot has nobody on its side to read it:
# no warning.
afk_bot = next((n.split('/', 1)[1] for n in bots if n.startswith('afk/')), None)
warn18 = [(who, int(st), t) for who in ('jon', 'kay') for st, t in chats_from(log(who), afk_bot)
          if re.search(r'catch up|speed up', t)] if afk_bot else []
duel_warn18 = [t for t in to_eve if re.search(r'catch up|speed up', t)]
ok18 = (len(warn18) == 1 and warn18[0][1] >= 450 and ('kay' in warn18[0][2] if warn18[0][0] == 'jon' else 'jon' in warn18[0][2])
        and not duel_warn18)
print(f"18. Warning about a rival:  read by {warn18}; eve read {duel_warn18}")
fail |= not ok18
if not ok18: bad.append("ok18")
# 19. A failing hospital asks its team for help (test hook MP_BOT_TEST_FAIL:
# both bots of "team" count as failing from game day 20): each says in the
# team chat that it is failing its objectives and asks ann for an amount, once
# (the next ask is 3 months later). The advice is off in this test, so no model
# review comes first.
help19 = [(int(st), who, t) for who in ('Bot Agnes', 'Bot Bertie') for st, t in chats_from(a, who)
          if re.search(r'objectives|falling behind|struggling', t) and re.search(r'\$\d', t)]
notes19 = [l for k, t in bots.items() if k.startswith('team/') for l in t.splitlines()
           if 'asked the team for $' in l]
ok19 = (sorted(w for _, w, _ in help19) == ['Bot Agnes', 'Bot Bertie'] and len(notes19) == 2
        and min(st for st, _, _ in help19) >= 20 * 50 - 50)
print(f"19. Failing, asks for help: {[(st, w, t) for st, w, t in help19]}; notes {[n.split('] ', 1)[1] for n in notes19]}")
fail |= not ok19
if not ok19: bad.append("ok19")
# 20. The floor in one piece. Each bot that builds (team, race, duel, lab)
# reads its own floor (Bot:floorMap) and says in its month lines in how many
# parts it is, in how many it would be without its corridor objects (a plot
# bought is often a building of its own: a part of its own), and what must be
# reached. Every month: its objects cut nothing (the same number), and the
# entrance, both sides of the desk and the doors of its rooms are found.
# Also, for information: spots refused because they would cut the floor in
# two, and objects sold because it was in parts already (Bot:repairFloor).
floor20, months20 = {}, {}
for k, t in bots.items():
    found = re.findall(r'month \d+: .*; floor (\d+) part\(s\) \((\d+) without its corridor objects\), to reach '
                       r'(\d+) entrance tile\(s\), (\d+) desk side\(s\), (\d+) door\(s\)', t)
    if found:
        months20[k] = [tuple(int(v) for v in f) for f in found]
        floor20[k] = months20[k][-1]
builders20 = [k for k in bots if k.split('/')[0] in ('team', 'race', 'duel', 'lab')]
refused20 = {k: sum(int(n) for n in re.findall(r'\((\d+) spot\(s\) refused: they would cut', t)) for k, t in bots.items()}
mended20 = {k: re.findall(r'its floor is in \d+ parts: sold the (\w+)', t) for k, t in bots.items()}
ok20 = bool(builders20) and all(k in floor20 and all(m[0] == m[1] for m in months20[k]) and floor20[k][2] >= 1
                                and floor20[k][3] >= 2 and floor20[k][4] >= 3 for k in builders20)
print(f"20. Floor in one piece:     (parts, without objects, entrance tiles, desk sides, doors) "
      f"{dict(sorted(floor20.items()))}; spots refused "
      f"{dict((k, v) for k, v in sorted(refused20.items()) if v)}; objects sold to mend it "
      f"{dict((k, v) for k, v in sorted(mended20.items()) if v)}")
fail |= not ok20
if not ok20: bad.append("ok20")
# 21. A plot asked of an allied bot. In "lab" frank asks for plot 7 at
# auction and drops out: the bot gets it. On game day 4 frank asks the bot
# for plot 7: it keeps it for the level's value goal (worth less than the
# goal without it; its requirements count as met only from day 5 in this room,
# MP_BOT_TEST_WIN "lab/2:5"). On day 6 he asks for any plot it can spare: plot
# 7 is empty (a building of its own; the bot's first rooms go by its
# reception, and it uses plot 7 only from about day 11) and its land is far
# from full, so it offers plot 7 for free (its bank holds more than the $1,000
# it keeps here); frank gets the fax, accepts, and plot 7 is his.
asked21 = re.search(r'UI: asking for plot (\d+)', f)
plot21 = asked21.group(1) if asked21 else '-'
won21 = re.search(rf'auction \d+: plot {plot21} sold to hospital 2', f)
decisions21 = re.findall(r'plot request from frank \(plot (\w+)\): (.*)', lb)
kept21 = [d for d in decisions21 if d[0] == plot21 and d[1].startswith('keeps it: value')]
gave21 = [d for d in decisions21 if d[0] == 'any' and d[1].startswith(f'offers plot {plot21} for $0')]
offers21 = applied(f, 2, 'offer_plot')
lines21 = [t for _, t in chats_from(f, lab_bot) if 'plot' in t.lower()] if lab_bot else []
fax21 = re.search(rf'UI: accept the offer of plot {plot21} for \$0', f)
handed21 = re.search(rf'offer of plot {plot21} to hospital 1: handed over', f)
owners21 = re.findall(r'UI: plotmap (.*)', f)
his21 = bool(owners21) and f' {plot21}:o1:' in ' ' + owners21[-1]
ok21 = (bool(won21) and len(decisions21) == 2 and bool(kept21) and bool(gave21) and len(offers21) == 1
        and offers21[0][1] == 'ok' and len(lines21) >= 2 and bool(fax21) and bool(handed21) and his21)
print(f"21. A plot asked of a bot:  plot {plot21} won by the bot: {bool(won21)}; its answers {decisions21}; "
      f"its lines {lines21}; offer_plot {offers21}; frank accepted: {bool(fax21)}, handed over: {bool(handed21)}, "
      f"his now: {his21}")
fail |= not ok21
if not ok21: bad.append("ok21")
for name, text in sorted(bots.items()):
    errors = [l for l in text.splitlines() if 'ERROR' in l or 'could not' in l]
    if errors: print(f"   {name} problems: {errors[:5]}")
if bad: print("failed checks: " + " ".join(bad))
sys.exit(1 if fail else 0)
PY
