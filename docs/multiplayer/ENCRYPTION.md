# Encryption of the multiplayer connection

The connection between the game and the multiplayer server (`mp_server/`) can
be encrypted with TLS. This document says what that protects, how it works,
which files it touches, how a server gets a certificate and how to test it.
It is one self-contained change: everything here can be reviewed (or left
out) on its own.

Short version: a player's game asks the server to switch the connection to
TLS before anything else is sent (`STARTTLS`, on the same port). Room
passwords, chat and the whole game then travel encrypted. The server's
certificate is self-signed; the game remembers its fingerprint the first time
and refuses the server if it ever changes (trust on first use). Games and
servers without TLS keep working in clear, and the lobby says so.

## 1. Threat model

What it protects against:

- **Passive eavesdropping.** Somebody on the way between a player and the
  server (the Wi-Fi of a cafe, a provider) can no longer read room
  passwords, chat, player names or the game commands, and cannot see the
  saves that are sent to repair a game.
- **Passwords on the wire.** A room password (`CREATE`, `JOIN`) was sent in
  clear until now. Inside TLS it is not visible. The server still stores only
  a salted PBKDF2 hash of it (`_hash_password` in `server.py`), as before.
- **Changing the server's identity later.** After the first connection a
  different certificate at the same address is refused with a message, so a
  man in the middle who was not there the first time is noticed.

What it does **not** protect against:

- **A man in the middle on the very first connection** to a server (trust on
  first use). There is no certificate authority: the certificate is
  self-signed and the game does not check its name or chain. Whoever
  answers the first time is remembered. To close this gap, give players the
  server's fingerprint on another channel (it is in the server log and in the
  output of `setup-referee-host.sh`) or build it into the game
  (`MultiplayerTransport.PINNED`, see section 5).
- **A downgrade by an active attacker.** The game goes on in clear when the
  server answers `STARTTLS` with an error or an old server closes the
  connection, because games and servers from before this change must keep
  working. An attacker who can change the traffic can make a game talk in
  clear. The lobby shows "Not encrypted" then, and the game asks twice before
  it sends a password in clear. A player who wants no fallback sets
  `CORSIXTH_MP_TLS=require`. A server that wants no clear players sets
  `CORSIXTH_MP_TLS_REQUIRED=1` (section 6).
- **The server's operator.** The server sees everything, as it must (it
  relays the game). TLS here is between a player and the server only.
- **Other players.** What one player sends to the room is relayed to the
  others; room membership is not secret.
- **Traffic analysis.** Sizes and timing of messages are visible.
- **A compromised computer,** on either side.

The password check itself is unchanged: it is a room password to keep
strangers out, not an account login.

## 2. Protocol

Nothing changes for a client that does not ask for TLS. A client that does:

```
client                               server
  STARTTLS\n                  --->
                              <---   STARTTLS ok\n          (server has a certificate)
  (TLS handshake, client first)
  HELLO ...  (encrypted)      --->   (everything as in protocol.md)
```

If the server has no certificate it answers `ERROR code=no_tls text=...` and
the client **may go on in clear on the same connection** with `HELLO`. A
server from before this change reads `STARTTLS` as a first line that is not
`HELLO`, answers `ERROR code=expected_hello` and hangs up; the client then
connects again and starts with `HELLO` as before.

- The handshake is a normal TLS 1.2 or 1.3 handshake (the server accepts 1.2
  and newer, nothing older). The client does not verify the certificate
  chain; it takes the SHA-256 of the DER certificate and compares it with the
  remembered one (section 4).
- `HEALTH` (the container health check) stays a plain line and is answered in
  clear.
- With `CORSIXTH_MP_TLS_REQUIRED=1` a connection that starts with `HELLO` and
  not `STARTTLS` gets `ERROR code=tls_required` and is closed. The exceptions
  are connections from the server's own machine (`127.0.0.1`, `::1`): its
  bots and the headless referee connect that way, in clear (they would only
  spend CPU on encrypting what never leaves the computer).
