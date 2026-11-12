#!/usr/bin/env bash
# Run the CorsixTH multiplayer server natively (a systemd service) with the
# headless referee, which repairs desyncs and lets a dropped player rejoin
# (docs/multiplayer/referee.md). Ubuntu or Debian; run as root (sudo).
#
#   sudo bash setup-referee-host.sh --release mp-test-c364e17a [--data DIR] [--port 47800] [--motd TEXT]
#        [--name eu2] [--experts "Argus,Matroftt"]
#   (a stable release is named mp-stable-<commit>)
#
# --release  a test release of lbakyl/CorsixTH-Multiplayer: its Linux package
#            is the referee, and the server code comes from the same commit.
#            The players must run that release (the build ids must match).
# --code     optional: the server code and the referee's and bots' scripts
#            from another branch or commit (newer than the release), for
#            server-side changes the players' build does not need (bots, the
#            server itself). Default: the release's own commit.
# --data     your Theme Hospital folder (the one with DATA, QDATA, ...), the
#            first time: it is copied to /opt/corsixth-mp/thdata, readable only
#            by the service account. It is not part of any release.
#
# Advice for the bots from a language model (mp_server/corsixth_mp/advisor.py):
# put the Anthropic API key into /etc/corsixth-mp-secrets.env yourself, as
#   ANTHROPIC_API_KEY=...   (root:corsixth, mode 640)
# This script never writes that file; the service reads it if it is there,
# and without it the bots play on their own rules. Optional settings there
# too: CORSIXTH_MP_AI_MODEL, CORSIXTH_MP_AI_DAILY_USD (default 3).
#
# A daily report to Discord at 7:00 (Europe/Prague): yesterday's games, how
# long, people and bots, and what the advice cost (corsixth_mp/daily_report.py).
# Put the webhook into the same secrets file yourself, as
#   DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
# Without it nothing is posted. --name names this server in the report
# (default: the host's name; kept from the last run).
#
# Bots that learn from expert players (corsixth_mp/learn.py): --experts lists
# their player names (kept from the last run; --experts none: nobody). While
# one of them plays, the referee saves the game at every year's end and at
# the game's end into /var/lib/corsixth/learn; every morning at 6:30 (Prague)
# the bots learn from the new saves, and the daily report says whose.
#
# Safe to run again, e.g. with the next release. Restarting the service drops
# every connected player: check that nobody is playing first.
set -euo pipefail

RELEASE=""
CODE=""
DATA=""
PORT=47800
MOTD="CorsixTH multiplayer server (with referee)"
NAME=""
EXPERTS="-"
REPO=lbakyl/CorsixTH-Multiplayer
BASE=/opt/corsixth-mp

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) RELEASE=$2; shift 2 ;;
    --code) CODE=$2; shift 2 ;;
    --data) DATA=$2; shift 2 ;;
    --port) PORT=$2; shift 2 ;;
    --motd) MOTD=$2; shift 2 ;;
    --name) NAME=$2; shift 2 ;;
    --experts) EXPERTS=$2; shift 2 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Unknown option $1 (see --help)" >&2; exit 2 ;;
  esac
done
die() { echo "ERROR: $*" >&2; exit 1; }
say() { printf '\n== %s\n' "$*"; }
[[ $(id -u) -eq 0 ]] || die "run as root, e.g. sudo bash $0 ..."
[[ "$RELEASE" =~ ^mp-(test|stable)-([0-9a-f]{7,40})$ ]] || die "--release must look like mp-test-<commit> or mp-stable-<commit>"
SHA=${BASH_REMATCH[2]}
export DEBIAN_FRONTEND=noninteractive

say "Packages: Python, git, and the libraries the game binary links against"
apt-get update -q >/dev/null
apt-get install -y -q --no-install-recommends python3 python3-venv git curl ca-certificates libgomp1 \
  libpulse0 libasound2t64 libjack-jackd2-0 libpipewire-0.3-0t64 libx11-6 libxext6 libxcursor1 \
  libxi6 libxfixes3 libxrandr2 libxss1 libgbm1 libwayland-egl1 libwayland-client0 \
  libwayland-cursor0 libdecor-0-0 >/dev/null

say "Service account corsixth"
id corsixth >/dev/null 2>&1 || useradd --system --home /var/lib/corsixth --create-home \
  --shell /usr/sbin/nologin corsixth
mkdir -p "$BASE/referee" /var/lib/corsixth/referee-work /var/lib/corsixth/learn
chown -R corsixth:corsixth /var/lib/corsixth

