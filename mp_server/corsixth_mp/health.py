"""Health check for the server: python -m corsixth_mp.health [host] [port]

Connects, sends HEALTH and expects an OK line. Exit code 0 if the server
answered, 1 otherwise. Used by the container HEALTHCHECK.
"""

import os
import socket
import sys


def main() -> int:
    host = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else int(os.environ.get("CORSIXTH_MP_PORT", "47800"))
    try:
        with socket.create_connection((host, port), timeout=3) as s:
            s.sendall(b"HEALTH\n")
            reply = s.makefile("rb").readline().decode("utf-8", "replace").strip()
    except OSError as exc:
        print(f"unhealthy: {exc}")
        return 1
    print(reply)
    return 0 if reply.startswith("OK") else 1


if __name__ == "__main__":
    sys.exit(main())
