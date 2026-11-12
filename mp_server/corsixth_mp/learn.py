"""The bots learn from expert players' games: once a night, the new saves.

While a person named like an expert (CORSIXTH_MP_EXPERTS, "Argus,Matroftt")
plays their own hospital, the room's referee saves the game at the end of
every game year and when the game ends, into CORSIXTH_MP_LEARN_DIR/saves
(scripts/multiplayer/referee.lua). This reads the saves it has not read yet
(scripts/multiplayer/layout_dump.lua, run with the referee's game), keeps
the experts' hospitals that no bot ever played (the .json beside each save),
and writes what the bots learn from all of them so far (learned.lua,
scripts/multiplayer/layout_learn.py). Bots started from then on read it
(scripts/multiplayer/bot.lua): they build their rooms the size the experts
do, put things where the experts put them, and on a map and place an expert
played they follow that expert's hospital.

    python -m corsixth_mp.learn [--dry-run]

Files in CORSIXTH_MP_LEARN_DIR: saves/ (the referee's), builds/ (what the
experts built, as it happened), layouts.jsonl (every hospital learnt from),
learned.lua (for the bots), runs.jsonl (a line per run: what was new; the
daily report names it), state.json (the saves read). The referee's game is
the server's own (CORSIXTH_MP_REFEREE_BINARY, _SOURCE, _DATA). A systemd
timer runs it every morning before the daily report
(deploy/setup-referee-host.sh). Without CORSIXTH_MP_LEARN_DIR or experts it
does nothing.
"""

from __future__ import annotations

import argparse
import datetime
import importlib.util
import json
import os
import pathlib
import subprocess
import sys
import time

from . import stats

DUMP_TIMEOUT = 1800  # seconds for reading the night's saves


def learn_dir(env: dict[str, str] | None = None) -> pathlib.Path | None:
    env = os.environ if env is None else env
    folder = env.get("CORSIXTH_MP_LEARN_DIR", "")
    return pathlib.Path(folder) if folder else None


def experts(env: dict[str, str] | None = None) -> list[str]:
    env = os.environ if env is None else env
    return [n.strip() for n in env.get("CORSIXTH_MP_EXPERTS", "").split(",") if n.strip()]


def _layout_learn(source: str):
    """scripts/multiplayer/layout_learn.py of the referee's source tree."""
    path = pathlib.Path(source) / "scripts" / "multiplayer" / "layout_learn.py"
    spec = importlib.util.spec_from_file_location("layout_learn", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _read_json(path: pathlib.Path, default):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default


def _write_json(path: pathlib.Path, data) -> None:
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=1, sort_keys=True), encoding="utf-8")
    os.replace(tmp, path)


def pending(folder: pathlib.Path) -> list[pathlib.Path]:
    """The saves not read yet, oldest first."""
    done = set(_read_json(folder / "state.json", {}).get("done", []))
    saves = sorted((folder / "saves").glob("*.sav")) if (folder / "saves").is_dir() else []
    return [s for s in saves if s.name not in done]


def dump(env: dict[str, str], saves: list[pathlib.Path], out: pathlib.Path, work: pathlib.Path) -> str:
    """Run the referee's game over the saves (layout_dump.lua); its output."""
    work.mkdir(parents=True, exist_ok=True)
    (work / "saves").mkdir(exist_ok=True)
    (work / "config").mkdir(exist_ok=True)
    config = work / "config.txt"
    config.write_text(
        f"theme_hospital_install = [[{env.get('CORSIXTH_MP_REFEREE_DATA', '')}]]\n"
        f"savegames = [[{work / 'saves'}]]\n"
        'player_name = "Learning"\n'
        "fullscreen = false\nwidth = 640\nheight = 480\nlanguage = [[English]]\n"
        "audio = false\nplay_music = false\nplay_sounds = false\nplay_announcements = false\n"
        "movies = false\nplay_intro = false\nplay_demo = false\ncheck_for_updates = false\n",
        encoding="utf-8")
    source = env.get("CORSIXTH_MP_REFEREE_SOURCE", "")
    run_env = dict(env)
    run_env.pop("ANTHROPIC_API_KEY", None)
    run_env.pop("DISCORD_WEBHOOK_URL", None)
    run_env.update({
        "CORSIXTH_SOURCE": source,
        "MP_LAYOUT_SAVES": ";".join(str(s) for s in saves),
        "MP_LAYOUT_OUT": str(out),
        "SDL_VIDEODRIVER": "dummy", "SDL_AUDIO_DRIVER": "dummy", "SDL_RENDER_DRIVER": "software",
        "XDG_CONFIG_HOME": str(work / "config"),
    })
    result = subprocess.run(
        [env.get("CORSIXTH_MP_REFEREE_BINARY", ""),
         f"--interpreter={source}/scripts/multiplayer/layout_dump.lua", f"--config-file={config}"],
        env=run_env, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=DUMP_TIMEOUT)
    return result.stdout + result.stderr