if [[ -n "$DATA" ]]; then
  say "Game data from $DATA"
  [[ -d "$DATA" ]] || die "no folder $DATA"
  rm -rf "$BASE/thdata" && mkdir -p "$BASE/thdata"
  cp -r "$DATA" "$BASE/thdata/themehos"
fi
[[ -d "$BASE/thdata/themehos" ]] || die "no game data yet: pass --data once"
chown -R root:corsixth "$BASE/thdata" && chmod -R u=rwX,g=rX,o= "$BASE/thdata"

say "Server code at ${CODE:-$SHA}"
if [[ ! -d "$BASE/src/.git" ]]; then git clone -q "https://github.com/$REPO.git" "$BASE/src"; fi
git -C "$BASE/src" fetch -q origin
if [[ -n "$CODE" ]]; then
  # A branch name (origin/<branch>) or a commit.
  if git -C "$BASE/src" rev-parse -q --verify "origin/$CODE" >/dev/null; then CODE="origin/$CODE"; fi
  git -C "$BASE/src" checkout -q -f "$CODE"
  git -C "$BASE/src" merge-base --is-ancestor "$SHA" HEAD || die "--code $CODE does not contain the release's commit $SHA"
else
  git -C "$BASE/src" checkout -q -f "$SHA"
fi
git -C "$BASE/src" log --oneline -1

say "Python environment for the server (the Anthropic SDK for the bots' advice)"
if [[ ! -x "$BASE/venv/bin/python" ]]; then python3 -m venv "$BASE/venv"; fi
"$BASE/venv/bin/pip" install -q --upgrade anthropic

say "Referee: the Linux package of $RELEASE"
R="$BASE/referee/$SHA"
rm -rf "$R" && mkdir -p "$R/scripts/multiplayer"
url="https://github.com/$REPO/releases/download/$RELEASE/CorsixTH-Multiplayer-$SHA-linux-x86_64.tar.gz"
curl -fsSL "$url" | tar xz -C "$R"
mv "$R/CorsixTH-Multiplayer" "$R/game"
ln -s game "$R/CorsixTH" # referee.lua loads <source>/CorsixTH/CorsixTH.lua
# The referee, and the bots (computer players) a room owner adds, if this
# release has them.
for f in referee.lua probe_builder.lua bot.lua bot_manager.lua; do
  if [[ -f "$BASE/src/scripts/multiplayer/$f" ]]; then cp "$BASE/src/scripts/multiplayer/$f" "$R/scripts/multiplayer/"; fi
done
chown -R root:corsixth "$BASE/referee" "$BASE/src" && chmod -R g+rX,o= "$BASE/referee"
missing=$(LD_LIBRARY_PATH="$R/game/lib" ldd "$R/game/corsix-th" | grep "not found" || true)
[[ -z "$missing" ]] || die "the game binary misses libraries: $missing"

say "Settings (/etc/corsixth-mp.env) and the service"
if [[ -z "$NAME" && -f /etc/corsixth-mp.env ]]; then
  NAME=$(sed -n 's/^CORSIXTH_MP_SERVER_NAME=//p' /etc/corsixth-mp.env)
fi
NAME=${NAME:-$(hostname)}
if [[ "$EXPERTS" == "-" ]]; then
  EXPERTS=$( (sed -n 's/^CORSIXTH_MP_EXPERTS=//p' /etc/corsixth-mp.env 2>/dev/null || true) | head -1)
fi
[[ "$EXPERTS" == "none" ]] && EXPERTS=""
cat > /etc/corsixth-mp.env <<EOF
# Written by setup-referee-host.sh for $RELEASE. The referee build must match
# the players' build: players of other builds are told to get this release.
CORSIXTH_MP_MOTD=$MOTD
CORSIXTH_MP_RELEASE=$RELEASE
CORSIXTH_MP_REFEREE_BINARY=$R/game/corsix-th
CORSIXTH_MP_REFEREE_SOURCE=$R
CORSIXTH_MP_REFEREE_DATA=$BASE/thdata/themehos
CORSIXTH_MP_REFEREE_LUA_CPATH=$R/game/lua/?.so
CORSIXTH_MP_REFEREE_LUA_PATH=$R/game/lua/?.lua;$R/game/lua/?/init.lua
CORSIXTH_MP_REFEREE_WORKDIR=/var/lib/corsixth/referee-work
LD_LIBRARY_PATH=$R/game/lib
CORSIXTH_MP_SERVER_NAME=$NAME
# Bots learn from these players' games (setup --experts; empty: nobody).
CORSIXTH_MP_LEARN_DIR=/var/lib/corsixth/learn
CORSIXTH_MP_EXPERTS=$EXPERTS
EOF
chmod 644 /etc/corsixth-mp.env
cat > /etc/systemd/system/corsixth-mp.service <<EOF
[Unit]
Description=CorsixTH multiplayer server (with the headless referee)
After=network-online.target
Wants=network-online.target

