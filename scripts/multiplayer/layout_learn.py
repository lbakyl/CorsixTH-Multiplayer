"""Room layouts from saved games, and what the bots learn from them.

Show the rooms of one hospital seen from their doors:
  python3 layout_learn.py LAYOUTS.jsonl [HOSPITAL_NAME] [ROOM_KIND]

Learn from expert players (bot.lua reads OUT.lua, MP_BOT_LEARNED):
  python3 layout_learn.py --learn OUT.lua --experts ARGUS[,NAME...] \\
      [--summary SUMMARY.json] LAYOUTS.jsonl [LAYOUTS.jsonl ...]

LAYOUTS are the lines of layout_dump.lua (one hospital each). A room is
seen from its door: turned so that the door is in the top wall (the frame:
W tiles wide along the door's wall, D deep), each object by the tiles it
stands on, (column, row) inside, its direction turned the same way. In a
picture '.' is floor, letters are objects (the legend under it) and 'D' the
door above it.

What is learnt, from the hospitals named like an expert (any case) that no
bot played (the room's own bot or a stand-in for a person who left):
- recipes: for each kind of room the size the experts build most and the
  layout they use most at that size (mirrored so that the door is in the
  left half; a bot mirrors it back to its own door), with how often it was
  seen;
- plans: for each level, map size, number of hospitals and hospital place
  an expert played, every room of theirs (kind, corner, size, door, layout)
  from their latest game there, and what stands in their corridors;
- corridor habits: how far apart their radiators and plants stand (the
  tiles to the nearest one of the same kind; a quarter of them are closer),
  so that a bot keeps its own apart as much; and where each kind of
  corridor object stands by a room's door and by a reception desk, seen
  from the door (the room turned so that the door's wall is at the top: the
  corridor above it, row -1 the tiles along the wall) or from the desk
  (turned so that it faces north), with how often, so that a bot puts its
  own there first.
"""
import json
import os
import sys
from collections import Counter, defaultdict

DIRS = ["north", "east", "south", "west"]
# Turns (clockwise quarter turns) that bring each door wall to the top.
ROT = {"north": 0, "west": 1, "south": 2, "east": 3}
DOORS = ("door", "swing_door_left", "swing_door_right")


def is_fixture(object_id):
    """Doors, the entrances and rat holes: part of the building, not bought."""
    return object_id in DOORS or object_id.startswith("entrance") or object_id == "rathole"


def door_wall(room):
    d = room.get("door")
    if not d:
        return None
    if d["dir"] == "north":
        return "north" if d["y"] == room["y"] else "south"
    return "west" if d["x"] == room["x"] else "east"


def frame_size(room):
    """(W, D): the door wall's length and the room's depth from it."""
    wall = door_wall(room) or "north"
    return (room["w"], room["h"]) if wall in ("north", "south") else (room["h"], room["w"])


def door_col(room):
    """The door's column in the frame."""
    d, wall = room["door"], door_wall(room)
    x, y, w, h = room["x"], room["y"], room["w"], room["h"]
    if wall == "north":
        return d["x"] - x
    if wall == "south":
        return w - 1 - (d["x"] - x)
    if wall == "west":
        return h - 1 - (d["y"] - y)
    return d["y"] - y


def to_frame(room, x, y):
    """A map tile inside the room as (column, row) in its frame."""
    rx, ry = x - room["x"], y - room["y"]
    w, h = room["w"], room["h"]
    wall = door_wall(room) or "north"
    if wall == "north":
        return rx, ry
    if wall == "south":
        return w - 1 - rx, h - 1 - ry
    if wall == "west":
        return h - 1 - ry, rx
    return ry, w - 1 - rx


def frame_dir(room, direction):
    if direction not in DIRS:
        return direction
    return DIRS[(DIRS.index(direction) + ROT[door_wall(room) or "north"]) % 4]


def mirrored(objects, width):
    """The layout mirrored left to right in a frame `width` wide."""
    swap = {"east": "west", "west": "east"}
    out = []
    for o in objects:
        out.append({"id": o["id"], "dir": swap.get(o["dir"], o["dir"]),
                    "tiles": sorted([width - 1 - c, r] for c, r in o["tiles"])})
    return sorted(out, key=lambda o: (o["id"], o["tiles"], o["dir"]))


def frame_layout(room):
    """(W, D, door column, objects in the frame) of a room with a door."""
    W, D = frame_size(room)
    objects = []
    for o in room["objects"]:
        if o["id"] in DOORS:
            continue
        tiles = o.get("tiles") or [[o["x"], o["y"]]]
        objects.append({"id": o["id"], "dir": frame_dir(room, o.get("dir")),
                        "tiles": sorted(list(to_frame(room, tx, ty)) for tx, ty in tiles)})
    objects.sort(key=lambda o: (o["id"], o["tiles"], o["dir"]))
    return W, D, door_col(room), objects


