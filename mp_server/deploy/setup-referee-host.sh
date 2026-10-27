#!/usr/bin/env bash
# Run the CorsixTH multiplayer server natively (a systemd service) with the
# headless referee, which repairs desyncs and lets a dropped player rejoin
# (docs/multiplayer/referee.md). Ubuntu or Debian; run as root (sudo).
#
#   sudo bash setup-referee-host.sh --release mp-test-c364e17a [--data DIR] [--port 47800] [--motd TEXT]
#   (a stable release is named mp-stable-<commit>)
#
# --release  a test release of lbakyl/CorsixTH-Multiplayer: its Linux package
#            is the referee, and the server code comes from the same commit.
#            The players must run that release (the build ids must match).
# --data     your Theme Hospital folder (the one with DATA, QDATA, ...), the
#            first time: it is copied to /opt/corsixth-mp/thdata, readable only
#            by the service account. It is not part of any release.
#
# Safe to run again, e.g. with the next release. Restarting the service drops
# every connected player: check that nobody is playing first.
set -euo pipefail

RELEASE=""
DATA=""
PORT=47800
MOTD="CorsixTH multiplayer server (with referee)"
REPO=lbakyl/CorsixTH-Multiplayer
BASE=/opt/corsixth-mp

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) RELEASE=$2; shift 2 ;;
    --data) DATA=$2; shift 2 ;;
    --port) PORT=$2; shift 2 ;;
    --motd) MOTD=$2; shift 2 ;;
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
apt-get install -y -q --no-install-recommends python3 git curl ca-certificates libgomp1 \
  libpulse0 libasound2t64 libjack-jackd2-0 libpipewire-0.3-0t64 libx11-6 libxext6 libxcursor1 \
  libxi6 libxfixes3 libxrandr2 libxss1 libgbm1 libwayland-egl1 libwayland-client0 \
  libwayland-cursor0 libdecor-0-0 >/dev/null

say "Service account corsixth"
id corsixth >/dev/null 2>&1 || useradd --system --home /var/lib/corsixth --create-home \
  --shell /usr/sbin/nologin corsixth
mkdir -p "$BASE/referee" /var/lib/corsixth/referee-work
chown -R corsixth:corsixth /var/lib/corsixth

if [[ -n "$DATA" ]]; then
  say "Game data from $DATA"
  [[ -d "$DATA" ]] || die "no folder $DATA"
  rm -rf "$BASE/thdata" && mkdir -p "$BASE/thdata"
  cp -r "$DATA" "$BASE/thdata/themehos"
fi
[[ -d "$BASE/thdata/themehos" ]] || die "no game data yet: pass --data once"
chown -R root:corsixth "$BASE/thdata" && chmod -R u=rwX,g=rX,o= "$BASE/thdata"

say "Server code at $SHA"
if [[ ! -d "$BASE/src/.git" ]]; then git clone -q "https://github.com/$REPO.git" "$BASE/src"; fi
git -C "$BASE/src" fetch -q origin
git -C "$BASE/src" checkout -q -f "$SHA"
git -C "$BASE/src" log --oneline -1

say "Referee: the Linux package of $RELEASE"
R="$BASE/referee/$SHA"
rm -rf "$R" && mkdir -p "$R/scripts/multiplayer"
url="https://github.com/$REPO/releases/download/$RELEASE/CorsixTH-Multiplayer-$SHA-linux-x86_64.tar.gz"
curl -fsSL "$url" | tar xz -C "$R"
mv "$R/CorsixTH-Multiplayer" "$R/game"
ln -s game "$R/CorsixTH" # referee.lua loads <source>/CorsixTH/CorsixTH.lua
# The referee, and the bots (computer players) a room owner adds, if this
# release has them.
for f in referee.lua probe_builder.lua bot.lua; do
  if [[ -f "$BASE/src/scripts/multiplayer/$f" ]]; then cp "$BASE/src/scripts/multiplayer/$f" "$R/scripts/multiplayer/"; fi
done
chown -R root:corsixth "$BASE/referee" "$BASE/src" && chmod -R g+rX,o= "$BASE/referee"
missing=$(LD_LIBRARY_PATH="$R/game/lib" ldd "$R/game/corsix-th" | grep "not found" || true)
[[ -z "$missing" ]] || die "the game binary misses libraries: $missing"

say "Settings (/etc/corsixth-mp.env) and the service"
cat > /etc/corsixth-mp.env <<EOF
# Written by setup-referee-host.sh for $RELEASE. The referee build must match
# the players' build.
CORSIXTH_MP_MOTD=$MOTD
CORSIXTH_MP_REFEREE_BINARY=$R/game/corsix-th
CORSIXTH_MP_REFEREE_SOURCE=$R
CORSIXTH_MP_REFEREE_DATA=$BASE/thdata/themehos
CORSIXTH_MP_REFEREE_LUA_CPATH=$R/game/lua/?.so
CORSIXTH_MP_REFEREE_LUA_PATH=$R/game/lua/?.lua;$R/game/lua/?/init.lua
CORSIXTH_MP_REFEREE_WORKDIR=/var/lib/corsixth/referee-work
LD_LIBRARY_PATH=$R/game/lib
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
ExecStart=/usr/bin/python3 -m corsixth_mp --host 0.0.0.0 --port $PORT
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
systemctl daemon-reload
systemctl enable corsixth-mp.service >/dev/null 2>&1
systemctl restart corsixth-mp.service
sleep 2
systemctl is-active --quiet corsixth-mp.service || die "the service did not start: journalctl -u corsixth-mp"
python3 - "$PORT" <<'PY'
import socket, sys
s = socket.create_connection(("127.0.0.1", int(sys.argv[1])), 5)
s.sendall(b"HEALTH\n")
print("   " + s.recv(200).decode().strip())
PY
# Old referee builds are not needed any more.
find "$BASE/referee" -mindepth 1 -maxdepth 1 -type d ! -name "$SHA" -exec rm -rf {} +
say "Done: the server runs $RELEASE with the referee on port $PORT"
echo "   Logs: journalctl -u corsixth-mp -f; referee logs in /var/lib/corsixth/referee-work"
