# CorsixTH multiplayer server

Relay and lobby for the experimental multiplayer mode: rooms with passwords,
a game-build check, ping measurement with a recommended game speed, the start
handshake (seed, level, settings, player numbers), relaying of the lockstep
messages, fingerprint comparison, shared speed/pause and leave handling.
Protocol: `docs/multiplayer/protocol.md`.

Standard library only (Python 3.11+).

```bash
python3 -m corsixth_mp --port 47800          # run
python3 -m pytest -q                          # tests (needs pytest)
docker build -t corsixth-mp-server mp_server  # container
docker run -p 47800:47800 corsixth-mp-server
```

Environment variables: `CORSIXTH_MP_HOST`, `CORSIXTH_MP_PORT`,
`CORSIXTH_MP_MOTD`, `CORSIXTH_MP_LOG` (log level).

Traffic is plain TCP unless the server has a certificate
(`CORSIXTH_MP_TLS_CERT`, `CORSIXTH_MP_TLS_KEY`): then players that ask for it
(`STARTTLS` as the first line) get TLS on the same port; see
docs/multiplayer/ENCRYPTION.md. In clear, room passwords travel unencrypted;
don't reuse a real password for a room.
