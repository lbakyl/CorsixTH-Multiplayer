# Setting up your own multiplayer server (with the referee)

This guide sets up a server like `eu1.bachelor-tech.com` and
`eu2.bachelor-tech.com`: the lobby where players make and join rooms, plus
the **referee**, a copy of every game that runs on the server. The referee
repairs games that get out of sync within a moment, lets a player whose game
crashed join again, and runs the computer players (bots). One script does
the whole installation.

You need to be comfortable with typing commands into an SSH session. It
takes about 15 minutes.

## 1. What you need

- **A Linux server (VPS)** with a public IPv4 address, from any provider
  (Hetzner, OVH, DigitalOcean, ...):
  - **Ubuntu 24.04 or newer**, or **Debian 13**, on a normal **x86_64** (Intel or
    AMD) machine. ARM servers do not work: the referee is the game's Linux
    x86_64 build.
  - **2 CPU cores and 2 GB of memory** are enough for a few rooms at once
    (each running game uses about 80 MB on the server, a bot about the same).
  - **20 GB of disk** is plenty.
- **SSH access** with sudo rights (the provider tells you how; use an SSH key,
  not a password).
- **Your own copy of Theme Hospital** (the full game, not the demo). The
  referee plays the game too, so the server needs the game files. They are not
  part of any download here and must not be shared publicly.
- **The same edition of Theme Hospital as your players.** The server turns
  away players whose game files differ from its own, because different
  editions make games drift out of sync. eu1 and eu2 use the **GOG** edition;
  if your players also play on eu1/eu2, use GOG too.

## 2. Firewall and security

### Open only SSH and the game port

Players connect on **TCP port 47800** (you can pick another one, see step 5).

- If your provider has a firewall in its web control panel (Hetzner, OVH,
  ...), allow incoming **TCP 22** (SSH) and **TCP 47800** there. This is the
  most reliable way.
- Or, on the server itself with `ufw` (check that SSH stays open, or you lock
  yourself out):

```bash
sudo ufw allow 22/tcp
sudo ufw allow 47800/tcp
sudo ufw enable
```

### Block repeated failed SSH logins (fail2ban)

Any server on the internet gets thousands of password guesses on SSH (port
22) a day. **fail2ban** watches the SSH log and blocks an address on port 22
for an hour after 5 failed logins within 10 minutes. eu1 and eu2 run exactly
this setup.

Install it and write its settings:

