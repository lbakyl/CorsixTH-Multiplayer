#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_lobby_probe.sh BINARY GAME_DATA
#
# Multiplayer through the relay server, like players would use it: both games
# open Multiplayer from the main menu, connect to a local mp_server, create or
# join a password-protected room, get ready and start. Checks:
#   1. two players: room, ping and pacing in the lobby, game start, actions
#      from both (buy, hire), a pause by one player that both get, an
#      unpause by the other, a speed change (voted: bob agrees), a doctor whose tick breaks in
#      both games (set aside alike, reported), a question that does not
#      pause the game, a frozen game the other one waits for (and says
#      for whom) -> IN SYNC
#   2. wrong password -> refused
#   3. one player changes money locally only -> DESYNC (found by the game
#      and by the server)
#   4. one player leaves mid-game -> the other is told and carries on alone;
#      MULTIPLAYER > PLAYERS lists both with a ping, then the leaver as left;
#      the room the leaver was furnishing is taken over (room_takeover)
#   5. rooms: both draw a room on the same spot in the same hour (one wins
#      on both machines), the other player sees the reserved outline, a
#      later room elsewhere, a window -> IN SYNC, same rooms on both; the
#      drawer's own outline stays blue (with its walls) after the
#      checkmark; the chat key (Y, also with Shift) with a room editor open
#      opens the chat with an empty line, and Enter stays the editor's
#   6. rooms drawn where people stand (busy hospital): they are asked to
#      walk out and the build is retried -> IN SYNC, same rooms on both; the
#      room editor stays up (waiting) until the room is built
#   7. faxes: a VIP fax refused by clicking in the fax window, a second one
#      left to time out (accepted), shown at different moments on the two
#      screens -> IN SYNC, same decisions on both
#   8. co-op on an original two-player map: a hospital each, both opened
#      early, purchases and hires in each player's own hospital, money and a
#      nurse sent between them, loans, a price, research and heating changed
#      in their windows, the send icon in a staff window -> IN SYNC, every
#      command accepted
#   9. co-op events: an emergency and a VIP visit for player 2's hospital,
#      accepted by player 2; the emergency countdown runs in the simulation
#      -> IN SYNC
#  10. staff and queues: two pay rises asked (test command) and answered in
#      the pay rise window (accepted, declined), a nurse fired in staff
#      management, a queue reordered by dragging in the queue window by each
#      player, a bench picked up and put down elsewhere, another sold, a GP's
#      office furnished by hand (one command per object, then confirmed),
#      toilets drawn and cancelled while furnishing -> IN SYNC; no door or
#      window markers left on the floor (windows on every wall); a doctor
#      picked up (right click) and put into a room, there on both games
#  12. room editing (and a cardiogram room furnished by hand on level 2): a GP's office built and furnished by hand, then edited
#      while patients are about (picked up, placed, bought, moved, confirmed)
#      and removed; every edit command ok, IN SYNC, no markers left
#  11. save and continue: a co-op game saved with File > Save, continued from
#      the lobby by the same players (other host, own hospitals by name),
#      loaded state identical to the saved one -> IN SYNC, commands after it;
#      an error in one game's screen tick is reported and that game carries on
#  20. a destroyed room cleared away and built again ("clear it away and
#      build it again", with the remove option off): the room editor opens
#      on the old outline and the room is built there again -> IN SYNC, the
#      same rooms on both
#  21. co-op team win: player 1's hospital reaches the level's goals (test
#      command), both hear who is still missing; then player 2's; the win fax
#      comes to both and player 2 answers "Back to the lobby": the game ends
#      for both at the same step, IN SYNC until then
#  22. co-op team loss: player 2's hospital fails the goals at a year end
#      (both told), and still at the next one: the game ends for both at the
#      same step
#  24. clicks on the map: in no game of the suite were they found off with
#      no placement window open (MultiplayerSession:checkMapClicks)
#  23. Slowest at real-time pace: a step every 54 ms (not an hour every
#      second), a game hour every 18 or 19 steps, a purchase and a hire take
#      effect `delay` steps after the click -> IN SYNC
#  26. the lobby's room list refreshes itself: a player waiting in the lobby
#      sees a new room appear without clicking Refresh, and what they typed
#      (the password) stays -> they join, IN SYNC
#  28. a room's code fails as a patient enters (test command): the patient
#      walks out and queues again in both games, the report has the room's
#      layout -> IN SYNC
#  27. the reception desk moved one tile over (right, then down) -> both
#      moves accepted, IN SYNC
#  25. speed votes with three players: a new speed declined (one player by
#      clicking in the vote fax, one by itself), one agreed in the fax (2 of
#      3 is a majority), one nobody answers lapses after 30 s of play; the
#      speed changes only for the agreed one -> IN SYNC
# With MP_REFEREE=1 the local server also runs its headless referee for every
# room, and four more checks: 13. the referee agrees with the players in every
# room except 'cheat' (that one desyncs before the referee is there); 14, 15.
# desync repair in a shared and a co-op game; 16. rejoin after a quit.
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
    export MP_REFEREE_PROBE_SCENARIO="crowd=busy;staff=busy;edit=busy;cardio=none;epi=busy;wreck=none" # the probes' own start, see below
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
  # MP_AUDIO=1: sound on (the dummy driver), for the spoken announcements.
  local audio=false
  for a in "$@"; do [[ $a == MP_AUDIO=1 ]] && audio=true; done
  cat > "$dir/config.txt" <<EOF
theme_hospital_install = [[$game_data]]
savegames = [[$dir/saves]]
player_name = "$name"
fullscreen = false
width = 800
height = 600
language = [[English]]
audio = $audio
play_music = false
play_sounds = false
play_announcements = $audio
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
  MP_UI_SCRIPT="30:buy:bench;60:hire:Doctor;200:pause;600:breakstaff:Doctor;620:ticks:Doctor;650:inputerror;700:speed:Slower;900:holdpause:3;1100:freeze:3" & pids+=($!)
sleep 1
run_probe bob MP_ROLE=join MP_ROOM=ward MP_STEPS=1500 MP_DRAW_EVERY=3 \
  MP_UI_SCRIPT="40:buy:plant;90:hire:Nurse;190:unpause:150;620:ticks:Doctor" & pids+=($!)
sleep 1
run_probe mallory MP_ROLE=join MP_ROOM=ward MP_JOIN_PASSWORD=guess & pids+=($!)
run_probe carol MP_ROLE=host MP_ROOM=cheat MP_STEPS=400 & pids+=($!)
sleep 1
run_probe dave MP_ROLE=join MP_ROOM=cheat MP_STEPS=400 MP_UI_SCRIPT="50:cheat" & pids+=($!)
run_probe erin MP_ROLE=host MP_ROOM=leave MP_STEPS=800 MP_AUDIO=1 MP_UI_SCRIPT="100:buy:bench;250:players;600:players" & pids+=($!)
sleep 1
run_probe frank MP_ROLE=join MP_ROOM=leave MP_STEPS=800 MP_FURNISH_PACE=40 \
  MP_UI_SCRIPT="200:furnishroom:gp:5:5;300:quit" & pids+=($!)
