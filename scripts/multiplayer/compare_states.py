#!/usr/bin/env python3
"""Who was in a different place, or doing something else, at a desync?

Usage: python3 scripts/multiplayer/compare_states.py SERVER_LOG [ROOM]
       journalctl -u corsixth-mp | python3 scripts/multiplayer/compare_states.py - [ROOM]

After a desync every game sends its state to the server log ("state of
'<player>' ... part N: ..."), ending with what it looked like at the desync
step itself ("AT STEP <n>: h1 bal=... tx[...]; <id>:<class>@x,y <action>>tx,ty;
..."; MultiplayerSession.stepDetail). That step is the same in every report, so
this lists the lines in which a game differs from the referee's (or the first
player's): the hospitals' last money transactions, and every person whose
tile, action or target differs. With several desyncs in the log, the last one
of the room is used.
"""

import re
import sys


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    text = sys.stdin.read() if sys.argv[1] == "-" else open(sys.argv[1], errors="replace").read()
    room = sys.argv[2] if len(sys.argv) > 2 else None
    states = {}  # player -> {step, parts}
    pattern = re.compile(r"room ['\"](.+?)['\"]: state of '(.+?)' \(player \d+\) at step (\d+), part (\d+): (.*)")
    for match in pattern.finditer(text):
        name, who, step, part, body = match.groups()
        if room and name != room:
            continue
        state = states.get(who)
        if not state or (int(step) > state["step"] and int(part) == 1):
            state = states[who] = {"step": int(step), "parts": {}}
        state["parts"][int(part)] = body
    details = {}
    for who, state in states.items():
        full = "".join(state["parts"][k] for k in sorted(state["parts"]))
        head, sep, rest = full.partition("; AT STEP ")
        if not sep:
            continue
        step, _, body = rest.partition(": ")
        lines = [x.strip() for x in re.split(r";\s*", body) if x.strip()]
        keyed = {}
        for line in lines:
            key = line.split(" ", 1)[0] if line.startswith("h") else line.split(":", 1)[0]
            keyed[key] = line
        details[who] = (step, keyed)
    if not details:
        print("no 'AT STEP' records in the log (a game from before they were sent?)")
        return 1
    for who, (step, keyed) in sorted(details.items()):
        print(f"{who}: step {step}, {len(keyed)} lines")
    base = "referee" if "referee" in details else sorted(details)[0]
    for who in sorted(details):
        if who == base:
            continue
        a, b = details[base][1], details[who][1]
        if details[base][0] != details[who][0]:
            print(f"\n{who}: at step {details[who][0]}, {base} at {details[base][0]} (not comparable)")
            continue
        diff = []
        for key in sorted(set(a) | set(b), key=lambda k: (len(k), k)):
            if a.get(key) != b.get(key):
                diff.append(f"  {base}: {a.get(key, '(none)')}\n  {who}: {b.get(key, '(none)')}")
        print(f"\n{who} against {base}: " + ("the same" if not diff else f"{len(diff)} differ"))
        for line in diff[:40]:
            print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
