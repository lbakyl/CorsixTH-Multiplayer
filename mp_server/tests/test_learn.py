import json
import os
import pathlib
import stat
import sys

import pytest

from corsixth_mp import daily_report, learn

REPO = pathlib.Path(__file__).resolve().parents[2]
# (Importing layout_learn.py from the scripts: no __pycache__ beside it.)
sys.dont_write_bytecode = True


def _room(kind, x, y, objects):
    """A 4 x 4 room with its door in the north wall at column 1."""
    return {"kind": kind, "x": x, "y": y, "w": 4, "h": 4, "built": True,
            "door": {"x": x + 1, "y": y, "dir": "north"},
            "objects": [{"id": i, "x": tx, "y": ty, "dir": d, "tiles": [[tx, ty]]} for i, tx, ty, d in objects]}


def _record(save, index, name, rooms, bot=False, date="2-01-01T00"):
    return {"save": save, "date": date, "map": [128, 128], "index": index, "level": "TEST TOWN",
            "hospitals": 3, "name": name, "bot": bot, "standin": False, "plots": [index],
            "rooms": rooms, "corridor": [{"id": "bench", "x": 9, "y": 9, "dir": "north", "tiles": [[9, 9]]}]}


def test_learnt_on_names_the_night_in_the_report(tmp_path):
    env = {"CORSIXTH_MP_STATS_DIR": str(tmp_path), "CORSIXTH_MP_SERVER_NAME": "eu2",
           "CORSIXTH_MP_LEARN_DIR": str(tmp_path)}
    (tmp_path / "runs.jsonl").write_text(
        json.dumps({"day": "2026-11-12", "learnt": [{"player": "ARGUS", "save": "20261112-210000 Argus's room y3-01-01",
                                                     "level": "CROSSROADS", "date": "3-01-01T00", "rooms": 27}]}) + "\n"
        + json.dumps({"day": "2026-11-13", "learnt": []}) + "\n", encoding="utf-8")
    text = daily_report.report("2026-11-12", env)
    assert text.splitlines()[-1] == ("Bots learnt from ARGUS: 20261112-210000 Argus's room y3-01-01 "
                                     "(CROSSROADS 3-01-01, 27 rooms)")
    # A night with nothing new: not mentioned.
    assert "learnt" not in daily_report.report("2026-11-13", env)
    assert "learnt" not in daily_report.report("2026-11-14", env)


def test_learning_is_off_without_a_folder_or_experts(tmp_path):
    assert learn.run({"CORSIXTH_MP_LEARN_DIR": str(tmp_path)})["learnt"] == []
    assert learn.run({"CORSIXTH_MP_EXPERTS": "Argus"})["learnt"] == []
    assert not (tmp_path / "runs.jsonl").exists()