run_probe gina MP_ROLE=host MP_ROOM=build MP_STEPS=900 MP_DRAW_EVERY=4   MP_UI_SCRIPT="50:enterchat;100:room:gp:5:5:window;400:buy:bench" & pids+=($!)
sleep 1
run_probe hugo MP_ROLE=join MP_ROOM=build MP_STEPS=900   MP_UI_SCRIPT="100:room:pharmacy:4:4;300:room:toilets:4:4" & pids+=($!)
run_probe ivan MP_ROLE=host MP_ROOM=crowd MP_STEPS=1200 MP_SCENARIO=busy & pids+=($!)
sleep 1
run_probe judy MP_ROLE=join MP_ROOM=crowd MP_STEPS=1200 MP_SCENARIO=busy   MP_UI_SCRIPT="300:crowdroom:gp:4:4;340:crowdroom:gp:4:4;380:crowdroom:gp:4:4;500:crowdroom:toilets:4:4;700:buyunder:bench" & pids+=($!)
run_probe kate MP_ROLE=host MP_ROOM=fax MP_STEPS=1300 MP_UI_SCRIPT="100:vip;400:vip" & pids+=($!)
sleep 1
run_probe liam MP_ROLE=join MP_ROOM=fax MP_STEPS=1300 MP_DRAW_EVERY=2   MP_UI_SCRIPT="160:answerfax:personality:2" & pids+=($!)
run_probe mira MP_ROLE=host MP_ROOM=coop MP_COOP=1 MP_LEVEL=2 MP_STEPS=1200 \
  MP_UI_SCRIPT="20:openhospital;60:buy:bench;80:hire:Doctor;200:givemoney:5000;250:loan;260:priceup;270:research:cure;280:heatup;330:acceptoffer;400:bonus:Doctor;410:raise:Doctor;500:buyplot" & pids+=($!)
sleep 1
run_probe nico MP_ROLE=join MP_ROOM=coop MP_STEPS=1200 MP_DRAW_EVERY=3 \
  MP_UI_SCRIPT="30:openhospital;60:buy:plant;90:hire:Nurse;200:staffwindow:Nurse;300:sendstaff:Nurse;350:loan;360:heatup;370:heatup;520:buyplot:other;600:sendhome" & pids+=($!)
run_probe olga MP_ROLE=host MP_ROOM=events MP_COOP=1 MP_LEVEL=2 MP_STEPS=1600   MP_UI_SCRIPT="20:openhospital;100:emergency:2;400:vip:2" & pids+=($!)
sleep 1
run_probe paul MP_ROLE=join MP_ROOM=events MP_STEPS=1600 MP_DRAW_EVERY=3   MP_UI_SCRIPT="30:openhospital;130:answerfax:emergency:1;430:answerfax:personality:1" & pids+=($!)
# Epidemic (co-op): one starts in player 2's hospital (test command); player
# 2 covers it up, turns vaccination mode on and off (the watch's syringe
# button, Esc, a right-click), marks the infected for vaccination, the countdown runs in
# the simulation on both machines, the inspector's result fax comes (early
# when the cover-up ends early: an infected patient left, or none are left).
run_probe ella MP_ROLE=host MP_ROOM=epi MP_COOP=1 MP_SCENARIO=busy MP_STEPS=7500   MP_UI_SCRIPT="20:openhospital" & pids+=($!)
sleep 1
run_probe finn MP_ROLE=join MP_ROOM=epi MP_SCENARIO=busy MP_STEPS=7500   MP_UI_SCRIPT="30:openhospital;300:epidemic;320:answerfax:epidemy:2:wait;360:vaccmode;365:vaccmode;370:vaccmode;375:vaccmode:esc;380:vaccmode;385:vaccmode:right;400:vaccinate;600:answerfax:report:1:wait" & pids+=($!)

# Offers (co-op): patients referred from the patient window and from a
# "no treatment" fax, a nurse offered for $3,000; offers accepted and declined in the
# purple offer window.
run_probe xavi MP_ROLE=host MP_ROOM=refer MP_COOP=1 MP_STEPS=1100 \
  MP_UI_SCRIPT="20:openhospital;100:patients:4;140:referpatient;400:acceptoffer;620:declineoffer;780:acceptoffer" & pids+=($!)
sleep 1
run_probe yuki MP_ROLE=join MP_ROOM=refer MP_STEPS=1100 \
  MP_UI_SCRIPT="30:openhospital;180:acceptoffer;200:hire:Nurse;300:sendstaff:Nurse:3000;500:patients:3;540:referpatient;700:notreatfax;720:answerfax:information:4" & pids+=($!)

# Research sharing (co-op, level 5: much to research): the host's hospital discovers two things (test
# command) and offers them for $5,000; the other player accepts in the fax.
# Then one more, offered free, is declined. Also in-game chat (to all, then
# Tab to the other player) and money requests from the bank manager ($7,500
# paid, $2,000 declined).
run_probe kim MP_ROLE=host MP_ROOM=research MP_COOP=1 MP_LEVEL=5 MP_STEPS=900 \
  MP_UI_SCRIPT="20:openhospital;100:learn;104:learn;108:learn;112:learn;116:learn;120:learn;124:learn;128:learn;150:shareresearch:5000;190:askmoney:7500;200:chat:0:hello everyone;230:chat:1:just for you;500:learn;540:shareresearch:0;600:askmoney:2000" & pids+=($!)
sleep 1
run_probe lea MP_ROLE=join MP_ROOM=research MP_STEPS=900 \
  MP_UI_SCRIPT="30:openhospital;250:answermoney:pay;300:answerresearch:accept;650:answermoney:decline;700:answerresearch:decline" & pids+=($!)

# Staff and queues: pay rises asked (test command) and answered in the pay
# rise window, one accepted and one declined; a nurse fired; queues
# reordered by dragging in the queue window.
run_probe wade MP_ROLE=host MP_ROOM=staff MP_STEPS=1000 MP_SCENARIO=busy \
  MP_UI_SCRIPT="100:askraise:Doctor;300:askraise:Handyman;400:patients:10;410:queuefront;600:fire:Nurse;640:breakroom:gp;650:buy:bench;660:buy:bench;700:moveobject:bench;800:sellobject:bench;860:movestaff:Doctor;870:whereis:Doctor;950:overlay" & pids+=($!)
sleep 1
run_probe yara MP_ROLE=join MP_ROOM=staff MP_STEPS=1000 MP_SCENARIO=busy \
  MP_UI_SCRIPT="150:answerraise:accept;350:answerraise:decline;420:queuefront;500:furnishroom:gp:5:5;750:cancelroom:toilets:4:4;870:whereis:Doctor;900:uistate;950:overlay" & pids+=($!)
# Room editing: ed builds a GP's office, then edits it while patients are
# about (pick up, place, buy, move, confirm) and later removes it; flo watches.
run_probe ed MP_ROLE=host MP_ROOM=edit MP_STEPS=1400 MP_SCENARIO=busy \
  MP_UI_SCRIPT="100:furnishroom:gp:5:5;500:editroom:gp:pickup:cabinet+place+buy:first+place+buy:radiator+place+move:1:0+place+done;950:overlay;1000:editroom:gp:tool+delete;1300:overlay;1310:uistate" & pids+=($!)
sleep 1
run_probe flo MP_ROLE=join MP_ROOM=edit MP_STEPS=1400 MP_SCENARIO=busy MP_UI_SCRIPT="1350:overlay" & pids+=($!)
# Level 2, a cardiogram room furnished by hand: the cardio faces east, the
# screen cannot (the editor once kept the facing and failed on one machine).
run_probe jan MP_ROLE=host MP_ROOM=cardio MP_LEVEL=2 MP_STEPS=700 MP_SCENARIO=none   MP_FURNISH_PACE=10 \
  MP_UI_SCRIPT="20:openhospital;40:buy:reception_desk;60:discover:cardiogram;80:furnishroom:cardiogram:5:5;85:losteditor;110:reopen" & pids+=($!)