- Lines, limits and everything else are as in `protocol.md`; TLS only wraps
  the byte stream. A saved game is one long line of hundreds of kilobytes;
  see section 7 for how the client handles that without blocking the game.

The server logs `connection N from ADDRESS (TLS)` for encrypted connections.

## 3. What is in the change (files touched)

Server (`mp_server/`, standard library only: the `ssl` module):

| File | Change |
|---|---|
| `corsixth_mp/tls.py` | new: `TlsConfig` (context, TLS 1.2 minimum, the certificate's fingerprint), settings from the environment |
| `corsixth_mp/server.py` | `_serve_connection` handles `STARTTLS` (`_starttls`, `StreamWriter.start_tls`), `tls_required`, options `--tls-cert`, `--tls-key`, `--tls-required` |
| `deploy/setup-referee-host.sh` | makes a certificate on the first run and keeps it, `--require-tls`, `--allow-clear`, prints the fingerprint |
| `compose.yaml` | passes the TLS settings to the Docker server |
| `tests/test_tls.py` | pytest, see section 8 |

Game (`CorsixTH/Lua/`):

| File | Change |
|---|---|
| `mp_transport.lua` | `require("ssl")` optional (`pcall`); the `STARTTLS` negotiation in `startJoin`/`pollJoin`/`join` (non-blocking, a state machine); trust on first use; `transport.encrypted` and `.note` |
| `mp_lobby.lua` | `lobby.encrypted` and `lobby.security_note`; the failure code of a changed certificate |
| `dialogs/resizables/multiplayer.lua` | the room list shows "Encrypted connection (TLS)" or why not; asks twice before a password goes in clear; explains a changed certificate |
| `languages/english.lua` | the new texts (other languages fall back to English) |
| `Luatest/spec/mp_transport_spec.lua` | busted test against a Lua TLS server in the same process |

Builds (LuaSec and OpenSSL ship with the game):

| File | Change |
|---|---|
| `vcpkg.json`, `CorsixTH/CMakeLists.txt` | Windows: vcpkg port `luasec` (with `openssl`); `ssl.dll`, `ssl.lua`, `libssl-3-x64.dll`, `libcrypto-3-x64.dll` are copied next to `CorsixTH.exe` and so into the install |
| `scripts/multiplayer/build_linux_package.sh`, `.github/workflows/LinuxPackage.yml` | LuaSec 1.3.2 built for Lua 5.5 (`libssl-dev` on the builder); libssl and libcrypto are bundled by the script's library copying |
| `scripts/multiplayer/build_macos_app.sh`, `.github/workflows/macOS.yml` | LuaSec built against Homebrew's `openssl@3`; `dylibbundler` also fixes `ssl.so`, which brings libssl and libcrypto into `Contents/Frameworks` |
| `scripts/multiplayer/tls_smoke.lua`, `ci_tls_smoke.sh`, the three workflows | smoke test of the built game: its own Lua does `require("ssl")`, STARTTLS and a handshake against a server |
| `scripts/multiplayer/run_lobby_probe.sh`, `lobby_probe.lua` | `MP_TLS=1`: the lobby probe with encrypted connections |

The multiplayer build id is a checksum of the game's Lua code, so a build with
this change is a different build from one without it. Players and servers
must run the same build as before; nothing else about that changes.

## 4. The game's side

**LuaSec is optional.** `mp_transport.lua` does
`pcall(require, "ssl")`. Without it (a Lua 5.1 or distribution build, or the
DLLs missing) the game connects in clear as before; `transport.note` is
`no_ssl` and the room list says "Not encrypted: this game has no LuaSec".
LuaSec works with Lua 5.1 to 5.5 and LuaJIT; 1.3.2 was tested here with 5.1,
5.4 and 5.5.

**Setting** (environment variable `CORSIXTH_MP_TLS`):

| Value | Meaning |
|---|---|
| `auto` (default) | try TLS, except to this computer (`127.0.0.1`, `::1`, `localhost`) |
| `on` | try TLS also to this computer; go on in clear if the server or this build cannot |
| `require` | only encrypted connections; fail otherwise (for tests and careful players) |
| `off` | never |

**Trust on first use.** After the handshake the game computes the SHA-256
of the server's certificate and looks up `host:port`:

1. in `MultiplayerTransport.PINNED` (fingerprints built into the game; empty
   today). A server listed there must have exactly that certificate.
2. in the file `mp_known_servers.txt` next to the game's `config.txt`
   (override: `CORSIXTH_MP_TRUST_FILE`). Lines are `host:port sha256hex`.
3. A server that is in neither is remembered (a line is appended). Any
   other certificate for a known server refuses the connection with
   "The certificate of host:port has changed" and a window that explains it:
   the server was set up again, or somebody is between the player and the
   server. If the new certificate is right, the player deletes the server's
   line from the file.

The fingerprint is of the whole certificate, not of its key: a server that
renews its certificate (even with the same key) must be trusted again by
every player. `setup-referee-host.sh` therefore makes a certificate valid
for 20 years and keeps it on every later run.

**In the lobby.** The room list's status line shows "Encrypted connection
(TLS)", or "Not encrypted: ..." with the reason (`no_ssl`, `server` for a
server without certificate or an old one). A server on the same computer
shows nothing. Pressing Join or Create with a password over a connection that
is not encrypted first shows "Not encrypted: the password goes in clear.
Press again to send." and sends only on the second press.