def _bot_ever(save: pathlib.Path) -> set[int]:
    """The hospitals a bot played at some time (the referee's .json)."""
    info = _read_json(save.with_suffix(".json"), {})
    return {int(h["index"]) for h in info.get("hospitals", []) if h.get("bot_ever")}


def run(env: dict[str, str] | None = None, now: float | None = None, dry_run: bool = False) -> dict:
    """Read the new saves and learn again; what was new (also in runs.jsonl)."""
    env = dict(os.environ if env is None else env)
    folder = learn_dir(env)
    names = experts(env)
    now = time.time() if now is None else now
    # The day the daily report about it is for: the night's run in the
    # morning belongs to the day before; a run by hand in the evening to
    # that day (its report comes the next morning).
    day = datetime.datetime.fromtimestamp(now - 12 * 3600, stats.timezone(env)).date().isoformat()
    summary = {"ran": now, "day": day, "saves": 0, "learnt": [], "errors": []}
    if folder is None or not names:
        summary["errors"].append("learning is off (no CORSIXTH_MP_LEARN_DIR or CORSIXTH_MP_EXPERTS)")
        return summary
    saves = pending(folder)
    summary["saves"] = len(saves)
    want = {n.upper() for n in names}
    new_records = []
    if saves:
        out = folder / "work" / "dump.jsonl"
        if out.exists():
            out.unlink()
        text = dump(env, saves, out, folder / "work")
        for save in saves:
            if f"dumped {save}" not in text:
                summary["errors"].append(f"could not read {save.name}")
        by_path = {str(s): s for s in saves}
        lines = out.read_text(encoding="utf-8").splitlines() if out.is_file() else []
        for line in lines:
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            save = by_path.get(rec.get("save", ""))
            if save is not None and rec.get("index") in _bot_ever(save):
                rec["standin"] = True  # (a bot played it at some time: not learnt from)
            new_records.append(rec)
            if (rec.get("name", "").upper() in want and not rec.get("bot") and not rec.get("standin")
                    and not rec.get("ai")):
                summary["learnt"].append({"player": rec["name"], "save": save.stem if save else rec.get("save"),
                                          "level": rec.get("level", ""), "date": rec.get("date", ""),
                                          "rooms": len(rec.get("rooms", []))})
    if dry_run:
        return summary
    layouts = folder / "layouts.jsonl"
    if new_records:
        with layouts.open("a", encoding="utf-8") as f:
            for rec in new_records:
                f.write(json.dumps(rec, sort_keys=True) + "\n")
    if layouts.is_file():
        learner = _layout_learn(env.get("CORSIXTH_MP_REFEREE_SOURCE", ""))
        data = learner.learn([str(layouts)], names)
        learner.write_lua(data, str(folder / "learned.lua"))
        summary["recipes"], summary["plans"] = len(data["recipes"]), len(data["plans"])
    state = _read_json(folder / "state.json", {})
    state["done"] = sorted(set(state.get("done", [])) | {s.name for s in saves})
    _write_json(folder / "state.json", state)
    with (folder / "runs.jsonl").open("a", encoding="utf-8") as f:
        f.write(json.dumps(summary, sort_keys=True) + "\n")
    return summary


def learnt_on(day: str, env: dict[str, str] | None = None) -> list[dict]:
    """What the bots learnt in the night after that local day (runs.jsonl)."""
    folder = learn_dir(env)
    path = folder / "runs.jsonl" if folder else None
    out: list[dict] = []
    if path and path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("day") == day:
                out.extend(entry.get("learnt", []))
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dry-run", action="store_true", help="read the new saves, change nothing")
    args = parser.parse_args(argv)
    summary = run(dry_run=args.dry_run)
    for e in summary["learnt"]:
        print(f"learnt from {e['player']}: {e['save']} ({e['level']}, {e['date']}, {e['rooms']} rooms)")
    for err in summary["errors"]:
        print(err, file=sys.stderr)
    print(f"{summary['saves']} new saves; {summary.get('recipes', 0)} room recipes, "
          f"{summary.get('plans', 0)} plans")
    return 0


if __name__ == "__main__":
    sys.exit(main())