sleep 1
run_probe abi MP_ROLE=join MP_ROOM=cardio MP_STEPS=700 MP_SCENARIO=none & pids+=($!)
# A destroyed room cleared away and built again: a GP's office is destroyed
# (test command), its player confirms "clear it away and build it again"
# with the remove option off, the room editor opens on the old outline and
# the office is built there again. Then a pharmacy with windows is destroyed
# and repaired: built again where it was, same door and windows, for the
# price of a new one (no clearing fee).
run_probe nell MP_ROLE=host MP_ROOM=wreck MP_STEPS=900 MP_SCENARIO=none \
  MP_UI_SCRIPT="20:openhospital;40:buy:reception_desk;60:room:gp:5:5;300:crash:gp;330:rebuildcrashed;500:buyinroom:radiator:gp;520:room:pharmacy:4:4:window;600:crash:pharmacy;620:repaircrashed:pharmacy" & pids+=($!)
sleep 1
run_probe otto MP_ROLE=join MP_ROOM=wreck MP_STEPS=900 MP_SCENARIO=none & pids+=($!)
# Save and continue: a co-op game saves at step 300 (File > Save) and ends;
# then the same two players continue it from the lobby, the other one
# hosting this time (each gets their own hospital back by name).
(
  run_probe sara MP_ROLE=host MP_ROOM=savegame MP_COOP=1 MP_STEPS=400 \
    MP_UI_SCRIPT="20:openhospital;60:buy:bench;80:hire:Doctor;120:uierror;300:mpsave" & a=$!
  sleep 1
  run_probe tom MP_ROLE=join MP_ROOM=savegame MP_STEPS=400 \
    MP_UI_SCRIPT="30:openhospital;90:hire:Nurse;290:staleui" & b=$!
  wait $a $b
  mkdir -p "$out/tom-2/saves"
  cp -r "$out/tom/saves/." "$out/tom-2/saves/"
  run_probe tom-2 MP_NAME=tom MP_ROLE=host MP_ROOM=savegame2 MP_STEPS=700 MP_CONTINUE=latest \
    MP_UI_SCRIPT="420:uistate;450:buy:plant;460:enterchat" & a=$!
  sleep 1
  run_probe sara-2 MP_NAME=sara MP_ROLE=join MP_ROOM=savegame2 MP_STEPS=700 \
    MP_UI_SCRIPT="500:hire:Nurse" & b=$!
  wait $a $b
) & pids+=($!)
# Slowest at real-time pace (check 23).
run_probe pia MP_ROLE=host MP_ROOM=slowest MP_STEPS=400 MP_FAST=0 MP_REALTIME=1   MP_UI_SCRIPT="10:speed:Slowest;60:buy:bench" & pids+=($!)
sleep 1
run_probe quin MP_ROLE=join MP_ROOM=slowest MP_STEPS=400 MP_FAST=0 MP_REALTIME=1 MP_UI_SCRIPT="80:hire:Nurse" & pids+=($!)
# The room list refreshes itself (check 26): lina is in the lobby before
# kai creates the room, types the password and never clicks Refresh.
run_probe lina MP_ROLE=join MP_ROOM=autolist MP_STEPS=100 MP_AUTO_ROOMS=1 & pids+=($!)
sleep 6
run_probe kai MP_ROLE=host MP_ROOM=autolist MP_STEPS=100   MP_UI_SCRIPT="40:moveobject:reception_desk:1:0;70:moveobject:reception_desk:0:1" & pids+=($!)
# Speed votes with three players (check 25).
run_probe vic MP_ROLE=host MP_ROOM=vote MP_PLAYERS=3 MP_STEPS=1400 \
  MP_UI_SCRIPT="50:speedother;300:speedother;450:speedother" & pids+=($!)
sleep 1
run_probe wren MP_ROLE=join MP_ROOM=vote MP_STEPS=1400 MP_VOTE=ask MP_UI_SCRIPT="60:votefax:2;310:votefax:1" & pids+=($!)
sleep 1
run_probe zack MP_ROLE=join MP_ROOM=vote MP_STEPS=1400 MP_VOTE=no & pids+=($!)
# Co-op level goals (test commands decide the goals; checks 21 and 22).
run_probe gil MP_ROLE=host MP_ROOM=goals MP_COOP=1 MP_STEPS=600 \
  MP_UI_SCRIPT="20:openhospital;100:goals:1:win;150:wincheck;250:goals:2:win;300:wincheck" & pids+=($!)
sleep 1
run_probe hana MP_ROLE=join MP_ROOM=goals MP_STEPS=600 \
  MP_UI_SCRIPT="30:openhospital;350:answerfax:information:1" & pids+=($!)
run_probe ian MP_ROLE=host MP_ROOM=teamloss MP_COOP=1 MP_STEPS=600 \
  MP_UI_SCRIPT="20:openhospital;100:goals:2:lose;150:yearend;300:yearend" & pids+=($!)
sleep 1
run_probe joy MP_ROLE=join MP_ROOM=teamloss MP_STEPS=600 MP_UI_SCRIPT="30:openhospital" & pids+=($!)
if [[ "${MP_REFEREE:-0}" == 1 ]]; then
  # Desync repair: one player changes money locally, the server holds both
  # games, both load the referee's save and play on (shared and co-op).
  run_probe quinn MP_ROLE=host MP_ROOM=fix MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="500:buy:bench" & pids+=($!)
  sleep 1
  run_probe rosa MP_ROLE=join MP_ROOM=fix MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="300:cheat;520:hire:Nurse" & pids+=($!)
  # (Each has a VIP fax waiting when the game is repaired: after loading the
  # referee's save, each shows only their own. Player 2 opens their hospital
  # only after the repair, with their own opening countdown, which the
  # referee's save did not have on its screen.)
  run_probe sam MP_ROLE=host MP_ROOM=fixcoop MP_COOP=1 MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="20:openhospital;300:vip:1;400:cheat;500:buy:bench" & pids+=($!)
  sleep 1
  run_probe tess MP_ROLE=join MP_ROOM=fixcoop MP_STEPS=1000 MP_EXPECT_REPAIR=1 \
    MP_UI_SCRIPT="310:vip:2;450:openhospital;520:hire:Nurse" & pids+=($!)
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
def is_ok(line):
    # (A fax answer is logged with what it answered: "-> ok (emergency: accept_emergency)".)
    return re.search(r'-> ok( \(.*\))?$', line) is not None
server = (out / 'server.log').read_text()
fail = False

a, b = log('alice'), log('bob')
lobby = re.search(r'lobby: .*', a)
paused_both = 'speed is now Pause' in a and 'speed is now Pause' in b
unpaused = bool(re.search(r'\[bob\] UI: pressed P at step \d+ \(paused\)', b))
slower_both = 'speed is now Slower' in a and 'speed is now Slower' in b
ok_cmds = [x for x in applied('alice') if is_ok(x) and 'set_speed' not in x and 'speed_vote' not in x]
speeds1 = [x for x in applied('alice') if 'set_speed -> ok' in x]
votes1 = 'speed vote 1 for Slower: agreed' in a and 'speed vote 1 for Slower: agreed' in b
# At step 600 the doctor's tick breaks in all games (probe_break, as a bug would): all
# set him aside alike, stay in sync, and tell the server.
# An error in alice's mouse handler leaves it connected (her mouse goes on).
# alice keeps a question open: in multiplayer it does not pause her game
# (her steps go on). Then her game stops for 3 s: bob's game turns blue and
# says whom it waits for.
opened1 = re.search(r'UI: opened a question at step (\d+)', log('alice'))
closed1 = re.search(r'UI: closed the question at step (\d+)', log('alice'))
question1 = opened1 is not None and closed1 is not None and int(closed1.group(1)) - int(opened1.group(1)) >= 20
wait1 = (re.search(r'waiting for peer 1 at step \d+: the screen turns blue', log('bob')) is not None
         and 'notice: Waiting for alice...' in log('bob') and question1)
