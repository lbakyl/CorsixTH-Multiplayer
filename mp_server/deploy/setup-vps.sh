#!/usr/bin/env bash
# One-command setup of the CorsixTH multiplayer server on a Debian or Ubuntu
# VPS. Run as root (or with sudo). Safe to run again: it updates the server.
#
#   curl -fsSLO https://raw.githubusercontent.com/lbakyl/CorsixTH-Multiplayer/master/mp_server/deploy/setup-vps.sh
#   sudo bash setup-vps.sh [options]
#
# Options:
#   --port N        port players connect to (default 47800)
#   --tag TAG       server image tag (default latest, built from master; e.g. sha-1234abc)
#   --ref REF       git branch/commit to take compose.yaml from (default master)
#   --motd TEXT     message shown to players when they connect
#   --ufw           also set up the ufw firewall: allow SSH and the game port only
#   --dir DIR       install directory (default /opt/corsixth-mp)
#
# What it does: installs Docker Engine with the Compose plugin from Docker's
# repository (if missing), optionally configures ufw, writes DIR/compose.yaml
# and DIR/.env, pulls and starts the container, waits until it is healthy,
# and prints the address players use. See docs/multiplayer/vps-guide.md.
set -euo pipefail

PORT=47800
TAG=latest
REF=master
MOTD=""
UFW=0
DIR=/opt/corsixth-mp
REPO=lbakyl/CorsixTH-Multiplayer

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port) PORT=$2; shift 2 ;;
    --tag) TAG=$2; shift 2 ;;
    --ref) REF=$2; shift 2 ;;
    --motd) MOTD=$2; shift 2 ;;
    --ufw) UFW=1; shift ;;
    --dir) DIR=$2; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "Unknown option $1 (see --help)" >&2; exit 2 ;;
  esac
done

say() { printf '\n== %s\n' "$*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

[[ $(id -u) -eq 0 ]] || die "run as root, e.g. sudo bash $0"
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) || die "invalid --port $PORT"
[[ -r /etc/os-release ]] || die "cannot read /etc/os-release"
. /etc/os-release
case "${ID:-}" in
  debian|ubuntu) ;;
  *) die "this script supports Debian and Ubuntu (found ${ID:-unknown}); see docs/multiplayer/vps-guide.md" ;;
esac
export DEBIAN_FRONTEND=noninteractive

install_docker() {
  say "Installing Docker Engine and the Compose plugin from download.docker.com"
  apt-get update -q
  apt-get install -y -q ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -q
  apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

if docker compose version >/dev/null 2>&1; then
  say "Docker with Compose is already installed: $(docker compose version)"
else
  install_docker
fi
command -v curl >/dev/null || apt-get install -y -q curl

if (( UFW )); then
  say "Configuring ufw: SSH and the game port only"
  command -v ufw >/dev/null || apt-get install -y -q ufw
  # Keep every port sshd listens on open, so this cannot lock you out.
  ssh_ports=$(sshd -T 2>/dev/null | awk '$1 == "port" {print $2}' | sort -u)
  [[ -n "$ssh_ports" ]] || ssh_ports=22
  for p in $ssh_ports; do ufw allow "${p}/tcp" comment "SSH" >/dev/null; done
  ufw allow "${PORT}/tcp" comment "CorsixTH multiplayer" >/dev/null
  ufw --force enable >/dev/null
  ufw status verbose | sed 's/^/   /'
  echo "   Note: ports published by Docker bypass ufw; the compose file publishes only ${PORT}."
fi

say "Writing ${DIR}/compose.yaml and ${DIR}/.env"
mkdir -p "$DIR"
curl -fsSL "https://raw.githubusercontent.com/${REPO}/${REF}/mp_server/compose.yaml" -o "${DIR}/compose.yaml.new"
grep -q "corsixth-mp-server" "${DIR}/compose.yaml.new" || die "downloaded compose.yaml looks wrong"
mv "${DIR}/compose.yaml.new" "${DIR}/compose.yaml"
umask 077
{
  echo "# Written by setup-vps.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ); edit and run 'docker compose up -d'."
  echo "CORSIXTH_MP_TAG=${TAG}"
  echo "CORSIXTH_MP_PUBLISH=${PORT}"
  echo "CORSIXTH_MP_MOTD=${MOTD}"
  echo "CORSIXTH_MP_LOG=INFO"
} > "${DIR}/.env"

say "Pulling and starting the server (image tag ${TAG})"
cd "$DIR"
docker compose pull -q
docker compose up -d --remove-orphans

say "Waiting for the health check"
status=""
for _ in $(seq 1 30); do
  status=$(docker inspect -f '{{.State.Health.Status}}' corsixth-mp-server 2>/dev/null || true)
  [[ "$status" == healthy ]] && break
  sleep 2
done
if [[ "$status" != healthy ]]; then
  docker compose logs --tail 20
  die "the server did not become healthy (status: ${status:-none})"
fi
docker exec corsixth-mp-server python -m corsixth_mp.health | sed 's/^/   /'

# IPv4 addresses of real interfaces (not Docker's bridges).
addresses=$(ip -4 -o addr show scope global 2>/dev/null |
  awk '$2 !~ /^(docker|br-|veth)/ {split($4, a, "/"); print a[1]}' | head -3 | tr '\n' ' ')
say "Done. The server is running."
echo "   Players connect with: <this VPS's public IP>:${PORT}"
echo "   Addresses of this machine: ${addresses:-unknown} (behind NAT the public IP may differ)"
echo "   Logs:    cd ${DIR} && docker compose logs -f"
echo "   Update:  cd ${DIR} && docker compose pull && docker compose up -d"
echo "   Stop:    cd ${DIR} && docker compose down"
(( UFW )) || echo "   Firewall: not changed. Open TCP ${PORT} in the provider's firewall (or rerun with --ufw)."