## 5. Deploying a certificate

`setup-referee-host.sh` does it: the first run makes an EC P-256
self-signed certificate valid for 7300 days in
`/etc/corsixth-mp-tls/server.crt` and `server.key` (owner root, group
`corsixth`, key mode 640), writes the paths into `/etc/corsixth-mp.env`, and
prints the fingerprint. Later runs keep the files. The service reads
`CORSIXTH_MP_TLS_CERT`, `CORSIXTH_MP_TLS_KEY` and `CORSIXTH_MP_TLS_REQUIRED`.
Restarting the service drops the connected players: check first, as for every
update.

By hand, or for a Docker server (set the three variables, mount the files):

```
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes \
  -days 7300 -subj "/CN=eu1.example.com" -keyout server.key -out server.crt
openssl x509 -in server.crt -noout -fingerprint -sha256
```

A certificate from a real authority (Let's Encrypt) also works, with the cert
chain in the certificate file; the game still pins its fingerprint, so it
needs a new trust entry at every renewal. A self-signed certificate that is
kept is the simpler choice here.

**Pinning a known server in the game** (so that even the first connection is
safe): add the lines to `MultiplayerTransport.PINNED` in `mp_transport.lua`:

```lua
MultiplayerTransport.PINNED = {
  ["eu1.bachelor-tech.com:47800"] = "<64 hex digits of the fingerprint>",
}
```

This is a code change, so it changes the build id; none is built in yet.

**Refusing clear players.** `--require-tls` (or `CORSIXTH_MP_TLS_REQUIRED=1`)
turns old games away with the message "This server only accepts encrypted
connections; update the game". Do it once the players have a build with this
change.

## 6. Settings summary

| Where | Name | Effect |
|---|---|---|
| server | `CORSIXTH_MP_TLS_CERT`, `--tls-cert` | certificate (PEM): enables STARTTLS |
| server | `CORSIXTH_MP_TLS_KEY`, `--tls-key` | private key (default: in the certificate file) |
| server | `CORSIXTH_MP_TLS_REQUIRED`, `--tls-required` | refuse players in clear (this machine's bots and `HEALTH` excepted); needs a certificate |
| game | `CORSIXTH_MP_TLS` | `auto`, `on`, `require`, `off` |
| game | `CORSIXTH_MP_TRUST_FILE` | the remembered fingerprints |

## 7. Large lines and the non-blocking connection

The game must never wait on the network: `send` buffers and writes what the
socket takes, `receive` returns a whole line or nothing. LuaSec's sockets
behave like LuaSocket's with one addition: a read or write that cannot go on
returns `wantread` or `wantwrite` (instead of `timeout`). The transport treats
all three as "try again next frame". A TLS write that failed that way must be
repeated with the same bytes, so the transport remembers the length it tried
(`retry_len`) and does not append what was queued meanwhile to the retry. Any
other error on an encrypted connection ends it. The busted test sends 4 MB in
four long lines (more than the socket buffer takes at once) through TLS and
checks every byte arrives. The handshake itself is also non-blocking
(`dohandshake` once per frame), so the lobby window stays alive while it runs;
the connect has a 10 second limit for the TCP connection and another 10 for
STARTTLS and the handshake.

Closing a LuaSec socket twice can crash the process; `MultiplayerTransport:close`
is idempotent for that reason.

## 8. Testing

Server (needs the `openssl` command for throwaway certificates; they are made
into temporary folders, nothing is committed):

```
cd mp_server && python3 -m pytest -q tests/test_tls.py
```

It covers: STARTTLS then HELLO and a password room, the certificate's
fingerprint, the password and room name absent from the bytes a man in the
middle sees, a server without certificate (`no_tls`, then clear on the same
connection), clear players with a certificate, `--tls-required` (refused,
except this machine and HEALTH), a failed handshake, TLS 1.1 refused, 3.6 MB
of long lines both ways, and the settings.

Game transport (Lua 5.1 busted, with LuaSocket, LuaSec and `openssl`; the
tests are skipped without):

```
cd CorsixTH/Luatest && busted spec/mp_transport_spec.lua
```

It starts a small non-blocking LuaSec server in the same process and checks
the upgrade, the remembering of the fingerprint, a changed or wrongly pinned
certificate, a server without certificate, a server that does not know
STARTTLS (second connection), `require` mode, `auto` to the local computer,
4 MB in long lines, and a closed connection.

Whole games with encrypted connections (the lobby probe starts a server with
a throwaway certificate and every player runs with `CORSIXTH_MP_TLS=require`):

```
MP_TLS=1 bash scripts/multiplayer/run_lobby_probe.sh BINARY GAME_DATA
```

Check 0 of its report says that every player's connection was encrypted and
counts the TLS connections at the server; all the other checks (IN SYNC and so
on) are the ones of the normal run.

A built game (CI runs this on the Windows, Linux and macOS builds):

```
bash scripts/multiplayer/ci_tls_smoke.sh PATH/TO/GAME_PROGRAM
```

It runs `tls_smoke.lua` with the game's own program and Lua: `require("ssl")`
must work (LuaSec and the OpenSSL libraries are there), and against a server
started with a throwaway certificate it must do STARTTLS, the handshake,
compare the fingerprint and get `WELCOME` through the encrypted connection.

## 9. Building the pieces

- **Windows:** `luasec` in `vcpkg.json` builds LuaSec 1.3.2 and OpenSSL 3 with
  the project's triplet (`x64-windows-release` and the others). CMake copies
  the module as `ssl.dll` (the port names it `lua-ssl.dll`, but Lua looks for
  `ssl.dll`), `ssl.lua` and the OpenSSL DLLs next to the program; the install
  rule already takes every `*.dll` and `*.lua` from there.
- **Linux package:** Ubuntu 24.04 builder with `libssl-dev`; LuaSec 1.3.2 is
  compiled against the Lua 5.5 headers like LuaSocket and installed in the
  package's `lua/` folder; `copy_deps` bundles `libssl.so.3` and
  `libcrypto.so.3`.
- **macOS:** `brew install openssl@3` (the workflow installs it, and so must
  anybody building by hand); `build_macos_app.sh` builds LuaSec against it and
  `dylibbundler` copies the two dylibs into the app. As with the other
  Homebrew libraries, the deployment target of the build must not be older
  than the one the Homebrew bottles were built for.
- **Debian, Ubuntu and others, with the system Lua:** `lua-sec`
  (`apt install lua-sec`, `luarocks install luasec`).