def canonical(W, col, objects):
    """Door in the left half (or the middle): mirror the layout if needed."""
    if col > W - 1 - col:
        return W - 1 - col, mirrored(objects, W)
    return col, objects


def picture(W, D, col, objects):
    grid = [["." for _ in range(W)] for _ in range(D)]
    legend = {}
    letters = iter("ABCEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    for o in objects:
        key = (o["id"], o["dir"])
        if key not in legend:
            legend[key] = next(letters, "?")
        for c, r in o["tiles"]:
            if 0 <= r < D and 0 <= c < W:
                grid[r][c] = legend[key]
    top = "".join("D" if i == col else "-" for i in range(W))
    keys = ", ".join(f"{v}={k[0]}({k[1]})" for k, v in legend.items())
    return [top] + ["".join(row) for row in grid], keys


def read_layouts(paths):
    for path in paths:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    yield json.loads(line)


def show(path, name="ARGUS", kind=None):
    seen = set()
    for rec in read_layouts([path]):
        if rec["name"] != name:
            continue
        for room in rec["rooms"]:
            if (kind and room["kind"] != kind) or not room.get("door"):
                continue
            sig = (room["kind"], room["x"], room["y"])
            if sig in seen:
                continue
            seen.add(sig)
            W, D, col, objects = frame_layout(room)
            lines, keys = picture(W, D, col, objects)
            print(f"{room['kind']} {room['w']}x{room['h']} at {room['x']},{room['y']} "
                  f"(door in the {door_wall(room)} wall; seen from it {W} wide, {D} deep)")
            for l in lines:
                print("   " + l)
            print("   " + keys)
        print("corridor:", dict(Counter(o["id"] for o in rec["corridor"] if not is_fixture(o["id"]))))
        break


def plan_key(rec):
    """Which plan a hospital's layout is: level, map size, hospitals, place."""
    w, h = rec["map"]
    return f"{rec['level']}/{w}x{h}/{rec['hospitals']}/{rec['index']}"


def date_key(date):
    """'4-01-01T00' as a sortable tuple."""
    try:
        day, hour = date.split("T")
        y, m, d = (int(v) for v in day.split("-"))
        return (y, m, d, int(hour))
    except ValueError:
        return (0, 0, 0, 0)


def nearest_gaps(items, kind):
    """For each object of `kind`, the tiles to the nearest other one (the
    larger of the two distances along the axes)."""
    pts = [(o["x"], o["y"]) for o in items if o["id"] == kind]
    if len(pts) < 2:
        return []
    return [min(max(abs(x - a), abs(y - b)) for j, (a, b) in enumerate(pts) if j != i)
            for i, (x, y) in enumerate(pts)]


# How far from a door or desk its corridor objects are looked at: columns
# to either side, rows out from the door's wall; tiles around a desk.
DOOR_COLS, DOOR_ROWS, DESK_R = 5, 6, 5
# Turns (clockwise quarter turns) that bring a desk's facing to north.
DESK_ROT = {"north": 0, "east": 3, "south": 2, "west": 1}


def single_tile(o):
    return len(o.get("tiles") or [[o["x"], o["y"]]]) == 1


def turn(x, y, k):
    """(x, y) turned k quarter turns clockwise (y grows down the map)."""
    for _ in range(k % 4):
        x, y = -y, x
    return x, y


def near_spots(recs):
    """Where the experts' one-tile corridor objects stand by room doors
    and reception desks, seen from the door or desk: per kind, each spot
    seen at least twice, the most seen first."""
    door, desk = Counter(), Counter()
    doors = desks = 0
    for rec in recs:
        items = [o for o in rec["corridor"]
                 if not is_fixture(o["id"]) and o["id"] != "litter" and single_tile(o)]
        for room in rec.get("rooms", []):
            if not (room.get("built") and room.get("door")):
                continue
            doors += 1
            col = door_col(room)
            for o in items:
                c, r = to_frame(room, o["x"], o["y"])
                if -DOOR_ROWS <= r <= -1 and abs(c - col) <= DOOR_COLS:
                    door[(o["id"], c - col, r, frame_dir(room, o.get("dir")))] += 1
        for d in items:
            if d["id"] != "reception_desk" or d.get("dir") not in DESK_ROT:
                continue
            desks += 1
            k = DESK_ROT[d["dir"]]
            for o in items:
                if o is d or max(abs(o["x"] - d["x"]), abs(o["y"] - d["y"])) > DESK_R:
                    continue
                dx, dy = turn(o["x"] - d["x"], o["y"] - d["y"], k)
                odir = o.get("dir")
                if odir in DIRS:
                    odir = DIRS[(DIRS.index(odir) + k) % 4]
                desk[(o["id"], dx, dy, odir)] += 1

    def spots(counts, a, b):
        out = defaultdict(list)
        for (oid, u, v, d), n in counts.items():
            if n >= 2:
                out[oid].append({a: u, b: v, "dir": d, "seen": n})
        for oid in out:
            out[oid].sort(key=lambda s: (-s["seen"], abs(s[a]) + abs(s[b]), s[a], s[b], str(s["dir"])))
        return dict(sorted(out.items()))
    return {"doors_seen": doors, "door_spots": spots(door, "dc", "row"),
            "desks_seen": desks, "desk_spots": spots(desk, "dx", "dy")}


def corridor_habits(recs):
    """How far apart the experts keep their radiators and plants: the gap a
    quarter of them are closer than (at least 8 seen; within sane bounds)."""
    out = {}
    for kind, low, high in (("radiator", 2, 6), ("plant", 2, 5)):
        gaps = []
        for rec in recs:
            items = [o for o in rec["corridor"] if not is_fixture(o["id"])]
            gaps += nearest_gaps(items, kind)
        if len(gaps) >= 8:
            gaps.sort()
            out[kind + "_gap"] = max(low, min(high, gaps[len(gaps) // 4]))
            out[kind + "_seen"] = len(gaps)
    out.update(near_spots(recs))
    return out


def learn(paths, experts):
    """Recipes and plans from the experts' hospitals in the layouts."""
    want = {e.strip().upper() for e in experts if e.strip()}
    # The latest record of each (save, hospital): a save dumped twice counts once.
    records = {}
    for rec in read_layouts(paths):
        if rec["name"].upper() not in want or rec.get("bot") or rec.get("standin") or rec.get("ai"):
            continue
        records[(os.path.basename(rec["save"]), rec["index"], rec["date"])] = rec
    # One game's yearly saves show the same rooms again: each room counts
    # once per game place (its latest state), by kind and corner.
    rooms = {}
    sources = []
    latest_plan = {}
    for rec in sorted(records.values(), key=lambda r: date_key(r["date"])):
        sources.append({"player": rec["name"], "save": os.path.basename(rec["save"]), "date": rec["date"],
                        "level": rec["level"], "index": rec["index"], "rooms": len(rec["rooms"])})
        for room in rec["rooms"]:
            if room.get("built") and room.get("door"):
                rooms[(plan_key(rec), rec["name"].upper(), room["kind"], room["x"], room["y"])] = (rec, room)
        latest_plan[plan_key(rec)] = rec
    by_kind = defaultdict(list)
    for (_, _, kind, _, _), (rec, room) in rooms.items():
        by_kind[kind].append((rec, room))
    recipes = {}
    for kind, entries in sorted(by_kind.items()):
        sizes = Counter(frame_size(room) for _, room in entries)
        # The most used size; equal counts: the smaller one.
        (W, D), _ = min(sizes.items(), key=lambda kv: (-kv[1], kv[0][0] * kv[0][1], kv[0]))
        layouts = Counter()
        example = {}
        for rec, room in entries:
            if frame_size(room) != (W, D):
                continue
            w_, d_, col, objects = frame_layout(room)
            col, objects = canonical(W, col, objects)
            sig = json.dumps([col, objects], sort_keys=True)
            layouts[sig] += 1
            example[sig] = (rec, col, objects)
        sig, count = max(layouts.items(), key=lambda kv: (kv[1], kv[0]))
        rec, col, objects = example[sig]
        # The game's objects are not the same shape facing every way (and
        # some cannot face every way): a layout is copied exactly only into
        # a room with its door in the same wall at the same column. So the
        # layouts at that size as the experts had them, by door wall and
        # column, the most seen first; a bot builds the room to suit one.
        by_door = Counter()
        door_example = {}
        for _, room in entries:
            if frame_size(room) != (W, D):
                continue
            _, _, dcol, dobjects = frame_layout(room)
            key = (door_wall(room), dcol)
            dsig = json.dumps(dobjects, sort_keys=True)
            by_door[(key, dsig)] += 1
            door_example[(key, dsig)] = dobjects
        variants, walls_seen = [], set()
        for ((wall, dcol), dsig), n in sorted(by_door.items(), key=lambda kv: (-kv[1], kv[0])):
            if (wall, dcol) in walls_seen:
                continue
            walls_seen.add((wall, dcol))
            variants.append({"wall": wall, "col": dcol, "seen": n, "objects": door_example[((wall, dcol), dsig)]})
        recipes[kind] = {"w": W, "d": D, "door": col, "objects": objects, "seen": count,
                         "rooms": len(entries), "from": rec["name"], "variants": variants}
    plans = {}
    for key, rec in sorted(latest_plan.items()):
        if not any(r.get("built") and r.get("door") for r in rec["rooms"]):
            continue  # (a hospital without rooms yet: nothing to follow)
        plan_rooms = []
        for room in sorted(rec["rooms"], key=lambda r: (r["kind"], r["x"], r["y"])):
            if not (room.get("built") and room.get("door")):
                continue
            W, D, col, objects = frame_layout(room)
            plan_rooms.append({"kind": room["kind"], "x": room["x"], "y": room["y"], "w": room["w"],
                               "h": room["h"], "wall": door_wall(room), "fw": W, "fd": D, "door": col,
                               "objects": objects})
        # What stands in their corridors, nearest to their (first) reception
        # desk first: a bot fills the spots from there.
        items = [o for o in rec["corridor"] if not is_fixture(o["id"])]
        desks = [o for o in items if o["id"] == "reception_desk"]
        dx, dy = (desks[0]["x"], desks[0]["y"]) if desks else (0, 0)
        items.sort(key=lambda o: (abs(o["x"] - dx) + abs(o["y"] - dy), o["y"], o["x"], o["id"]))
        plan_objects = [{"id": o["id"], "dir": o.get("dir"), "tiles": sorted(o.get("tiles") or [[o["x"], o["y"]]])}
                        for o in items]
        corridor = Counter(o["id"] for o in items)
        plans[key] = {"player": rec["name"], "date": rec["date"], "rooms": plan_rooms,
                      "objects": plan_objects, "corridor": dict(sorted(corridor.items()))}
    return {"version": 1, "experts": sorted(want), "sources": sources, "recipes": recipes, "plans": plans,
            "corridor": corridor_habits(list(records.values()))}


def lua_value(v, indent=""):
    """Lua table constructor text for plain JSON-like data."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "nil"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    inner = indent + "  "
    if isinstance(v, dict):
        if not v:
            return "{}"
        parts = []
        for k in sorted(v):
            key = k if k.isidentifier() else "[" + lua_value(k) + "]"
            parts.append(f"{inner}{key} = {lua_value(v[k], inner)}")
        return "{\n" + ",\n".join(parts) + ",\n" + indent + "}"
    items = [lua_value(x, inner) for x in v]
    flat = "{" + ", ".join(items) + "}"
    if len(flat) < 100 and "\n" not in flat:
        return flat
    return "{\n" + ",\n".join(inner + x for x in items) + ",\n" + indent + "}"


def write_lua(data, path):
    text = ("-- What the bots learnt from expert players' hospitals (layout_learn.py).\n"
            "-- Made by the learning job; changes here are overwritten.\n"
            "return " + lua_value(data) + "\n")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.replace(tmp, path)


def print_recipes(data):
    for kind, r in data["recipes"].items():
        lines, keys = picture(r["w"], r["d"], r["door"], r["objects"])
        doors = ", ".join(f"{v['wall']} {v['col']}" for v in r.get("variants", []))
        print(f"{kind}: {r['w']} wide, {r['d']} deep, seen {r['seen']} of {r['rooms']} ({r['from']}); doors: {doors}")
        for l in lines:
            print("   " + l)
        print("   " + keys)
    for key, plan in data["plans"].items():
        print(f"plan {key}: {plan['player']} {plan['date']}, {len(plan['rooms'])} rooms, corridor {plan['corridor']}")


def main(argv):
    if argv and argv[0] == "--learn":
        out, experts, summary, paths = None, [], None, []
        i = 0
        while i < len(argv):
            a = argv[i]
            if a == "--learn":
                out = argv[i + 1]
                i += 2
            elif a == "--experts":
                experts = argv[i + 1].split(",")
                i += 2
            elif a == "--summary":
                summary = argv[i + 1]
                i += 2
            else:
                paths.append(a)
                i += 1
        if not out or not experts or not paths:
            print(__doc__)
            return 2
        data = learn(paths, experts)
        write_lua(data, out)
        if summary:
            with open(summary, "w", encoding="utf-8") as f:
                json.dump({"sources": data["sources"], "recipes": sorted(data["recipes"]),
                           "plans": sorted(data["plans"])}, f, indent=1)
        print_recipes(data)
        habits = data["corridor"]
        print("corridor habits: " + ", ".join(f"{k} {v}" for k, v in habits.items() if not k.endswith("spots")) +
              "; by doors: " + ", ".join(f"{k} {len(v)}" for k, v in habits["door_spots"].items()) +
              "; by desks: " + ", ".join(f"{k} {len(v)}" for k, v in habits["desk_spots"].items()))
        print(f"learnt {len(data['recipes'])} room recipes and {len(data['plans'])} plans from "
              f"{len(data['sources'])} hospitals; written to {out}")
        return 0
    if not argv:
        print(__doc__)
        return 2
    show(argv[0], argv[1] if len(argv) > 1 else "ARGUS", argv[2] if len(argv) > 2 else None)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