input1 = 'UI: motion handler after an error at step 650: connected (before true)' in log('alice')
stopped1 = all(re.search(r'UI: Doctor #\d+ ticks false at step 620', log(p)) for p in ('alice', 'bob'))
reported1 = all(re.search(rf"room 'ward': state of '{p}' .*ERROR at step 6\d\d in the tick of Doctor", server) for p in ('alice', 'bob'))
ok1 = (result('alice').startswith('IN SYNC') and result('bob').startswith('IN SYNC')
       and applied('alice') == applied('bob') and len(ok_cmds) == 5 and len(speeds1) == 2 and votes1
       and paused_both and unpaused and slower_both and stopped1 and reported1 and input1 and wait1)
print(f"1. Two players via server:  {result('alice')}; commands applied {len(ok_cmds)}/5, identical: {applied('alice') == applied('bob')}; broken doctor set aside on both: {stopped1}, reported: {reported1}; mouse after an error: {input1}; question does not pause: {question1}; waiting shown: {wait1}")
print(f"   {lobby.group(0) if lobby else 'no lobby line'}")
print(f"   shared pause on both: {paused_both}; unpaused by the other player: {unpaused}; shared speed change: {slower_both}, voted: {votes1}")
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
# MULTIPLAYER > PLAYERS before and after frank quits.
lists4 = re.findall(r'UI: players at step \d+: (.*)', e)
listed = (len(lists4) == 2 and re.search(r'erin\|[^|]*\|[^|]*\|you', lists4[0]) is not None
          and re.search(r'frank\|[^|]*\|[^|]*\|playing', lists4[0]) is not None  # (no ping yet: frank's game lasts a second)
          and 'frank|' in lists4[1] and '|-|left the game|' in lists4[1]
          and re.search(r'erin\|[^|]*\|\d+ ms\|you', lists4[1]) is not None)
# frank left while furnishing a room by hand: erin's game takes it over.
taken4 = re.search(r'room_takeover -> ok', e) is not None
# ... and said aloud (the sound loaded and played).
spoken4 = re.search(r'ANNOUNCED: mp_player_left\.wav \(sound 0, handle [1-9]', e) is not None
ok4 = told and alone and listed and taken4 and spoken4 and result('erin').startswith('IN SYNC through step 800')
print(f"4. Player leaves:           told: {told}; spoken: {spoken4}; carried on alone to step 800: {alone}; room taken over: {taken4}; player list: {listed} {lists4[-1] if lists4 else ''}")
fail |= not ok4

g, h = log('gina'), log('hugo')
rooms_g = re.search(r'rooms built: (.*)', g); rooms_h = re.search(r'rooms built: (.*)', h)
rooms_g = rooms_g.group(1).split() if rooms_g else []; rooms_h = rooms_h.group(1).split() if rooms_h else []
saw = 'showing reserved area of player 1: gp' in h and 'showing reserved area of player 2: toilets' in g
built = sorted(r.split('@')[0] for r in rooms_g)
# The own outline stays blue after the checkmark, until the room is built;
# The chat key (Y) with a room editor open opens the chat with an empty
# line; Enter stays the editor's.
kept = re.search(r'UI: outline of gp after the checkmark: (\d+) of (\d+) tiles blue, (\d+) wall pieces', g)
kept = bool(kept and kept.group(1) == kept.group(2) and int(kept.group(3)) > 0)
enter = re.search(r'UI: chat key with a room editor open at step 50: chat opened, text "", editor \w+; Enter for (\S+); Shift: chat opened, text ""', g)
enter = bool(enter and 'UIEditRoom' in enter.group(1).split(',') and 'UIMultiplayerChat' not in enter.group(1))
ok5 = (result('gina').startswith('IN SYNC') and result('hugo').startswith('IN SYNC')
       and rooms_g == rooms_h and built == ['gp', 'toilets'] and saw and kept and enter)
print(f"5. Rooms:                   {result('gina')}; built on both: {rooms_g == rooms_h} {rooms_g}; reserved outlines seen: {saw}; "
      f"own outline kept: {kept}; Y opens the chat, Enter the editor's: {enter}")
fail |= not ok5

i, j = log('ivan'), log('judy')
ri = re.search(r'rooms built: (.*)', i); rj = re.search(r'rooms built: (.*)', j)
ri = ri.group(1) if ri else None; rj = rj.group(1) if rj else None
retries = len(re.findall(r'build_room -> rejected: retry', j))
drawn = len(re.findall(r'UI: drew ', j))
# A bench put down where somebody stands (as if they stepped there just
# after the click): placed once they stepped aside, or back in the list.
bench_tried = 'UI: put a bench where' in j
bench_cmds = [x for x in applied('judy') if 'place_object' in x]
bench_placed = any(x.endswith('place_object -> ok') for x in bench_cmds)
bench_back = 'gave up' in ' '.join(bench_cmds) and 'objects to place: bench x1' in j
bench_ok = bench_tried and not any('someone is in the way' in x for x in bench_cmds) and (bench_placed or bench_back)
# The editor waits on the screen while people walk out (retries during a
# wait), and goes when the room is built.
waits, waited_over_retry, wait_from = 0, False, None
for line in j.splitlines():
    mstep = re.search(r'UI: room editor (.*) at step (\d+)', line)
    if mstep:
        if mstep.group(1) == 'mp_waiting (window up)':
            wait_from = int(mstep.group(2))
        elif wait_from is not None:
            waits += 1
            wait_from = None
    elif wait_from is not None and re.search(r'build_room -> rejected: retry', line):
        waited_over_retry = True
ok6 = (result('ivan').startswith('IN SYNC') and result('judy').startswith('IN SYNC') and ri == rj
       and drawn >= 1 and retries > 0 and bench_ok and waits >= 1 and waited_over_retry)
print(f"6. Rooms over people:       {result('ivan')}; same rooms on both: {ri == rj}; drawn over people: {drawn}; retries while people left: {retries}; "
      f"bench where somebody stood: {'placed' if bench_placed else 'back in the list' if bench_back else 'LOST'} "
      f"({sum(1 for x in bench_cmds if 'retry' in x)} retries); editor waited on the screen {waits} times, "
      f"over a retry: {waited_over_retry}")
for l in sorted(set(re.findall(r'step \d+: peer 2 #\d+ build_room -> .*', j))):
    print("   " + l)
fail |= not ok6

k, l = log('kate'), log('liam')
choices = [x for x in applied('kate') if 'fax_choice' in x]
clicked = 'UI: clicked choice 2 of personality fax' in l
ok7 = (result('kate').startswith('IN SYNC') and result('liam').startswith('IN SYNC')
       and applied('kate') == applied('liam') and clicked and len(choices) == 1
       and is_ok(choices[0]))