```bash
sudo apt-get update
sudo apt-get install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd
# Never block these (optional): your own address, e.g. 203.0.113.7
# ignoreip = 127.0.0.1/8 ::1 203.0.113.7

[sshd]
enabled = true
port = ssh
EOF
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

If your SSH runs on another port than 22, write that number instead of `ssh`
in `port = ssh`.

Check that it watches SSH (it may take a few seconds after the restart):

```bash
sudo fail2ban-client status sshd
```

It shows `Currently failed`, `Total banned` and the blocked addresses. On a
new server the numbers grow within hours. It works together with `ufw` and
with the provider's firewall.

If you block yourself (5 wrong passwords or keys in 10 minutes), wait an hour,
or log in from another network or through the provider's web console and
unblock your address:

```bash
sudo fail2ban-client set sshd unbanip 203.0.113.7
```

Two more good habits: log in with an SSH key, not a password, and keep the
server updated (`sudo apt update && sudo apt upgrade`).

## 3. Copy your Theme Hospital files to the server

Find the folder with the game files: it has the folders **DATA**, **QDATA**,
**LEVELS** and **SOUND** inside. It is the folder you chose when CorsixTH first
asked where Theme Hospital is.

- GOG on a Mac: `/Applications/Theme Hospital.app/Contents/Resources/game`
- GOG on Windows: inside the folder GOG installed the game into (for example
  `C:\GOG Games\Theme Hospital`); look for the folder with DATA and QDATA in it.

Copy that whole folder to your home folder on the server and call it
`themehos`. From a Mac (Terminal) or Windows (PowerShell), replace the folder
and the server address with yours:

```bash
scp -r "/Applications/Theme Hospital.app/Contents/Resources/game" you@your.server:themehos
```

Check on the server that it arrived (you should see DATA, QDATA, LEVELS, ...):

```bash
ls ~/themehos
```

## 4. Pick the game version

Every player and the server must run **the same release**. Open the releases
page: <https://github.com/lbakyl/CorsixTH-Multiplayer/releases>

- **Stable** releases are called `mp-stable-<number>` (the one marked
  *Latest*). eu1 runs the newest stable one.
- **Test** releases are called `mp-test-<number>` (marked *Pre-release*). eu2
  runs the newest test one.

Note the name of the release you want, for example `mp-stable-ee780da1`.
Your players download the same release for Windows, Mac or Linux.

## 5. Install the server

Log in to the server with SSH and run these two commands. Replace the
release name, and the welcome text (`--motd`, shown to players when they
connect) with your own:

```bash
curl -fsSLO https://raw.githubusercontent.com/lbakyl/CorsixTH-Multiplayer/master/mp_server/deploy/setup-referee-host.sh
sudo bash setup-referee-host.sh --release mp-stable-ee780da1 --data ~/themehos --motd "Welcome to my CorsixTH server"
```

Add `--port 47900` if you want another port than 47800 (then open that one in
step 2 instead).

The script installs what the server needs, makes a service account
`corsixth`, copies your game files to `/opt/corsixth-mp/thdata` (readable only
by that account), downloads the server code and the game for the referee,
and starts the server as a system service that also starts by itself after a
reboot. It ends with:

```
== Done: the server runs mp-stable-ee780da1 with the referee on port 47800
```

Once it says Done, you can delete your copy in `~/themehos` if you like
(`rm -rf ~/themehos`); the server keeps its own.

## 6. Check that it works

Look at the server's log:

```bash
sudo journalctl -u corsixth-mp -n 30
```

You should see these lines (the numbers differ):

```
headless referee enabled: /opt/corsixth-mp/referee/.../game/corsix-th
players must have build 8f59465a (mp-stable-ee780da1)
players must have Theme Hospital data 899c66d0
```

`899c66d0` means the GOG edition. Another number means another edition: then
only players with that edition can play on your server.

Then try it from the game: main menu, **Multiplayer**, type your server's
address with the port into the address box (for example
`203.0.113.25:47800`, or a name like `play.example.com:47800` if you have a
domain pointing at the server), your name, **Connect**. Make a room, click an
empty place to add a bot, and start: if the bot plays along, the referee
works.

To watch the log live while people play: `sudo journalctl -u corsixth-mp -f`
(Ctrl+C to stop watching).

## 7. Updating to a new release

When a new release comes out, run the script again with its name, **without
`--data`** (the server keeps the game files from the first time):

```bash
curl -fsSLO https://raw.githubusercontent.com/lbakyl/CorsixTH-Multiplayer/master/mp_server/deploy/setup-referee-host.sh
sudo bash setup-referee-host.sh --release mp-stable-NEWNUMBER --motd "Welcome to my CorsixTH server"
```

- **Updating restarts the server and drops everybody who is playing.** Check
  that nobody is in a game first (the log shows the rooms).
- After the update, players with the old version are told which release to
  download, with a link.
- **Never** pass `--data /opt/corsixth-mp/thdata/...`: the script empties that
  folder first, and your game files would be gone. To change the game files,
  copy them to `~/themehos` again as in step 3 and pass `--data ~/themehos`.

## 8. Everyday commands

| What | Command |
|---|---|
| Is it running? | `systemctl status corsixth-mp` |
| Last 50 log lines | `sudo journalctl -u corsixth-mp -n 50` |
| Watch the log | `sudo journalctl -u corsixth-mp -f` |
| Restart (drops players) | `sudo systemctl restart corsixth-mp` |
| Stop | `sudo systemctl stop corsixth-mp` |
| Addresses blocked by fail2ban | `sudo fail2ban-client status sshd` |
| Settings (welcome text, release) | `/etc/corsixth-mp.env` (restart after a change) |
| One game's referee log | `/var/lib/corsixth/referee-work/<room>-<number>/referee.log` |

## 9. When something goes wrong

- **The game cannot connect at all:** the port is closed. Check the
  provider's firewall and `ufw` (step 2), and that the service runs
  (`systemctl status corsixth-mp`).
- **"Other game version: get ... on GitHub":** the player's game is not the
  release the server runs. They download the release it names.
- **"Your Theme Hospital files differ from this server's":** the player's
  edition differs from the server's (step 1). They need the same edition, for
  example GOG; the game then explains how to point CorsixTH at it.
- **The script stops with "the game binary misses libraries":** the server
  is not Ubuntu 24.04+/Debian 13, or not x86_64.
- **The log says "referee build ... differs":** the server code and the
  referee are from different releases; run the script again with one
  `--release`.
- **A game got out of sync:** the referee repairs it by itself within a
  moment; the log shows `state of ...` lines about it. If you want the cause
  found, send those log lines to the maintainers.

## 10. Good to know

- Passwords and game traffic are **not encrypted**. Room passwords only keep
  strangers out of a room; do not use a password you use anywhere else.
- Keep the server updated (`sudo apt update && sudo apt upgrade`), log in
  with SSH keys only, and keep fail2ban on (step 2).
- Without a referee, a lighter server without game files exists too (Docker,
  `vps-guide.md`), but there a game that gets out of sync ends, a player who
  left cannot come back, and there are no bots. The technical details of the
  referee are in `referee.md`.