@pytest.mark.skipif(os.name == "nt", reason="the stand-in game is a shell script")
def test_a_night_reads_new_saves_once_and_learns(tmp_path):
    folder = tmp_path / "learn"
    (folder / "saves").mkdir(parents=True)
    save = folder / "saves" / "20261112-210000 duo y2-01-01.sav"
    save.write_bytes(b"save")
    # The referee's note: a bot played hospital 3 at some time.
    save.with_suffix(".json").write_text(json.dumps({"hospitals": [
        {"index": 1, "name": "ARGUS", "expert": True, "bot_ever": False},
        {"index": 3, "name": "ARGUS", "expert": True, "bot_ever": True}]}), encoding="utf-8")
    records = [
        _record(str(save), 1, "ARGUS", [_room("gp", 10, 10, [("desk", 12, 12, "south"), ("radiator", 10, 13, "east")])]),
        _record(str(save), 2, "JAN", [_room("gp", 30, 10, [("desk", 31, 11, "north")])]),
        _record(str(save), 3, "ARGUS", [_room("pharmacy", 50, 10, [("pharmacy_cabinet", 51, 12, "west")])]),
    ]
    dump_out = tmp_path / "dump-lines.jsonl"
    dump_out.write_text("".join(json.dumps(r) + "\n" for r in records), encoding="utf-8")
    # A stand-in for the game running layout_dump.lua: copies the lines.
    game = tmp_path / "corsix-th"
    game.write_text("#!/bin/sh\ncp '%s' \"$MP_LAYOUT_OUT\"\necho \"dumped $MP_LAYOUT_SAVES\"\n" % dump_out)
    game.chmod(game.stat().st_mode | stat.S_IEXEC)
    env = {"CORSIXTH_MP_LEARN_DIR": str(folder), "CORSIXTH_MP_EXPERTS": "argus",
           "CORSIXTH_MP_REFEREE_BINARY": str(game), "CORSIXTH_MP_REFEREE_SOURCE": str(REPO),
           "CORSIXTH_MP_REFEREE_DATA": str(tmp_path), "PATH": os.environ.get("PATH", "")}
    summary = learn.run(env, now=1762984800.0)  # (2026-11-12 22:00 UTC)
    assert summary["saves"] == 1 and summary["errors"] == []
    # Argus's own hospital only: not Jan's, not the one a bot played.
    assert [(e["player"], e["rooms"]) for e in summary["learnt"]] == [("ARGUS", 1)]
    assert summary["recipes"] == 1 and summary["plans"] == 1
    text = (folder / "learned.lua").read_text(encoding="utf-8")
    assert "gp = {" in text and "pharmacy" not in text and '["TEST TOWN/128x128/3/1"]' in text
    assert learn.learnt_on(summary["day"], env)[0]["save"] == save.stem
    # The next night: nothing new.
    again = learn.run(env, now=1763071200.0)
    assert again["saves"] == 0 and again["learnt"] == [] and again["recipes"] == 1
    # A save the game could not read is tried again the next night.
    broken = folder / "saves" / "20261113-210000 trio y1-03-01.sav"
    broken.write_bytes(b"broken")
    game.write_text("#!/bin/sh\necho could not load\n")
    third = learn.run(env, now=1763157600.0)
    assert third["saves"] == 1 and third["errors"] == [f"could not read {broken.name}"]
    assert learn.run(env, now=1763244000.0)["saves"] == 1


def test_the_learned_file_loads_in_lua(tmp_path):
    """layout_learn.py writes plain Lua data (bot_learned.lua reads it)."""
    sys.path.insert(0, str(REPO / "scripts" / "multiplayer"))
    try:
        import layout_learn
    finally:
        sys.path.pop(0)
    data = {"version": 1, "experts": ["ARGUS"], "recipes": {"gp": {"w": 4, "d": 4, "door": 1, "objects": [
        {"id": "desk", "dir": "south", "tiles": [[2, 2]]}], "seen": 1, "rooms": 1, "from": "ARGUS"}},
        "plans": {"CROSSROADS/192x192/6/6": {"player": "ARGUS", "rooms": [], "objects": []}}}
    out = tmp_path / "learned.lua"
    layout_learn.write_lua(data, str(out))
    text = out.read_text(encoding="utf-8")
    assert text.startswith("-- What the bots learnt")
    assert 'return {' in text and '["CROSSROADS/192x192/6/6"] = {' in text and 'tiles = {{2, 2}}' in text