print(f"7. Fax decisions:           {result('kate')}; refusal clicked: {clicked}; applied on both: {applied('kate') == applied('liam')} {choices}")
fail |= not ok7

m, n = log('mira'), log('nico')
cm = applied('mira')
kinds = [re.search(r'#\d+ (\w+) ->', x).group(1) for x in cm]
# nico's try to buy a plot on mira's side is refused; everything else is ok.
other8 = [x for x in cm if "buy_plot -> rejected: another player's side" in x]
ok_all = len(other8) == 1 and all(is_ok(x) for x in cm if x not in other8)
# mira buys a plot with entrance doors on it: they are made in the same
# order on both machines (pairs order once differed).
plot8 = re.search(r'UI: buying plot (\d+) \(\$\d+, (\d+) objects', m)
# The purple send icon in the nurse's staff window opens the trade window with her selected.
icon8 = 'send icon opens the trade window: true, selected: true' in log('nico')
ok8 = (icon8 and result('mira').startswith('IN SYNC') and result('nico').startswith('IN SYNC') and cm == applied('nico')
       and ok_all and sorted(kinds) == sorted(['open_hospital', 'open_hospital', 'place_object', 'place_object',
                                               'hire', 'hire', 'give_money', 'offer_staff', 'fax_choice', 'loan', 'loan',
                                               'set_price', 'research_frac', 'set_heat', 'set_heat', 'set_heat',
                                               'staff_bonus', 'raise_wage', 'send_home', 'buy_plot', 'buy_plot'])
       and plot8 is not None and int(plot8.group(2)) > 0
       and 'co-op: 2 hospitals' in m)
print(f"8. Co-op, a hospital each:  {result('mira')}; commands {len(cm)} all ok: {ok_all}; identical: {cm == applied('nico')}; plot bought: {plot8.group(1, 2) if plot8 else '-'}; send icon in the staff window: {icon8}")
for line in re.findall(r'hospital \d (?:[A-Z]+:|settings:).*', m)[-4:]:
    print("   " + line)
fail |= not ok8

o, q = log('olga'), log('paul')
co = applied('olga')
okc = [x for x in co if is_ok(x)]
kinds9 = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in okc)
helicopter_crash = 'Traceback' in o or 'Traceback' in q
ok9 = (result('olga').startswith('IN SYNC') and result('paul').startswith('IN SYNC') and co == applied('paul')
       and kinds9 == sorted(['open_hospital', 'open_hospital', 'probe_emergency', 'fax_choice', 'probe_vip', 'fax_choice'])
       and 'clicked choice 1 of emergency fax' in q and 'clicked choice 1 of personality fax' in q)
print(f"9. Co-op events, player 2:  {result('olga')}; emergency and VIP for hospital 2 accepted: {ok9}; commands {len(okc)}/{len(co)} ok")
for x in co: print("   " + x)
fail |= not ok9

xl, yl = log('xavi'), log('yuki')
cx = applied('xavi')
okx = [x for x in cx if is_ok(x)]
kinds_x = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in okx)
arrived_p = len(re.findall(r'referred patient #\d+ arrived', xl))
arrived_s = len(re.findall(r'transferred staff #\d+ arrived', xl))
# The nurse was offered for $3,000: hospital 1 paid it on accepting.
paid17 = all(re.search(r'offer of staff #\d+ to hospital 1 accepted: on the way, paid \$3000', t) for t in (xl, yl))
okr = (result('xavi').startswith('IN SYNC through step 1100') and result('yuki').startswith('IN SYNC')
       and cx == applied('yuki') and kinds_x.count('offer_patient') == 3 and kinds_x.count('offer_staff') == 1
       and 'UI: declined offer' in xl and arrived_p == 2 and arrived_s == 1 and paid17)
print(f"17. Offers and referrals:   {result('xavi')}; offers {kinds_x.count('offer_patient')} patients, "
      f"{kinds_x.count('offer_staff')} staff; arrived: {arrived_p} patients, {arrived_s} staff; identical: {cx == applied('yuki')}; nurse paid for: {paid17}")
fail |= not okr

kl, ll = log('kim'), log('lea')
ck = applied('kim')
kinds_k = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in ck if is_ok(x))
paid = re.search(r'research offer to hospital 2 accepted: (\d+) items for \$(\d+)', kl)
know_k = re.findall(r'hospital (\d) research: (.*)', kl)
know_l = re.findall(r'hospital (\d) research: (.*)', ll)
r1 = dict(know_k).get('1', '?').split(';')[0]
r2 = dict(know_k).get('2', '?').split(';')[0]
offered19 = re.search(r'UI: offered research (\S+) for \$5000', kl)
offered19 = len(offered19.group(1).split(',')) if offered19 else None
okres = (result('kim').startswith('IN SYNC through step 900') and result('lea').startswith('IN SYNC through step 900')
         and ck == applied('lea') and kinds_k.count('offer_research') == 2 and kinds_k.count('fax_choice') == 4 and kinds_k.count('probe_learn') == 9 and kinds_k.count('ask_money') == 2
         # all that was offered (eight discoveries and more on level 5): more
         # than the six an offer's fax names one by one ("and 5 more")
         and paid is not None and offered19 is not None and int(paid.group(1)) == offered19 > 6
         and paid.group(2) == '5000'
         and 'UI: declined the research offer' in ll and know_k == know_l and len(r1.split(',')) == len(r2.split(',')) + 1
         and 'chat seen: kim: hello everyone | kim (to you): just for you [private]' in ll
         and 'money request of hospital 1 to hospital 2: paid $7500' in kl
         and 'money request of hospital 1 to hospital 2: declined' in kl)
print(f"19. Research sharing:       {result('kim')}; offers {kinds_k.count('offer_research')}, "
      f"accepted {paid.group(1) + ' items for $' + paid.group(2) if paid else 'no'}, one declined; "
      f"same knowledge on both: {know_k == know_l}; hospital 1 knows {len(r1.split(','))}, hospital 2 {len(r2.split(','))}; "
      f"chat to all and private: {'kim (to you): just for you [private]' in ll}; money asked, paid and declined: "
      f"{'paid $7500' in kl and 'hospital 2: declined' in kl}")
fail |= not okres

el, fl = log('ella'), log('finn')
ce = applied('ella')
kinds_e = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in ce if is_ok(x))
oke = (result('ella').startswith('IN SYNC through step 7500') and result('finn').startswith('IN SYNC through step 7500')
       and ce == applied('finn') and 'probe_epidemic' in kinds_e and 'mark_vaccinate' in kinds_e
       and kinds_e.count('fax_choice') >= 2 and 'clicked choice 1 of report fax' in fl)
# Vaccination mode by the watch's syringe button (on, off, on), Esc (off), the
# button (on) and a right-click (off); the cursor follows.
modes = re.findall(r'UI: vaccmode (\w+) at step \d+: mode (\w+) .*cursor (\w+)', fl)
okv = modes == [('button', 'true', 'epidemic_hover'), ('button', 'false', 'default'),
                ('button', 'true', 'epidemic_hover'), ('esc', 'false', 'default'),
                ('button', 'true', 'epidemic_hover'), ('right', 'false', 'default')]
oke = oke and okv
print(f"18. Co-op epidemic:         {result('finn')}; cover up, vaccination, result fax: {oke}; commands {' '.join(kinds_e)}; "
      f"vaccination mode by button, Esc and right-click: {okv}")
fail |= not oke

