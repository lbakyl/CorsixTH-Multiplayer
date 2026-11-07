#!/usr/bin/env bash
# Usage: bash scripts/multiplayer/run_plots_probe.sh BINARY GAME_DATA
#
# Trading between allies, through a local relay server: reputation, selling
# a plot back to the bank, handing a plot to the other player. Room "plots"
# (co-op, level 2, no auctions): ula (host) and vic. Checks:
#   1. ula buys plot 7 and vic plot 8 (the two plots of level 2 that touch each
#      other and nothing else, so that one can be handed to the other); the town map shows
#      the sell button (X) and the hand-over button (arrow) on it, not on the
#      starting plots
#   2. ula sells the empty plot back through the town map (the X, the
#      question, Yes): the bank pays 80 percent of the price, the plot is
#      nobody's, and ula buys the same plot again
#   3. a bench on the plot: the town map answers "You can only sell this
#      plot when it is emptied of any items." and sends no command; the
#      command sent anyway is refused in both games ("plot not empty"); the
#      bench sold, the plot can go again
#   4. ula hands the plot to vic for $2,500 through the arrow: vic declines
#      (nothing changes), ula offers again, vic accepts: the plot is vic's,
#      $2,500 went from vic to ula; vic sells it back to the bank, which pays
#      80 percent of the price the bank sold it for
#   5. reputation: ula vouches for vic in the trade window (100 + 100), the
#      third gift in the month is refused ("monthly limit"), and the next
#      month she may give again; the points moved are the same in both games
#   6. both games IN SYNC to the end (and the referee agrees with MP_REFEREE=1)
# With MP_SHOT_DIR the games save screenshots of the town map, the questions
# and the trade window there.
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
out=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-plots.XXXXXXXX")
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
  export MP_REFEREE_PROBE_SCENARIO="plots=light" # the probes' own start on every hospital
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
run_probe ula MP_ROLE=host MP_ROOM=plots MP_COOP=1 MP_LEVEL=2 MP_STEPS=1700 MP_OPTIONS="auctions=0 tricks=2" \
  MP_UI_SCRIPT="20:openhospital;50:plotbuy:plot:7;90:plotshot;110:plotsell;130:plotstate;150:plotbuy:again;170:plotbench;200:plotsell;205:plotsell:force;230:plotclear;260:plotgive:2:2500;340:plotgive:2:2500;420:plotstate;450:giverep:100;470:giverep:100;490:giverep:50;500:repstate;1580:giverep:30;1590:repstate;1650:plotstate" & pids+=($!)
sleep 1
run_probe vic MP_ROLE=join MP_ROOM=plots MP_STEPS=1700 \
  MP_UI_SCRIPT="30:openhospital;70:plotbuy:plot:8;300:answerplot:decline;380:answerplot:accept;420:plotstate;600:plotsell;640:plotstate" & pids+=($!)
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
fail = False
ula, vic = log('ula'), log('vic')

# 1. Buying, and the buttons on the town map
bought = re.findall(r'UI: plotbuy plot (\d+) price (\d+) balance (\d+)', ula)
plot, price = (bought[0][0], int(bought[0][1])) if bought else (None, 0)
buttons = re.search(r'UI: town map buttons at step \d+: (.*)', ula)
buttons = buttons.group(1).split() if buttons else []
vic_bought = re.findall(r'UI: plotbuy plot (\d+) price (\d+)', vic)
ok1 = (bool(bought) and bool(vic_bought) and f'{plot}:sell' in buttons and f'{plot}:give' in buttons
       and all(b.split(':')[0] not in ('1', '2') for b in buttons)
       and len(applied('ula', 'buy_plot')) >= 2 and all(x.endswith('-> ok') for x in applied('ula', 'buy_plot'))
       and applied('ula', 'buy_plot') == applied('vic', 'buy_plot'))
print(f"1. Buying:                  plot {plot} for ${price}, vic's {vic_bought}; buttons on the town map: {buttons}")
fail |= not ok1

