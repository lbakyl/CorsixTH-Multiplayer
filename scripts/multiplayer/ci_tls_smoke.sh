#!/usr/bin/env bash
# Smoke test of a built game's encryption (docs/multiplayer/ENCRYPTION.md),
# for the CI builds of Windows, Linux and macOS:
#
#   bash scripts/multiplayer/ci_tls_smoke.sh COMMAND [ARGS...]
#
# COMMAND is how the built game is started (its program, or the Linux
# launcher script); the arguments for scripts/multiplayer/tls_smoke.lua are
# added. Extra arguments for it (macOS: --resources=DIR) go into SMOKE_ARGS.
# It makes a throwaway certificate (openssl command), starts the multiplayer
# server with it, and lets the game's own Lua do require("ssl"), STARTTLS, the
# handshake and HELLO against it. Exit code 0 only if "TLS SMOKE OK" came.
# Python 3.11 or newer is needed for the server; with an older one only the
# require("ssl") part runs.
set -euo pipefail
src=$(cd "$(dirname "$0")/../.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/corsixth-tls-smoke.XXXXXXXX")
# Paths for programs of the platform (Git Bash on Windows turns /d/a/... into D:/a/...).
native() { if command -v cygpath > /dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
out=$work/smoke.txt
: > "$out"
server_pid=""
cleanup() { [[ -n "$server_pid" ]] && kill "$server_pid" 2> /dev/null || true; }
trap cleanup EXIT

py=""
for candidate in python3.13 python3.12 python3.11 python3 python; do
  if command -v "$candidate" > /dev/null &&
     "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2> /dev/null; then
    py=$candidate; break
  fi
done

server_args=()
if [[ -n "$py" ]] && command -v openssl > /dev/null; then
  openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 2 -subj /CN=smoke \
    -keyout "$work/tls.key" -out "$work/tls.crt" > /dev/null 2>&1
  fingerprint=$(openssl x509 -in "$work/tls.crt" -noout -fingerprint -sha256 | sed 's/^.*=//; s/://g')
  port=$((47900 + RANDOM % 90))
  (cd "$src/mp_server" && exec "$py" -m corsixth_mp --host 127.0.0.1 --port "$port" \
    --tls-cert "$(native "$work/tls.crt")" --tls-key "$(native "$work/tls.key")") > "$work/server.log" 2>&1 &
  server_pid=$!
  for _ in $(seq 50); do grep -q listening "$work/server.log" 2> /dev/null && break; sleep 0.2; done
  server_args=("--server=127.0.0.1:$port" "--fingerprint=$fingerprint")
else
  echo "No Python 3.11 or openssl command: only checking require(\"ssl\")"
fi

export SDL_VIDEODRIVER=dummy SDL_AUDIO_DRIVER=dummy SDL_RENDER_DRIVER=software
# (Not quoted: SMOKE_ARGS is a few words.)
# shellcheck disable=SC2086
"$@" "--interpreter=$(native "$src")/scripts/multiplayer/tls_smoke.lua" "--out=$(native "$out")" ${server_args[@]+"${server_args[@]}"} \
  ${SMOKE_ARGS:-} || true
sleep 1
echo "---- smoke output"; cat "$out"
if [[ -n "$server_pid" ]]; then echo "---- server log"; cat "$work/server.log"; fi
grep -q "TLS SMOKE OK" "$out"
if [[ -n "$server_pid" ]]; then
  grep -q "TLS SMOKE server: WELCOME" "$out"
  grep -q "(TLS)" "$work/server.log"
fi
echo "TLS smoke test passed"