nl, ol = log('nell'), log('otto')
first_gp = re.search(r'UI: drew gp at (\d+),(\d+) size', nl)
built_n, built_o = (re.search(r'rooms built: (.*)', x) for x in (nl, ol))
built_n, built_o = (m.group(1) if m else '-' for m in (built_n, built_o))
same_spot = first_gp is not None and f"gp@{first_gp.group(1)},{first_gp.group(2)}" in built_n.split()
removed = any('remove_crashed_room -> ok' in x for x in applied('nell'))
# (Then a radiator bought in the corridor shop goes into the working office.)
radiator = re.search(r'UI: put a radiator into gp #\d+ at (\d+),(\d+)', nl)
placed_in = radiator is not None and sum(1 for x in applied('nell') if 'place_object -> ok' in x) == 2
# The repaired pharmacy: same outline, door and windows; paid its price, nothing more.
before = re.search(r'UI: repairing crashed room #\d+ \(pharmacy\) at step \d+: (\S+ \S+) door (\S+) windows (\S+); '
                   r'balance (\d+), price (\d+)', nl)
after = re.search(r'UI: repaired room #\d+ \(pharmacy\) at (\S+ \S+): crashed false, built true, door (\S+) '
                  r'windows (\S+), objects \d+; balance (\d+)', nl)
repaired = bool(before and after and before.group(1) == after.group(1) and before.group(2) == after.group(2)
                and before.group(3) == after.group(3) and before.group(3) != 'nil'
                and int(before.group(4)) - int(after.group(4)) == int(before.group(5)))
ok20 = (result('nell').startswith('IN SYNC through step 900') and result('otto').startswith('IN SYNC through step 900')
        and applied('nell') == applied('otto') and 'probe_crash' in ' '.join(applied('nell')) and removed
        and 'on the old outline: true' in nl and same_spot and 'gp@' in built_n and built_n == built_o and placed_in
        and repaired)
print(f"20. Destroyed room rebuilt: {result('nell')}; cleared away: {removed}; editor on the old outline: "
      f"{'on the old outline: true' in nl}; built again on the same spot, on both: {same_spot and built_n == built_o} ({built_n}); "
      f"radiator put into it: {placed_in}; repaired where it was (door, windows, its price): {repaired}"
      f"{' $' + before.group(5) if before else ''}")
fail |= not ok20

def ended(text):
    m = re.search(r'LEVEL ENDED at step (\d+)', text); return int(m.group(1)) if m else None
g_, h_ = log('gil'), log('hana')
told21 = ("ADVISER: Your hospital has reached this level's goals! Still to get there: HANA." in g_
          and "ADVISER: GIL has reached this level's goals. Still to get there: HANA." in h_)
answered21 = [x for x in applied('gil') if 'fax_choice -> ok' in x]
ok21 = (told21 and len(answered21) == 1 and ended(g_) is not None and ended(g_) == ended(h_)
        and 'DESYNC' not in result('gil') + result('hana') and applied('gil') == applied('hana'))
print(f"21. Co-op team win:         who is missing told: {told21}; win fax answered: {answered21[0].split(': ', 1)[1] if answered21 else '-'}; "
      f"game ended at step {ended(g_)} / {ended(h_)}; {result('gil')} / {result('hana')}")
fail |= not ok21

i_, j_ = log('ian'), log('joy')
warned22 = ("ADVISER: Your hospital has failed this level's goals." in j_
            and "ADVISER: JOY has failed this level's goals." in i_)
ok22 = (warned22 and ended(i_) is not None and ended(i_) == ended(j_) and ended(i_) > 290
        and 'DESYNC' not in result('ian') + result('joy'))
print(f"22. Co-op team loss:        warned at the first year end: {warned22}; game ended at step {ended(i_)} / {ended(j_)}; "
      f"{result('ian')} / {result('joy')}")
fail |= not ok22

p_, q_ = log('pia'), log('quin')
wall23 = re.search(r'wall seconds ([\d.]+) for (\d+) steps', p_)
ms23 = 1000 * float(wall23.group(1)) / int(wall23.group(2)) if wall23 else 0
date23 = re.search(r'final \d+-\d+-(\d+)T(\d+)', p_)
hours23 = (int(date23.group(1)) - 1) * 50 + int(date23.group(2)) if date23 else -1
buy23 = re.search(r'step (\d+): peer 1 #\d+ place_object -> ok', p_)
hire23 = re.search(r'step (\d+): peer 2 #\d+ hire -> ok', p_)
# (The game's delay, from START: the lobby line shows the server's first guess.)
delay23 = re.search(r'START: .*delay (\d+)', p_)
d23 = int(delay23.group(1)) if delay23 else 0
ok23 = (result('pia').startswith('IN SYNC through step 400') and result('quin').startswith('IN SYNC')
        and applied('pia') == applied('quin') and 40 <= ms23 <= 80
        and buy23 is not None and int(buy23.group(1)) <= 60 + d23 + 1
        and hire23 is not None and int(hire23.group(1)) <= 80 + d23 + 1
        and 20 <= hours23 <= 40)
print(f"23. Slowest, real time:     {result('pia')}; {ms23:.0f} ms per step; game hours {hours23} in 400 steps; "
      f"purchase at step {buy23.group(1) if buy23 else '-'} and hire at {hire23.group(1) if hire23 else '-'} "
      f"(clicked at 60 and 80, delay {d23}: {d23 * ms23:.0f} ms)")
fail |= not ok23

logs25 = {n: log(n) for n in ('vic', 'wren', 'zack')}
outcomes25 = {n: re.findall(r'speed vote \d+ for ([\w ]+): (\w+)', t) for n, t in logs25.items()}
want25 = ['declined', 'agreed', 'lapsed']
fax25 = len(re.findall(r'UI: answered the speed vote fax', logs25['wren'])) == 2
# (Each vote is for a speed other than the current one, within the room's
# top speed, which depends on the connection.) The agreed speed is the last.
agreed25 = [sp for sp, r in outcomes25['vic'] if r == 'agreed']
max25 = bool(agreed25) and all(re.findall(r'speed is now ([\w ]+?) at step', t)[-1:] == agreed25
                               for t in logs25.values())
ok25 = (all([r for _, r in o] == want25 for o in outcomes25.values()) and fax25 and max25
        and all(result(n).startswith('IN SYNC') for n in logs25)
        and applied('vic') == applied('wren') == applied('zack'))
print(f"25. Speed votes:            {result('vic')}; votes {outcomes25['vic']}; same on all three: "
      f"{len(set(map(tuple, outcomes25.values()))) == 1}; answered in the fax: {fax25}; speed only changed when agreed: {max25}")
fail |= not ok25

# The next patient entering a GP's office makes the room's code fail (test
# command): the patient walks out and queues again in both games, and the
# report carries the room's layout.
fail28 = [re.search(r"ERROR at step (\d+) in the gp room #\d+ \(patient #(\d+) leaves and queues again\)", log(n))
          for n in ('wade', 'yara')]
same28 = all(fail28) and fail28[0].groups() == fail28[1].groups()
layout28 = re.search(r"room #\d+ gp at \d+,\d+ size \d+x\d+; door .*; objects: .*desk", server) is not None
ok28 = same28 and layout28 and result('wade').startswith('IN SYNC through step 1000') and result('yara').startswith('IN SYNC')
print(f"28. Room failed on entry:   {result('wade')}; patient walked out and queued again in both games at the same step: "
      f"{same28} {fail28[0].groups() if fail28[0] else '-'}; room layout reported: {layout28}")