def test_corridor_habits_keep_radiators_apart():
    """The experts' radiators: the gap a quarter of them are closer than, so
    that a bot keeps its own as far apart (Argus: not flush together)."""
    sys.path.insert(0, str(REPO / "scripts" / "multiplayer"))
    try:
        import layout_learn
    finally:
        sys.path.pop(0)
    # Ten radiators in a row along a wall, 3 tiles apart, two of them 2 apart;
    # three plants only (too few to learn from).
    xs = [0, 3, 6, 9, 12, 15, 18, 21, 24, 26]
    corridor = [{"id": "radiator", "x": 10 + x, "y": 5, "dir": "north", "tiles": [[10 + x, 5]]} for x in xs]
    corridor += [{"id": "plant", "x": 10 + x, "y": 8, "dir": "north", "tiles": [[10 + x, 8]]} for x in (0, 1, 5)]
    rec = {"corridor": corridor}
    habits = layout_learn.corridor_habits([rec])
    assert (habits["radiator_gap"], habits["radiator_seen"]) == (3, 10) and "plant_gap" not in habits
    assert layout_learn.nearest_gaps(corridor, "plant") == [1, 1, 4]
    # Radiators flush together are not learnt as the habit: never below 2.
    flush = [{"id": "radiator", "x": x, "y": 5} for x in range(10)]
    assert layout_learn.corridor_habits([{"corridor": flush}])["radiator_gap"] == 2


def test_corridor_spots_by_doors_seen_from_the_door():
    """Where an expert's benches stand by a room's door, seen from the door
    (the room turned so that its door's wall is at the top)."""
    sys.path.insert(0, str(REPO / "scripts" / "multiplayer"))
    try:
        import layout_learn
    finally:
        sys.path.pop(0)
    # Two rooms 4 x 4: one with its door in the north wall at 11,10, a bench
    # beside it at 12,9 facing north; one with its door in the west wall at
    # 30,12 (rows of the room 10..13), a bench beside it at 29,11 facing west:
    # the same spot seen from the door (a column to the right, row -1).
    rooms = [{"kind": "gp", "x": 10, "y": 10, "w": 4, "h": 4, "built": True,
              "door": {"x": 11, "y": 10, "dir": "north"}, "objects": []},
             {"kind": "gp", "x": 30, "y": 10, "w": 4, "h": 4, "built": True,
              "door": {"x": 30, "y": 12, "dir": "west"}, "objects": []}]
    corridor = [{"id": "bench", "x": 12, "y": 9, "dir": "north", "tiles": [[12, 9]]},
                {"id": "bench", "x": 29, "y": 11, "dir": "west", "tiles": [[29, 11]]},
                {"id": "plant", "x": 40, "y": 40, "dir": "north", "tiles": [[40, 40]]}]
    near = layout_learn.near_spots([{"rooms": rooms, "corridor": corridor}])
    assert near["doors_seen"] == 2
    assert near["door_spots"] == {"bench": [{"dc": 1, "row": -1, "dir": "north", "seen": 2}]}
    assert near["desk_spots"] == {} and near["desks_seen"] == 0


def _layout_learn():
    sys.path.insert(0, str(REPO / "scripts" / "multiplayer"))
    try:
        import layout_learn
    finally:
        sys.path.pop(0)
    return layout_learn


def test_one_game_saved_many_times_counts_once(tmp_path):
    """Argus, 2026-11-14: one game continued from a save again and again, eight
    saves of it; each game counts once, as its latest save has it (Jan)."""
    layout_learn = _layout_learn()
    gp = _room("gp", 10, 10, [("desk", 12, 12, "south")])
    ward = _room("ward", 20, 10, [("bed", 21, 12, "south")])
    pharmacy = _room("pharmacy", 30, 10, [("pharmacy_cabinet", 31, 12, "west")])
    # Game one: three saves, growing (and one continued from the first save,
    # out of game-date order); game two at the same place: other corners.
    one = [_record("a y2.sav", 1, "ARGUS", [gp], date="2-01-01T00"),
           _record("b y3.sav", 1, "ARGUS", [gp, ward], date="3-01-01T00"),
           _record("c y2.sav", 1, "argus", [gp, ward, pharmacy], date="2-06-01T00"),
           _record("d y3.sav", 1, "ARGUS", [gp, ward, pharmacy], date="3-02-01T00")]
    two = [_record("e y1.sav", 1, "ARGUS", [_room("gp", 60, 60, [("desk", 61, 62, "south")])], date="1-04-01T00")]
    for rec in two:
        rec["corridor"] = [{"id": "bench", "x": 70, "y": 70, "dir": "north", "tiles": [[70, 70]]}]
    # The same rooms at another place (hospital 2): another game.
    other_place = [_record("a y2.sav", 2, "ARGUS", [gp], date="2-01-01T00")]
    groups = layout_learn.games(one + two + other_place)
    assert [[r["save"] for r in g] for g in groups] == [
        ["a y2.sav", "c y2.sav", "b y3.sav", "d y3.sav"], ["e y1.sav"], ["a y2.sav"]]
    assert layout_learn.games([]) == []
    # Learnt: each game once, as its latest save has it. The gp is seen in
    # three games (not in six saves).
    layouts = tmp_path / "layouts.jsonl"
    layouts.write_text("".join(json.dumps(r) + "\n" for r in one + two + other_place), encoding="utf-8")
    data = layout_learn.learn([str(layouts)], ["Argus"])
    assert [(s["save"], s["saves"]) for s in data["sources"]] == [("e y1.sav", 1), ("a y2.sav", 1), ("d y3.sav", 4)]
    assert data["recipes"]["gp"]["rooms"] == 3 and data["recipes"]["ward"]["rooms"] == 1


