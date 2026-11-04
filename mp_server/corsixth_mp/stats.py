"""What the server keeps for its daily report (daily_report.py): every game
played (games.jsonl, a line per game when its room closes) and what the
bots' advice cost (ai-daily.json, per local day).

The files go to CORSIXTH_MP_STATS_DIR, by default /var/lib/corsixth if that
folder exists (else nothing is kept). Days are local days in
CORSIXTH_MP_REPORT_TZ (default Europe/Prague), as the report is read.
"""

from __future__ import annotations

import datetime
import json
import logging
import os
import pathlib

log = logging.getLogger("corsixth_mp.stats")

DEFAULT_TZ = "Europe/Prague"
KEEP_DAYS = 90


def stats_dir(env: dict[str, str] | None = None) -> pathlib.Path | None:
    env = os.environ if env is None else env
    folder = env.get("CORSIXTH_MP_STATS_DIR")
    if folder:
        return pathlib.Path(folder)
    default = pathlib.Path("/var/lib/corsixth")
    return default if default.is_dir() else None


def timezone(env: dict[str, str] | None = None) -> datetime.tzinfo:
    env = os.environ if env is None else env
    name = env.get("CORSIXTH_MP_REPORT_TZ", DEFAULT_TZ)
    try:
        from zoneinfo import ZoneInfo  # noqa: PLC0415
        return ZoneInfo(name)
    except Exception:  # (no tz database: UTC)
        return datetime.timezone.utc


def local_day(ts: float, env: dict[str, str] | None = None) -> str:
    return datetime.datetime.fromtimestamp(ts, timezone(env)).strftime("%Y-%m-%d")


def record_game(game: dict, env: dict[str, str] | None = None) -> None:
    """One game played: room, mode, level, started/ended (Unix time),
    humans and bots (names), repairs."""
    folder = stats_dir(env)
    if folder is None:
        return
    try:
        with open(folder / "games.jsonl", "a", encoding="utf-8") as f:
            f.write(json.dumps(game, ensure_ascii=False) + "\n")
    except OSError as exc:
        log.warning("cannot record the game: %s", exc)


def record_advice(cost: float, now: float, env: dict[str, str] | None = None) -> None:
    """One answer of the language model and what it cost, on its local day."""
    folder = stats_dir(env)
    if folder is None:
        return
    path = folder / "ai-daily.json"
    try:
        data = json.loads(path.read_text(encoding="utf-8")) if path.is_file() else {}
    except (OSError, ValueError):
        data = {}
    day = local_day(now, env)
    entry = data.get(day) or {"usd": 0.0, "answers": 0}
    entry["usd"] = round(float(entry.get("usd", 0)) + cost, 6)
    entry["answers"] = int(entry.get("answers", 0)) + 1
    data[day] = entry
    for old in sorted(data)[:-KEEP_DAYS]:
        del data[old]
    try:
        path.write_text(json.dumps(data, sort_keys=True), encoding="utf-8")
    except OSError as exc:
        log.warning("cannot record the advice cost: %s", exc)