fail |= not ok28

auto26 = re.search(r"UI: the room list showed 'autolist' without Refresh after ([\d.]+) s; password kept: true", log('lina'))
ok26 = auto26 is not None and result('kai').startswith('IN SYNC') and result('lina').startswith('IN SYNC')
print(f"26. Room list refreshes:    {result('lina')}; room shown by itself after {auto26.group(1) if auto26 else '-'} s, "
      f"password kept: {auto26 is not None}")
fail |= not ok26

# The reception desk moved one tile over, twice (its own tiles do not count
# as taken while it is moved).
moves27 = re.findall(r'UI: moved reception_desk #\d+ .* \(spot valid: true\)', log('kai'))
desk27 = [x for x in applied('kai') if 'move_object -> ok' in x]
ok27 = len(moves27) == 2 and len(desk27) == 2 and applied('kai') == applied('lina') and result('kai').startswith('IN SYNC')
print(f"27. Desk one tile over:     {result('kai')}; moves accepted on the screen {len(moves27)}/2, in the game {len(desk27)}/2")
fail |= not ok27

resets24 = []
for d in sorted(out.iterdir()):
    f = d / 'log.txt'
    # (The save test leaves a stale room editor on purpose: not counted.)
    if d.is_dir() and f.exists() and 'UI: left a stale room editor' not in f.read_text(errors='replace'):
        for line in f.read_text(errors='replace').splitlines():
            if 'map clicks were off with no placement window open' in line:
                resets24.append(d.name)
print(f"24. Map clicks:             turned back on by the safety net {len(resets24)} times {sorted(set(resets24)) or ''}")
fail |= bool(resets24)

w_, y_ = log('wade'), log('yara')
cw = applied('wade')
okw = [x for x in cw if is_ok(x)]
kinds10 = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in okw)
m10 = re.search(r'rooms built: (.*)', w_)
rooms10 = m10.group(1) if m10 else ''
# Where yara drew the furnished GP's office and the cancelled toilets.
drawn10 = {k: f"{k}@{x},{yy}" for k, x, yy in re.findall(r'UI: drew (\w+) at (\d+),(\d+)', y_)}

# After furnishing by hand and cancelling, clicks reach the whole map again.
states10 = [l for l in y_.splitlines() if 'UI: state at step' in l]
clicks10 = bool(states10) and 'world hit test on, edit_room false' in states10[-1]
# No door or window markers left on the floor (yara's rooms have a window on
# every wall; south and east ones once left blue tiles on the corridor).
marks10 = [m.group(1) for m in (re.search(r'UI: overlay at step \d+: (\d+) marks', t) for t in (w_, y_)) if m]
clean10 = marks10 == ['0', '0']
# wade moved a doctor into a room (right click, then a click there): both
# games have them in that room at the same tile a few hours later.
moving10 = re.search(r'UI: moving Doctor #(\d+) from \S+ to (\d+),(\d+) in (\S+) \(picked up: hidden (\w+)\)', w_)
where_w = re.search(r'UI: Doctor #(\d+) at step 870 is at (\S+) in (\S+), visible (\w+)', w_)
where_y = re.search(r'UI: Doctor #(\d+) at step 870 is at (\S+) in (\S+), visible (\w+)', y_)
moved10 = bool(moving10 and where_w and where_y and where_w.groups() == where_y.groups()
               and where_w.group(1) == moving10.group(1) and where_w.group(3) == moving10.group(4)
               # gone from the mover's screen at once, seen again where they landed
               and moving10.group(5) == 'true' and where_w.group(4) == 'true')
ok10 = moved10 and 'move_staff' in kinds10 and clean10 and clicks10 and (result('wade').startswith('IN SYNC through step 1000') and result('yara').startswith('IN SYNC')
        and cw == applied('yara') and kinds10.count('pay_rise') == 2 and kinds10.count('probe_raise') == 2
        and 'fire_staff' in kinds10 and kinds10.count('queue_move') >= 1 and 'probe_patients' in kinds10
        and 'move_object' in kinds10 and 'sell_object' in kinds10
        and kinds10.count('room_object') >= 2 and 'room_finish' in kinds10 and 'room_unbuild' in kinds10 and 'room_delete' in kinds10
        and rooms10 == re.search(r'rooms built: (.*)', y_).group(1)
        and drawn10.get('gp', '-') in rooms10.split() and drawn10.get('toilets', '-') not in rooms10.split()
        and 'accepted the pay rise' in y_ and 'declined the pay rise' in y_)
print(f"10. Staff and queues:       {result('wade')}; commands {len(okw)}/{len(cw)} ok, identical: {cw == applied('yara')}; {' '.join(kinds10)}; rooms {rooms10 or 'none'}; clicks after furnishing: {clicks10}; markers left: {'/'.join(marks10) or '-'}; staff moved: {moved10} {where_w.group(2, 3) if where_w else '-'}")
fail |= not ok10

ed, fl = log('ed'), log('flo')
ce = applied('ed')
kinds12 = sorted(set(re.search(r'#\d+ (\w+) ->', x).group(1) for x in ce if is_ok(x)))
# (A spot the probe tries for an object may be refused; it tries the next.)
bad12 = [x for x in ce if not is_ok(x) and 'retry' not in x and 'room_object -> rejected' not in x]
steps12 = re.findall(r'UI: edit (\S+) (ok|FAILED[^\n]*)', ed)
failed12 = [f"{s} {r}" for s, r in steps12 if r != 'ok']
want12 = ['room_buy', 'room_delete', 'room_edit', 'room_finish', 'room_object', 'room_pickup',
          'room_rebuild', 'room_unbuild']
# A radiator leaves its tile walkable: the first free spot takes it.
# (Placed twice: after buying it and after the room moved.)
radiator_puts12 = len(re.findall(r'UI: furnishing: put radiator at', ed))
radiator12 = radiator_puts12 - len(re.findall(r'UI: furnishing: radiator is in the room', ed))
moved12 = re.search(r'UI: edit: room now at (\d+),(\d+) \(was (\d+),(\d+)\)', ed)
marks12 = re.findall(r'UI: overlay at step \d+: (\d+) marks', ed + fl)
rooms12 = re.search(r'rooms built: (.*)', ed)
clicks12 = 'world hit test on, edit_room false' in ''.join(l for l in ed.splitlines() if 'UI: state at step' in l)
# The cardiogram room: same command results on both machines, room done.
# (jan's editor closes on its own while furnishing; the edit room tool on
# the room opens it again, and the room gets finished.)
cardio12 = (applied('jan') == applied('abi') and 'furnished room' in log('jan')
            and re.search(r'UI: reopened the editor of cardiogram#\d+ at step \d+: shown true', log('jan')) is not None
            and 'cardiogram@' in (re.search(r'rooms built: (.*)', log('abi')) or [None, ''])[1]
            and result('jan').startswith('IN SYNC') and result('abi').startswith('IN SYNC')
            and not [x for x in applied('jan') if '-> rejected: error' in x])
ok12 = cardio12 and (result('ed').startswith('IN SYNC through step 1400') and result('flo').startswith('IN SYNC through step 1400')
        and ce == applied('flo') and all(k in kinds12 for k in want12) and not bad12
        and len(steps12) == 10 and radiator_puts12 >= 1 and radiator12 == 0 and not failed12 and moved12 is not None and moved12.group(1, 2) != moved12.group(3, 4)
        and marks12 == ['0', '0', '0'] and clicks12
        and rooms12 is not None and rooms12.group(1) == re.search(r'rooms built: (.*)', fl).group(1)
        and f"gp@{moved12.group(1)},{moved12.group(2)}" not in rooms12.group(1).split())  # the edited room, removed
