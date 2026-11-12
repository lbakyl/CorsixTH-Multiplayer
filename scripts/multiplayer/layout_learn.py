"""Room layouts from saved games, as the bots could learn them.

python3 layout_learn.py LAYOUTS.jsonl [HOSPITAL_NAME] [ROOM_KIND]

Reads the lines of layout_dump.lua and shows each room of the hospital
(by name, ARGUS by default) seen from its door: the room turned so that
its door is in the top wall, each object at (column, row) inside, its
direction turned the same way. A room's picture: '.' floor, letters the
objects (the legend under it), 'D' the door above it.
"""
import json
import sys
from collections import Counter

# Turning the room: the door's wall becomes the top one.
DIRS = ["north", "east", "south", "west"]


def door_wall(room):
    d = room.get("door")
    if not d:
        return None
    if d["dir"] == "north":
        return "north" if d["y"] == room["y"] else "south"
    return "west" if d["x"] == room["x"] else "east"


def to_door_frame(room, x, y, direction=None):
    """(column, row, direction) with the door's wall at the top (row 0 the
    row next to it), the door at its column."""
    rx, ry = x - room["x"], y - room["y"]
    w, h = room["w"], room["h"]
    wall = door_wall(room) or "north"
    if wall == "north":
        c, r, turn = rx, ry, 0
    elif wall == "south":
        c, r, turn = w - 1 - rx, h - 1 - ry, 2
    elif wall == "west":
        c, r, turn = h - 1 - ry, rx, 1
    else:  # east
        c, r, turn = ry, w - 1 - rx, 3
    if direction in DIRS:
        direction = DIRS[(DIRS.index(direction) - turn) % 4]
    return c, r, direction


def picture(room):
    wall = door_wall(room) or "north"
    w, h = (room["w"], room["h"]) if wall in ("north", "south") else (room["h"], room["w"])
    grid = [["." for _ in range(w)] for _ in range(h)]
    legend = {}
    letters = iter("ABCEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    for o in room["objects"]:
        if o["id"] in ("door", "swing_door_left", "swing_door_right"):
            continue
        c, r, d = to_door_frame(room, o["x"], o["y"], o.get("dir"))
        key = (o["id"], d)
        if key not in legend:
            legend[key] = next(letters)
        if 0 <= r < h and 0 <= c < w:
            grid[r][c] = legend[key]
    dc = 0
    if room.get("door"):
        dc, _, _ = to_door_frame(room, room["door"]["x"], room["door"]["y"])
        if wall == "south":
            dc, _, _ = to_door_frame(room, room["door"]["x"], room["door"]["y"] - 1)
        elif wall == "east":
            dc, _, _ = to_door_frame(room, room["door"]["x"] - 1, room["door"]["y"])
    top = "".join("D" if i == dc else "-" for i in range(w))
    lines = [top] + ["".join(row) for row in grid]
    keys = ", ".join(f"{v}={k[0]}({k[1]})" for k, v in legend.items())
    return lines, keys


def main():
    path = sys.argv[1]
    name = sys.argv[2] if len(sys.argv) > 2 else "ARGUS"
    kind = sys.argv[3] if len(sys.argv) > 3 else None
    seen = set()
    for line in open(path, encoding="utf-8"):
        rec = json.loads(line)
        if rec["name"] != name:
            continue
        for room in rec["rooms"]:
            if kind and room["kind"] != kind:
                continue
            sig = (room["kind"], room["x"], room["y"])
            if sig in seen:
                continue
            seen.add(sig)
            lines, keys = picture(room)
            print(f"{room['kind']} {room['w']}x{room['h']} at {room['x']},{room['y']} "
                  f"(door in the {door_wall(room)} wall)")
            for l in lines:
                print("   " + l)
            print("   " + keys)
        counts = Counter(o["id"] for o in rec["corridor"])
        print("corridor:", dict(counts))
        break


if __name__ == "__main__":
    main()
