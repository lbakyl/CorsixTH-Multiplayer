"""Compare two hourly fingerprint files (sync_probe.lua MP_OUT output).

Usage: python3 scripts/multiplayer/compare_fingerprints.py A.txt B.txt

Prints IDENTICAL, or the first game hour where they differ and both lines.
Lines may end in CRLF (Windows); that is ignored. Exit code 0 if identical
over the common length and both files have the same length.
"""

import sys


def main() -> int:
    a = open(sys.argv[1], encoding="utf-8", errors="replace").read().splitlines()
    b = open(sys.argv[2], encoding="utf-8", errors="replace").read().splitlines()
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            print(f"DIFFERENT from game hour {i + 1} ({len(a)} vs {len(b)} hours)")
            print("  A:", x[:200])
            print("  B:", y[:200])
            return 1
    if len(a) != len(b):
        print(f"Same for the first {min(len(a), len(b))} hours, but lengths differ: {len(a)} vs {len(b)}")
        return 1
    print(f"IDENTICAL for {len(a)} game hours")
    return 0


if __name__ == "__main__":
    sys.exit(main())