print(f"12. Room editing:           {result('ed')} / {result('flo')}; steps ok {len(steps12) - len(failed12)}/10; radiator refused {radiator12} of {radiator_puts12} {' '.join(failed12)}; "
      f"moved {moved12.group(3, 4) if moved12 else '-'} -> {moved12.group(1, 2) if moved12 else '-'}; commands {' '.join(kinds12)}; "
      f"refused {len(bad12)}; markers {'/'.join(marks12)}; clicks {clicks12}; rooms at the end {rooms12.group(1) if rooms12 else '-'}; cardiogram room by hand: {cardio12}")
fail |= not ok12

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
after = [x for x in applied('tom-2') if is_ok(x)]
kinds11 = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in after)
# Tom saved with a stale room editor in his UI; after continuing he can
# click on the whole map again.
clicks_ok = 'world hit test on, edit_room false' in t2
# The chat window came with Tom's save: its key (Y) works again after loading.
chat_ok = 'chat key with a room editor open at step 460: chat opened' in t2
ok11 = (same_save and same_load and seats and clicks_ok and chat_ok and result('tom-2').startswith('IN SYNC through step 700')
        and result('sara-2').startswith('IN SYNC through step 700') and applied('tom-2') == applied('sara-2')
        and kinds11 == ['hire', 'place_object'])
# sara's screen tick failed once at step 120: her game carried on, and the
# server log has the error.
ui_error = bool(re.search(r"room 'savegame': state of 'sara' .*ERROR at step 1[2-3]\d in the screen tick: .*probe: an error in the screen tick", server))
ok11 = ok11 and ui_error
print(f"11. Save and continue:      saved at step {saved_t.group(2) if saved_t else '-'} on both: {same_save}; error reported: {ui_error}; "
      f"continued from it: {same_load}; own hospitals: {seats}; clicks after load: {clicks_ok}; chat key after load: {chat_ok}; {result('tom-2')} / {result('sara-2')}; "
      f"commands after it: {' '.join(kinds11)}")
fail |= not ok11

if with_referee:
    # (savegame2 is a continued game: the referee waits for the host's save.)
    rooms = ['ward', 'leave', 'build', 'crowd', 'fax', 'coop', 'events', 'staff', 'edit', 'cardio', 'refer', 'epi', 'savegame2']
    connected = [r for r in rooms if f"room '{r}': referee connected" in server]
    differ = re.findall(r"room '(\w+)': the players differ from the referee", server)
    confirmed = dict(re.findall(r"room '(\w+)': referee confirmed steps through (\d+)", server))
    def confirmed_after(room): return confirmed.get(room, 0)
    ok10 = (connected == rooms and not differ and all(int(confirmed.get(r, 0)) > 300 for r in rooms)
            # (It joins a few seconds late; the fast test game ends soon after.)
            and "room 'savegame2': the referee disconnected" not in server and int(confirmed.get('savegame2', 0)) > 303)
    print(f"13. Headless referee:       connected in {len(connected)}/{len(rooms)} rooms; "
          f"differs in {differ or 'none'}; confirmed through " +
          ", ".join(f"{r} {confirmed.get(r, 0)}" for r in rooms))
    fail |= not ok10

    for n, (host, join, room) in enumerate([('quinn', 'rosa', 'fix'), ('sam', 'tess', 'fixcoop')]):
        hl, jl = log(host), log(join)
        repaired = 'REPAIRED' in hl and 'REPAIRED' in jl
        fixed = re.search(rf"room '{room}': repaired: everybody loads the referee's game at step (\d+) \((\d+) bytes", server)
        same = applied(host) == applied(join)
        kinds = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in applied(host) if is_ok(x))
        later = 'place_object' in kinds and 'hire' in kinds
        # The players hear about it only from the adviser, afterwards; no
        # popup (the referee's level introduction neither), the view kept.
        quiet = all('notice: Your game got out of sync and was recovered successfully.' in x
                    and 'Multiplayer games are out of sync' not in x
                    and re.search(r'REPAIRED: .*popups 0; view kept true', x) is not None for x in (hl, jl))
        ok = (repaired and fixed is not None and same and later and quiet
              and result(host).startswith('IN SYNC through step 1000')
              and result(join).startswith('IN SYNC through step 1000')
              and int(confirmed_after(room)) >= 900)
        where = f"at step {fixed.group(1)}, save {int(fixed.group(2)) // 1024} KiB" if fixed else "not repaired"
        own = ''
        if room == 'fixcoop':
            # After the repair each player's bar shows their own VIP fax only.
            shown = [re.search(r'REPAIRED: .*messages shown: ([^;]*)', x) for x in (hl, jl)]
            shown = [m.group(1).split(',') if m else [] for m in shown]
            own_ok = shown[0] == ['personality@1'] and shown[1] == ['personality@2']
            # ... and their own countdowns: player 2's opening watch, opening
            # player 2's hospital.
            watches = [re.search(r'REPAIRED: .*watches: (.*)', x) for x in (hl, jl)]
            watches = [m.group(1) if m else '?' for m in watches]
            opened = re.search(r'hospital 2 TESS: .*open true', jl) is not None
            watch_ok = watches == ['', 'initial_opening@2'] and opened
            own = f"; own messages only: {own_ok} {shown}; own countdowns: {watch_ok} {watches}"
            ok = ok and own_ok and watch_ok
        print(f"{14 + n}. Desync repair ({room}):{' ' * (8 - len(room))}{result(host)} / {result(join)}; "
              f"{where}; commands after it ok on both: {same and later}; quiet repair, view kept: {quiet}{own}")
        fail |= not ok

    u, v = log('uma'), log('vera-back')
    rejoined = re.search(r"REJOINED: loaded the shared save at step (\d+)", v)
    at = int(rejoined.group(1)) if rejoined else 10**9
    after_u = [x for x in applied('uma') if int(re.search(r'step (\d+):', x).group(1)) > at]
    after_v = [x for x in applied('vera-back') if int(re.search(r'step (\d+):', x).group(1)) > at]
    kinds = sorted(re.search(r'#\d+ (\w+) ->', x).group(1) for x in after_u
                   if is_ok(x) and 'set_speed' not in x and 'speed_vote' not in x)
    # (The game steps on while paused, so the steps go past 1500.)
    ok13 = (rejoined is not None and "room 'back': 'vera' rejoins as player 2" in server
            and result('uma').startswith('IN SYNC through step')
            and result('vera-back').startswith('IN SYNC through step')
            # (uma stops first: vera's game then marks uma away, one line more.)
            and after_u == after_v[:len(after_u)] and kinds in (['hire', 'place_object'], ['hire', 'place_object', 'player_away'])
            # (Away while gone, counted again once back: the shared save's load
            # marks them back, MultiplayerLobby:_loadShared.)
            and 'is back: their hospital counts' in u
            and int(confirmed_after('back')) >= 1400
            # (A player coming back is no desync: uma is not told about one.)
            and 'recovered successfully' not in u)
    print(f"16. Rejoin after a crash:   {result('uma')} / {result('vera-back')}; "
          f"rejoined at step {at if rejoined else '-'}; commands after it on both: {after_u == after_v[:len(after_u)]} {kinds}")
    fail |= not ok13
sys.exit(1 if fail else 0)
PY