def test_a_hospital_without_rooms_teaches_nothing(tmp_path):
    layout_learn = _layout_learn()
    layouts = tmp_path / "layouts.jsonl"
    layouts.write_text(json.dumps(_record("x y1.sav", 1, "ARGUS", [], date="1-01-05T00")) + "\n", encoding="utf-8")
    data = layout_learn.learn([str(layouts)], ["Argus"])
    assert data["sources"] == [] and data["plans"] == {} and data["recipes"] == {}


def test_the_report_names_a_game_once_with_its_saves(tmp_path):
    env = {"CORSIXTH_MP_STATS_DIR": str(tmp_path), "CORSIXTH_MP_SERVER_NAME": "eu2",
           "CORSIXTH_MP_LEARN_DIR": str(tmp_path)}
    (tmp_path / "runs.jsonl").write_text(json.dumps({"day": "2026-11-14", "learnt": [
        {"player": "ARGUS", "save": "20261114-120641 Argus's room y5-01-08", "level": "CROSSROADS",
         "date": "5-01-08T00", "rooms": 26, "saves": 8},
        {"player": "ARGUS", "save": "20261114-192458 Jan's room y1-10-29", "level": "CROSSROADS",
         "date": "1-10-29T23", "rooms": 20}]}) + "\n", encoding="utf-8")
    lines = daily_report.report("2026-11-14", env).splitlines()
    assert lines[-2:] == [
        "Bots learnt from ARGUS: 20261114-120641 Argus's room y5-01-08 (CROSSROADS 5-01-08, 26 rooms, latest of 8 saves)",
        "Bots learnt from ARGUS: 20261114-192458 Jan's room y1-10-29 (CROSSROADS 1-10-29, 20 rooms)"]


def test_the_night_reports_each_game_once():
    """The night's saves of one game: one line, its latest save, and how many
    saves it had; a hospital without rooms yet: none."""
    gp = _room("gp", 10, 10, [("desk", 12, 12, "south")])
    ward = _room("ward", 20, 10, [("bed", 21, 12, "south")])
    records = [_record("/l/saves/1 a y2.sav", 1, "ARGUS", [gp], date="2-01-01T00"),
               _record("/l/saves/2 a y3.sav", 1, "ARGUS", [gp, ward], date="3-01-01T00"),
               _record("/l/saves/3 b y1.sav", 1, "ARGUS", [], date="1-01-05T00")]
    records[-1]["corridor"] = []  # (another game, just started)
    learnt = learn._learnt(records, {"CORSIXTH_MP_REFEREE_SOURCE": str(REPO)})
    assert learnt == [{"player": "ARGUS", "save": "2 a y3", "level": "TEST TOWN", "date": "3-01-01T00",
                       "rooms": 2, "saves": 2}]