# 2. Selling it back
refund = price * 80 // 100
sells = [x for x in applied('ula', 'sell_plot') if 'peer 1 ' in x]
first = [x for x in sells if x.endswith('-> ok (plot %s for $%d)' % (plot, refund))]
rebought = len(bought) >= 2 and bought[1][0] == plot
asked = re.search(r'UI: the question asked: (.*)', ula)
state = re.search(r'UI: plotstate at step \d+: plot %s owner (\d+), paid (\w+),' % plot, ula)
ok2 = (len(first) == 1 and sells[0] == first[0] and rebought and asked is not None
       and ('$%d' % refund) in asked.group(1) and state is not None and state.group(1) == '0'
       and applied('ula', 'sell_plot') == applied('vic', 'sell_plot'))
print(f"2. Sold back:               {first}; asked: {asked.group(1) if asked else '-'}; plot {plot} nobody's after: "
      f"{state.group(1) if state else '-'}; bought again: {rebought}")
fail |= not ok2

# 3. Not empty
msg = re.search(r'UI: message after the sale: (.*)', ula)
refused = [x for x in sells if 'rejected: plot not empty' in x]
ok3 = (msg is not None and msg.group(1) == 'You can only sell this plot when it is emptied of any items.'
       and len(refused) == 1 and len(sells) == 2 and any('sell_object' in x for x in
       [l for l in ula.splitlines() if 'sell_object -> ok' in l])
       and applied('ula', 'sell_plot') == applied('vic', 'sell_plot'))
print(f"3. Not empty:               message: {msg.group(1) if msg else '-'}; command refused on both: {refused}")
fail |= not ok3

# 4. Handed over
offers = applied('ula', 'offer_plot')
declined = re.search(r'offer of plot %s to hospital 2: declined' % plot, ula) and re.search(
    r'offer of plot %s to hospital 2: declined' % plot, vic)
handed = (re.search(r'offer of plot %s to hospital 2: handed over for \$2500' % plot, ula) and re.search(
    r'offer of plot %s to hospital 2: handed over for \$2500' % plot, vic))
owners = {n: re.findall(r'UI: plotstate at step (\d+): plot \d+ owner (\d+), paid (\w+), balance (-?\d+), loan (\d+), owned ([\d,]*)',
                        log(n)) for n in ('ula', 'vic')}
vic_state = owners['vic'][0] if owners['vic'] else None
vic_sells = [x for x in applied('vic', 'sell_plot') if 'peer 2 ' in x]
ok4 = (len([x for x in offers if x.endswith('-> ok (plot %s for $2500)' % plot)]) == 2 and bool(declined) and bool(handed)
       and vic_state is not None and vic_state[1] == '2' and plot in vic_state[5].split(',')
       and len(vic_sells) == 1 and vic_sells[0].endswith('-> ok (plot %s for $%d)' % (plot, refund))
       and applied('ula', 'offer_plot') == applied('vic', 'offer_plot'))
print(f"4. Handed over:             {offers}; declined first: {bool(declined)}; accepted: {bool(handed)}; vic after: {vic_state}; "
      f"vic sold it back: {vic_sells}")
fail |= not ok4

# 5. Reputation
gifts = applied('ula', 'give_reputation')
reps = re.findall(r'UI: reputation at step (\d+): (.*)', ula)
gift_ok = [g for g in gifts if '-> ok (' in g]
gift_no = [g for g in gifts if 'rejected: monthly limit' in g]
ok5 = (len(gift_ok) == 3 and len(gift_no) == 1 and [re.search(r'\((\d+) points\)', g).group(1) for g in gift_ok] == ['100', '100', '30']
       and applied('ula', 'give_reputation') == applied('vic', 'give_reputation'))
print(f"5. Reputation:              {gifts}; reputation {reps}")
fail |= not ok5

# 6. Sync
sync = all(result(n).startswith('IN SYNC') for n in ('ula', 'vic'))
print(f"6. Games:                   {result('ula')} / {result('vic')}")
fail |= not sync
if with_referee:
    confirmed = re.search(r"room 'plots': referee confirmed steps through (\d+)", server)
    clean = not re.search(r"room 'plots': (the players differ|repaired)", server)
    print(f"7. Referee:                 confirmed through {confirmed.group(1) if confirmed else '-'}, no differences: {clean}")
    fail |= not (confirmed and int(confirmed.group(1)) >= 1500 and clean)
print("Plots probe: " + ("FAILED" if fail else "all checks passed"))
sys.exit(1 if fail else 0)
PY
