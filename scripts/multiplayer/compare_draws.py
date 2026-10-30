#!/usr/bin/env python3
"""Where did one game draw a random number the others did not?

Usage: python3 scripts/multiplayer/compare_draws.py SERVER_LOG [ROOM]
       journalctl -u corsixth-mp | python3 scripts/multiplayer/compare_draws.py - [ROOM]

After a desync every game sends its state to the server log ("state of
'<player>' ... part N: ..."), and its last random draws ("random <n> draws,
the last <k>: <step> <file>:<line> [xN], ..."; MultiplayerSession.randomDraws).
This puts each game's parts together and shows how the draw lists differ from
the referee's (or the first player's): the extra or missing draw names the
line that drew a number in one game only. With several desyncs in the log, the
last one of the room is used.
"""

import difflib
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
    journals = {}
    for who, state in states.items():
        full = "".join(state["parts"][k] for k in sorted(state["parts"]))
        full = full.split("; AT STEP ")[0]  # (compare_states.py reads that part)
        at = full.find("random ")
        if at < 0:
            continue
        head, _, rest = full[at:].partition(": ")
        journals[who] = (head, [x.strip() for x in rest.split(",") if x.strip()])
    if not journals:
        print("no random draw lists in the log (a game from before they were sent?)")
        return 1
    for who, (head, _) in sorted(journals.items()):
        print(f"{who}: {head}")
    base = "referee" if "referee" in journals else sorted(journals)[0]
    for who in sorted(journals):
        if who == base:
            continue
        diff = list(difflib.unified_diff(journals[base][1], journals[who][1], base, who, n=1, lineterm=""))
        print(f"\n{who} against {base}: " + ("the same" if not diff else ""))
        for line in diff:
            print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main())
