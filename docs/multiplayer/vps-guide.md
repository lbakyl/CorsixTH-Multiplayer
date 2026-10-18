# Running the multiplayer server on a VPS

This sets up the relay and lobby server (`mp_server/`) on a Linux VPS with
Docker. Players then connect from the game: main menu, Multiplayer, server
address.

The server is small: it never runs the game, only relays messages between the
players and keeps the rooms. It needs **no Theme Hospital data** and no
CorsixTH game code.

## 1. What you need

- A Linux VPS with a public IPv4 address. 1 vCPU and 512 MB RAM are plenty
  (the container is limited to 256 MB).
- Docker Engine with the Compose plugin.
- One TCP port open to the internet; this guide uses **47800**.
- SSH access with a key (no password logins).

## 2. Install Docker

The dependable way on any distribution is Docker's own repository:
<https://docs.docker.com/engine/install/> (Debian, Ubuntu and others). It
installs Docker Engine with the Compose plugin. On Ubuntu 24.04 the
distribution's packages work too:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
docker compose version     # must print version 2 or newer
```

Debian 12's own `docker-compose` package is the old version 1; use Docker's
repository there.

## 3. Firewall

Allow only SSH and the game port. Use the VPS provider's firewall if it has
one: that is the most reliable.

**Watch out:** ports published by Docker bypass `ufw` on the same machine
(Docker writes its own iptables rules). So with `ufw` alone, every port in
the compose file is reachable whatever `ufw` says. The compose file publishes
only the game port, so that is fine here; just don't add others without
thinking about it.

## 4. Get the compose file

```bash
sudo mkdir -p /opt/corsixth-mp && cd /opt/corsixth-mp
sudo curl -fsSLo compose.yaml \
  https://raw.githubusercontent.com/lbakyl/CorsixTH-Multiplayer/mp/server-docker/mp_server/compose.yaml
```

Once the branch is merged, use `mp/dev` instead of `mp/server-docker` in that
address.

Optional settings go in `/opt/corsixth-mp/.env` (all have defaults):

```ini
# Which image to run: a branch name (/ becomes -), sha-<commit>, or latest
CORSIXTH_MP_TAG=mp-server-docker
# Port players connect to
CORSIXTH_MP_PUBLISH=47800
# Shown to players when they connect
CORSIXTH_MP_MOTD=Welcome to our hospital server
CORSIXTH_MP_LOG=INFO
# Connection limits (in total, and from one IP address)
CORSIXTH_MP_MAX_CONNECTIONS=256
CORSIXTH_MP_MAX_PER_ADDRESS=8
```

`:latest` exists once the server is merged into `mp/dev`; until then use the
branch tag above (or a `sha-...` tag from the GitHub Actions run).

## 5. Access to the image

GitHub Actions publishes the image to
`ghcr.io/lbakyl/corsixth-mp-server`. It takes its visibility from the
public repository, so `docker compose pull` works without logging in (checked
2026-10-18). If it is ever made private (GitHub, your profile, Packages,
`corsixth-mp-server`, Package settings), log in on the VPS with a personal
access token that has only `read:packages`:
`echo <token> | docker login ghcr.io -u lbakyl --password-stdin`

## 6. Start and check

```bash
cd /opt/corsixth-mp
sudo docker compose up -d
sudo docker compose ps            # STATUS should say (healthy) after a few seconds
sudo docker compose logs -f       # "listening on 0.0.0.0:47800"
```

From home, check that the port is reachable (any machine with Python and this
checkout):

```bash
python3 -m corsixth_mp.health <vps-ip> 47800    # run in mp_server/; prints "OK players=0 rooms=0"
```

## 7. Playing

- Everybody needs **the same game build**: the same commit, the same Lua
  version and the same game language. The lobby refuses a different build
  (`build_mismatch`).
  - Windows: the CI download ("Windows" workflow, artifact `CorsixTH`) of
    the commit you agreed on. It includes LuaSocket.
  - Linux: build with `scripts/multiplayer/setup_lua55_linux.sh` (Lua 5.5,
    like the Windows builds).
- In the game: main menu, **Multiplayer**, server `<vps-ip>:47800`, your
  name, Connect. One player creates a room (with a password), the others
  join it, press Ready, and the room owner starts.
- The room screen shows each player's ping and the speed the connection
  allows. Faster speeds are not offered.

## 8. Updating

```bash
cd /opt/corsixth-mp
sudo docker compose pull && sudo docker compose up -d
```

Pin a version by setting `CORSIXTH_MP_TAG=sha-<commit>` in `.env`. Players
must update their game to the matching build at the same time.

## 9. Security notes

- Traffic is plain TCP. **Room passwords travel unencrypted** until TLS is
  added (milestone S8). Never use a real password for a room.
- The container runs as an unprivileged user, with a read-only file system,
  no Linux capabilities and memory/process limits. It stores nothing.
- Keep the VPS itself updated (`unattended-upgrades` on Debian/Ubuntu) and
  use SSH keys only.
- Later, the headless referee (milestone S3) will need Theme Hospital data.
  It will come from your own copy, mounted read-only (see the comment in
  `compose.yaml`), never built into the image.

## 10. Troubleshooting

| Problem | Check |
|---|---|
| The game cannot connect | Port open in the provider's firewall? `docker compose ps` healthy? Right address and port? |
| `build_mismatch` when joining | Players run different builds or languages. Everybody uses the same CI download. |
| `busy` error | Too many connections from one address (`CORSIXTH_MP_MAX_PER_ADDRESS`). |
| The game is slow or waits for the other player | A higher ping lowers the allowed speed; the room screen shows it. |
| Players go out of sync | Both games show a message. Note the step and send the server log (`docker compose logs`). Recovery comes with milestone S4. |