[Service]
User=corsixth
Group=corsixth
WorkingDirectory=$BASE/src/mp_server
EnvironmentFile=/etc/corsixth-mp.env
EnvironmentFile=-/etc/corsixth-mp-secrets.env
ExecStart=$BASE/venv/bin/python -m corsixth_mp --host 0.0.0.0 --port $PORT
Restart=on-failure
RestartSec=5
KillMode=control-group
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/corsixth
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes
LockPersonality=yes
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# The Docker server (setup-vps.sh) uses the same port: stop it.
if command -v docker >/dev/null && docker ps --format '{{.Names}}' | grep -qx corsixth-mp-server; then
  say "Stopping the Docker server (kept for going back: docker compose up -d in $BASE)"
  docker stop corsixth-mp-server >/dev/null
fi
# The daily report (posted only if DISCORD_WEBHOOK_URL is in the secrets).
cat > /etc/systemd/system/corsixth-mp-report.service <<EOF
[Unit]
Description=CorsixTH multiplayer: yesterday's games to Discord

[Service]
Type=oneshot
User=corsixth
Group=corsixth
WorkingDirectory=$BASE/src/mp_server
EnvironmentFile=/etc/corsixth-mp.env
EnvironmentFile=-/etc/corsixth-mp-secrets.env
ExecStart=$BASE/venv/bin/python -m corsixth_mp.daily_report
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
EOF
cat > /etc/systemd/system/corsixth-mp-report.timer <<EOF
[Unit]
Description=CorsixTH multiplayer: the daily report at 7:00 Prague time

[Timer]
OnCalendar=*-*-* 07:00:00 Europe/Prague
Persistent=true

[Install]
WantedBy=timers.target
EOF
# The bots learn from the night's saves of expert players, before the report.
cat > /etc/systemd/system/corsixth-mp-learn.service <<EOF
[Unit]
Description=CorsixTH multiplayer: the bots learn from expert players' saved games

[Service]
Type=oneshot
User=corsixth
Group=corsixth
WorkingDirectory=$BASE/src/mp_server
EnvironmentFile=/etc/corsixth-mp.env
ExecStart=$BASE/venv/bin/python -m corsixth_mp.learn
Nice=10
TimeoutStartSec=2h
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/corsixth
PrivateTmp=yes
EOF
cat > /etc/systemd/system/corsixth-mp-learn.timer <<EOF
[Unit]
Description=CorsixTH multiplayer: the bots learn at 6:30 Prague time

[Timer]
OnCalendar=*-*-* 06:30:00 Europe/Prague
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now corsixth-mp-report.timer >/dev/null 2>&1
systemctl enable --now corsixth-mp-learn.timer >/dev/null 2>&1
systemctl enable corsixth-mp.service >/dev/null 2>&1
systemctl restart corsixth-mp.service
sleep 2
systemctl is-active --quiet corsixth-mp.service || die "the service did not start: journalctl -u corsixth-mp"
python3 - "$PORT" <<'PY'
import socket, sys, time
# The server listens after a few seconds (eu1 2026-11-12: 3.4 s).
for attempt in range(30):
    try:
        s = socket.create_connection(("127.0.0.1", int(sys.argv[1])), 5)
        break
    except ConnectionRefusedError:
        if attempt == 29:
            raise
        time.sleep(1)
s.sendall(b"HEALTH\n")
print("   " + s.recv(200).decode().strip())
PY
# Old referee builds are not needed any more.
find "$BASE/referee" -mindepth 1 -maxdepth 1 -type d ! -name "$SHA" -exec rm -rf {} +
say "Done: the server runs $RELEASE with the referee on port $PORT"
echo "   Logs: journalctl -u corsixth-mp -f; referee logs in /var/lib/corsixth/referee-work"
if [[ -n "$EXPERTS" ]]; then
  echo "   Bots learn from: $EXPERTS (saves in /var/lib/corsixth/learn; journalctl -u corsixth-mp-learn)"
fi
